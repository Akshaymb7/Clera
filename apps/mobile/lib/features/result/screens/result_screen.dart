import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../../shared/widgets/skeleton.dart';

const _favBox = 'favourites';

void _showPurchaseIntentSheet(BuildContext context, WidgetRef ref, String scanId, bool dark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: dark ? SSColors.surfaceDark : SSColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: dark ? SSColors.lineDark : SSColors.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Are you buying this?', style: SSTypography.title.copyWith(color: dark ? SSColors.inkDark : SSColors.ink)),
          const SizedBox(height: 6),
          Text('Your answer helps us improve safety insights.', style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _IntentBtn(label: '✓  Buying it', color: SSColors.excellent, onTap: () {
                ref.read(apiClientProvider).savePurchaseIntent(scanId, 'buying');
                Navigator.pop(context);
              })),
              const SizedBox(width: 10),
              Expanded(child: _IntentBtn(label: '✕  Not buying', color: SSColors.avoid, onTap: () {
                ref.read(apiClientProvider).savePurchaseIntent(scanId, 'not_buying');
                Navigator.pop(context);
              })),
            ],
          ),
          const SizedBox(height: 10),
          _IntentBtn(label: '?  Maybe later', color: SSColors.caution, onTap: () {
            ref.read(apiClientProvider).savePurchaseIntent(scanId, 'maybe');
            Navigator.pop(context);
          }),
        ],
      ),
    ),
  );
}

class _IntentBtn extends StatelessWidget {
  const _IntentBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: SSRadius.borderMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: SSTypography.bodySemibold.copyWith(color: color)),
      ),
    );
  }
}

final _scanDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.read(apiClientProvider).getScan(id),
);

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;
    final scanAsync = ref.watch(_scanDetailProvider(productId));

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SSTopBar(
              title: 'Result',
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SSIconBtn(
                    icon: Icons.picture_as_pdf_outlined,
                    onTap: () {
                      final url = ref.read(apiClientProvider).scanExportUrl(productId);
                      Share.share(
                        'Clera scan report: $url',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  SSIconBtn(
                    icon: Icons.ios_share_outlined,
                    onTap: () {
                      final scanData = scanAsync.valueOrNull;
                      final name = (scanData?['productName'] as String?) ?? 'this product';
                      final score = (scanData?['score'] as num?)?.toInt() ?? 0;
                      Share.share(
                        'I scanned $name on Clera — safety score: $score/100. Check your labels before you buy!',
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: scanAsync.when(
                loading: () => const SingleChildScrollView(child: ResultHeroSkeleton()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load result', style: SSTypography.body.copyWith(color: dark ? SSColors.inkDark : SSColors.ink)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => ref.refresh(_scanDetailProvider(productId)), child: const Text('Retry')),
                    ],
                  ),
                ),
                data: (scan) {
                  // Show purchase intent sheet once after scan loads
                  final intent = scan['purchaseIntent'];
                  if (intent == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        _showPurchaseIntentSheet(context, ref, productId, dark);
                      }
                    });
                  }
                  return _ResultBody(scan: scan, productId: productId, dark: dark, brand: brand);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SSTabNav(dark: dark, brand: brand),
    );
  }
}

class _ResultBody extends StatefulWidget {
  const _ResultBody({required this.scan, required this.productId, required this.dark, required this.brand});
  final Map<String, dynamic> scan;
  final String productId;
  final bool dark;
  final Color brand;

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(_favBox);
    _isFav = box.containsKey(widget.productId);
  }

  void _toggleFav() {
    final box = Hive.box(_favBox);
    setState(() {
      if (_isFav) {
        box.delete(widget.productId);
        _isFav = false;
      } else {
        box.put(widget.productId, true);
        _isFav = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final productId = widget.productId;
    final dark = widget.dark;
    final brand = widget.brand;
    // API returns flat fields + rawResponse (Claude's full JSON)
    final raw = scan['rawResponse'] as Map<String, dynamic>? ?? {};
    final score = (scan['score'] as num?)?.toInt() ?? (raw['score'] as num?)?.toInt() ?? 0;
    final productName = (scan['productName'] as String?) ?? (raw['productName'] as String?) ?? (scan['category'] as String?) ?? 'Product';
    final summary = (raw['summary'] as String?) ?? '';
    final flagged = (raw['flaggedIngredients'] as List<dynamic>?) ?? [];
    final ingredients = (scan['ingredients'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero ring
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 1.2,
                colors: dark
                    ? [SSColors.forestDark.withOpacity(0.1), Colors.transparent]
                    : [SSColors.forest.withOpacity(0.06), Colors.transparent],
              ),
              borderRadius: SSRadius.borderXl,
            ),
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 22),
            child: Column(
              children: [
                ScoreRing(score: score),
                const SizedBox(height: 22),
                Text(
                  (scan['category'] as String? ?? '').toUpperCase(),
                  style: TextStyle(
                    fontFamily: SSTypography.monoFamily,
                    fontSize: 10.5,
                    letterSpacing: 2,
                    color: dark ? SSColors.mutedDark : SSColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  productName,
                  textAlign: TextAlign.center,
                  style: SSTypography.title.copyWith(color: dark ? SSColors.inkDark : SSColors.ink),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (summary.isNotEmpty)
            Text(
              summary,
              style: SSTypography.bodyMedium.copyWith(
                color: dark ? SSColors.inkDark : SSColors.ink,
                fontSize: 17,
                letterSpacing: -0.2,
                height: 1.45,
              ),
            ),

          if (flagged.isNotEmpty) ...[
            const SizedBox(height: 22),
            const SSSectionLabel('Watch out for'),
            const SizedBox(height: 10),
            ...flagged.map((item) {
              final f = item as Map<String, dynamic>;
              final bandStr = (f['band'] as String? ?? 'caution').toLowerCase();
              final band = _bandFromString(bandStr);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RiskCard(
                  band: band,
                  name: f['name'] as String? ?? '',
                  hint: f['reason'] as String? ?? '',
                  onTap: () => context.push('/result/$productId/ingredients'),
                ),
              );
            }),
          ],

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: SSPrimaryButton(
                  label: 'See all ${ingredients.length} ingredients',
                  onTap: () => context.push('/result/$productId/ingredients'),
                ),
              ),
              const SizedBox(width: 10),
              SSIconBtn(
                icon: _isFav ? Icons.favorite : Icons.favorite_border,
                size: 52,
                onTap: _toggleFav,
              ),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  ScoreBand _bandFromString(String s) => switch (s) {
    'excellent' => ScoreBand.excellent,
    'good' => ScoreBand.good,
    'poor' => ScoreBand.poor,
    'avoid' => ScoreBand.avoid,
    _ => ScoreBand.caution,
  };
}

class _SSTabNav extends StatelessWidget {
  const _SSTabNav({required this.dark, required this.brand});
  final bool dark;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: dark ? const Color(0xD90B0B0E) : const Color(0xD9FFFFFF),
        border: Border(top: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(icon: Icons.camera_alt_outlined, label: 'Scan', active: true, color: brand),
            _NavItem(icon: Icons.history, label: 'History', active: false,
                color: dark ? SSColors.mutedDark : SSColors.muted,
                onTap: () => context.push('/history')),
            _NavItem(icon: Icons.person_outline, label: 'Profile', active: false,
                color: dark ? SSColors.mutedDark : SSColors.muted,
                onTap: () => context.push('/settings')),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
