import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/score_ring.dart';
import '../../../shared/widgets/skeleton.dart';

final _historyProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(apiClientProvider).listScans(limit: 100),
);

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All';
  bool _searching = false;
  String _query = '';
  final _searchController = TextEditingController();

  static const _filterOptions = ['All', 'Food', 'Cosmetic', 'Medicine', 'Household'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<dynamic> items) {
    return items.cast<Map<String, dynamic>>().where((scan) {
      final cat = (scan['category'] as String? ?? '').toLowerCase();
      final name = (scan['productName'] as String? ?? '').toLowerCase();
      final brand = (scan['brand'] as String? ?? '').toLowerCase();

      final matchesCat = _filter == 'All' || cat == _filter.toLowerCase();
      final matchesQuery = _query.isEmpty ||
          name.contains(_query.toLowerCase()) ||
          brand.contains(_query.toLowerCase());

      return matchesCat && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(_historyProvider);

    return SSMainScaffold(
      currentTab: SSTab.history,
      onTabTap: (tab) {
        if (tab == SSTab.scan) context.go('/home');
        if (tab == SSTab.profile) context.push('/settings');
      },
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  if (_searching)
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: SSTypography.bodyFamily,
                          fontSize: 15,
                          color: dark ? SSColors.inkDark : SSColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products…',
                          hintStyle: TextStyle(color: dark ? SSColors.mutedDark : SSColors.muted),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    )
                  else
                    const Spacer(),
                  SSIconBtn(
                    icon: _searching ? Icons.close : Icons.search,
                    onTap: () {
                      setState(() {
                        _searching = !_searching;
                        if (!_searching) {
                          _query = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            if (!_searching) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
                child: Text(
                  'History',
                  style: SSTypography.display.copyWith(
                    color: dark ? SSColors.inkDark : SSColors.ink,
                    fontSize: 34,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              historyAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text('Loading…', style: SSTypography.body.copyWith(fontSize: 13, color: dark ? SSColors.mutedDark : SSColors.muted)),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  final total = (data['total'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text(
                      '$total scan${total == 1 ? '' : 's'}',
                      style: SSTypography.body.copyWith(fontSize: 13, color: dark ? SSColors.mutedDark : SSColors.muted),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filterOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final f = _filterOptions[i];
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: SSChip(label: f, selected: _filter == f),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: historyAsync.when(
                loading: () => ListView.builder(
                  itemCount: 8,
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                  itemBuilder: (_, __) => const ScanCardSkeleton(),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load', style: SSTypography.body.copyWith(color: dark ? SSColors.inkDark : SSColors.ink)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => ref.refresh(_historyProvider), child: const Text('Retry')),
                    ],
                  ),
                ),
                data: (data) {
                  final allItems = (data['items'] as List<dynamic>?) ?? [];
                  final items = _applyFilters(allItems);

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        allItems.isEmpty ? 'No scans yet.\nTap Scan to get started.' : 'No results found.',
                        textAlign: TextAlign.center,
                        style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted),
                      ),
                    );
                  }

                  final grouped = <String, List<Map<String, dynamic>>>{};
                  for (final scan in items) {
                    final dt = DateTime.tryParse(scan['createdAt'] as String? ?? '') ?? DateTime.now();
                    grouped.putIfAbsent(_dateLabel(dt), () => []).add(scan);
                  }

                  return RefreshIndicator(
                    color: dark ? SSColors.forestDark : SSColors.forest,
                    onRefresh: () async => ref.refresh(_historyProvider),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      children: grouped.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DayGroup(
                            label: entry.key,
                            items: entry.value,
                            dark: dark,
                            onTap: (id) => context.push('/result/$id'),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'TODAY';
    if (d == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.label, required this.items, required this.dark, required this.onTap});
  final String label;
  final List<Map<String, dynamic>> items;
  final bool dark;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: SSTypography.monoFamily,
            fontSize: 10.5,
            letterSpacing: 1.8,
            color: dark ? SSColors.mutedDark : SSColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        SSCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final scan = entry.value;
              return _HistoryRow(
                scan: scan,
                dark: dark,
                last: i == items.length - 1,
                onTap: () => onTap(scan['id'] as String),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.scan, required this.dark, required this.last, required this.onTap});
  final Map<String, dynamic> scan;
  final bool dark;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = (scan['score'] as num?)?.toInt() ?? 0;
    final band = bandFromScore(score);
    final productName = (scan['productName'] as String?) ?? 'Unknown Product';
    final brand = (scan['brand'] as String?) ?? '';
    final cat = (scan['category'] as String?) ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
        ),
        child: Row(
          children: [
            _ProductThumbSmall(band: band, label: cat.isNotEmpty ? cat[0].toUpperCase() : '?', dark: dark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: TextStyle(fontFamily: SSTypography.monoFamily, fontSize: 9.5, letterSpacing: 1.5, color: dark ? SSColors.mutedDark : SSColors.muted),
                    ),
                  Text(
                    productName,
                    style: TextStyle(fontFamily: SSTypography.displayFamily, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2, color: dark ? SSColors.inkDark : SSColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.isNotEmpty ? cat[0].toUpperCase() + cat.substring(1) : '',
                    style: TextStyle(fontFamily: SSTypography.bodyFamily, fontSize: 11, fontWeight: FontWeight.w500, color: dark ? SSColors.mutedDark : SSColors.muted),
                  ),
                ],
              ),
            ),
            ScoreChip(score: score),
          ],
        ),
      ),
    );
  }
}

class _ProductThumbSmall extends StatelessWidget {
  const _ProductThumbSmall({required this.band, required this.label, required this.dark});
  final ScoreBand band;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = band.color(dark);
    final soft = band.softColor(dark);
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.7, -0.7),
          end: Alignment.bottomRight,
          colors: [soft, dark ? SSColors.surfaceDark : SSColors.surface],
        ),
        borderRadius: SSRadius.borderSm,
        border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: SSRadius.sm, bottomLeft: SSRadius.sm),
              ),
            ),
          ),
          Center(
            child: Text(label, style: TextStyle(fontFamily: SSTypography.displayFamily, fontWeight: FontWeight.w600, fontSize: 18, color: color)),
          ),
        ],
      ),
    );
  }
}
