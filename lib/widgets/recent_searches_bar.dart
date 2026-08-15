import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vipinde_todo/core/app_theme.dart';
import 'package:vipinde_todo/providers/user_search_provider.dart';

/// Horizontal list of the last few searched usernames. Tapping one runs that
/// search again immediately. Renders nothing when there is no history.
class RecentSearchesBar extends StatelessWidget {
  const RecentSearchesBar({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recent = context.select<UserSearchProvider, List<String>>(
      (p) => p.recentSearches,
    );

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppShape.screenPadding, 18, 8, 0),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Recent searches',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: context.read<UserSearchProvider>().clearRecentSearches,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppShape.screenPadding),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final username = recent[index];
              return ActionChip(
                label: Text(username),
                onPressed: () => onSelected(username),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: scheme.surface,
                side: BorderSide(color: scheme.outlineVariant),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}
