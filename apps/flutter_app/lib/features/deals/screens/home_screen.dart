import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/deal.dart';
import '../../../providers/deals_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = context.locale.languageCode == 'ar';
    final dealsAsync = ref.watch(allDealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('dealsBrowse'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: isAr ? 'English' : 'عربي',
            onPressed: () {
              context.setLocale(
                  isAr ? const Locale('en') : const Locale('ar'));
            },
          ),
        ],
      ),
      body: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('errorsNetwork'.tr()),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(allDealsProvider),
                child: Text('commonConfirm'.tr()),
              ),
            ],
          ),
        ),
        data: (deals) {
          if (deals.isEmpty) {
            return Center(child: Text('dealsNoDeals'.tr()));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deals.length,
            itemBuilder: (ctx, i) =>
                _DealCard(deal: deals[i], isAr: isAr),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DealCard extends StatelessWidget {
  final Deal deal;
  final bool isAr;
  const _DealCard({required this.deal, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final title = isAr ? deal.titleAr : deal.titleEn;
    final description =
        isAr ? deal.descriptionAr : deal.descriptionEn;
    final discountedPrice =
        deal.originalPrice * (1 - deal.discountPct / 100);
    final categoryName =
        isAr ? deal.category.nameAr : deal.category.nameEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/deal/${deal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: deal.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(deal.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.store,
                                    color: AppColors.primary)),
                          )
                        : const Icon(Icons.store,
                            color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.trader.businessName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.discountBadge,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${deal.discountPct.round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'SAR ${discountedPrice.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SAR ${deal.originalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Icon(Icons.sell_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    categoryName,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
