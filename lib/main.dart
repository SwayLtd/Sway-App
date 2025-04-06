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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
Future<void> main() async {
  usePathUrlStrategy(); // Remove # from URL
  await WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize Isar and Supabase via DatabaseService
  await DatabaseService().isar;
  await DatabaseService().initialize();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics configuration:
  // In development mode, disable report sending to avoid polluting your data.
  bool isInDebugMode = false;
  assert(() {
    isInDebugMode = true;
    return true;
  }());
  FlutterError.onError = isInDebugMode
      ? FlutterError.dumpErrorToConsole
      : FirebaseCrashlytics.instance.recordFlutterError;

  // Initialize Notification Services (e.g., for Firebase Messaging)
  await NotificationService().initialize();

  // Ensure a user is logged in (authenticated or anonymous)
  final authService = AuthService();
  await authService.ensureUser();

  // Initialize PDF service (for importing tickets, etc.)
  final PdfService pdfService = PdfService(rootNavigatorKey);
  await pdfService.initialize();

  // Initialize Firebase Analytics instance
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(
    SwayApp(analytics: analytics),
  );
}

class SwayApp extends StatelessWidget {
  final FirebaseAnalytics analytics;

  const SwayApp({Key? key, required this.analytics}) : super(key: key);

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
                    // Wrap SecurityUtils in a Positioned widget to ensure it doesn't visually affect the app.
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: SecurityUtils(),
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
