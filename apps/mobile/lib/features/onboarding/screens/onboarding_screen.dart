import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/clera_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Already logged in → skip onboarding entirely
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
  }

  static const _slides = [
    _Slide(
      headline: 'Know what\'s inside.',
      body: 'Every product, every ingredient — understood in seconds, not hours.',
      icon: Icons.eco_rounded,
    ),
    _Slide(
      headline: 'Scan any label.',
      body: 'Food, cosmetics, medicine, household cleaners. Point. Tap. Done.',
      icon: Icons.camera_alt_outlined,
    ),
    _Slide(
      headline: 'Personal & private.',
      body: 'Your health profile stays on your device. We never sell your data.',
      icon: Icons.lock_outline_rounded,
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D4A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4EE890).withOpacity(0.2)),
                    ),
                    child: const Center(child: CleraIcon(size: 20)),
                  ),
                  const SizedBox(width: 10),
                  CleraWordmark(fontSize: 18, dark: dark),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/auth/login'),
                    child: Text('Skip', style: SSTypography.bodySemibold.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted)),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: _slides.length,
                itemBuilder: (context, i) =>
                    _SlideView(slide: _slides[i], dark: dark, brand: brand, isFirst: i == 0),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? brand : brand.withOpacity(0.25),
                    borderRadius: SSRadius.borderFull,
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SSPrimaryButton(
                label: _page < _slides.length - 1 ? 'Continue' : 'Get started',
                onTap: _next,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.headline,
    required this.body,
    required this.icon,
  });
  final String headline;
  final String body;
  final IconData icon;
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.dark,
    required this.brand,
    this.isFirst = false,
  });

  final _Slide slide;
  final bool dark;
  final Color brand;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFirst)
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0D4A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF4EE890).withOpacity(0.2)),
                boxShadow: [BoxShadow(color: const Color(0xFF0D4A2E).withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))],
              ),
              child: const Center(child: CleraIcon(size: 56)),
            )
          else
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [brand.withOpacity(0.9), brand, Color.lerp(brand, Colors.black, 0.2)!],
                  stops: const [0, 0.6, 1],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: brand.withOpacity(0.33), blurRadius: 40, offset: const Offset(0, 20))],
              ),
              child: Icon(slide.icon, color: Colors.white, size: 44),
            ),
          const SizedBox(height: 48),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: SSTypography.display.copyWith(
              color: dark ? SSColors.inkDark : SSColors.ink,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: SSTypography.body.copyWith(
              color: dark ? SSColors.mutedDark : SSColors.muted,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
