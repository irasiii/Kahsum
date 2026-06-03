import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/claim.dart';
import '../../../providers/claims_provider.dart';

class QrDisplayScreen extends ConsumerWidget {
  final String claimId;
  const QrDisplayScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(myClaimsProvider);
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text('consumerShowQr'.tr())),
      body: claimsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            Center(child: Text('errorsGeneral'.tr())),
        data: (claims) {
          final Claim? claim = claims.cast<Claim?>().firstWhere(
              (c) => c?.id == claimId,
              orElse: () => null);
          if (claim == null) {
            return Center(child: Text('errorsGeneral'.tr()));
          }
          return _QrView(claim: claim, isAr: isAr);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _QrView extends StatelessWidget {
  final Claim claim;
  final bool isAr;

  const _QrView({required this.claim, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final title = isAr ? claim.deal.titleAr : claim.deal.titleEn;
    final discountedPrice =
        claim.deal.originalPrice * (1 - claim.deal.discountPct / 100);
    final expiry = DateTime.tryParse(claim.deal.expiryDate);
    final expiryFormatted = expiry != null
        ? '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}'
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Deal title + business name
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            claim.deal.trader.businessName,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 28),

          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 4))
              ],
            ),
            child: QrImageView(
              data: claim.qrToken,
              version: QrVersions.auto,
              size: 240,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Deal details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _Row(
                  label:
                      isAr ? 'السعر بعد الخصم' : 'Price after discount',
                  value: 'SAR ${discountedPrice.toStringAsFixed(0)}',
                  bold: true,
                  valueColor: AppColors.primary,
                ),
                const Divider(height: 20),
                _Row(
                  label: 'dealsDiscount'.tr(),
                  value: '-${claim.deal.discountPct.round()}%',
                  valueColor: AppColors.discountBadge,
                ),
                const Divider(height: 20),
                _Row(
                  label: 'dealsExpires'.tr(),
                  value: expiryFormatted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Instruction banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr
                        ? 'أرِ هذا الرمز للتاجر ليقوم بمسحه وتفعيل العرض'
                        : 'Show this QR to the trader so they can scan and validate your deal',
                    style: TextStyle(
                        color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
