// lib/main.dart

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sway/core/constants/app_theme.dart';
import 'package:sway/core/constants/l10n.dart';
import 'package:sway/core/routes.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/core/services/pdf_service.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/security/utils/security_utils.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sway/features/user/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  usePathUrlStrategy(); // Remove # from URL
  await WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize Isar first
  await DatabaseService().isar;

  // Initialize Supabase
  await DatabaseService().initialize();

  // Initialize Notification Services
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();

  final authService = AuthService();
  // Make sure a user is logged in (authenticated or anonymous)
  await authService.ensureUser();

  // Initialize the ability to open PDFs with the application to import tickets
  final PdfService pdfService = PdfService(rootNavigatorKey);
  await pdfService.initialize();

  runApp(
    SwayApp(),
  );
}

class SwayApp extends StatelessWidget {
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
