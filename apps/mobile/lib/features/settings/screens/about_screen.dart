import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/clera_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: brand,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4EE890).withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: brand.withOpacity(0.3), blurRadius: 32, offset: const Offset(0, 16)),
                        ],
                      ),
                      child: const Center(child: CleraIcon(size: 48)),
                    ),
                    const SizedBox(height: 18),
                    CleraWordmark(fontSize: 28, dark: dark),
                    const SizedBox(height: 6),
                    Text(
                      'Version 1.0.0',
                      style: SSTypography.caption.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                    ),

                    const SizedBox(height: 32),

                    SSCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _AboutRow(
                            label: 'Powered by',
                            value: 'Claude (Anthropic AI)',
                            dark: dark,
                          ),
                          _AboutRow(
                            label: 'Data',
                            value: 'Supabase · United States',
                            dark: dark,
                          ),
                          _AboutRow(
                            label: 'Contact',
                            value: 'hello@clera.app',
                            dark: dark,
                          ),
                          _AboutRow(
                            label: 'Support',
                            value: 'support@clera.app',
                            dark: dark,
                            last: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Clera helps you decode product labels using AI.\n\nWe believe you deserve to know what you\'re putting in and on your body.',
                      textAlign: TextAlign.center,
                      style: SSTypography.body.copyWith(
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                        fontSize: 13.5,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      '© 2026 Clera · Made with care',
                      style: SSTypography.caption.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
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

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value, required this.dark, this.last = false});
  final String label, value;
  final bool dark, last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 14,
              color: dark ? SSColors.mutedDark : SSColors.muted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: dark ? SSColors.inkDark : SSColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
