import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

// Fetches full user profile from server.
final _profileProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get<Map<String, dynamic>>('/api/users/me');
  return response.data!['user'] as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isAr = context.locale.languageCode == 'ar';

    // Guest state
    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        appBar: AppBar(title: Text('settingsTitle'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? 'سجّل الدخول لإدارة حسابك'
                      : 'Login to manage your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: Text('authLogin'.tr()),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text('authRegister'.tr()),
                ),
                // Language section for guests
                const Divider(height: 32),
                _LanguageTile(isAr: isAr),
              ],
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settingsTitle'.tr())),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            Center(child: Text('errorsNetwork'.tr())),
        data: (profile) => _ProfileBody(
            profile: profile, isAr: isAr),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ProfileBody extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;
  final bool isAr;
  const _ProfileBody(
      {required this.profile, required this.isAr});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  // Trader-specific
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p['name'] as String? ?? '');
    _phoneCtrl =
        TextEditingController(text: p['phone'] as String? ?? '');
    final trader = p['traderProfile'] as Map<String, dynamic>?;
    _businessNameCtrl = TextEditingController(
        text: trader?['businessName'] as String? ?? '');
    _addressCtrl = TextEditingController(
        text: trader?['address'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put<Map<String, dynamic>>('/api/users/me', data: {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      await ref
          .read(authProvider.notifier)
          .updateLocalName(_nameCtrl.text.trim());
      ref.invalidate(_profileProvider);
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('commonSuccess'.tr()),
              backgroundColor: AppColors.genuineGreen),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorsGeneral'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final isAr = widget.isAr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج؟' : 'Logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('commonCancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('authLogout'.tr())),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final p = widget.profile;
    final isTrader = p['type'] == 'trader';
    final trader = p['traderProfile'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + name chip
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (p['name'] as String? ?? '?')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                p['name'] as String? ?? '',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTrader
                      ? (isAr ? 'تاجر' : 'Trader')
                      : (isAr ? 'مستهلك' : 'Consumer'),
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Edit toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'معلومات الحساب' : 'Account Info',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined,
                  size: 16),
              label: Text(_editing
                  ? 'commonCancel'.tr()
                  : (isAr ? 'تعديل' : 'Edit')),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_editing) ...[
          // Editable fields
          TextFormField(
            controller: _nameCtrl,
            decoration:
                InputDecoration(labelText: 'authName'.tr()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration:
                InputDecoration(labelText: 'authPhone'.tr()),
            keyboardType: TextInputType.phone,
            
          ),
          if (isTrader && trader != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessNameCtrl,
              decoration: InputDecoration(
                  labelText: isAr ? 'اسم النشاط التجاري' : 'Business Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                  labelText: isAr ? 'العنوان' : 'Address'),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('commonSave'.tr()),
            ),
          ),
        ] else ...[
          // Read-only info tiles
          _InfoTile(label: 'authEmail'.tr(), value: p['email'] as String? ?? ''),
          _InfoTile(label: 'authPhone'.tr(), value: p['phone'] as String? ?? ''),
          if (isTrader && trader != null) ...[
            _InfoTile(
              label: isAr ? 'اسم النشاط' : 'Business',
              value: trader['businessName'] as String? ?? '',
            ),
            if (trader['address'] != null)
              _InfoTile(
                label: isAr ? 'العنوان' : 'Address',
                value: trader['address'] as String,
              ),
            _InfoTile(
              label: isAr ? 'التقييم' : 'Rating',
              value:
                  '${(trader['ratingAvg'] as num?)?.toStringAsFixed(1) ?? '—'} ★ (${trader['ratingCount'] ?? 0})',
            ),
          ],
        ],

        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 12),

        // Language
        _LanguageTile(isAr: isAr),
        const SizedBox(height: 8),

        // Logout
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text('authLogout'.tr(),
              style: const TextStyle(color: Colors.red)),
          onTap: _logout,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  final bool isAr;
  const _LanguageTile({required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          const Icon(Icons.language, color: AppColors.primary),
      title: Text('settingsLanguage'.tr()),
      trailing: Text(
        isAr ? 'عربي' : 'English',
        style: const TextStyle(color: AppColors.primary),
      ),
      onTap: () {
        final newLocale =
            isAr ? const Locale('en') : const Locale('ar');
        context.setLocale(newLocale);
      },
    );
  }
}
