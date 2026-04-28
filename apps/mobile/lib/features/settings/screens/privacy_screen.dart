import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            SSTopBar(
              title: 'Privacy Policy',
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      title: 'What we collect',
                      body: 'We collect your email address, age, gender, and optional health context (allergies, pregnancy) to personalise ingredient safety analysis. We collect images of product labels you scan, and your purchase intent responses (buying / not buying / maybe).',
                      dark: dark,
                    ),
                    _Section(
                      title: 'How we use it',
                      body: 'Label images and ingredient data are analysed by Claude (Anthropic AI) to generate safety scores. Health context is used solely to flag relevant ingredients for you — it is never sold or shared individually. Aggregated, anonymised purchase intent data may be licensed to consumer research companies.',
                      dark: dark,
                    ),
                    _Section(
                      title: 'Data storage',
                      body: 'Your data is stored on Supabase infrastructure hosted in the United States. Label images are retained for up to 12 months. You may request deletion at any time by contacting us.',
                      dark: dark,
                    ),
                    _Section(
                      title: 'Third parties',
                      body: 'We use Anthropic (AI analysis), Supabase (database and storage), and Apple / Google (payments). We do not share personal data with advertisers.',
                      dark: dark,
                    ),
                    _Section(
                      title: 'Your rights',
                      body: 'You may request access to, correction of, or deletion of your personal data at any time by emailing privacy@clera.app. We will respond within 30 days.',
                      dark: dark,
                    ),
                    _Section(
                      title: 'Contact',
                      body: 'Clera · privacy@clera.app\nLast updated: April 2026',
                      dark: dark,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, required this.dark});
  final String title, body;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: SSTypography.displayFamily,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: dark ? SSColors.inkDark : SSColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 14,
              height: 1.6,
              color: dark ? SSColors.ink2Dark : SSColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
