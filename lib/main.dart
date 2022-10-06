import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foodo_provider/translation/arabic_plural_resolver.dart';
import 'package:foodo_provider/translation/translations.dart';
import 'package:foodo_provider/ui/pages/landing/landing_page.dart';
import 'package:foodo_provider/ui/theme/theme.dart';
import 'package:foodo_provider/utils/preferences.dart';
import 'package:foodo_provider/utils/service_locator.dart';

void main() async {
  await initCoreServices();

  ArabicPluralResolver().setup();
  String storedLocale = prefs.getPreferredLanguage() ?? 'ar';
  LocaleSettings.setLocaleRaw(storedLocale);

  runApp(TranslationProvider(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromWindow(
      child: AppTheme(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              title: 'Flutter template',
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: LocaleSettings.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: context.theme.material(context),
              themeMode: AppTheme.of(context).themeMode,
              home: const LandingPage(),
            );
          }
        ),
      ),
    );
  }
}