import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/clera_icon.dart';

// Stores email across login → otp screens
final pendingEmailProvider = StateProvider<String>((ref) => '');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).sendOtp(email);
      ref.read(pendingEmailProvider.notifier).state = email;
      if (mounted) context.push('/auth/otp');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D4A2E),
                      borderRadius: SSRadius.borderSm,
                      border: Border.all(color: const Color(0xFF4EE890).withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D4A2E).withOpacity(dark ? 0.5 : 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: CleraIcon(size: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'CLERA',
                          style: SSTypography.headline.copyWith(
                            color: dark ? SSColors.inkDark : SSColors.ink,
                            fontFamily: SSTypography.displayFamily,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: SSTypography.headline.copyWith(
                            color: dark ? SSColors.forestDark : SSColors.forest,
                            fontFamily: SSTypography.displayFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                "Know what's\nreally inside.",
                style: SSTypography.display.copyWith(color: dark ? SSColors.inkDark : SSColors.ink, fontSize: 36),
              ),
              const SizedBox(height: 10),
              Text(
                'Scan any label — food, cosmetics, medicine — and get a plain-language safety read.',
                style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
              ),
              const SizedBox(height: 32),
              Text('EMAIL', style: SSTypography.mono.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
                  borderRadius: SSRadius.borderSm,
                  border: Border.all(color: _error != null ? Colors.red.shade300 : (dark ? SSColors.lineDark : SSColors.line)),
                  boxShadow: [
                    BoxShadow(
                      color: dark ? Colors.black.withOpacity(0.55) : const Color(0xFF123C24).withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.mail_outline, size: 16, color: dark ? SSColors.mutedDark : SSColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: SSTypography.body.copyWith(color: dark ? SSColors.inkDark : SSColors.ink),
                        decoration: InputDecoration(
                          hintText: 'you@email.com',
                          hintStyle: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _continue(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              SSPrimaryButton(label: _loading ? 'Sending…' : 'Continue', onTap: _loading ? null : _continue),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'By continuing, you agree to our Terms and Privacy Policy. Your scans are private.',
                  textAlign: TextAlign.center,
                  style: SSTypography.caption.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

