// lib/features/user/widgets/auth_modal.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:sway/features/user/screens/terms_and_conditions_screen.dart';

class AuthModal extends StatelessWidget {
  const AuthModal({Key? key}) : super(key: key);

  /// Méthode statique pour afficher le modal d'authentification
  static void showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Pour ajuster la hauteur en fonction du contenu
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AuthModal(),
    );
  }

  /// Validateur de mot de passe personnalisé
  String? _passwordValidator(String? password) {
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

  /// Local username validator
  String? _usernameValidator(String? username) {
    if (username == null || username.isEmpty) {
      return 'Please enter a username.';
    }
    // Regular expression to allow letters, numbers, dots, and underscores
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Barre grise horizontale
          Container(
            height: 5,
            width: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            child: SupaEmailAuth(
              // URL de redirection pour les liens magiques
              redirectTo: kIsWeb ? null : 'app.sway.main://login-callback/',
              // Callback après une connexion réussie
              onSignInComplete: (response) {
                if (response.session != null) {
                  Navigator.of(context).pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed in successfully')),
                );
              },
              // Callback après une inscription réussie
              onSignUpComplete: (response) {
                if (response.session != null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please confirm your signup by email')),
                  );
                }
              },
              // Validateur de mot de passe personnalisé
              passwordValidator: _passwordValidator,
              // URL de redirection après réinitialisation du mot de passe
              resetPasswordRedirectTo:
                  kIsWeb ? null : 'app.sway.main://reset-password/',
              // Champs de métadonnées pour capturer des informations supplémentaires lors de l'inscription
              metadataFields: [
                MetaDataField(
                  prefixIcon: const Icon(Icons.person),
                  label: 'Username',
                  key: 'username',
                  validator: _usernameValidator,
                ),
                BooleanMetaDataField(
                  label: 'I wish to receive marketing emails',
                  key: 'marketing_consent',
                  checkboxPosition: ListTileControlAffinity.leading,
                ),
                BooleanMetaDataField(
                  key: 'terms_agreement',
                  isRequired: true,
                  checkboxPosition: ListTileControlAffinity.leading,
                  richLabelSpans: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const TermsAndConditionsScreen()),
                          );
                        },
                    ),
                  ],
                ),
              ],
              // Gestion des erreurs
              onError: (error) {
                String errorMessage = 'An unknown error occurred.';
                if (error is AuthException) {
                  errorMessage = error.message;
                } else if (error is Exception) {
                  errorMessage = error.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $errorMessage')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
