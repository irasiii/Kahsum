import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_provider.dart';
import '../../../models/deal.dart';
import '../../../core/theme/app_colors.dart';

final dealsProvider = FutureProvider<List<Deal>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/deals');
  final data = response.data as Map<String, dynamic>;
  final list = data['deals'] as List<dynamic>;
  return list.map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale;
    final isRtl = locale.languageCode == 'ar';
    final dealsAsync = ref.watch(dealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Khasm'),
        actions: [
          IconButton(
            icon: Icon(isRtl ? Icons.language : Icons.language),
            onPressed: () {
              final newLocale = isRtl ? const Locale('en') : const Locale('ar');
              context.setLocale(newLocale);
            },
          ),
        ],
      ),
      body: dealsAsync.when(
        data: (deals) {
          if (deals.isEmpty) {
              return Center(
                child: Text('dealsNoDeals'.tr()),
              );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deals.length,
            itemBuilder: (context, index) => _DealCard(deal: deals[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('errorsNetwork'.tr()),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;

  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final isAr = locale.languageCode == 'ar';
    final title = isAr ? deal.titleAr : deal.titleEn;
    final description = isAr ? deal.descriptionAr : deal.descriptionEn;
    final businessName = deal.trader.businessName;
    final categoryName = isAr ? deal.category.nameAr : deal.category.nameEn;
    final discountedPrice = deal.originalPrice * (1 - deal.discountPct / 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(
                    Icons.store,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.discountBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${deal.discountPct}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'SAR ${discountedPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SAR ${deal.originalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.sell_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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
