import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class SkeletonLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;
  
  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 4,
    this.isCircle = false,
  });
  
  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withOpacity(_animation.value),
            borderRadius: widget.isCircle 
                ? BorderRadius.circular(widget.height / 2) 
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  
  const SkeletonCard({
    super.key,
    this.height = 150,
    this.width = double.infinity,
    this.borderRadius = AppTheme.radiusMd,
    this.padding = const EdgeInsets.all(AppTheme.spacingMd),
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoading(
                width: 40,
                height: 40,
                isCircle: true,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoading(
                      width: width * 0.6,
                      height: 18,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    SkeletonLoading(
                      width: width * 0.4,
                      height: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const SkeletonLoading(height: 16),
          const SizedBox(height: AppTheme.spacingMd),
          const SkeletonLoading(height: 16),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SkeletonLoading(width: width * 0.25, height: 30),
              SkeletonLoading(width: width * 0.25, height: 30),
              SkeletonLoading(width: width * 0.25, height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final bool scrollable;
  
  const SkeletonListView({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 150,
    this.spacing = AppTheme.spacingMd,
    this.scrollable = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final list = List.generate(
      itemCount,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
        child: SkeletonCard(height: itemHeight),
      ),
    );
    
    if (scrollable) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: list,
      );
    }
    
    return Column(
      children: list,
    );
  }
} 