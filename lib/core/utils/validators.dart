import 'dart:convert';
import 'package:flutter/services.dart';

/// Global field validator class that can be configured with several rules.
class FieldValidator {
  final bool isRequired;
  final int maxLength;
  // Utilise ce pattern par défaut s'il n'est pas fourni :
  // Bloque ;, " et exactement deux tirets consécutifs (sans tirets supplémentaires autour)
  final RegExp? forbiddenPattern;
  final List<String>? forbiddenWords;

  FieldValidator({
    this.isRequired = false,
    this.maxLength = 500,
    // Par défaut, si aucun forbiddenPattern n'est fourni, on utilise le suivant :
    this.forbiddenPattern,
    this.forbiddenWords,
  });

  /// Validates the given [value] according to the configured rules.
  String? validate(String? value) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'This field is required.';
    }
    if (value != null && value.length > maxLength) {
      return 'The text must not exceed $maxLength characters.';
    }
    // Utiliser le pattern fourni ou le pattern par défaut qui bloque ;, " et exactement "--"
    final pattern = forbiddenPattern ?? RegExp(r'[;"]|(?<!-)--(?!-)');
    if (value != null) {
      final match = pattern.firstMatch(value);
      if (match != null) {
        return 'Invalid characters used: "${match.group(0)}" is not allowed.';
      }
    }
    if (forbiddenWords != null && value != null) {
      for (var word in forbiddenWords!) {
        // Vérification sur les mots entiers pour éviter les faux positifs.
        final wordPattern =
            RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
        if (wordPattern.hasMatch(value)) {
          return 'Content not allowed: "$word" is forbidden.';
        }
      }
    }
    return null;
  }
}

/// Validates a username according to specified rules.
String? usernameValidator(String? username) {
  if (username == null || username.isEmpty) {
    return 'Please enter a username.';
  }
  // Regular expression to allow letters, numbers, dots, and underscores.
  final usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');
  if (!usernameRegex.hasMatch(username)) {
    return 'Username can only contain letters, numbers, dots, and underscores.';
  }
  if (username.contains(' ')) {
    return 'Username cannot contain spaces.';
  }
  if (username.length < 4 || username.length > 30) {
    return 'Username must be between 4 and 30 characters long.';
  }
  return null;
}

/// Validates an email address.
String? emailValidator(String? email) {
  if (email == null || email.isEmpty) {
    return 'Please enter an email.';
  }
  // Regular expression to validate email format.
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email.';
  }
  return null;
}

/// Validates a password ensuring a minimum length and composition.
String? passwordValidator(String? password) {
  if (password == null || password.isEmpty) {
    return 'Please enter a password.';
  }
  if (password.length < 8) {
    return 'Password must be at least 8 characters long.';
  }
  final hasUppercase = password.contains(RegExp(r'[A-Z]'));
  final hasLowercase = password.contains(RegExp(r'[a-z]'));
  final hasDigits = password.contains(RegExp(r'\d'));
  final hasSpecialCharacters =
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
    return 'Password must include uppercase, lowercase, number, and special character.';
  }
  return null;
}

// Validation URL pour tickets
String? ticketLinkValidator(String? value) {
  if (value != null && value.isNotEmpty) {
    final urlRegex =
        RegExp(r"^(http|https):\/\/[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+([\/?].*)?$");
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL for the ticket link.';
    }
  }
  return null;
}

/// Loads forbidden words from a local JSON asset file based on the [languageCode].
/// The expected file path is "assets/data/forbidden_words_{languageCode}.json".
///
/// Example:
///   For French: assets/data/forbidden_words_fr.json
///   For English: assets/data/forbidden_words_en.json
Future<List<String>> loadForbiddenWords(String languageCode) async {
  final assetPath = 'assets/data/forbidden_words_$languageCode.json';
  final jsonString = await rootBundle.loadString(assetPath);
  final List<dynamic> jsonResponse = json.decode(jsonString);
  return jsonResponse.cast<String>();
}

/*
Resources for forbidden words lists:

English:
  - RobertJGabriel's "Google-profanity-words" repository:
    https://github.com/RobertJGabriel/Google-profanity-words
  - LDNOOBW's "list-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words":
    https://github.com/LDNOOBW/list-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words

French:
  - darwiin's "french-badwords-list" repository:
    https://github.com/darwiin/french-badwords-list

Note:
Make sure to place the appropriate JSON files in your assets folder and declare them in your pubspec.yaml:
  
flutter:
  assets:
    - assets/data/forbidden_words_fr.json
    - assets/data/forbidden_words_en.json
*/

/*
To quickly format a plain text list into a valid JSON array in VS Code, follow these steps:

1. Open the file containing your list, ensuring each item is on a separate line.
2. Open the Replace panel (Ctrl+H) and enable regular expressions (the .* icon).
3. In the "Find" field, enter: ^(.*)$
   In the "Replace" field, enter: "$1",
   Then click "Replace All" to wrap each line in quotes and add a trailing comma.
4. Remove the extra comma from the last line manually.
5. Enclose the entire list by adding an opening bracket [ at the beginning and a closing bracket ] at the end.
6. Save the file with a .json extension to verify the syntax with VS Code’s JSON support (you can also use an extension like Prettier for further formatting).

This process will convert your text list into a properly formatted JSON array.
*/
