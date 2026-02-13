import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Visual indicator for streak with emoji and animation
class StreakIndicator extends StatefulWidget {
  final String label;
  final int streakValue;
  final IconData icon;
  final Color color;
  final bool isAnimated;
  final VoidCallback? onTap;

  const StreakIndicator({
    super.key,
    required this.label,
    required this.streakValue,
    this.icon = Icons.local_fire_department,
    this.color = AppColors.warning,
    this.isAnimated = false,
    this.onTap,
  });

  /// Create a fire emoji indicator for current streak
  factory StreakIndicator.currentStreak({
    required int streakValue,
    bool isAnimated = false,
    VoidCallback? onTap,
  }) {
    return StreakIndicator(
      label: 'Current Streak',
      streakValue: streakValue,
      icon: Icons.local_fire_department,
      color: AppColors.streakActive,
      isAnimated: isAnimated,
      onTap: onTap,
    );
  }

  /// Create a trophy emoji indicator for longest streak
  factory StreakIndicator.longestStreak({
    required int streakValue,
    VoidCallback? onTap,
  }) {
    return StreakIndicator(
      label: 'Longest Streak',
      streakValue: streakValue,
      icon: Icons.emoji_events,
      color: AppColors.streakRecord,
      isAnimated: false,
      onTap: onTap,
    );
  }

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated && !oldWidget.isAnimated) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimated && oldWidget.isAnimated) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isAnimated ? _scaleAnimation.value : 1.0,
                  child: Transform.rotate(
                    angle: widget.isAnimated ? _rotationAnimation.value : 0.0,
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Streak Information
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.streakValue.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.streakValue == 1 ? 'day' : 'days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Tap indicator
            if (widget.onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact streak badge for use in task items
class StreakBadge extends StatelessWidget {
  final int streakValue;
  final Color? color;

  const StreakBadge({
    super.key,
    required this.streakValue,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (streakValue == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.streakActive).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? AppColors.streakActive).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: color ?? AppColors.streakActive,
          ),
          const SizedBox(width: 2),
          Text(
            streakValue.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.streakActive,
            ),
          ),
        ],
      ),
    );
  }
}
