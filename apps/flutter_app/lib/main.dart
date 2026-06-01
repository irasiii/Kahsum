import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final locale = await _getSavedLocale();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'lib/l10n',
      fallbackLocale: const Locale('ar'),
      startLocale: locale,
      saveLocale: true,
      useOnlyLangCode: true,
      child: const ProviderScope(
        child: KhasmApp(),
      ),
    ),
  );
}

Future<Locale?> _getSavedLocale() async {
  try {
    final storage = await const FlutterSecureStorage().read(key: 'app_language');
    if (storage == 'en') return const Locale('en');
    return const Locale('ar');
  } catch (_) {
    return null;
  }
}
