import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({super.key});

  void _pickLocaleAndContinue(
      BuildContext context, WidgetRef ref, Locale locale, String next) {
    context.setLocale(locale);
    context.go(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.local_offer,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                'appName'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              Text(
                'appTagline'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 44),

              // Language selection
              Text('languagePickerTitle'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              _LangButton(
                label: 'languageArabic'.tr(),
                onTap: () => _pickLocaleAndContinue(
                    context, ref, const Locale('ar'), '/login'),
              ),
              const SizedBox(height: 10),
              _LangButton(
                label: 'languageEnglish'.tr(),
                onTap: () => _pickLocaleAndContinue(
                    context, ref, const Locale('en'), '/login'),
              ),
              const SizedBox(height: 32),

              // Auth actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: Text('authLogin'.tr()),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('authRegister'.tr()),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).continueAsGuest();
                  context.go('/home');
                },
                child: Text('authContinueAsGuest'.tr(),
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.language, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}
