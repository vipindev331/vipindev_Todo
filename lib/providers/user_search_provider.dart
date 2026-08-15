import 'package:flutter/foundation.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/services/github_api_service.dart';
import 'package:vipinde_todo/services/recent_searches_service.dart';

/// Owns the state of the search screen: the profile lookup and the
/// locally-stored recent searches.
class UserSearchProvider extends ChangeNotifier {
  UserSearchProvider({
    required GithubApiService api,
    required RecentSearchesService recentSearches,
  })  : _api = api,
        _recentSearches = recentSearches;

  final GithubApiService _api;
  final RecentSearchesService _recentSearches;

  UiState<GithubUser> _state = const UiState.idle();
  List<String> _recent = const <String>[];
  String _lastQuery = '';

  /// Guards against a slow earlier request overwriting a newer one.
  int _requestId = 0;

  UiState<GithubUser> get state => _state;

  /// Stable instance — returning a fresh copy here would defeat `select()`.
  List<String> get recentSearches => _recent;
  String get lastQuery => _lastQuery;

  Future<void> loadRecentSearches() async {
    _recent = List.unmodifiable(await _recentSearches.load());
    notifyListeners();
  }

  Future<void> search(String username) async {
    final query = username.trim();
    if (query.isEmpty) {
      _lastQuery = '';
      _setState(const UiState.failure(
        AppException('Please enter a GitHub username.', kind: ErrorKind.notFound),
      ));
      return;
    }

    _lastQuery = query;
    final requestId = ++_requestId;
    _setState(const UiState.loading());

    try {
      final user = await _api.fetchUser(query);
      if (requestId != _requestId) return; // superseded by a newer search
      _setState(UiState.success(user));
      _recent = List.unmodifiable(await _recentSearches.add(user.login));
      notifyListeners();
    } on AppException catch (e) {
      if (requestId != _requestId) return;
      _setState(UiState.failure(e));
    } catch (_) {
      if (requestId != _requestId) return;
      _setState(const UiState.failure(
        AppException('Something went wrong. Please try again.'),
      ));
    }
  }

  /// Re-runs the most recent query, e.g. from a "Retry" button.
  Future<void> retry() => search(_lastQuery);

  Future<void> clearRecentSearches() async {
    _recent = List.unmodifiable(await _recentSearches.clear());
    notifyListeners();
  }

  void reset() {
    _requestId++;
    _lastQuery = '';
    _setState(const UiState.idle());
  }

  void _setState(UiState<GithubUser> next) {
    _state = next;
    notifyListeners();
  }
}
