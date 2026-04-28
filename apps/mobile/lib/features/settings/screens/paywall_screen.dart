import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ss_primitives.dart';

// Product IDs — must match exactly what you register in App Store / Play Store
const _kAnnualId = 'clera_pro_annual';
const _kMonthlyId = 'clera_pro_monthly';
const _kFamilyId = 'clera_family_annual';

const _kProductIds = {_kAnnualId, _kMonthlyId, _kFamilyId};

final _iapProvider = StateNotifierProvider<_IAPNotifier, _IAPState>(
  (ref) => _IAPNotifier(ref.read(apiClientProvider)),
);

class _IAPState {
  final bool available;
  final bool loading;
  final Map<String, ProductDetails> products;
  final String? error;
  final bool purchased;

  const _IAPState({
    this.available = false,
    this.loading = true,
    this.products = const {},
    this.error,
    this.purchased = false,
  });

  _IAPState copyWith({bool? available, bool? loading, Map<String, ProductDetails>? products, String? error, bool? purchased}) =>
      _IAPState(
        available: available ?? this.available,
        loading: loading ?? this.loading,
        products: products ?? this.products,
        error: error,
        purchased: purchased ?? this.purchased,
      );
}

class _IAPNotifier extends StateNotifier<_IAPState> {
  _IAPNotifier(this._apiClient) : super(const _IAPState()) {
    _init();
  }

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> _init() async {
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) {
      state = state.copyWith(available: false, loading: false, error: 'Store not available');
      return;
    }

    _sub = iap.purchaseStream.listen(_onPurchase);

