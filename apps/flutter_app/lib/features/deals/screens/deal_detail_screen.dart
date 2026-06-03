import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/deal.dart';
import '../../../providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _dealDetailProvider =
    FutureProvider.family<Deal, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/deals/$id');
  return Deal.fromJson(response.data!['deal'] as Map<String, dynamic>);
});

final _marketValueProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, dealId) async {
  final api = ref.read(apiClientProvider);
  try {
    final response =
        await api.get<Map<String, dynamic>>('/api/ai/market-value/$dealId');
    return response.data;
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DealDetailScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  bool _claiming = false;
  bool _claimed = false;
  String? _claimId;

  Future<void> _claimDeal() async {
    final auth = ref.read(authProvider);
    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.locale.languageCode == 'ar'
                ? 'سجّل الدخول لتتمكن من الحصول على العرض'
                : 'Login to claim deals')),
      );
      return;
    }

    setState(() => _claiming = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/api/claims',
        data: {'dealId': widget.dealId},
      );
      final claimId = response.data!['claim']['id'] as String;
      if (mounted) {
        setState(() {
          _claimed = true;
          _claimId = claimId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notificationsClaimConfirmed'.tr()),
            backgroundColor: AppColors.genuineGreen,
            action: SnackBarAction(
              label: 'consumerShowQr'.tr(),
              textColor: Colors.white,
              onPressed: () => context.push('/qr/$claimId'),
            ),
          ),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('errorsGeneral'.tr()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(_dealDetailProvider(widget.dealId));
    final isAr = context.locale.languageCode == 'ar';
    final auth = ref.watch(authProvider);
    final isConsumer =
        auth.userType == 'consumer' || auth.status == AuthStatus.guest;

    return Scaffold(
      appBar: AppBar(title: Text('dealsBrowse'.tr())),
      body: dealAsync.when(
        data: (deal) => _buildContent(context, deal, isAr, isConsumer),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('errorsGeneral'.tr())),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Deal deal, bool isAr, bool isConsumer) {
    final title = isAr ? deal.titleAr : deal.titleEn;
    final description = isAr ? deal.descriptionAr : deal.descriptionEn;
    final discountedPrice = deal.originalPrice * (1 - deal.discountPct / 100);
    final marketAsync = ref.watch(_marketValueProvider(widget.dealId));
    final expiry = DateTime.tryParse(deal.expiryDate);
    final daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays.clamp(0, 999)
        : 0;
    final isFull = deal.redeemedCount >= deal.maxRedemptions;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero image / placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: deal.imageUrl != null
                      ? Image.network(deal.imageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_offer,
                              size: 64,
                              color: AppColors.primary))
                      : const Icon(Icons.local_offer,
                          size: 64, color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                // Discount badge + title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.discountBadge,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${deal.discountPct.round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  deal.trader.businessName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                // Prices
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SAR ${discountedPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'SAR ${deal.originalPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'commonVat'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Expiry + redemptions row
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${'dealsExpires'.tr()}: $daysLeft ${isAr ? 'يوم' : 'days'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    const Icon(Icons.people_outline,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${deal.redeemedCount}/${deal.maxRedemptions}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: isFull
                                  ? Colors.red
                                  : AppColors.textSecondary),
                    ),
                  ],
                ),

                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(description,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],

                const SizedBox(height: 16),

                // AI market-value badge
                _AiMarketValueCard(marketAsync: marketAsync, isAr: isAr),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Claim button (consumers + guests only)
        if (isConsumer)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_claimed || _claiming || isFull)
                      ? null
                      : _claimDeal,
                  child: _claiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _claimed
                              ? 'dealsClaimed'.tr()
                              : isFull
                                  ? (isAr ? 'مكتمل' : 'Fully Redeemed')
                                  : 'dealsClaim'.tr(),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AI badge widget
// ---------------------------------------------------------------------------

class _AiMarketValueCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> marketAsync;
  final bool isAr;

  const _AiMarketValueCard(
      {required this.marketAsync, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return marketAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null || data['available'] != true) {
          return _unavailable(context);
        }
        final verdict = data['verdict'] as String? ?? '';
        final avg = (data['marketPriceAvg'] as num?)?.toDouble();
        final isGenuine = verdict == 'honest';
        final borderColor =
            isGenuine ? AppColors.genuineGreen : AppColors.inflatedAmber;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: borderColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                isGenuine
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                color: borderColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('aiMarketValue'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    if (avg != null)
                      Text(
                        isAr
                            ? 'متوسط السوق: ${avg.toStringAsFixed(0)} ريال'
                            : 'Market avg: ${avg.toStringAsFixed(0)} SAR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(
                      isGenuine
                          ? 'aiGenuine'.tr()
                          : 'aiPriceMayBeInflated'.tr(),
                      style: TextStyle(color: borderColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _unavailable(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.noDataGray.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.noDataGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.noDataGray),
          const SizedBox(width: 12),
          Text('aiNoData'.tr(),
              style: const TextStyle(color: AppColors.noDataGray)),
        ],
      ),
    );
  }
}
