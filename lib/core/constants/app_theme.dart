// app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    primaryColor: const Color.fromRGBO(255, 188, 0, 1),
    colorScheme: ColorScheme.light(
      primary: const Color.fromRGBO(255, 188, 0, 1),
      secondary: Colors.amberAccent,
      error: Colors.red,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      surfaceContainerHighest: Colors.transparent,
      surface: Colors.white, // Couleur de surface pour les dialogues
    ),
    primarySwatch: Colors.amber,
    brightness: Brightness.light,
    fontFamily: 'SpaceGrotesk',
    disabledColor: Colors.black54,
    scaffoldBackgroundColor: Colors.grey[200], // Fond légèrement grisé
    cardColor: Colors.white.withValues(
        alpha: 0.5), // Couleur blanche semi-transparente pour les cartes
    cardTheme: CardTheme(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    canvasColor: Colors.white,
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.all(Colors.grey[500]),
    ),
    snackBarTheme: SnackBarThemeData(
      actionTextColor:
          Colors.white, // Utilise la couleur primaire pour les actions
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        iconColor: Colors.black,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 1),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: Color.fromRGBO(0, 0, 0, 0.25), // Couleur de la bordure
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation:
          0.0, // Désactive le changement de couleur lors du scroll
      systemOverlayStyle: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.grey[100],
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      elevation: 0.0,
      color: Colors
          .grey[100], // Fond légèrement grisé pour harmoniser avec le reste
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[100],
      selectedItemColor: const Color.fromRGBO(255, 188, 0, 1),
      unselectedItemColor: Colors.black54,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey[100],
      indicatorColor: const Color.fromRGBO(255, 188, 0, 1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(
          color: Colors.black,
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white, // Arrière-plan opaque pour PopupMenuButton
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white, // Fond des dialogues
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(
          color: Colors.grey, // Bordure grise
          width: 2.0,
        ),
      ),
      elevation: 4.0,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.15,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    ).apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: Colors.grey[200],
      hourMinuteTextStyle: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      dayPeriodTextStyle: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      dialHandColor: const Color.fromRGBO(255, 188, 0, 1),
      dialBackgroundColor: Colors.grey[200],
    ),
  );

  static ThemeData dark = ThemeData(
    primaryColor: const Color.fromRGBO(255, 188, 0, 1),
    colorScheme: ColorScheme.dark(
      primary: const Color.fromRGBO(255, 188, 0, 1),
      secondary: Colors.amberAccent,
      surface: Colors.black54, // Couleur de surface pour les dialogues
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surfaceContainerHighest: Colors.grey[200],
    ),
    primarySwatch: Colors.amber,
    brightness: Brightness.dark,
    fontFamily: 'SpaceGrotesk',
    disabledColor: Colors.white70,
    scaffoldBackgroundColor: const Color.fromRGBO(15, 13, 8, 1),
    cardColor: const Color.fromRGBO(15, 13, 8, 1),
    cardTheme: CardTheme(
      color: const Color.fromRGBO(15, 13, 8, 1),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    canvasColor: Colors.black,
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.all(Colors.grey[500]),
    ),
    snackBarTheme: SnackBarThemeData(
      actionTextColor: Colors.black,
      contentTextStyle: const TextStyle(color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        iconColor: Colors.white,
        elevation: 2,
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.25),
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0.0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromRGBO(15, 13, 8, 1),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      elevation: 0.0,
      color: const Color.fromRGBO(15, 13, 8, 1),
      /*actionsIconTheme: const IconThemeData(
        size: 20.0,
      ),*/
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      selectedItemColor: const Color.fromRGBO(255, 188, 0, 1),
      unselectedItemColor: Colors.white70,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      indicatorColor: const Color.fromRGBO(255, 188, 0, 1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(
          color: Colors.white,
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color.fromRGBO(15, 13, 8, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(
          color: Colors.grey,
          width: 2.0,
        ),
      ),
      elevation: 4.0,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color.fromRGBO(15, 13, 8, 1),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      hourMinuteTextStyle: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      hourMinuteColor: const Color.fromRGBO(255, 188, 0, 1),
      dayPeriodTextStyle: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      dialHandColor: const Color.fromRGBO(255, 188, 0, 1),
      dialBackgroundColor: Colors.black54,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
    ),
  );
}

extension ShimmerColors on ThemeData {
  Color get shimmerBaseColor => brightness == Brightness.dark
      ? Colors.grey.shade700
      : Colors.grey.shade300;

  Color get shimmerHighlightColor => brightness == Brightness.dark
      ? Colors.grey.shade500
      : Colors.grey.shade100;
}
