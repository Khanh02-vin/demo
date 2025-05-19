import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingIconTap;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool animate;
  final Duration animationDuration;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onLeadingIconTap,
    this.actions,
    this.showBackButton = false,
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            if (leadingIcon != null && !showBackButton)
              IconButton(
                icon: Icon(leadingIcon, color: AppTheme.textLight),
                onPressed: onLeadingIconTap,
              ),
            Expanded(
              child: Text(
                title,
                style: AppTheme.headingMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(
              left: showBackButton || leadingIcon != null ? 48 : 0,
              top: AppTheme.spacingSm,
            ),
            child: Text(
              subtitle!,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMedium),
            ),
          ),
      ],
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: animationDuration,
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: header,
      );
    }

    return header;
  }
} 