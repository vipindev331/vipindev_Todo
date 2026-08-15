import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/models/repo_sort.dart';
import 'package:vipinde_todo/providers/repositories_provider.dart';
import 'package:vipinde_todo/services/github_api_service.dart';

class _FakeApi implements GithubApiService {
  _FakeApi({this.repos = const [], this.error});

  final List<GithubRepo> repos;
  final AppException? error;

  @override
  Future<List<GithubRepo>> fetchRepositories(
    String username, {
    int perPage = 100,
    CancelToken? cancelToken,
  }) async {
    final err = error;
    if (err != null) throw err;
    return repos;
  }

  @override
  Future<GithubUser> fetchUser(String username, {CancelToken? cancelToken}) =>
      throw UnimplementedError();
}

GithubRepo _repo(String name, int stars, String? updated) => GithubRepo.fromJson({
      'id': name.hashCode,
      'name': name,
      'stargazers_count': stars,
      'updated_at': updated,
    });

void main() {
  final repos = [
    _repo('popular', 900, '2021-01-01T00:00:00Z'),
    _repo('recent', 5, '2026-08-14T00:00:00Z'),
  ];

  test('load fills the list and defaults to sorting by stars', () async {
    final provider = RepositoriesProvider(api: _FakeApi(repos: repos), username: 'x');

    await provider.load();

    expect(provider.state, isA<Success<List<GithubRepo>>>());
    expect(provider.sort, RepoSort.stars);
    expect(provider.sortedRepos!.first.name, 'popular');
  });

  test('changing the sort reorders without refetching', () async {
    final provider = RepositoriesProvider(api: _FakeApi(repos: repos), username: 'x');
    await provider.load();

    var notifications = 0;
    provider.addListener(() => notifications++);
    provider.changeSort(RepoSort.recentlyUpdated);

    expect(provider.sortedRepos!.first.name, 'recent');
    expect(notifications, 1);

    // Selecting the same sort again is a no-op.
    provider.changeSort(RepoSort.recentlyUpdated);
    expect(notifications, 1);
  });

  test('an API error becomes a failure state', () async {
    final provider = RepositoriesProvider(
      api: _FakeApi(error: const AppException('Offline.', kind: ErrorKind.network)),
      username: 'x',
    );

    await provider.load();

    expect(provider.state, isA<Failure<List<GithubRepo>>>());
    expect(provider.sortedRepos, isNull);
  });

  test('an empty repo list is a success, not an error', () async {
    final provider = RepositoriesProvider(api: _FakeApi(), username: 'x');

    await provider.load();

    expect(provider.state, isA<Success<List<GithubRepo>>>());
    expect(provider.sortedRepos, isEmpty);
  });
}
