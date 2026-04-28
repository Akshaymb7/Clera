import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? SSColors.surfaceDark : SSColors.paper2;
    final highlight = dark ? SSColors.surface2Dark : SSColors.surface;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(base, highlight, _anim.value),
        ),
      ),
    );
  }
}

// Skeleton row matching a history/scan card
class ScanCardSkeleton extends StatelessWidget {
  const ScanCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Skeleton(width: 44, height: 44, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                Skeleton(width: 100, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Skeleton(width: 36, height: 36, radius: 18),
        ],
      ),
    );
  }
}

// Skeleton for the result screen hero area
class ResultHeroSkeleton extends StatelessWidget {
  const ResultHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          // Hero ring placeholder
          Center(child: Skeleton(width: 160, height: 160, radius: 80)),
          const SizedBox(height: 22),
          Center(child: Skeleton(width: 80, height: 11)),
          const SizedBox(height: 8),
          Center(child: Skeleton(width: 180, height: 20)),
          const SizedBox(height: 24),
          Skeleton(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          Skeleton(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          Skeleton(width: 200, height: 14),
          const SizedBox(height: 24),
          Skeleton(width: double.infinity, height: 72, radius: 16),
          const SizedBox(height: 10),
          Skeleton(width: double.infinity, height: 72, radius: 16),
        ],
      ),
    );
  }
}
