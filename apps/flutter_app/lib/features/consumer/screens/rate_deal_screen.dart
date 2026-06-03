import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/claims_provider.dart';

class RateDealScreen extends ConsumerStatefulWidget {
  final String claimId;
  const RateDealScreen({super.key, required this.claimId});

  @override
  ConsumerState<RateDealScreen> createState() => _RateDealScreenState();
}

class _RateDealScreenState extends ConsumerState<RateDealScreen> {
  double _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.locale.languageCode == 'ar'
                ? 'اختر عدد النجوم أولاً'
                : 'Please select a star rating first',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>('/api/ratings', data: {
        'claimId': widget.claimId,
        'stars': _stars.round(),
        if (_commentCtrl.text.trim().isNotEmpty)
          'comment': _commentCtrl.text.trim(),
      });
      ref.invalidate(myClaimsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('commonSuccess'.tr()),
            backgroundColor: AppColors.genuineGreen,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.contains('Already rated')
                  ? (context.locale.languageCode == 'ar'
                      ? 'قمت بتقييم هذا العرض من قبل'
                      : 'You already rated this deal')
                  : 'errorsGeneral'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final claimsAsync = ref.watch(myClaimsProvider);

    final dealTitle = claimsAsync.whenOrNull(
      data: (claims) {
        try {
          final claim = claims.firstWhere((c) => c.id == widget.claimId);
          return isAr ? claim.deal.titleAr : claim.deal.titleEn;
        } catch (_) {
          return null;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text('consumerRateDeal'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.star_rate_rounded,
                  size: 56, color: AppColors.accent),
              const SizedBox(height: 16),
              if (dealTitle != null)
                Text(
                  dealTitle.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'كيف كانت تجربتك مع هذا العرض؟'
                    : 'How was your experience with this deal?',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Star rating
              RatingBar.builder(
                initialRating: _stars,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 44,
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                ),
                onRatingUpdate: (r) => setState(() => _stars = r),
              ),
              const SizedBox(height: 8),
              if (_stars > 0)
                Text(
                  _starLabel(_stars.round(), isAr),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 24),

              // Comment
              TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  labelText: 'consumerLeaveComment'.tr(),
                  hintText: isAr
                      ? 'اختياري — شارك رأيك'
                      : 'Optional — share your thoughts',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('consumerSubmitRating'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _starLabel(int stars, bool isAr) {
    if (isAr) {
      return switch (stars) {
        1 => 'سيء جداً',
        2 => 'سيء',
        3 => 'مقبول',
        4 => 'جيد',
        _ => 'ممتاز',
      };
    }
    return switch (stars) {
      1 => 'Very poor',
      2 => 'Poor',
      3 => 'Fair',
      4 => 'Good',
      _ => 'Excellent',
    };
  }
}
