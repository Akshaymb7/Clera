import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../providers/scan_provider.dart';

class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  int _msgIdx = 0;
  bool _started = false;

  static const _messages = [
    'Reading your label…',
    'Checking ingredients…',
    'Cross-referencing safety data…',
    'Applying your profile…',
  ];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return false;
      setState(() => _msgIdx = (_msgIdx + 1) % _messages.length);
      return true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis() async {
    final pending = ref.read(pendingScanProvider);
    if (pending == null) {
      if (mounted) context.go('/home');
      return;
    }

    final id = await ref.read(scanNotifierProvider.notifier).analyze(
          imageBytes: pending.imageBytes,
          mimeType: pending.mimeType,
          category: pending.category,
        );

    if (!mounted) return;

    if (id != null) {
      ref.read(pendingScanProvider.notifier).state = null;
      context.pushReplacement('/result/$id');
    } else {
      final err = ref.read(scanNotifierProvider).error;
      if (err is QuotaExceededException) {
        _showQuotaDialog(err.message);
      } else {
        _showError();
      }
    }
  }

  void _showError() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Analysis failed'),
        content: const Text('Could not analyse the image. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/scan');
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  void _showQuotaDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan limit reached'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Maybe later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pushReplacement('/paywall');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
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
            SSTopBar(
              leading: SSIconBtn(
                icon: Icons.close,
                onTap: () => context.go('/home'),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ClipRRect(
                borderRadius: SSRadius.borderLg,
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.7, -0.7),
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [const Color(0xFF1E1F23), const Color(0xFF141519)]
                          : [const Color(0xFFFCFAF3), SSColors.paper2],
                    ),
                    border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
                    boxShadow: dark
                        ? [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))]
                        : [BoxShadow(color: const Color(0xFF123C24).withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 20))],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            9,
                            (i) => ClipRRect(
                              child: Container(
                                height: 6,
                                width: MediaQuery.of(context).size.width * (0.5 + (i * 9 % 45) / 100),
                                decoration: BoxDecoration(
                                  color: (dark ? SSColors.inkDark : SSColors.ink).withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        child: Text(
                          'ANALYSING LABEL…',
                          style: TextStyle(
                            fontFamily: SSTypography.monoFamily,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: dark ? SSColors.mutedDark : SSColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + _pulseCtrl.value * 0.06;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.3),
                              colors: [brand.withOpacity(0.93), brand, brand.withOpacity(0.67)],
                              stops: const [0, 0.6, 1],
                            ),
                            boxShadow: [BoxShadow(color: brand.withOpacity(0.33), blurRadius: 40, offset: const Offset(0, 20))],
                          ),
                          child: const Align(
                            alignment: Alignment(-0.3, -0.35),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0x66FFFFFF)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _messages[_msgIdx],
                      key: ValueKey(_msgIdx),
                      style: SSTypography.headline.copyWith(color: dark ? SSColors.inkDark : SSColors.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usually takes 2–3 seconds.',
                    style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final active = (_progressCtrl.value * 5) >= i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 26,
                            height: 5,
                            decoration: BoxDecoration(
                              color: active ? brand : (dark ? SSColors.lineDark : SSColors.line),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
