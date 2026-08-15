import 'package:flutter/material.dart';
import 'package:vipinde_todo/core/app_theme.dart';
import 'package:vipinde_todo/core/formatters.dart';
import 'package:vipinde_todo/models/github_user.dart';

/// Profile summary. Tapping it opens the user's repositories.
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  final GithubUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: AppShape.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppShape.card,
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(url: user.avatarUrl, fallback: user.login, size: 68),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.login}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              if (user.bio != null) ...[
                const SizedBox(height: 16),
                Text(
                  user.bio!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
              if (user.company != null || user.location != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (user.company != null)
                      _MetaLine(icon: Icons.business_rounded, text: user.company!),
                    if (user.location != null)
                      _MetaLine(icon: Icons.place_outlined, text: user.location!),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatTile(label: 'Followers', value: user.followers)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatTile(label: 'Following', value: user.following)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(label: 'Repositories', value: user.publicRepos),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar with a primary-tinted ring; falls back to the first initial while
/// loading or when the image cannot be fetched.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallback, required this.size});

  final String url;
  final String fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = fallback.isEmpty ? '?' : fallback.substring(0, 1).toUpperCase();

    Widget placeholder() => ColoredBox(
          color: scheme.primaryContainer,
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35), width: 2),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
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
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            formatCount(value),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
