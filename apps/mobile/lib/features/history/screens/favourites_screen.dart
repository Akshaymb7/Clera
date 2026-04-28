import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';
import '../../../shared/widgets/skeleton.dart';

const _favBox = 'favourites';

final _favsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final box = Hive.box(_favBox);
  final ids = box.keys.cast<String>().toList();
  if (ids.isEmpty) return [];
  final api = ref.read(apiClientProvider);
  final results = await Future.wait(
    ids.map((id) => api.getScan(id).catchError((_) => <String, dynamic>{})),
  );
  return results.where((r) => r.isNotEmpty).toList();
});

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;
    final favsAsync = ref.watch(_favsProvider);

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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'Favourites',
                style: SSTypography.display.copyWith(
                  color: dark ? SSColors.inkDark : SSColors.ink,
                  fontSize: 34,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            Expanded(
              child: favsAsync.when(
                loading: () => ListView.builder(
                  itemCount: 5,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                  itemBuilder: (_, __) => const ScanCardSkeleton(),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load', style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted)),
                ),
                data: (favs) {
                  if (favs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border, size: 48, color: dark ? SSColors.mutedDark : SSColors.muted),
                          const SizedBox(height: 16),
                          Text(
                            'No favourites yet',
                            style: SSTypography.label.copyWith(color: dark ? SSColors.inkDark : SSColors.ink, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap ♥ on any result to save it here.',
                            style: SSTypography.body.copyWith(color: dark ? SSColors.mutedDark : SSColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final scan = favs[i];
                      final score = (scan['score'] as num?)?.toInt() ?? 0;
                      final name = (scan['productName'] as String?) ?? (scan['category'] as String?) ?? 'Product';
                      final category = (scan['category'] as String? ?? '').toUpperCase();
                      return GestureDetector(
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
                                      category,
                                      style: TextStyle(
                                        fontFamily: SSTypography.monoFamily,
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                        color: dark ? SSColors.mutedDark : SSColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Hive.box(_favBox).delete(scan['id'] as String);
                                  ref.refresh(_favsProvider);
                                },
                                child: Icon(Icons.favorite, size: 20, color: brand),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
