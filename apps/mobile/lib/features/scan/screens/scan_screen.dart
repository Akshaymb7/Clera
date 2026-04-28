import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _torchOn = false;
  String _category = 'Food';
  final _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    ref.read(pendingScanProvider.notifier).state = PendingScan(
      imageBytes: bytes,
      mimeType: 'image/jpeg',
      category: _category.toLowerCase(),
    );
    if (mounted) context.pushReplacement('/scan/analyzing');
  }
  late AnimationController _lineCtrl;
  late Animation<double> _lineAnim;

  static const _categories = ['Food', 'Cosmetic', 'Medicine', 'Household'];

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = SSColors.forest;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  _GlassBtn(
                    icon: Icons.close,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _GlassBtn(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    iconColor: _torchOn ? const Color(0xFFFFD47A) : Colors.white,
                    onTap: () => setState(() => _torchOn = !_torchOn),
                  ),
                  const SizedBox(width: 8),
                  _GlassBtn(
                    icon: Icons.image_outlined,
                    onTap: _pickFromGallery,
                  ),
                ],
              ),
            ),

            // Camera viewfinder
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera bg simulation
                  Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 1.2,
                        colors: [Color(0xFF2A2C27), Color(0xFF16181A), Color(0xFF0B0C0A)],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),

                  // Blur-text background
                  Positioned(
                    left: '14%'.isEmpty ? 0 : MediaQuery.of(context).size.width * 0.14,
                    right: MediaQuery.of(context).size.width * 0.14,
                    top: MediaQuery.of(context).size.height * 0.12,
                    bottom: MediaQuery.of(context).size.height * 0.18,
                    child: Opacity(
                      opacity: 0.14,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          14,
                          (i) => Container(
                            height: 1,
                            width: MediaQuery.of(context).size.width * (0.7 + (i * 7 % 28) / 100),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Viewfinder frame
                  Container(
                    width: 260,
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.38),
                          spreadRadius: 2000,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        // Corner markers
                        ..._corners(),

                        // Scan line
                        AnimatedBuilder(
                          animation: _lineAnim,
                          builder: (context, _) {
                            return Positioned(
                              left: 8,
                              right: 8,
                              top: 8 + (320 - 16) * _lineAnim.value,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      brand.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: brand.withOpacity(0.6),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Label
                        const Positioned(
                          bottom: -36,
                          left: 0,
                          right: 0,
                          child: Text(
                            'ALIGNING · HOLD STEADY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: SSTypography.monoFamily,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: Color(0xB3FFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const Text(
                    'Point at the ingredients list',
                    style: TextStyle(
                      fontFamily: SSTypography.displayFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Auto-captures when the text is sharp.',
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 13,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((c) {
                        final on = c == _category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _category = c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                              decoration: BoxDecoration(
                                color: on ? Colors.white : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: on ? Colors.white : Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontFamily: SSTypography.bodyFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: on ? const Color(0xFF0B0C0A) : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shutter row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassBtn(icon: Icons.history, size: 48, onTap: () => context.push('/history')),

                      // 3D shutter button
                      GestureDetector(
                        onTap: () async {
                          final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                          if (file == null || !mounted) return;
                          final bytes = await file.readAsBytes();
                          ref.read(pendingScanProvider.notifier).state = PendingScan(
                            imageBytes: bytes,
                            mimeType: 'image/jpeg',
                            category: _category.toLowerCase(),
                          );
                          if (mounted) context.pushReplacement('/scan/analyzing');
                        },
                        child: SizedBox(
                          width: 82,
                          height: 82,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 3,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: Alignment(-0.3, -0.3),
                                    colors: [Colors.white, Color(0xFFE8E6DE), Color(0xFFBFBCB0)],
                                    stops: [0, 0.7, 1],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x73000000),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      _GlassBtn(icon: Icons.auto_awesome_outlined, size: 48, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    return [
      _Corner(top: 0, left: 0, rotate: 0),
      _Corner(top: 0, right: 0, rotate: 90),
      _Corner(bottom: 0, left: 0, rotate: 270),
      _Corner(bottom: 0, right: 0, rotate: 180),
    ];
  }
}

class _Corner extends StatelessWidget {
  const _Corner({this.top, this.bottom, this.left, this.right, required this.rotate});
  final double? top, bottom, left, right;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotate * 3.14159 / 180,
        child: CustomPaint(
          size: const Size(28, 28),
          painter: _CornerPainter(),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(2, 12), const Offset(2, 4), paint);
    canvas.drawArc(
      const Rect.fromLTWH(2, 2, 8, 8),
      -3.14159 / 2,
      -3.14159 / 2,
      false,
      paint,
    );
    canvas.drawLine(const Offset(6, 2), const Offset(14, 2), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, this.iconColor, required this.onTap, this.size = 40});
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Icon(icon, size: size * 0.45, color: iconColor ?? Colors.white),
      ),
    );
  }
}
