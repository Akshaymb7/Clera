import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../routing/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/ss_primitives.dart';

final _meProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(apiClientProvider).getMe(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final meAsync = ref.watch(_meProvider);

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
                'Settings',
                style: SSTypography.display.copyWith(
                  color: dark ? SSColors.inkDark : SSColors.ink,
                  fontSize: 34,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Profile card
                  meAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (me) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SSCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: dark ? SSColors.forestDark.withOpacity(0.15) : SSColors.forest.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  ((me['name'] as String?) ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: SSTypography.displayFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: dark ? SSColors.forestDark : SSColors.forest,
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
                                    (me['name'] as String?) ?? '',
                                    style: TextStyle(
                                      fontFamily: SSTypography.displayFamily,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: dark ? SSColors.inkDark : SSColors.ink,
                                    ),
                                  ),
                                  Text(
                                    (me['email'] as String?) ?? '',
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 13,
                                      color: dark ? SSColors.mutedDark : SSColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SSChip(label: (me['tier'] as String? ?? 'free').toUpperCase()),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Theme toggle
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SSCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.brightness_6_outlined, size: 20, color: dark ? SSColors.inkDark : SSColors.ink),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Appearance',
                              style: TextStyle(
                                fontFamily: SSTypography.bodyFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: dark ? SSColors.inkDark : SSColors.ink,
                              ),
                            ),
                          ),
                          Consumer(builder: (context, ref, _) {
                            final mode = ref.watch(themeModeProvider);
                            return SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 14)),
                                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 14)),
                                ButtonSegment(value: ThemeMode.dark,  icon: Icon(Icons.dark_mode, size: 14)),
                              ],
                              selected: {mode},
                              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                              style: ButtonStyle(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  SSCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.person_outline,
                          label: 'Edit Profile',
                          dark: dark,
                          onTap: () => context.push('/profile/setup'),
                        ),
                        _SettingsRow(
                          icon: Icons.favorite_border_rounded,
                          label: 'Favourites',
                          dark: dark,
                          onTap: () => context.push('/favourites'),
                        ),
                        _SettingsRow(
                          icon: Icons.star_outline_rounded,
                          label: 'Subscription',
                          dark: dark,
                          onTap: () => context.push('/paywall'),
                        ),
                        _SettingsRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Privacy Policy',
                          dark: dark,
                          onTap: () => context.push('/privacy'),
                        ),
                        _SettingsRow(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          dark: dark,
                          onTap: () => context.push('/terms'),
                        ),
                        _SettingsRow(
                          icon: Icons.feedback_outlined,
                          label: 'Send feedback',
                          dark: dark,
                          onTap: () => context.push('/feedback'),
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          label: 'About',
                          dark: dark,
                          onTap: () => context.push('/about'),
                        ),
                        _SettingsRow(
                          icon: Icons.logout_rounded,
                          label: 'Sign out',
                          dark: dark,
                          destructive: true,
                          onTap: () async {
                            ref.read(profileCompleteProvider.notifier).state = null;
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) context.go('/auth/login');
                          },
                        ),
                        _SettingsRow(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete account',
                          dark: dark,
                          destructive: true,
                          last: true,
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete account?'),
                                content: const Text(
                                  'This permanently deletes your account, all scans, and your data. This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) return;
                            try {
                              await ref.read(apiClientProvider).deleteMe();
                              ref.read(profileCompleteProvider.notifier).state = null;
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) context.go('/auth/login');
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to delete account. Please contact support@clera.app')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.dark,
    this.onTap,
    this.destructive = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final bool dark, destructive, last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? (dark ? SSColors.avoidDark : SSColors.avoid)
        : (dark ? SSColors.inkDark : SSColors.ink);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: SSTypography.bodyFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (!destructive)
              Icon(Icons.chevron_right, size: 18, color: dark ? SSColors.mutedDark : SSColors.muted),
          ],
        ),
      ),
    );
  }
}
