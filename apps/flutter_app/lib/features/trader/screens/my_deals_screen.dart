import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/deal.dart';
import '../../../providers/deals_provider.dart';

class MyDealsScreen extends ConsumerWidget {
  const MyDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(myTraderDealsProvider);
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text('traderMyDeals'.tr()),
        actions: [
          // Quick-access scan QR button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'traderScanQr'.tr(),
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myTraderDealsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add),
        label: Text('traderCreateDeal'.tr()),
        backgroundColor: AppColors.primary,
      ),
      body: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            Center(child: Text('errorsNetwork'.tr())),
        data: (deals) {
          if (deals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      isAr
                          ? 'لم تنشر أي عروض بعد'
                          : 'No deals posted yet',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/create'),
                      icon: const Icon(Icons.add),
                      label: Text('traderCreateDeal'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          // Summary stats row
          final active = deals.where((d) => d.status == 'active').length;
          final totalRedemptions =
              deals.fold<int>(0, (sum, d) => sum + d.redeemedCount);

          return Column(
            children: [
              _StatsBar(
                  active: active,
                  total: deals.length,
                  redemptions: totalRedemptions,
                  isAr: isAr),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: deals.length,
                  itemBuilder: (_, i) =>
                      _TraderDealCard(deal: deals[i], isAr: isAr),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats bar
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  final int active;
  final int total;
  final int redemptions;
  final bool isAr;

  const _StatsBar({
    required this.active,
    required this.total,
    required this.redemptions,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _Stat(
              label: isAr ? 'نشطة' : 'Active',
              value: '$active/$total',
              color: AppColors.genuineGreen),
          const SizedBox(width: 24),
          _Stat(
              label: 'traderTotalRedemptions'.tr(),
              value: '$redemptions',
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trader deal card
// ---------------------------------------------------------------------------

class _TraderDealCard extends ConsumerStatefulWidget {
  final Deal deal;
  final bool isAr;
  const _TraderDealCard({required this.deal, required this.isAr});

  @override
  ConsumerState<_TraderDealCard> createState() =>
      _TraderDealCardState();
}

class _TraderDealCardState extends ConsumerState<_TraderDealCard> {
  bool _toggling = false;

  Color get _statusColor {
    switch (widget.deal.status) {
      case 'active':
        return AppColors.genuineGreen;
      case 'paused':
        return Colors.orange;
      default:
        return AppColors.noDataGray;
    }
  }

  String _statusLabel(bool isAr) {
    switch (widget.deal.status) {
      case 'active':
        return isAr ? 'نشط' : 'Active';
      case 'paused':
        return isAr ? 'متوقف' : 'Paused';
      default:
        return isAr ? 'منتهي' : 'Expired';
    }
  }

  Future<void> _toggleStatus() async {
    final newStatus =
        widget.deal.status == 'active' ? 'paused' : 'active';
    setState(() => _toggling = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/api/deals/${widget.deal.id}/status',
        data: {'status': newStatus},
      );
      ref.invalidate(myTraderDealsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorsGeneral'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _confirmDelete() async {
    final isAr = widget.isAr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'حذف العرض؟' : 'Remove deal?'),
        content: Text(isAr
            ? 'لن يتمكن المستخدمون من رؤية هذا العرض بعد الآن'
            : 'Users will no longer see this deal'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('commonCancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isAr ? 'حذف' : 'Remove',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete<Map<String, dynamic>>(
          '/api/deals/${widget.deal.id}');
      ref.invalidate(myTraderDealsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorsGeneral'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final deal = widget.deal;
    final title = isAr ? deal.titleAr : deal.titleEn;
    final discountedPrice =
        deal.originalPrice * (1 - deal.discountPct / 100);
    final expiry = DateTime.tryParse(deal.expiryDate);
    final daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays
        : 0;
    final isExpired =
        deal.status == 'expired' || (expiry != null && daysLeft < 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + status badge
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
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(
                    _statusLabel(isAr),
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price + discount + redemptions
            Row(
              children: [
                Text(
                  'SAR ${discountedPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.discountBadge,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '-${deal.discountPct.round()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Icon(Icons.people_outline,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${deal.redeemedCount}/${deal.maxRedemptions}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Expiry
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  isExpired
                      ? (isAr ? 'منتهي الصلاحية' : 'Expired')
                      : '${isAr ? 'ينتهي خلال' : 'Expires in'} $daysLeft ${isAr ? 'يوم' : 'days'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: daysLeft <= 2 && !isExpired
                          ? Colors.orange
                          : AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            if (!isExpired)
              Row(
                children: [
                  // Edit
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/deal/edit/${deal.id}'),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('commonSave'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Toggle active/paused
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggling ? null : _toggleStatus,
                      icon: _toggling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : Icon(
                              deal.status == 'active'
                                  ? Icons.pause_outlined
                                  : Icons.play_arrow_outlined,
                              size: 16),
                      label: Text(
                        deal.status == 'active'
                            ? (isAr ? 'إيقاف' : 'Pause')
                            : (isAr ? 'تفعيل' : 'Activate'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    tooltip: isAr ? 'حذف' : 'Remove',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
