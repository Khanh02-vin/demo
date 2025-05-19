import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool iconLeading;
  final bool isLoading;
  final bool fullWidth;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.iconLeading = true,
    this.isLoading = false,
    this.fullWidth = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Determine button style based on type
    BoxDecoration? decoration;
    Color textColor;
    EdgeInsets padding;
    double height;
    TextStyle textStyle;

    // Set size parameters
    switch (size) {
      case ButtonSize.small:
        height = 36.0;
        padding = const EdgeInsets.symmetric(horizontal: 12.0);
        textStyle = AppTheme.labelSmall;
        break;
      case ButtonSize.large:
        height = 56.0;
        padding = const EdgeInsets.symmetric(horizontal: 24.0);
        textStyle = AppTheme.labelLarge;
        break;
      case ButtonSize.medium:
      default:
        height = 48.0;
        padding = const EdgeInsets.symmetric(horizontal: 16.0);
        textStyle = AppTheme.labelMedium;
        break;
    }

    // Set style parameters based on type
    switch (type) {
      case ButtonType.primary:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: AppTheme.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: onPressed == null ? null : [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.white;
        break;
      
      case ButtonType.secondary:
        decoration = BoxDecoration(
          color: AppTheme.cardLight,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: onPressed == null ? null : AppTheme.defaultShadow,
        );
        textColor = AppTheme.textLight;
        break;
      
      case ButtonType.outline:
        decoration = BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
        );
        textColor = AppTheme.primaryColor;
        break;
      
      case ButtonType.text:
        decoration = null;
        textColor = AppTheme.primaryColor;
        break;
    }

    // Build the button content
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else ...[
          if (icon != null && iconLeading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, color: textColor, size: size == ButtonSize.small ? 16 : 20),
            ),
          Text(
            text,
            style: textStyle.copyWith(color: textColor),
          ),
          if (icon != null && !iconLeading)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(icon, color: textColor, size: size == ButtonSize.small ? 16 : 20),
            ),
        ],
      ],
    );

    // Wrap with inkwell for ripple effect
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
        splashColor: type == ButtonType.primary 
            ? Colors.white.withOpacity(0.1) 
            : AppTheme.primaryColor.withOpacity(0.1),
        highlightColor: type == ButtonType.primary 
            ? Colors.white.withOpacity(0.1) 
            : AppTheme.primaryColor.withOpacity(0.05),
        child: Container(
          height: height,
          decoration: decoration,
          padding: padding,
          child: Center(child: content),
        ),
      ),
    );

    // Add opacity if disabled
    if (onPressed == null) {
      button = Opacity(
        opacity: 0.5,
        child: button,
      );
    }

    // Full width if requested
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
} 