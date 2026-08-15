import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vipinde_todo/core/app_theme.dart';
import 'package:vipinde_todo/core/ui_state.dart';
import 'package:vipinde_todo/models/github_user.dart';
import 'package:vipinde_todo/providers/user_search_provider.dart';
import 'package:vipinde_todo/screens/repositories_screen.dart';
import 'package:vipinde_todo/widgets/app_header.dart';
import 'package:vipinde_todo/widgets/error_view.dart';
import 'package:vipinde_todo/widgets/recent_searches_bar.dart';
import 'package:vipinde_todo/widgets/user_profile_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load the persisted history once the first frame is scheduled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserSearchProvider>().loadRecentSearches();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final query = (value ?? _controller.text).trim();
    _focusNode.unfocus();
    if (_controller.text != query) _controller.text = query;
    context.read<UserSearchProvider>().search(query);
  }

  void _searchRecent(String username) {
    _controller.text = username;
    _submit(username);
  }

  void _openRepositories(GithubUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RepositoriesScreen(user: user),
      ),
    );
  }

  /// The device back button on this screen would leave the app, so confirm
  /// first. A focused keyboard is dismissed instead — that is what the back
  /// button is expected to do while typing.
  Future<void> _handleBackPressed() async {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExitConfirmationDialog(),
    );

    if (shouldExit ?? false) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never pop straight away: _handleBackPressed decides what happens.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Welcome',
            subtitle: 'GitHub profile explorer',
            child: _SearchField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _submit,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  RecentSearchesBar(onSelected: _searchRecent),
                  Expanded(
                    child: Consumer<UserSearchProvider>(
                      builder: (context, provider, _) {
                        return switch (provider.state) {
                          Idle<GithubUser>() => const EmptyView(
                              icon: Icons.person_search_rounded,
                              title: 'Search for a GitHub user',
                              message: 'Enter a username above to see their '
                                  'profile and repositories.',
                            ),
                          Loading<GithubUser>() => const _LoadingView(),
                          Failure<GithubUser>(:final error) => ErrorView(
                              error: error,
                              onRetry:
                                  provider.lastQuery.isEmpty ? null : provider.retry,
                            ),
                          Success<GithubUser>(:final data) => SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                AppShape.screenPadding,
                                4,
                                AppShape.screenPadding,
                                28,
                              ),
                              child: UserProfileCard(
                                user: data,
                                onTap: () => _openRepositories(data),
                              ),
                            ),
                        };
                      },
                    ),
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

/// Asks the user to confirm leaving the app. Pops `true` to exit.
class _ExitConfirmationDialog extends StatelessWidget {
  const _ExitConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.exit_to_app_rounded,
          size: 24,
          color: scheme.onPrimaryContainer,
        ),
      ),
      title: const Text('Exit Confirmation'),
      content: const Text(
        'Are you sure you want to close vipinde_ToDo?',
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Search input, styled to sit on top of the coloured header.
///
/// The pill itself owns the border and the focus highlight; the [TextField]
/// inside is chrome-free, so the field and its action button read as one
/// control instead of a box within a box.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  static const double _height = 54;

  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _hasFocus != widget.focusNode.hasFocus) {
      setState(() => _hasFocus = widget.focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLoading = context.select<UserSearchProvider, bool>(
      (p) => p.state.isLoading,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: _height,
      padding: const EdgeInsets.only(left: 16, right: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppShape.field,
        border: Border.all(
          // Transparent rather than absent, so nothing shifts on focus.
          color: _hasFocus ? scheme.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.alternate_email_rounded,
            size: 20,
            color: _hasFocus ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              onSubmitted: isLoading ? null : widget.onSubmitted,
              cursorColor: scheme.primary,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              // Every scrap of decoration is stripped: the pill provides it.
              decoration: InputDecoration(
                hintText: 'GitHub username',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  )
                : IconButton.filled(
                    onPressed: () => widget.onSubmitted(widget.controller.text),
                    icon: const Icon(Icons.search_rounded, size: 20),
                    tooltip: 'Search',
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

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
            child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Looking up profile…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
