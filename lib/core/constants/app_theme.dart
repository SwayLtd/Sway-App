// app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    primaryColor: Color.fromRGBO(255, 188, 0, 1),
    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(255, 188, 0, 1),
      secondary: Colors.amberAccent,
      error: Colors.red,
      onPrimary: Colors.black,
      surface: Colors.white, // Couleur de surface pour les dialogues
    ),
    primarySwatch: Colors.amber,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    disabledColor: Colors.black54,
    scaffoldBackgroundColor: Colors.grey[200], // Légèrement grisé pour le fond
    cardColor: Colors.white, // Couleur blanche pour les cartes
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0.0, // Disable appbar color change on scroll
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      elevation: 0.0,
      color: Colors.grey[100], // Légèrement grisé pour harmoniser avec le fond
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:
          Colors.grey[100], // Légèrement grisé pour harmoniser avec le fond
      selectedItemColor: Color.fromRGBO(255, 188, 0, 1),
      unselectedItemColor: Colors.black54,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:
          Colors.grey[100], // Légèrement grisé pour harmoniser avec le fond
      indicatorColor: Color.fromRGBO(
          255, 188, 0, 1), // Couleur de l'indicateur de sélection
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(
          color: Colors.black, // Couleur des icônes sélectionnées
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors
          .white, // Arrière-plan opaque pour PopupMenuButton en mode clair
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor:
          Colors.white, // Couleur de fond des dialogues en mode clair
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    ).apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white, // Fond pour le BottomSheet en mode clair
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor:
          Colors.white, // Fond opaque du timePicker         // Fond du picker
      hourMinuteColor: Colors.grey[200],
      hourMinuteTextStyle: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      dayPeriodTextStyle: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 48, // La taille désirée
          fontWeight: FontWeight.bold,
          color: Colors.black, // Couleur souhaitée
        ),
      ),
      dialHandColor: const Color.fromRGBO(255, 188, 0, 1),
      dialBackgroundColor: Colors.grey[200],
      // Éventuellement d’autres propriétés, selon vos besoins
    ),
  );

  static ThemeData dark = ThemeData(
    primaryColor: Color.fromRGBO(255, 188, 0, 1),
    colorScheme: const ColorScheme.dark(
      primary: Color.fromRGBO(255, 188, 0, 1),
      secondary: Colors.amberAccent,
      surface: Colors.black54, // Couleur de surface pour les dialogues
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    primarySwatch: Colors.amber,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    disabledColor: Colors.white70,
    scaffoldBackgroundColor:
        Color.fromRGBO(15, 13, 8, 1), // Changer à noir opaque
    cardColor: Colors.black54, // Couleur pour les cartes dans le thème sombre
    appBarTheme: AppBarTheme(
      scrolledUnderElevation: 0.0, // Disable appbar color change on scroll
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      elevation: 0.0,
      color: Color.fromRGBO(
          15, 13, 8, 1), // grey[900] // Fond de l'AppBar légèrement grisé
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(
          15, 13, 8, 1), // grey[900] // Fond de l'AppBar légèrement grisé
      selectedItemColor: Color.fromRGBO(255, 188, 0, 1),
      unselectedItemColor: Colors.white70,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color.fromRGBO(
          15, 13, 8, 1), // Fond pour la NavigationBar en mode sombre
      indicatorColor: const Color.fromARGB(
          255, 255, 188, 0), // Couleur de l'indicateur de sélection
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(
          color: Colors
              .white, // Couleur contrastante pour les icônes sélectionnées en mode sombre
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Color.fromRGBO(15, 13, 8,
          1), // Arrière-plan opaque pour PopupMenuButton en mode sombre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Color.fromRGBO(
          15, 13, 8, 1), // Couleur de fond des dialogues en mode sombre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Color.fromRGBO(
          15, 13, 8, 1), // Fond pour le BottomSheet en mode sombre
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color.fromRGBO(15, 13, 8, 1),
      hourMinuteTextStyle: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      // Couleur de fond de la zone cliquable (non sélectionnée vs sélectionnée)
      hourMinuteColor: const Color.fromRGBO(255, 188, 0, 1),
      dayPeriodTextStyle: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      timeSelectorSeparatorTextStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 48, // La taille désirée
          fontWeight: FontWeight.bold,
          color: Colors.white, // Couleur souhaitée
        ),
      ),
      dialHandColor: const Color.fromARGB(255, 255, 188, 0),
      dialBackgroundColor: Colors.black54,
    ),
  );
}
