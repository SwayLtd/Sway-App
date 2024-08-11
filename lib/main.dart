// main.dart

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sway_events/core/constants/app_theme.dart';
import 'package:sway_events/core/constants/l10n.dart';
import 'package:sway_events/core/routes.dart';
import 'package:sway_events/core/services/database_service.dart';
import 'package:sway_events/core/services/notification_service.dart';
import 'package:sway_events/features/security/utils/security_utils.dart';
import 'package:url_strategy/url_strategy.dart';

Future<void> main() async {
  setPathUrlStrategy(); // Remove # from URL
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  DatabaseService().initialize();
  NotificationService().initialize();
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
              builder: (context, child) {
                return Stack(
                  children: [
                    child!,
                    // Encapsulating SecurityUtils in a Positioned widget to ensure it doesn't visually affect the application.
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child:
                          SecurityUtils(), // Instantiating SecurityUtils to execute checkDetection for root and jailbreak detection.
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
