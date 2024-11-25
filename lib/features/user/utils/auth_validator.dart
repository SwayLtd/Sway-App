// lib/features/user/utils/auth_validator.dart

/// Validateur de nom d'utilisateur local
String? usernameValidator(String? username) {
  if (username == null || username.isEmpty) {
    return 'Please enter a username.';
  }
  // Expression régulière pour permettre lettres, chiffres, points et underscores
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

/// Validateur d'email local
String? emailValidator(String? email) {
  if (email == null || email.isEmpty) {
    return 'Please enter an email.';
  }
  // Expression régulière pour valider le format de l'email
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email.';
  }
  return null;
}
