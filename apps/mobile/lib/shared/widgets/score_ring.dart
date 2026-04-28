import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ScoreRing extends StatefulWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 186,
    this.strokeWidth = 13,
    this.animate = true,
  });

  final int score;
  final double size;
  final double strokeWidth;
  final bool animate;

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(ScoreRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final band = bandFromScore(widget.score);
    final brandColor = dark ? SSColors.forestDark : SSColors.forest;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final progress = widget.animate ? _anim.value : 1.0;
        final displayScore = (widget.score * progress).round();

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D dome background
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    colors: dark
                        ? [
                            const Color(0xFF242529),
                            const Color(0xFF16161A),
                            const Color(0xFF0E0E12),
                          ]
                        : [
                            Colors.white,
                            SSColors.paper,
                            const Color(0xFFE9E3D3),
                          ],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: dark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(0xFF123C24).withOpacity(0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                ),
              ),
              // Ring painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: progress * widget.score / 100,
                  strokeWidth: widget.strokeWidth,
                  brandColor: brandColor,
                  dark: dark,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$displayScore',
                        style: TextStyle(
                          fontFamily: SSTypography.displayFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: widget.size * 0.36,
                          height: 1,
                          letterSpacing: -1.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: dark ? SSColors.inkDark : SSColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${band.letter}',
                        style: TextStyle(
                          fontFamily: SSTypography.displayFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: widget.size * 0.18,
                          height: 1,
                          letterSpacing: -0.5,
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Band chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: band.softColor(dark),
                      borderRadius: SSRadius.borderFull,
                      border: Border.all(
                        color: band.color(dark).withOpacity(0.2),
                      ),
                      boxShadow: dark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                offset: const Offset(0, 1),
                                blurRadius: 1,
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BandIcon(band: band, size: 10),
                        const SizedBox(width: 5),
                        Text(
                          band.label.toUpperCase(),
                          style: TextStyle(
                            fontFamily: SSTypography.bodyFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: band.color(dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.brandColor,
    required this.dark,
  });

  final double progress;
  final double strokeWidth;
  final Color brandColor;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color =
            dark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFF123C24).withOpacity(0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    final sweep = 2 * math.pi * progress;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: [brandColor, brandColor.withOpacity(0.78)],
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Specular highlight arc (30% of progress length)
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep * 0.3,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = strokeWidth * 0.25
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.brandColor != brandColor;
}

// ─── Band icon (shape-distinct, never color-only) ─────────────────────────────

class BandIcon extends StatelessWidget {
  const BandIcon({super.key, required this.band, this.size = 14});

  final ScoreBand band;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = band.color(dark);
    return CustomPaint(
      size: Size(size, size),
      painter: _BandIconPainter(band: band, color: color),
    );
  }
}

class _BandIconPainter extends CustomPainter {
  _BandIconPainter({required this.band, required this.color});
  final ScoreBand band;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final s = size.width;
    switch (band) {
      case ScoreBand.excellent:
        // Star
        final path = Path();
        final cx = s / 2, cy = s / 2;
        for (var i = 0; i < 5; i++) {
          final outer = math.pi * 2 * i / 5 - math.pi / 2;
          final inner = outer + math.pi / 5;
          final ox = cx + math.cos(outer) * s * 0.45;
          final oy = cy + math.sin(outer) * s * 0.45;
          final ix = cx + math.cos(inner) * s * 0.2;
          final iy = cy + math.sin(inner) * s * 0.2;
          if (i == 0) {
            path.moveTo(ox, oy);
          } else {
            path.lineTo(ox, oy);
          }
          path.lineTo(ix, iy);
        }
        path.close();
        canvas.drawPath(path, paint);
      case ScoreBand.good:
        canvas.drawCircle(Offset(s / 2, s / 2), s * 0.39, paint);
      case ScoreBand.caution:
        final path = Path()
          ..moveTo(s / 2, s * 0.07)
          ..lineTo(s * 0.93, s * 0.93)
          ..lineTo(s * 0.07, s * 0.93)
          ..close();
        canvas.drawPath(path, paint);
      case ScoreBand.poor:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.14, s * 0.14, s * 0.72, s * 0.72),
            const Radius.circular(2),
          ),
          paint,
        );
      case ScoreBand.avoid:
        final path = Path()
          ..moveTo(s / 2, s * 0.07)
          ..lineTo(s * 0.93, s / 2)
          ..lineTo(s / 2, s * 0.93)
          ..lineTo(s * 0.07, s / 2)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BandIconPainter old) =>
      old.band != band || old.color != color;
}
