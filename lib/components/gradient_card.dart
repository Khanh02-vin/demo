import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool animate;
  final Duration animationDuration;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradientColors,
    this.borderRadius = 24,
    this.boxShadow,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.width,
    this.height,
    this.onTap,
    this.animate = false,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: gradientColors ?? AppTheme.cardGradient,
        ),
        boxShadow: boxShadow ?? AppTheme.defaultShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          highlightColor: Colors.white.withOpacity(0.1),
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    // Apply animation if needed
    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: animationDuration,
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }
} 