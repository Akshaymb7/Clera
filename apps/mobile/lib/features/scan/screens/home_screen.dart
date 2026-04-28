import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/clera_icon.dart';
import '../../../shared/widgets/skeleton.dart';
import '../providers/scan_provider.dart';

final _recentProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(apiClientProvider).listScans(limit: 5),
);

final _quotaProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(apiClientProvider).getQuota(),
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _picker = ImagePicker();

  static const _tips = [
    ('Read the fine print', 'Ingredients are listed by weight — the first few matter most.'),
    ('Watch for aliases', '"Natural flavor" can mean hundreds of compounds.'),
    ('Check your profile', 'Set allergies to get instant personalized flags.'),
  ];

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    ref.read(pendingScanProvider.notifier).state = PendingScan(
      imageBytes: bytes,
      mimeType: 'image/jpeg',
      category: 'food',
    );
    if (mounted) context.push('/scan/analyzing');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;
    final recentAsync = ref.watch(_recentProvider);
    final quotaAsync = ref.watch(_quotaProvider);

    return SSMainScaffold(
      currentTab: SSTab.scan,
      onTabTap: (tab) {
        if (tab == SSTab.history) context.push('/history');
        if (tab == SSTab.profile) context.push('/settings');
      },
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D4A2E),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xFF4EE890).withOpacity(0.2)),
                        ),
                        child: const Center(child: CleraIcon(size: 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CleraWordmark(fontSize: 20, dark: dark),
                            Text(
                              'Scan · Decode · Know',
                              style: SSTypography.body.copyWith(
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SSIconBtn(
                        icon: Icons.settings_outlined,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),

                  // Quota banner (free tier only)
                  quotaAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (quota) {
                      if (quota['tier'] == 'pro' || quota['tier'] == 'family') return const SizedBox.shrink();
                      final daily = quota['daily'] as Map;
                      final remaining = (daily['remaining'] as num).toInt();
                      final limit = (daily['limit'] as num).toInt();
                      if (remaining > limit ~/ 2) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: GestureDetector(
                          onTap: () => context.push('/paywall'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: dark ? SSColors.cautionSoftDark : SSColors.cautionSoft,
                              borderRadius: SSRadius.borderMd,
                              border: Border.all(color: SSColors.caution.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 16, color: SSColors.caution),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    remaining == 0
                                        ? 'Daily limit reached — upgrade for unlimited scans'
                                        : '$remaining scan${remaining == 1 ? '' : 's'} remaining today',
                                    style: SSTypography.label.copyWith(
                                      color: dark ? SSColors.cautionDark : SSColors.caution,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Upgrade →',
                                  style: SSTypography.label.copyWith(
                                    color: dark ? SSColors.cautionDark : SSColors.caution,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Scan CTA
                  Center(
                    child: GestureDetector(
                      onTap: () => context.push('/scan'),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.3, -0.3),
                            colors: [
                              brand.withOpacity(0.9),
                              brand,
                              Color.lerp(brand, Colors.black, 0.2)!,
                            ],
                            stops: const [0, 0.6, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brand.withOpacity(0.35),
                              blurRadius: 48,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'Scan',
                              style: TextStyle(
                                fontFamily: SSTypography.displayFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Point at the ingredient list',
                      style: SSTypography.label.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gallery shortcut
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: SSCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.photo_library_outlined, color: brand, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan from gallery',
                                  style: SSTypography.label.copyWith(
                                    color: dark ? SSColors.inkDark : SSColors.ink, fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pick a screenshot of an ingredient list',
                                  style: SSTypography.caption.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: dark ? SSColors.mutedDark : SSColors.muted, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent scans
                  Row(
                    children: [
                      SSSectionLabel('Recent scans'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/history'),
                        child: Text(
                          'See all',
                          style: TextStyle(
                            fontFamily: SSTypography.bodyFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  recentAsync.when(
                    loading: () => Column(
                      children: List.generate(3, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: ScanCardSkeleton(),
                      )),
                    ),
                    error: (_, __) => _emptyState(dark),
                    data: (data) {
                      final items = (data['items'] as List<dynamic>?) ?? [];
                      if (items.isEmpty) return _emptyState(dark);
                      return Column(
                        children: items.map((item) {
                          final scan = item as Map<String, dynamic>;
                          final score = (scan['score'] as num?)?.toInt() ?? 0;
                          final name = (scan['productName'] as String?) ?? (scan['category'] as String?) ?? 'Product';
                          final dt = DateTime.tryParse(scan['createdAt'] as String? ?? '') ?? DateTime.now();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => context.push('/result/${scan['id']}'),
                              child: SSCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    ScoreChip(score: score),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontFamily: SSTypography.bodyFamily,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.1,
                                              color: dark ? SSColors.inkDark : SSColors.ink,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('d MMM · h:mm a').format(dt.toLocal()),
                                            style: SSTypography.caption.copyWith(
                                              color: dark ? SSColors.mutedDark : SSColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, size: 16, color: dark ? SSColors.mutedDark : SSColors.muted),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  SSSectionLabel('Quick tips'),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _tips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final (title, body) = _tips[i];
                    return SizedBox(
                      width: 240,
                      child: SSCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: SSTypography.label.copyWith(
                                color: dark ? SSColors.inkDark : SSColors.ink, fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: SSTypography.caption.copyWith(
                                color: dark ? SSColors.mutedDark : SSColors.muted, height: 1.45,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool dark) => SSCard(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 44, color: dark ? SSColors.mutedDark : SSColors.muted),
        const SizedBox(height: 14),
        Text('No scans yet', style: SSTypography.label.copyWith(color: dark ? SSColors.inkDark : SSColors.ink, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          'Scan your first label to see results here.',
          textAlign: TextAlign.center,
          style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 13),
        ),
      ],
    ),
  );
}

