import 'package:flutter/material.dart';

/// Clera brand icon — scan frame + leaf + scan line
class CleraIcon extends StatelessWidget {
  const CleraIcon({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CleraIconPainter(),
    );
  }
}

/// Clera wordmark: CLERA. with the dot in brand green
class CleraWordmark extends StatelessWidget {
  const CleraWordmark({super.key, this.fontSize = 22, this.dark = false});
  final double fontSize;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'CLERA',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * fontSize,
              color: dark ? Colors.white : const Color(0xFF0D4A2E),
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2ABF6A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleraIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bracketPaint = Paint()
      ..color = const Color(0xFF4EE890)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bracketLen = w * 0.28;
    final margin = w * 0.18;

    // Scan frame brackets
    canvas.drawLine(Offset(margin, margin + bracketLen), Offset(margin, margin), bracketPaint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + bracketLen, margin), bracketPaint);
    canvas.drawLine(Offset(w - margin - bracketLen, margin), Offset(w - margin, margin), bracketPaint);
    canvas.drawLine(Offset(w - margin, margin), Offset(w - margin, margin + bracketLen), bracketPaint);
    canvas.drawLine(Offset(margin, h - margin - bracketLen), Offset(margin, h - margin), bracketPaint);
    canvas.drawLine(Offset(margin, h - margin), Offset(margin + bracketLen, h - margin), bracketPaint);
    canvas.drawLine(Offset(w - margin - bracketLen, h - margin), Offset(w - margin, h - margin), bracketPaint);
    canvas.drawLine(Offset(w - margin, h - margin), Offset(w - margin, h - margin - bracketLen), bracketPaint);

    // Leaf
    final cx = w / 2;
    final leafTop = h * 0.28;
    final leafBot = h * 0.72;
    final leafPaint = Paint()
      ..color = const Color(0xFF2ABF6A)
      ..style = PaintingStyle.fill;
    final leafPath = Path()
      ..moveTo(cx, leafTop)
      ..cubicTo(cx - w * 0.18, h * 0.38, cx - w * 0.18, h * 0.58, cx, leafBot)
      ..cubicTo(cx + w * 0.18, h * 0.58, cx + w * 0.18, h * 0.38, cx, leafTop)
      ..close();
    canvas.drawPath(leafPath, leafPaint);

    // Leaf vein
    final linePaint = Paint()
      ..color = const Color(0xFF0D4A2E)
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, leafTop + h * 0.04), Offset(cx, leafBot - h * 0.04), linePaint);

    // Dashed scan line
    final scanPaint = Paint()
      ..color = const Color(0xFF4EE890).withOpacity(0.5)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke;
    final dashW = w * 0.07;
    final dashGap = w * 0.05;
    double x = margin;
    final y = h / 2;
    while (x < w - margin) {
      canvas.drawLine(Offset(x, y), Offset((x + dashW).clamp(0, w - margin), y), scanPaint);
      x += dashW + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