    final response = await iap.queryProductDetails(_kProductIds);
    final map = {for (final p in response.productDetails) p.id: p};
    state = state.copyWith(available: true, loading: false, products: map);
  }

  void _onPurchase(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        InAppPurchase.instance.completePurchase(p);
        _verifyWithServer(p);
        state = state.copyWith(purchased: true);
      } else if (p.status == PurchaseStatus.error) {
        state = state.copyWith(error: p.error?.message ?? 'Purchase failed', loading: false);
      } else if (p.status == PurchaseStatus.pending) {
        state = state.copyWith(loading: true);
      }
    }
  }

  Future<void> _verifyWithServer(PurchaseDetails p) async {
    try {
      // Determine platform from purchase source
      final platform = p.verificationData.source == 'app_store' ? 'ios' : 'android';
      final receipt = p.verificationData.serverVerificationData;
      await _apiClient?.verifySubscription(
        platform: platform,
        productId: p.productID,
        receipt: receipt,
      );
    } catch (_) {
      // Non-fatal — tier will be set on next app launch via getMe()
    }
  }

  final ApiClient? _apiClient;

  Future<void> buy(String productId) async {
    final product = state.products[productId];
    if (product == null) return;
    state = state.copyWith(loading: true);
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    state = state.copyWith(loading: true);
    await InAppPurchase.instance.restorePurchases();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _selected = _Plan.annual;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final brand = dark ? SSColors.forestDark : SSColors.forest;
    final iap = ref.watch(_iapProvider);

    // Close after successful purchase
    ref.listen(_iapProvider, (_, next) {
      if (next.purchased && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Clera Pro!')),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: dark ? SSColors.bgDark : SSColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SSTopBar(
              leading: SSIconBtn(
                icon: Icons.close,
                onTap: () => context.pop(),
              ),
            ),
            if (iap.loading)
              Expanded(child: Center(child: CircularProgressIndicator(color: brand)))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: dark ? SSColors.surfaceDark : SSColors.surface,
                          borderRadius: SSRadius.borderXl,
                          border: Border.all(color: dark ? SSColors.lineDark : SSColors.line),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? [SSColors.forestDark.withOpacity(0.18), Colors.transparent]
                                : [SSColors.forest.withOpacity(0.1), Colors.transparent],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: dark ? SSColors.forestDark.withOpacity(0.14) : const Color(0xFFE6EFE8),
                                borderRadius: SSRadius.borderFull,
                                border: Border.all(color: brand.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 10, color: brand),
                                  const SizedBox(width: 5),
                                  Text(
                                    'CLERA PRO',
                                    style: TextStyle(
                                      fontFamily: SSTypography.bodyFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                      color: brand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unlimited scans.\nDeeper answers.',
                              style: SSTypography.title.copyWith(
                                color: dark ? SSColors.inkDark : SSColors.ink,
                                fontSize: 30,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan as much as you want, add family profiles, and get ingredient-level reports in PDF.',
                              style: SSTypography.body.copyWith(
                                color: dark ? SSColors.mutedDark : SSColors.muted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (iap.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            iap.error!,
                            style: SSTypography.caption.copyWith(color: SSColors.avoid),
                          ),
                        ),

                      // Plan cards — show store prices when available
                      ..._Plan.values.map((plan) {
                        final storeProduct = iap.products[plan.productId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlanCard(
                            plan: plan,
                            selected: _selected == plan,
                            dark: dark,
                            brand: brand,
                            storePrice: storeProduct?.price,
                            onTap: () => setState(() => _selected = plan),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      const SSSectionLabel('Everything in Pro'),
                      const SizedBox(height: 10),
                      SSCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Column(
                          children: [
                            _FeatureRow('Unlimited scans (Free: 5 / day)', dark: dark, brand: brand, first: true),
                            _FeatureRow('Per-ingredient deep-dives', dark: dark, brand: brand),
                            _FeatureRow('Allergy + pregnancy profile flags', dark: dark, brand: brand),
                            _FeatureRow('Export scans as PDF', dark: dark, brand: brand),
                            _FeatureRow('No ads, ever', dark: dark, brand: brand, last: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: SSGhostButton(
                              label: 'Maybe later',
                              onTap: () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SSPrimaryButton(
                              label: _ctaLabel(iap),
                              onTap: iap.available ? () => ref.read(_iapProvider.notifier).buy(_selected.productId) : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () => ref.read(_iapProvider.notifier).restore(),
                          child: Text(
                            'Restore purchases',
                            style: SSTypography.caption.copyWith(
                              color: dark ? SSColors.mutedDark : SSColors.muted,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        'Billed through the App Store or Play Store · Cancel anytime',
                        textAlign: TextAlign.center,
                        style: SSTypography.caption.copyWith(
                          color: dark ? SSColors.mutedDark : SSColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _ctaLabel(_IAPState iap) {
    final product = iap.products[_selected.productId];
    if (product != null) return 'Start ${_selected.title} · ${product.price}';
    return _selected.cta;
  }
}

enum _Plan { annual, monthly, family }

extension _PlanX on _Plan {
  String get productId => switch (this) {
    _Plan.annual => _kAnnualId,
    _Plan.monthly => _kMonthlyId,
    _Plan.family => _kFamilyId,
  };
  String get title => switch (this) {
    _Plan.annual => 'Annual',
    _Plan.monthly => 'Monthly',
    _Plan.family => 'Family',
  };
  String get price => switch (this) {
    _Plan.annual => '₹2,999',
    _Plan.monthly => '₹399',
    _Plan.family => '₹4,999',
  };
  String get period => switch (this) {
    _Plan.annual => '/ year',
    _Plan.monthly => '/ month',
    _Plan.family => '/ year',
  };
  String get note => switch (this) {
    _Plan.annual => '≈ ₹250 / mo · save 37%',
    _Plan.monthly => 'Cancel anytime',
    _Plan.family => 'Up to 5 profiles',
  };
  bool get recommended => this == _Plan.annual;
  String get cta => switch (this) {
    _Plan.annual => 'Start Annual · ₹2,999',
    _Plan.monthly => 'Start Monthly · ₹399',
    _Plan.family => 'Start Family · ₹4,999',
  };
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.dark,
    required this.brand,
    required this.onTap,
    this.storePrice,
  });

  final _Plan plan;
  final bool selected;
  final bool dark;
  final Color brand;
  final VoidCallback onTap;
  final String? storePrice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: plan.recommended
              ? (dark ? Color.lerp(SSColors.surfaceDark, brand, 0.08) : const Color(0xFFEEF3EC))
              : (dark ? SSColors.surfaceDark : SSColors.surface),
          borderRadius: SSRadius.borderLg,
          border: Border.all(
            color: selected ? brand : (dark ? SSColors.lineDark : SSColors.line),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: plan.recommended
              ? [BoxShadow(color: brand.withOpacity(0.13), blurRadius: 26, offset: const Offset(0, 10))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? brand : (dark ? SSColors.lineDark : SSColors.line),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(child: Container(width: 11, height: 11, decoration: BoxDecoration(shape: BoxShape.circle, color: brand)))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontFamily: SSTypography.displayFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          color: dark ? SSColors.inkDark : SSColors.ink,
                        ),
                      ),
                      if (plan.recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: brand, borderRadius: SSRadius.borderXs),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              fontFamily: SSTypography.monoFamily,
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    plan.note,
                    style: TextStyle(
                      fontFamily: SSTypography.bodyFamily,
                      fontSize: 12,
                      color: dark ? SSColors.mutedDark : SSColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  storePrice ?? plan.price,
                  style: TextStyle(
                    fontFamily: SSTypography.displayFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    letterSpacing: -0.4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: dark ? SSColors.inkDark : SSColors.ink,
                  ),
                ),
                Text(
                  plan.period,
                  style: TextStyle(
                    fontFamily: SSTypography.bodyFamily,
                    fontSize: 11.5,
                    color: dark ? SSColors.mutedDark : SSColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text, {required this.dark, required this.brand, this.first = false, this.last = false});
  final String text;
  final bool dark, first, last;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: dark ? SSColors.lineDark : SSColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: dark ? brand.withOpacity(0.13) : const Color(0xFFE6EFE8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 14, color: brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: SSTypography.bodyFamily,
                fontSize: 14,
                letterSpacing: -0.1,
                color: dark ? SSColors.inkDark : SSColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
