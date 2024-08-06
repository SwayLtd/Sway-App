import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sway_events/core/constants/app_theme.dart';
import 'package:sway_events/core/constants/l10n.dart';
import 'package:sway_events/core/routes.dart';
import 'package:sway_events/core/services/database_service.dart';
import 'package:sway_events/core/services/notification_service.dart';
import 'package:url_strategy/url_strategy.dart';

Future<void> main() async {
  setPathUrlStrategy(); // Remove # from URL
  WidgetsFlutterBinding.ensureInitialized();
  initializeSupabase();
  initializeOneSignal();
  // initializeAwesomeNotifications();
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
