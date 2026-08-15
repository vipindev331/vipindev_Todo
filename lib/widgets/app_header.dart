import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vipinde_todo/core/app_theme.dart';

/// The rounded brand-coloured block that tops both screens.
///
/// Keeping the header in one widget is what makes the search screen and the
/// repositories screen read as the same app.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.leading,
    this.child,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;

  /// Optional widget shown to the left of the title (e.g. an avatar).
  final Widget? leading;

  /// Optional content pinned below the title, such as the search field.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = AppColors.header(theme.brightness);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppShape.headerRadius),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppShape.screenPadding,
          MediaQuery.paddingOf(context).top + 12,
          AppShape.screenPadding,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBackButton) ...[
                  _CircleAction(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                ],
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onHeader,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onHeader.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 20),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.onHeader.withValues(alpha: 0.16),
        foregroundColor: AppColors.onHeader,
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
