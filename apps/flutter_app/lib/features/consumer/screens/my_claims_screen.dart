import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/claim.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/claims_provider.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAr = context.locale.languageCode == 'ar';

    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: AppBar(title: Text('consumerMyDeals'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? 'سجّل الدخول لرؤية عروضك المحجوزة'
                      : 'Login to see your claimed deals',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: Text('authLogin'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final claimsAsync = ref.watch(myClaimsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('consumerMyDeals'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(myClaimsProvider),
          ),
        ],
      ),
      body: claimsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            Center(child: Text('errorsNetwork'.tr())),
        data: (claims) {
          if (claims.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_num_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('consumerNoClaims'.tr(),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.storefront),
                      label: Text('dealsBrowse'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            itemBuilder: (_, i) =>
                _ClaimCard(claim: claims[i], isAr: isAr),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim card
// ---------------------------------------------------------------------------

class _ClaimCard extends StatelessWidget {
  final Claim claim;
  final bool isAr;
  const _ClaimCard({required this.claim, required this.isAr});

  Color get _statusColor => switch (claim.status) {
        'redeemed' => AppColors.genuineGreen,
        'expired' => AppColors.noDataGray,
        _ => AppColors.primary,
      };

  String _statusLabel() => switch (claim.status) {
        'redeemed' => 'consumerStatusRedeemed'.tr(),
        'expired' => 'consumerStatusExpired'.tr(),
        _ => 'consumerStatusClaimed'.tr(),
      };

  bool get _canShowQr {
    final expiry = DateTime.tryParse(claim.deal.expiryDate);
    final notExpired =
        expiry == null || expiry.isAfter(DateTime.now());
    return claim.status == 'claimed' && notExpired;
  }

  bool get _canRate =>
      claim.status == 'redeemed' && claim.rating == null;

  @override
  Widget build(BuildContext context) {
    final title =
        isAr ? claim.deal.titleAr : claim.deal.titleEn;
    final discountedPrice =
        claim.deal.originalPrice * (1 - claim.deal.discountPct / 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _canShowQr ? () => context.push('/qr/${claim.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                claim.deal.trader.businessName,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'SAR ${discountedPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.discountBadge,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${claim.deal.discountPct.round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (_canShowQr) ...[
                    const Icon(Icons.qr_code_2,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'consumerShowQr'.tr(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (_canRate) ...[
                    const Icon(Icons.star_outline,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          context.push('/rate/${claim.id}'),
                      child: Text(
                        'consumerRateDeal'.tr(),
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  if (claim.status == 'redeemed' &&
                      claim.rating != null) ...[
                    RatingBarIndicator(
                      rating: claim.rating!.stars.toDouble(),
                      itemBuilder: (_, __) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
