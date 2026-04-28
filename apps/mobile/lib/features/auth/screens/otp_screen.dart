import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/ss_primitives.dart';
import 'login_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  int _resendSeconds = 30;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  void _onDigitEntered(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == _otpLength) _verify(code);
  }

  Future<void> _verify(String code) async {
    setState(() { _verifying = true; _error = null; });
    try {
      final email = ref.read(pendingEmailProvider);
      await ref.read(authServiceProvider).verifyOtp(email, code);
      if (mounted) context.go('/profile/setup');
    } catch (e) {
      setState(() => _error = 'Invalid or expired code. Please try again.');
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Check your email.',
                      style: SSTypography.title.copyWith(
                        color: dark ? SSColors.inkDark : SSColors.ink,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 6-digit code we sent you.",
                      style: SSTypography.body.copyWith(
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP boxes
                    Row(
                      children: List.generate(_otpLength, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < _otpLength - 1 ? 8 : 0),
                            child: _OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              dark: dark,
                              brand: brand,
                              onChanged: (v) => _onDigitEntered(i, v),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
                      const SizedBox(height: 16),
                    ],

                    if (_verifying)
                      Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: brand,
                          ),
                        ),
                      )
                    else
                      SSPrimaryButton(label: 'Verify', onTap: () {
                        final code = _controllers.map((c) => c.text).join();
                        if (code.length == _otpLength) _verify(code);
                      }),

                    const SizedBox(height: 20),
                    Center(
                      child: _resendSeconds > 0
                          ? Text(
                              'Resend in ${_resendSeconds}s',
                              style: SSTypography.label.copyWith(
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                setState(() => _resendSeconds = 30);
                                _startResendTimer();
                              },
                              child: Text(
                                'Resend code',
                                style: SSTypography.label.copyWith(
                                  color: brand,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.dark,
    required this.brand,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool dark;
  final Color brand;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
        borderRadius: SSRadius.borderSm,
        border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(0.5)
                : const Color(0xFF123C24).withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontFamily: SSTypography.displayFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: dark ? SSColors.inkDark : SSColors.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
