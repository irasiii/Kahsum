import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String _type = 'consumer'; // 'consumer' | 'trader'
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passCtrl.text,
            type: _type,
            language: context.locale.languageCode,
          );
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      final msg = e.toString();
      setState(() {
        _error = msg.contains('409') || msg.contains('already')
            ? (context.locale.languageCode == 'ar'
                ? 'البريد الإلكتروني أو رقم الجوال مستخدم بالفعل'
                : 'Email or phone already registered')
            : 'errorsGeneral'.tr();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text('authRegisterTitle'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account type selector
                Text(
                  'onboardingSelectRole'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _TypeCard(
                      selected: _type == 'consumer',
                      icon: Icons.person_outline,
                      label: isAr ? 'مستهلك' : 'Consumer',
                      sublabel: isAr
                          ? 'ابحث عن العروض ووفّر'
                          : 'Find deals & save',
                      onTap: () =>
                          setState(() => _type = 'consumer'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _TypeCard(
                      selected: _type == 'trader',
                      icon: Icons.store_outlined,
                      label: isAr ? 'تاجر' : 'Trader',
                      sublabel: isAr
                          ? 'انشر عروضك وسع عملك'
                          : 'Post deals & grow',
                      onTap: () =>
                          setState(() => _type = 'trader'),
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'authName'.tr(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'errorsRequiredField'.tr()
                          : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'authEmail'.tr(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'errorsRequiredField'.tr();
                    }
                    if (!v.contains('@')) {
                      return 'errorsInvalidEmail'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'authPhone'.tr(),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: isAr ? 'مثال: 0501234567' : 'e.g. 0501234567',
                  ),
                  keyboardType: TextInputType.phone,
                  
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'errorsRequiredField'.tr();
                    }
                    if (v.trim().length < 8) {
                      return 'errorsInvalidPhone'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'authPassword'.tr(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'errorsRequiredField'.tr();
                    }
                    if (v.length < 6) {
                      return 'errorsPasswordShort'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Error
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text('authRegister'.tr()),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      isAr
                          ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                          : 'Already have an account? Login',
                      style:
                          const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
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
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
