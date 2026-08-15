import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/providers/user_search_provider.dart';
import 'package:vipinde_todo/screens/search_screen.dart';
import 'package:vipinde_todo/services/github_api_service.dart';
import 'package:vipinde_todo/services/recent_searches_service.dart';

class _FakeApi implements GithubApiService {
  _FakeApi({this.user, this.error, this.repos = const [], this.delay = Duration.zero});

  GithubUser? user;
  AppException? error;
  List<GithubRepo> repos;
  Duration delay;

  @override
  Future<GithubUser> fetchUser(String username, {CancelToken? cancelToken}) async {
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
      repos;
}

GithubUser _octocat() => GithubUser.fromJson(const {
      'login': 'octocat',
      'name': 'The Octocat',
      'bio': 'Just a mascot',
      'avatar_url': '',
      'followers': 1500,
      'following': 9,
      'public_repos': 8,
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(_FakeApi api) {
    return MultiProvider(
      providers: [
        Provider<GithubApiService>.value(value: api),
        ChangeNotifierProvider<UserSearchProvider>(
          create: (_) => UserSearchProvider(
            api: api,
            recentSearches: RecentSearchesService(),
          ),
        ),
      ],
      child: const MaterialApp(home: SearchScreen()),
    );
  }

  testWidgets('shows the empty prompt before any search', (tester) async {
    await tester.pumpWidget(wrap(_FakeApi()));
    await tester.pumpAndSettle();

    expect(find.text('Search for a GitHub user'), findsOneWidget);
  });

  testWidgets('renders the profile on a successful search', (tester) async {
    await tester.pumpWidget(wrap(_FakeApi(user: _octocat())));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'octocat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('The Octocat'), findsOneWidget);
    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('Just a mascot'), findsOneWidget);
    expect(find.text('1.5k'), findsOneWidget); // followers
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Repositories'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while the request is in flight',
      (tester) async {
    final api = _FakeApi(user: _octocat(), delay: const Duration(milliseconds: 50));
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'octocat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(); // one frame: the request is still in flight

    expect(find.text('Looking up profile…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Looking up profile…'), findsNothing);
  });

  testWidgets('shows the not-found message for an unknown user', (tester) async {
    await tester.pumpWidget(wrap(_FakeApi(
      error: const AppException('User not found.', kind: ErrorKind.notFound),
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('User not found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows a network error and retries on tap', (tester) async {
    final api = _FakeApi(
      error: const AppException('Offline.', kind: ErrorKind.network),
    );
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'octocat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);

    // Network comes back, user taps retry.
    api
      ..error = null
      ..user = _octocat();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('The Octocat'), findsOneWidget);
  });

  testWidgets('a recent-search chip re-runs that search', (tester) async {
    final api = _FakeApi(user: _octocat());
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'octocat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);

    // Clear the result, then tap the chip to search it again.
    tester.widget<TextField>(find.byType(TextField)).controller!.clear();
    await tester.tap(find.widgetWithText(ActionChip, 'octocat'));
    await tester.pumpAndSettle();

    expect(find.text('The Octocat'), findsOneWidget);
  });

  group('device back button', () {
    /// Records calls to SystemNavigator.pop(), i.e. "the app actually exited".
    List<MethodCall> captureSystemCalls(WidgetTester tester) {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      return calls;
    }

    testWidgets('asks for confirmation instead of leaving straight away',
        (tester) async {
      await tester.pumpWidget(wrap(_FakeApi()));
      await tester.pumpAndSettle();

      final exitCalls = captureSystemCalls(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Exit app?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(
        exitCalls.where((c) => c.method == 'SystemNavigator.pop'),
        isEmpty,
        reason: 'the app must not exit before the user confirms',
      );
    });

    testWidgets('Cancel closes the dialog and stays in the app', (tester) async {
      await tester.pumpWidget(wrap(_FakeApi()));
      await tester.pumpAndSettle();

      final exitCalls = captureSystemCalls(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Exit app?'), findsNothing);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(exitCalls.where((c) => c.method == 'SystemNavigator.pop'), isEmpty);
    });

    testWidgets('Exit closes the app', (tester) async {
      await tester.pumpWidget(wrap(_FakeApi()));
      await tester.pumpAndSettle();

      final exitCalls = captureSystemCalls(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      expect(
        exitCalls.map((c) => c.method),
        contains('SystemNavigator.pop'),
      );
    });

    testWidgets('dismisses the keyboard first when the field has focus',
        (tester) async {
      await tester.pumpWidget(wrap(_FakeApi()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // No dialog on the first press — the keyboard went away instead.
      expect(find.text('Exit app?'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Exit app?'), findsOneWidget);
    });
  });

  testWidgets('tapping the profile opens the repositories screen', (tester) async {
    final api = _FakeApi(
      user: _octocat(),
      repos: [
        GithubRepo.fromJson(const {
          'id': 1,
          'name': 'hello-world',
          'description': 'My first repo',
          'stargazers_count': 42,
          'language': 'Dart',
          'updated_at': '2026-08-14T00:00:00Z',
        }),
      ],
    );
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'octocat');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Octocat'));
    await tester.pumpAndSettle();

    expect(find.text('@octocat · 1 repository'), findsOneWidget);
    expect(find.text('hello-world'), findsOneWidget);
    expect(find.text('My first repo'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(find.text('⭐ Stars'), findsOneWidget);
    expect(find.text('🕒 Recently updated'), findsOneWidget);
  });
}
