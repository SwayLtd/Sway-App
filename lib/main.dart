import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sway_events/core/constants/app_theme.dart';
import 'package:sway_events/core/constants/l10n.dart';
import 'package:sway_events/core/routes.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  setPathUrlStrategy(); // Remove # from URL
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SwayEvents());
}

class SwayEvents extends StatelessWidget {
  const SwayEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanguageCubit(),
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, lang) {
          return AdaptiveTheme(
            light: AppTheme.light,
            dark: AppTheme.dark,
            initial: AdaptiveThemeMode.system,
            builder: (theme, darkTheme) => MaterialApp.router(
              debugShowCheckedModeBanner: false, // Remove debug banner
              // showSemanticsDebugger: true, // Show Semantics Debugger on screen
              onGenerateTitle: (BuildContext context) => context.loc.title,
              theme: theme,
              darkTheme: darkTheme,
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          );
        },
      ),
    );
  }
}

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en', ''));

  Future<void> chargeStartLang() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('lang');
    debugPrint(langCode);
    if (langCode != null) {
      emit(Locale(langCode, ''));
    }
  }

  Future<void> changeLang(BuildContext context, String data) async {
    emit(Locale(data, ''));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', data);
  }
}
