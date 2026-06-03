import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/deals_provider.dart';

class CreateDealScreen extends ConsumerStatefulWidget {
  const CreateDealScreen({super.key});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  int _step = 0;
  bool _submitting = false;

  // Step 1 – Basics
  final _titleArCtrl = TextEditingController();
  final _titleEnCtrl = TextEditingController();
  final _descArCtrl = TextEditingController();
  final _descEnCtrl = TextEditingController();
  int? _selectedCategoryId;
  final _formKey1 = GlobalKey<FormState>();

  // Step 2 – Pricing
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  bool _fetchingAi = false;
  Map<String, dynamic>? _aiSuggestion;
  final _formKey2 = GlobalKey<FormState>();

  // Step 3 – Details
  final _maxClaimsCtrl = TextEditingController(text: '100');
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  final _formKey3 = GlobalKey<FormState>();

  // Step 4 – Tier
  String _tier = 'basic';

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

  // -------------------------------------------------------------------------
  // AI price suggestion
  // -------------------------------------------------------------------------

  Future<void> _fetchAiSuggestion() async {
    if (_titleEnCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar'
              ? 'أدخل الاسم والسعر والفئة أولاً'
              : 'Enter title, price and category first'),
        ),
      );
      return;
    }

    setState(() {
      _fetchingAi = true;
      _aiSuggestion = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.post<Map<String, dynamic>>('/api/ai/price-suggestion', data: {
        'productName': _titleEnCtrl.text.trim(),
        'categoryId': _selectedCategoryId,
        'traderPrice': double.parse(_priceCtrl.text.trim()),
        'discountPct': double.tryParse(_discountCtrl.text.trim()) ?? 0,
        'language': context.locale.languageCode,
      });
      if (mounted) setState(() => _aiSuggestion = response.data);
    } catch (_) {
      // AI is optional; swallow errors silently
    } finally {
      if (mounted) setState(() => _fetchingAi = false);
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);

      final dealRes =
          await api.post<Map<String, dynamic>>('/api/deals', data: {
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
        'tier': _tier,
      });

      final dealId = dealRes.data!['deal']['id'] as String;

      await api.post<Map<String, dynamic>>('/api/payments/initiate',
          data: {'dealId': dealId, 'tier': _tier});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('commonSuccess'.tr()),
            backgroundColor: AppColors.genuineGreen,
          ),
        );
        context.go('/home');
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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text('traderCreateDeal'.tr())),
      body: Column(
        children: [
          _StepBar(current: _step, total: 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: [
                _buildStep1(context, isAr),
                _buildStep2(context, isAr),
                _buildStep3(context, isAr),
                _buildStep4(context, isAr),
              ][_step],
            ),
          ),
          _BottomNav(
            step: _step,
            submitting: _submitting,
            onBack: () => setState(() => _step--),
            onNext: () {
              final valid = switch (_step) {
                0 => _formKey1.currentState?.validate() ?? false,
                1 => _formKey2.currentState?.validate() ?? false,
                2 => _formKey3.currentState?.validate() ?? false,
                _ => true,
              };
              if (valid) {
                if (_step == 3) {
                  _submit();
                } else {
                  setState(() => _step++);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Step 1: Basics ────────────────────────────────────────────────────────

  Widget _buildStep1(BuildContext context, bool isAr) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: isAr ? 'معلومات العرض' : 'Deal Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleArCtrl,
            
            decoration:
                InputDecoration(labelText: 'traderDealTitleAr'.tr()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'errorsRequiredField'.tr() : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleEnCtrl,
            decoration:
                InputDecoration(labelText: 'traderDealTitleEn'.tr()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'errorsRequiredField'.tr() : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descArCtrl,
            
            decoration:
                InputDecoration(labelText: 'traderDealDescAr'.tr()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descEnCtrl,
            decoration:
                InputDecoration(labelText: 'traderDealDescEn'.tr()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text('errorsGeneral'.tr()),
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
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? 'errorsRequiredField'.tr() : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Pricing ───────────────────────────────────────────────────────

  Widget _buildStep2(BuildContext context, bool isAr) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: isAr ? 'التسعير' : 'Pricing'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceCtrl,
            decoration: InputDecoration(
              labelText: 'traderOriginalPrice'.tr(),
              suffixText: 'commonSar'.tr(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'errorsRequiredField'.tr();
              }
              if (double.tryParse(v.trim()) == null) {
                return 'errorsGeneral'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _discountCtrl,
            decoration: InputDecoration(
              labelText: 'traderDiscountPercent'.tr(),
              suffixText: '%',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'errorsRequiredField'.tr();
              }
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0 || n > 100) {
                return 'errorsGeneral'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchingAi ? null : _fetchAiSuggestion,
              icon: _fetchingAi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text('aiPriceSuggestion'.tr()),
            ),
          ),
          if (_aiSuggestion != null) ...[
            const SizedBox(height: 12),
            _AiSuggestionCard(
              suggestion: _aiSuggestion!,
              isAr: isAr,
              onUseSuggested: (price) =>
                  setState(() => _priceCtrl.text = price.toStringAsFixed(0)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 3: Details ───────────────────────────────────────────────────────

  Widget _buildStep3(BuildContext context, bool isAr) {
    final formatted =
        '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}';

    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
              title: isAr ? 'تفاصيل إضافية' : 'Additional Details'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxClaimsCtrl,
            decoration:
                InputDecoration(labelText: 'traderMaxClaims'.tr()),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'errorsRequiredField'.tr();
              }
              final n = int.tryParse(v.trim());
              if (n == null || n < 1) return 'errorsGeneral'.tr();
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text('traderExpiryDate'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
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
              if (picked != null) setState(() => _expiryDate = picked);
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
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(formatted,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Tier selection ────────────────────────────────────────────────

  Widget _buildStep4(BuildContext context, bool isAr) {
    const tiers = ['basic', 'standard', 'premium'];
    final tierLabelKeys = [
      'traderBasicTier',
      'traderStandardTier',
      'traderPremiumTier'
    ];
    final tierPrices = [49, 99, 199];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'traderSelectTier'.tr()),
        const SizedBox(height: 16),
        ...List.generate(tiers.length, (i) {
          final selected = _tier == tiers[i];
          return GestureDetector(
            onTap: () => setState(() => _tier = tiers[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: tiers[i],
                    groupValue: _tier,
                    onChanged: (v) => setState(() => _tier = v!),
                    activeColor: AppColors.primary,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tierLabelKeys[i].tr(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        if (tiers[i] == 'premium')
                          Text(
                            isAr
                                ? '+ وسام مميز + ظهور في المقدمة'
                                : '+ Featured badge + top placement',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.accent),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${tierPrices[i]} ${isAr ? 'ريال' : 'SAR'}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('traderMockPaymentNote'.tr(),
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _StepBar extends StatelessWidget {
  final int current;
  final int total;
  const _StepBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= current
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int step;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.step,
    required this.submitting,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text('commonBack'.tr()),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: submitting ? null : onNext,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(step == 3
                        ? 'traderPostDeal'.tr()
                        : 'commonNext'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final bool isAr;
  final ValueChanged<double> onUseSuggested;

  const _AiSuggestionCard({
    required this.suggestion,
    required this.isAr,
    required this.onUseSuggested,
  });

  @override
  Widget build(BuildContext context) {
    final verdict = suggestion['verdict'] as String? ?? '';
    final isHonest = verdict == 'honest';
    final avg = (suggestion['marketPriceAvg'] as num?)?.toDouble();
    final verdictLabel =
        suggestion['verdictLabel'] as String? ?? verdict;
    final suggestionText = suggestion['suggestion'] as String?;
    final borderColor =
        isHonest ? AppColors.genuineGreen : AppColors.inflatedAmber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHonest
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: borderColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('aiPriceSuggestion'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  verdictLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (suggestionText != null) ...[
            const SizedBox(height: 8),
            Text(suggestionText, style: const TextStyle(fontSize: 13)),
          ],
          if (avg != null && !isHonest) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onUseSuggested(avg),
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: Text(
                '${isAr ? 'استخدام السعر المقترح' : 'Use suggested'}: ${avg.toStringAsFixed(0)} SAR',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
