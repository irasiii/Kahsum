import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/deal.dart';
import '../../../providers/deals_provider.dart';

// Provider that fetches a single deal by ID for pre-filling the form.
final _editDealProvider =
    FutureProvider.family<Deal, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/deals/$id');
  return Deal.fromJson(response.data!['deal'] as Map<String, dynamic>);
});

class EditDealScreen extends ConsumerWidget {
  final String dealId;
  const EditDealScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(_editDealProvider(dealId));

    return Scaffold(
      appBar: AppBar(title: Text(context.locale.languageCode == 'ar' ? 'تعديل العرض' : 'Edit Deal')),
      body: dealAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('errorsGeneral'.tr())),
        data: (deal) => _EditForm(deal: deal),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  final Deal deal;
  const _EditForm({required this.deal});

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleArCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _descArCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _maxClaimsCtrl;
  late DateTime _expiryDate;
  late int? _selectedCategoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.deal;
    _titleArCtrl = TextEditingController(text: d.titleAr);
    _titleEnCtrl = TextEditingController(text: d.titleEn);
    _descArCtrl = TextEditingController(text: d.descriptionAr ?? '');
    _descEnCtrl = TextEditingController(text: d.descriptionEn ?? '');
    _priceCtrl = TextEditingController(
        text: d.originalPrice.toStringAsFixed(0));
    _discountCtrl = TextEditingController(
        text: d.discountPct.toStringAsFixed(0));
    _maxClaimsCtrl =
        TextEditingController(text: d.maxRedemptions.toString());
    _expiryDate = DateTime.tryParse(d.expiryDate) ??
        DateTime.now().add(const Duration(days: 7));
    _selectedCategoryId = d.category.id;
  }

  @override
  void dispose() {
    _titleArCtrl.dispose();
    _titleEnCtrl.dispose();
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _maxClaimsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put<Map<String, dynamic>>(
        '/api/deals/${widget.deal.id}',
        data: {
          'categoryId': _selectedCategoryId,
          'titleAr': _titleArCtrl.text.trim(),
          'titleEn': _titleEnCtrl.text.trim(),
          if (_descArCtrl.text.trim().isNotEmpty)
            'descriptionAr': _descArCtrl.text.trim(),
          if (_descEnCtrl.text.trim().isNotEmpty)
            'descriptionEn': _descEnCtrl.text.trim(),
          'discountPct': double.parse(_discountCtrl.text.trim()),
          'originalPrice': double.parse(_priceCtrl.text.trim()),
          'maxRedemptions': int.parse(_maxClaimsCtrl.text.trim()),
          'expiryDate': _expiryDate.toIso8601String(),
        },
      );
      ref.invalidate(myTraderDealsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('commonSuccess'.tr()),
              backgroundColor: AppColors.genuineGreen),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('errorsGeneral'.tr()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final categoriesAsync = ref.watch(categoriesProvider);
    final formatted =
        '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleArCtrl,
            
            decoration: InputDecoration(
                labelText: 'traderDealTitleAr'.tr()),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'errorsRequiredField'.tr()
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleEnCtrl,
            decoration: InputDecoration(
                labelText: 'traderDealTitleEn'.tr()),
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'errorsRequiredField'.tr()
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descArCtrl,
            
            decoration: InputDecoration(
                labelText: 'traderDealDescAr'.tr()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descEnCtrl,
            decoration: InputDecoration(
                labelText: 'traderDealDescEn'.tr()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => DropdownButtonFormField<int>(
              decoration: InputDecoration(
                  labelText: isAr ? 'الفئة' : 'Category'),
              value: _selectedCategoryId,
              isExpanded: true,
              items: cats
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          isAr ? c.nameAr : c.nameEn,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategoryId = v),
              validator: (v) =>
                  v == null ? 'errorsRequiredField'.tr() : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'traderOriginalPrice'.tr(),
                    suffixText: 'SAR',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  validator: (v) =>
                      (v == null ||
                              v.trim().isEmpty ||
                              double.tryParse(v.trim()) == null)
                          ? 'errorsRequiredField'.tr()
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _discountCtrl,
                  decoration: InputDecoration(
                    labelText: 'traderDiscountPercent'.tr(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0 || n > 100) {
                      return 'errorsRequiredField'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _maxClaimsCtrl,
            decoration:
                InputDecoration(labelText: 'traderMaxClaims'.tr()),
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) {
                return 'errorsRequiredField'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text('traderExpiryDate'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate,
                firstDate:
                    DateTime.now().add(const Duration(days: 1)),
                lastDate:
                    DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _expiryDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(formatted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('commonSave'.tr()),
          ),
        ],
      ),
    );
  }
}
