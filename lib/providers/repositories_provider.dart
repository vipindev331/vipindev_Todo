import 'package:flutter/foundation.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/repo_sort.dart';
import 'package:vipinde_todo/services/github_api_service.dart';

/// Owns the state of the repositories screen for a single user.
///
/// Created per-screen (not app-wide) so each visited profile gets a clean
/// slate and the state is disposed with the route.
class RepositoriesProvider extends ChangeNotifier {
  RepositoriesProvider({
    required GithubApiService api,
    required this.username,
  }) : _api = api;

  final GithubApiService _api;
  final String username;

  UiState<List<GithubRepo>> _state = const UiState.idle();
  RepoSort _sort = RepoSort.stars;

  UiState<List<GithubRepo>> get state => _state;
  RepoSort get sort => _sort;

  /// Repositories in the currently selected order, or `null` while the list
  /// has not loaded successfully.
  List<GithubRepo>? get sortedRepos {
    final repos = _state.dataOrNull;
    return repos == null ? null : _sort.apply(repos);
  }

  Future<void> load() async {
    _setState(const UiState.loading());
    try {
      final repos = await _api.fetchRepositories(username);
      _setState(UiState.success(repos));
    } on AppException catch (e) {
      _setState(UiState.failure(e));
    } catch (_) {
      _setState(const UiState.failure(
        AppException('Could not load repositories. Please try again.'),
      ));
    }
  }

  void changeSort(RepoSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void _setState(UiState<List<GithubRepo>> next) {
    _state = next;
    notifyListeners();
  }
}
