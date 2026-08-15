import 'package:flutter/material.dart';
import 'package:vipinde_todo/core/app_exception.dart';
import 'package:vipinde_todo/core/app_theme.dart';

/// Shared empty/error presentation so every failure looks the same.
///
/// The state is carried by the icon and copy rather than by a warning colour,
/// which keeps the screen inside the two-colour palette.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final AppException error;
  final VoidCallback? onRetry;

  IconData get _icon => switch (error.kind) {
        ErrorKind.network => Icons.wifi_off_rounded,
        ErrorKind.notFound => Icons.person_search_rounded,
        ErrorKind.rateLimited => Icons.hourglass_empty_rounded,
        ErrorKind.server => Icons.cloud_off_rounded,
        ErrorKind.unknown => Icons.error_outline_rounded,
      };

  String get _title => switch (error.kind) {
        ErrorKind.network => 'No connection',
        ErrorKind.notFound => 'User not found',
        ErrorKind.rateLimited => 'Slow down a moment',
        ErrorKind.server => 'GitHub is unhappy',
        ErrorKind.unknown => 'Something went wrong',
      };

  @override
  Widget build(BuildContext context) {
    return _MessagePanel(
      icon: _icon,
      title: _title,
      message: error.message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
    );
  }
}

/// Neutral placeholder for "nothing here yet" situations.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return _MessagePanel(icon: icon, title: title, message: message);
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppShape.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
