import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/score_ring.dart';

final _ingredientScanProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.read(apiClientProvider).getScan(id),
);

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  String _filter = 'All';
  final Set<int> _expanded = {};

  static const _filterOptions = ['All', 'Flags', 'Caution', 'Safe'];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scanAsync = ref.watch(_ingredientScanProvider(widget.productId));

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SSTopBar(
              title: 'Ingredients',
              leading: SSIconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.pop(),
              ),
              trailing: SSIconBtn(icon: Icons.more_horiz),
            ),
            Expanded(
              child: scanAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: dark ? SSColors.forestDark : SSColors.forest)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load', style: SSTypography.body.copyWith(color: dark ? SSColors.inkDark : SSColors.ink)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.refresh(_ingredientScanProvider(widget.productId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (scan) => _IngredientsBody(
                  scan: scan,
                  dark: dark,
                  filter: _filter,
                  expanded: _expanded,
                  onFilterChange: (f) => setState(() => _filter = f),
                  onToggle: (i) => setState(() {
                    if (_expanded.contains(i)) _expanded.remove(i);
                    else _expanded.add(i);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientsBody extends StatelessWidget {
  const _IngredientsBody({
    required this.scan,
    required this.dark,
    required this.filter,
    required this.expanded,
    required this.onFilterChange,
    required this.onToggle,
  });

  final Map<String, dynamic> scan;
  final bool dark;
  final String filter;
  final Set<int> expanded;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<int> onToggle;

  static const _filterOptions = ['All', 'Flags', 'Caution', 'Safe'];

  ScoreBand _bandFromRisk(String risk) => switch (risk.toLowerCase()) {
    'safe' => ScoreBand.excellent,
    'low' => ScoreBand.good,
    'moderate' => ScoreBand.caution,
    'high' => ScoreBand.poor,
    'critical' => ScoreBand.avoid,
    _ => ScoreBand.caution,
  };

  bool _matchesFilter(Map<String, dynamic> ing) {
    if (filter == 'All') return true;
    final risk = (ing['riskLevel'] as String? ?? '').toLowerCase();
    return switch (filter) {
      'Flags' => risk == 'high' || risk == 'critical',
      'Caution' => risk == 'moderate',
      'Safe' => risk == 'safe' || risk == 'low',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final result = scan['result'] as Map<String, dynamic>? ?? {};
    final score = (result['score'] as num?)?.toInt() ?? (scan['score'] as num?)?.toInt() ?? 0;
    final productName = (result['productName'] as String?) ?? (scan['productName'] as String?) ?? 'Product';
    final brand = (scan['brand'] as String?) ?? '';
    final category = (scan['category'] as String?) ?? '';
    final band = bandFromScore(score);

    final allIngredients = (scan['ingredients'] as List<dynamic>?) ?? [];
    final filtered = allIngredients
        .cast<Map<String, dynamic>>()
        .where(_matchesFilter)
        .toList();

    final isMedicine = category.toLowerCase() == 'medicine';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Row(
            children: [
              _ProductThumb(band: band, label: category.isNotEmpty ? category[0].toUpperCase() : '?', dark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty)
                      Text(
                        brand.toUpperCase(),
                        style: TextStyle(
                          fontFamily: SSTypography.monoFamily,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      productName,
                      style: SSTypography.headline.copyWith(color: dark ? SSColors.inkDark : SSColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SSChip(label: category[0].toUpperCase() + category.substring(1)),
                        const SizedBox(width: 6),
                        _BandChip(band: band, score: score, dark: dark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (isMedicine)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? SSColors.caution.withOpacity(0.1) : const Color(0xFFFBF1DA),
                borderRadius: SSRadius.borderSm,
                border: Border.all(color: SSColors.caution.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: dark ? SSColors.cautionDark : SSColors.caution),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This isn't medical advice — talk to a professional before changing anything.",
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 12.5,
                        height: 1.45,
                        color: dark ? SSColors.ink2Dark : SSColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isMedicine) const SizedBox(height: 14),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onFilterChange(f),
                    child: SSChip(label: f, selected: filter == f),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No ingredients in this category.',
                  style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                ),
              ),
            )
          else
            SSCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: filtered.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ing = entry.value;
                  final band = _bandFromRisk(ing['riskLevel'] as String? ?? '');
                  final flags = (ing['regulatoryFlags'] as List<dynamic>?)?.cast<String>() ?? [];
                  final isExpanded = expanded.contains(i);
                  final explain = ing['reason'] as String?;

                  return _IngredientRow(
                    name: ing['name'] as String? ?? '',
                    role: ing['normalizedName'] as String? ?? '',
                    band: band,
                    explain: explain,
                    flags: flags.isNotEmpty ? flags : null,
                    dark: dark,
                    last: i == filtered.length - 1,
                    expanded: isExpanded,
                    onToggle: explain != null ? () => onToggle(i) : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.name,
    required this.role,
    required this.band,
    required this.dark,
    required this.last,
    required this.expanded,
    this.explain,
    this.flags,
    this.onToggle,
  });

  final String name, role;
  final ScoreBand band;
  final bool dark, last, expanded;
  final String? explain;
  final List<String>? flags;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bandColor = band.color(dark);
    final softColor = band.softColor(dark);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: softColor, borderRadius: SSRadius.borderXs),
                  child: Center(child: BandIcon(band: band, size: 12)),
                ),
                const SizedBox(width: 12),
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
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          fontFamily: SSTypography.bodyFamily,
                          fontSize: 12,
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (explain != null)
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 14, color: dark ? SSColors.mutedDark : SSColors.muted),
                  ),
              ],
            ),
            if (expanded && explain != null) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(left: 40),
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: bandColor.withOpacity(0.33), width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      explain!,
                      style: TextStyle(
                        fontFamily: SSTypography.bodyFamily,
                        fontSize: 13,
                        height: 1.55,
                        color: dark ? SSColors.ink2Dark : SSColors.ink2,
                      ),
                    ),
                    if (flags != null && flags!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: flags!.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dark ? SSColors.surface2Dark : SSColors.paper2,
                              borderRadius: SSRadius.borderXs,
                              border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontFamily: SSTypography.monoFamily,
                                fontSize: 10,
                                letterSpacing: 1,
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.band, required this.label, required this.dark});
  final ScoreBand band;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = band.color(dark);
    final soft = band.softColor(dark);
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.7, -0.7),
          end: Alignment.bottomRight,
          colors: [soft, dark ? SSColors.surfaceDark : SSColors.surface],
        ),
        borderRadius: SSRadius.borderMd,
        border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
        boxShadow: dark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : [BoxShadow(color: const Color(0xFF123C24).withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: SSRadius.md, bottomLeft: SSRadius.md),
              ),
            ),
          ),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: SSTypography.displayFamily,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: -0.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({required this.band, required this.score, required this.dark});
  final ScoreBand band;
  final int score;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = band.color(dark);
    final soft = band.softColor(dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: SSRadius.borderFull,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BandIcon(band: band, size: 9),
          const SizedBox(width: 5),
          Text(
            '$score · ${band.label}',
            style: TextStyle(
              fontFamily: SSTypography.bodyFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
