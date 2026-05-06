import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../routing/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches = _controller.text == 'DELETE';
      if (matches != _confirmed) setState(() => _confirmed = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_confirmed || _loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).deleteMe();
      ref.read(profileCompleteProvider.notifier).state = null;
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/auth/login');
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please contact support@clera.app'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final avoidColor = dark ? SSColors.avoidDark : SSColors.avoid;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            SSTopBar(
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              title: 'Delete account',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 32),

                  // Warning icon
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.4),
                          colors: [
                            avoidColor.withValues(alpha: 0.8),
                            avoidColor,
                            Color.lerp(avoidColor, Colors.black, 0.25)!,
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: avoidColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Delete your account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: SSTypography.displayFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      letterSpacing: -0.6,
                      color: dark ? SSColors.inkDark : SSColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "We'll keep your data for 30 days in case you change your mind. After that, it's gone for good.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: dark ? SSColors.mutedDark : SSColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // What will be removed card
                  SSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will be removed',
                          style: TextStyle(
                            fontFamily: SSTypography.displayFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: dark ? SSColors.inkDark : SSColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RemovalItem(
                          text: 'All saved scans',
                          dark: dark,
                          avoidColor: avoidColor,
                        ),
                        _RemovalItem(
                          text: 'Family profiles & allergies',
                          dark: dark,
                          avoidColor: avoidColor,
                        ),
                        _RemovalItem(
                          text: 'Clera Pro subscription (cancels immediately, no refund for current term)',
                          dark: dark,
                          avoidColor: avoidColor,
                        ),
                        _RemovalItem(
                          text: 'Email, sign-in, and account history',
                          dark: dark,
                          avoidColor: avoidColor,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirmation input
                  Text(
                    'TYPE DELETE TO CONFIRM',
                    style: TextStyle(
                      fontFamily: SSTypography.monoFamily,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: dark ? SSColors.mutedDark : SSColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _controller,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        fontFamily: SSTypography.monoFamily,
                        fontSize: 15,
                        letterSpacing: 1.5,
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: SSRadius.borderMd,
                          borderSide: BorderSide(color: dark ? SSColors.lineDark : SSColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: SSRadius.borderMd,
                          borderSide: BorderSide(color: dark ? SSColors.lineDark : SSColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: SSRadius.borderMd,
                          borderSide: BorderSide(color: avoidColor, width: 1.5),
                        ),
                        fillColor: dark ? const Color(0xFF0E0F11) : const Color(0xFFF2ECDC),
                        filled: true,
                        hintText: 'DELETE',
                        hintStyle: TextStyle(
                          fontFamily: SSTypography.monoFamily,
                          fontSize: 15,
                          letterSpacing: 1.5,
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delete button
                  GestureDetector(
                    onTap: _confirmed && !_loading ? _delete : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _confirmed
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  avoidColor,
                                  Color.lerp(avoidColor, Colors.black, 0.2)!,
                                ],
                              )
                            : null,
                        color: _confirmed
                            ? null
                            : (dark
                                ? SSColors.surfaceDark
                                : SSColors.line.withValues(alpha: 0.5)),
                        borderRadius: SSRadius.borderMd,
                        boxShadow: _confirmed
                            ? [
                                BoxShadow(
                                  color: avoidColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Permanently delete account',
                                style: TextStyle(
                                  fontFamily: SSTypography.bodyFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _confirmed
                                      ? Colors.white
                                      : (dark ? SSColors.mutedDark : SSColors.muted),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: SSRadius.borderMd,
                        border: Border.all(
                          color: dark ? SSColors.lineDark : SSColors.line,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel — keep my account',
                          style: TextStyle(
                            fontFamily: SSTypography.bodyFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: dark ? SSColors.inkDark : SSColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Need a break instead? You can pause notifications or export your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 12,
                      color: dark ? SSColors.mutedDark : SSColors.muted,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovalItem extends StatelessWidget {
  const _RemovalItem({
    required this.text,
    required this.dark,
    required this.avoidColor,
    this.last = false,
  });

  final String text;
  final bool dark;
  final Color avoidColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: dark ? SSColors.avoidSoftDark : SSColors.avoidSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: avoidColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 13.5,
                height: 1.45,
                color: dark ? SSColors.inkDark : SSColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
