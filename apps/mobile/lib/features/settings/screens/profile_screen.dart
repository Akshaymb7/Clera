import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../routing/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';

final _profileMeProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(apiClientProvider).getMe(),
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final meAsync = ref.watch(_profileMeProvider);
    final brand = dark ? SSColors.forestDark : SSColors.forest;

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SSTopBar(
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Profile',
                style: SSTypography.display.copyWith(
                  color: dark ? SSColors.inkDark : SSColors.ink,
                  fontSize: 34,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Expanded(
              child: meAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load profile',
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      color: dark ? SSColors.mutedDark : SSColors.muted,
                    ),
                  ),
                ),
                data: (me) {
                  final name = (me['name'] as String?) ?? '';
                  final email = (me['email'] as String?) ?? '';
                  final tier = (me['tier'] as String?) ?? 'free';
                  final isPro = tier == 'pro';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Identity card
                      SSCard(
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(-0.3, -0.4),
                                  colors: [
                                    brand.withValues(alpha: 0.85),
                                    brand,
                                    Color.lerp(brand, Colors.black, 0.2)!,
                                  ],
                                  stops: const [0, 0.55, 1],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: brand.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontFamily: SSTypography.displayFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: SSTypography.displayFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 19,
                                      color: dark ? SSColors.inkDark : SSColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 13,
                                      color: dark ? SSColors.mutedDark : SSColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPro ? brand : (dark ? SSColors.surfaceDark : SSColors.surface),
                                borderRadius: SSRadius.borderFull,
                                border: Border.all(
                                  color: isPro ? brand : (dark ? SSColors.lineDark : SSColors.line),
                                ),
                              ),
                              child: Text(
                                isPro ? 'Pro · Annual' : 'Free',
                                style: TextStyle(
                                  fontFamily: SSTypography.bodyFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPro ? Colors.white : (dark ? SSColors.ink2Dark : SSColors.ink2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          Expanded(child: _StatCard(value: '142', label: 'Scans', dark: dark)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(value: '7', label: 'Day streak', dark: dark)),
                          const SizedBox(width: 10),
                          Expanded(child: _StatCard(value: '3', label: 'Profiles', dark: dark)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Account section
                      _SectionLabel('ACCOUNT', dark: dark),
                      const SizedBox(height: 8),
                      SSCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              iconColor: brand,
                              title: 'Personal info',
                              hint: 'Name, photo, date of birth',
                              dark: dark,
                              onTap: () => context.push('/profile/setup'),
                            ),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              iconColor: brand,
                              title: 'Email & sign-in',
                              hint: email,
                              dark: dark,
                            ),
                            _InfoRow(
                              icon: Icons.favorite_outline_rounded,
                              iconColor: SSColors.poor,
                              title: 'Allergies & profile',
                              hint: 'Manage allergen flags',
                              dark: dark,
                            ),
                            _InfoRow(
                              icon: Icons.lock_outline_rounded,
                              iconColor: brand,
                              title: 'Privacy & data',
                              hint: 'Export · what we store',
                              dark: dark,
                              last: true,
                              onTap: () => context.push('/privacy'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subscription section
                      _SectionLabel('SUBSCRIPTION', dark: dark),
                      const SizedBox(height: 8),
                      _SubscriptionCard(isPro: isPro, dark: dark, brand: brand, context: context),
                      const SizedBox(height: 24),

                      // Preferences section
                      _SectionLabel('PREFERENCES', dark: dark),
                      const SizedBox(height: 8),
                      SSCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ToggleRow(
                              icon: Icons.notifications_outlined,
                              iconColor: brand,
                              label: 'Push notifications',
                              dark: dark,
                            ),
                            _InfoRow(
                              icon: Icons.bar_chart_rounded,
                              iconColor: brand,
                              title: 'Score format',
                              hint: '72 · B',
                              dark: dark,
                              trailingText: '›',
                            ),
                            _InfoRow(
                              icon: Icons.public_rounded,
                              iconColor: brand,
                              title: 'Region',
                              hint: 'IN',
                              dark: dark,
                              last: true,
                              trailingText: '›',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Support section
                      _SectionLabel('SUPPORT', dark: dark),
                      const SizedBox(height: 8),
                      SSCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.help_outline_rounded,
                              iconColor: brand,
                              title: 'Help center',
                              dark: dark,
                            ),
                            _InfoRow(
                              icon: Icons.mail_outline_rounded,
                              iconColor: brand,
                              title: 'Contact us',
                              hint: 'hello@clera.app',
                              dark: dark,
                            ),
                            _InfoRow(
                              icon: Icons.description_outlined,
                              iconColor: brand,
                              title: 'Terms & privacy',
                              dark: dark,
                              last: true,
                              onTap: () => context.push('/policies'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Danger zone
                      _SectionLabel('DANGER ZONE', dark: dark),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: dark ? SSColors.avoidSoftDark : SSColors.avoidSoft,
                          borderRadius: SSRadius.borderLg,
                          border: Border.all(
                            color: SSColors.avoid.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: SSRadius.borderLg,
                          child: Column(
                            children: [
                              _DangerRow(
                                icon: Icons.logout_rounded,
                                title: 'Sign out',
                                color: SSColors.poor,
                                dark: dark,
                                onTap: () async {
                                  ref.read(profileCompleteProvider.notifier).state = null;
                                  await Supabase.instance.client.auth.signOut();
                                  if (context.mounted) context.go('/auth/login');
                                },
                              ),
                              Divider(
                                height: 1,
                                color: SSColors.avoid.withValues(alpha: 0.15),
                              ),
                              _DangerRow(
                                icon: Icons.delete_outline_rounded,
                                title: 'Delete account',
                                color: dark ? SSColors.avoidDark : SSColors.avoid,
                                dark: dark,
                                last: true,
                                onTap: () => context.push('/delete-account'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Deleting your account cancels Pro and removes scans, profiles, and personal data.',
                          style: TextStyle(
                            fontFamily: SSTypography.bodyFamily,
                            fontSize: 12,
                            color: dark ? SSColors.mutedDark : SSColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Version footer
                      Center(
                        child: Text(
                          'CLERA · v1.0.0 · BUILD 1',
                          style: TextStyle(
                            fontFamily: SSTypography.monoFamily,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: dark ? SSColors.mutedDark : SSColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.dark});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: SSTypography.monoFamily,
        fontSize: 10.5,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w500,
        color: dark ? SSColors.mutedDark : SSColors.muted,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.dark,
    this.hint,
    this.onTap,
    this.last = false,
    this.trailingText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? hint;
  final bool dark;
  final VoidCallback? onTap;
  final bool last;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: dark ? SSColors.lineDark : SSColors.line,
                  ),
                ),
              ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: dark ? 0.15 : 0.1),
                borderRadius: SSRadius.borderSm,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? SSColors.inkDark : SSColors.ink,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 11.5,
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(
                  fontFamily: SSTypography.bodyFamily,
                  fontSize: 14,
                  color: dark ? SSColors.mutedDark : SSColors.muted,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 18,
                color: dark ? SSColors.mutedDark : SSColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.dark});
  final String value;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SSCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: SSTypography.displayFamily,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: dark ? SSColors.inkDark : SSColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 11,
              color: dark ? SSColors.mutedDark : SSColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.dark,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool dark;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: SSTypography.bodyFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends ConsumerStatefulWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool dark;

  @override
  ConsumerState<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends ConsumerState<_ToggleRow> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.dark ? SSColors.lineDark : SSColors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: widget.dark ? 0.15 : 0.1),
              borderRadius: SSRadius.borderSm,
            ),
            child: Icon(widget.icon, size: 16, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.dark ? SSColors.inkDark : SSColors.ink,
              ),
            ),
          ),
          Switch(
            value: _on,
            onChanged: (v) => setState(() => _on = v),
            activeColor: widget.dark ? SSColors.forestDark : SSColors.forest,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.isPro,
    required this.dark,
    required this.brand,
    required this.context,
  });

  final bool isPro;
  final bool dark;
  final Color brand;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    if (isPro) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    SSColors.forestDark.withValues(alpha: 0.15),
                    SSColors.forestDark.withValues(alpha: 0.05),
                  ]
                : [
                    const Color(0xFFEEF7EE),
                    const Color(0xFFF7F4EC),
                  ],
          ),
          borderRadius: SSRadius.borderLg,
          border: Border.all(
            color: dark ? SSColors.forestDark.withValues(alpha: 0.3) : SSColors.forest.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clera Pro · Annual',
                        style: TextStyle(
                          fontFamily: SSTypography.displayFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: dark ? SSColors.inkDark : SSColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹2,999 / year · renews soon',
                        style: TextStyle(
                          fontFamily: SSTypography.bodyFamily,
                          fontSize: 13,
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.15),
                    borderRadius: SSRadius.borderFull,
                    border: Border.all(color: brand.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push('/paywall'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: dark ? SSColors.surfaceDark : SSColors.surface,
                  borderRadius: SSRadius.borderMd,
                  border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
                ),
                child: Center(
                  child: Text(
                    'Manage plan',
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? SSColors.inkDark : SSColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: SSRadius.borderMd,
                  border: Border.all(
                    color: dark ? SSColors.avoidDark.withValues(alpha: 0.5) : SSColors.avoid.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Cancel subscription',
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? SSColors.avoidDark : SSColors.avoid,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You'll keep Pro access until renewal, then drop to Free (5 scans/day).",
              style: TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 11.5,
                color: dark ? SSColors.mutedDark : SSColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return SSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free plan',
                      style: TextStyle(
                        fontFamily: SSTypography.displayFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: dark ? SSColors.inkDark : SSColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '5 scans / day',
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 13,
                        color: dark ? SSColors.mutedDark : SSColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/paywall'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: dark ? SSColors.surfaceDark : SSColors.surface,
                borderRadius: SSRadius.borderMd,
                border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
              ),
              child: Center(
                child: Text(
                  'Manage plan',
                  style: TextStyle(
                    fontFamily: SSTypography.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dark ? SSColors.inkDark : SSColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
