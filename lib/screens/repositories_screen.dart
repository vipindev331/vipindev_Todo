import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vipinde_todo/core/app_theme.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_repo.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/models/repo_sort.dart';
import 'package:vipinde_todo/providers/repositories_provider.dart';
import 'package:vipinde_todo/services/github_api_service.dart';
import 'package:vipinde_todo/widgets/app_header.dart';
import 'package:vipinde_todo/widgets/error_view.dart';
import 'package:vipinde_todo/widgets/repo_tile.dart';

/// Repositories of a single user. Owns its own [RepositoriesProvider] so the
/// state is created and disposed with the route.
class RepositoriesScreen extends StatelessWidget {
  const RepositoriesScreen({super.key, required this.user});

  final GithubUser user;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RepositoriesProvider(
        api: context.read<GithubApiService>(),
        username: user.login,
      )..load(),
      child: _RepositoriesView(user: user),
    );
  }
}

class _RepositoriesView extends StatelessWidget {
  const _RepositoriesView({required this.user});

  final GithubUser user;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepositoriesProvider>();
    final repos = provider.sortedRepos;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            leading: _HeaderAvatar(url: user.avatarUrl, fallback: user.login),
            title: user.displayName,
            subtitle: repos == null
                ? '@${user.login}'
                : '@${user.login} · ${repos.length} '
                    '${repos.length == 1 ? 'repository' : 'repositories'}',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (repos != null && repos.isNotEmpty)
                    _SortBar(current: provider.sort, onChanged: provider.changeSort),
                  Expanded(
                    child: switch (provider.state) {
                      Idle<List<GithubRepo>>() || Loading<List<GithubRepo>>() =>
                        _LoadingView(),
                      Failure<List<GithubRepo>>(:final error) => ErrorView(
                          error: error,
                          onRetry: provider.load,
                        ),
                      Success<List<GithubRepo>>(:final data) when data.isEmpty =>
                        EmptyView(
                          icon: Icons.folder_off_rounded,
                          title: 'No public repositories',
                          message: '@${user.login} has not published any '
                              'repositories yet.',
                        ),
                      Success<List<GithubRepo>>() => _RepoList(
                          repos: repos ?? const [],
                          onRefresh: provider.load,
                        ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.url, required this.fallback});

  final String url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isEmpty ? '?' : fallback.substring(0, 1).toUpperCase();

    Widget placeholder() => ColoredBox(
          color: AppColors.onHeader.withValues(alpha: 0.18),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.onHeader,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );

    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: url.isEmpty
            ? placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder(),
                errorBuilder: (context, error, stack) => placeholder(),
              ),
      ),
    );
  }
}

class _RepoList extends StatelessWidget {
  const _RepoList({required this.repos, required this.onRefresh});

  final List<GithubRepo> repos;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppShape.screenPadding,
          4,
          AppShape.screenPadding,
          28,
        ),
        itemCount: repos.length,
        itemBuilder: (context, index) => RepoTile(repo: repos[index]),
      ),
    );
  }
}

/// Visible sort toggle: ⭐ Stars vs 🕒 Recently updated.
class _SortBar extends StatelessWidget {
  const _SortBar({required this.current, required this.onChanged});

  final RepoSort current;
  final ValueChanged<RepoSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppShape.screenPadding,
        16,
        AppShape.screenPadding,
        12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<RepoSort>(
          segments: [
            for (final option in RepoSort.values)
              ButtonSegment<RepoSort>(
                value: option,
                label: Text(
                  '${option.emoji} ${option.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selected: {current},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading repositories…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
