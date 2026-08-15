import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/providers/user_search_provider.dart';
import 'package:vipinde_todo/services/github_api_service.dart';
import 'package:vipinde_todo/services/recent_searches_service.dart';

/// Stands in for the real API so the tests never touch the network.
class _FakeApi implements GithubApiService {
  _FakeApi({this.user, this.error, this.delay = Duration.zero});

  GithubUser? user;
  AppException? error;
  Duration delay;
  final List<String> calls = [];

  @override
  Future<GithubUser> fetchUser(String username, {CancelToken? cancelToken}) async {
    calls.add(username);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final err = error;
    if (err != null) throw err;
    return user!;
  }

  @override
  Future<List<GithubRepo>> fetchRepositories(
    String username, {
    int perPage = 100,
    CancelToken? cancelToken,
  }) async =>
      const [];
}

GithubUser _user(String login) => GithubUser.fromJson({
      'login': login,
      'avatar_url': '',
      'followers': 1,
      'following': 2,
      'public_repos': 3,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  UserSearchProvider build(_FakeApi api) => UserSearchProvider(
        api: api,
        recentSearches: RecentSearchesService(),
      );

  test('starts idle', () {
    expect(build(_FakeApi()).state, isA<Idle<GithubUser>>());
  });

  test('successful search moves loading -> success and records history', () async {
    final api = _FakeApi(user: _user('octocat'));
    final provider = build(api);

    final states = <UiState<GithubUser>>[];
    provider.addListener(() => states.add(provider.state));

    await provider.search('octocat');

    expect(states.first, isA<Loading<GithubUser>>());
    expect(provider.state, isA<Success<GithubUser>>());
    expect(provider.state.dataOrNull?.login, 'octocat');
    expect(provider.recentSearches, ['octocat']);
  });

  test('404 surfaces a notFound failure', () async {
    final provider = build(_FakeApi(
      error: const AppException('User not found.', kind: ErrorKind.notFound),
    ));

    await provider.search('definitely-not-a-user');

    final state = provider.state;
    expect(state, isA<Failure<GithubUser>>());
    expect((state as Failure<GithubUser>).error.kind, ErrorKind.notFound);
  });

  test('network failure surfaces a network failure and keeps no history', () async {
    final provider = build(_FakeApi(
      error: const AppException('Offline.', kind: ErrorKind.network),
    ));

    await provider.search('octocat');

    expect((provider.state as Failure<GithubUser>).error.kind, ErrorKind.network);
    expect(provider.recentSearches, isEmpty);
  });

  test('an empty query fails fast without hitting the API', () async {
    final api = _FakeApi(user: _user('octocat'));
    final provider = build(api);

    await provider.search('   ');

    expect(provider.state, isA<Failure<GithubUser>>());
    expect(api.calls, isEmpty);
  });

  test('a stale in-flight request cannot overwrite a newer result', () async {
    final slow = _FakeApi(user: _user('slow'), delay: const Duration(milliseconds: 80));
    final provider = build(slow);

    final first = provider.search('slow');
    slow
      ..user = _user('fast')
      ..delay = Duration.zero;
    await provider.search('fast');
    await first;

    expect(provider.state.dataOrNull?.login, 'fast');
  });

  test('history keeps only the last five, most recent first, de-duplicated',
      () async {
    final api = _FakeApi();
    final provider = build(api);

    for (final name in ['a', 'b', 'c', 'd', 'e', 'f']) {
      api.user = _user(name);
      await provider.search(name);
    }
    api.user = _user('c');
    await provider.search('C'); // different case, same user

    expect(provider.recentSearches, ['c', 'f', 'e', 'd', 'b']);
  });

  test('history survives a new provider instance', () async {
    final api = _FakeApi(user: _user('octocat'));
    await build(api).search('octocat');

    final fresh = build(api);
    await fresh.loadRecentSearches();

    expect(fresh.recentSearches, ['octocat']);
  });

  test('clearRecentSearches empties the history', () async {
    final provider = build(_FakeApi(user: _user('octocat')));
    await provider.search('octocat');

    await provider.clearRecentSearches();

    expect(provider.recentSearches, isEmpty);
  });
}
