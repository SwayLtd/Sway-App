// lib/features/user/widgets/auth_modal.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/settings/screens/terms_and_conditions_screen.dart';
import 'package:sway/core/utils/validators.dart';

class AuthModal extends StatelessWidget {
  const AuthModal({Key? key}) : super(key: key);

  /// Méthode statique pour afficher le modal d'authentification
  static void showAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Permet au modal de s'ajuster en fonction du contenu et du clavier
      useSafeArea: true, // Évite les chevauchements avec les zones sensibles
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

  @override
  Widget build(BuildContext context) {
    // Définir une hauteur maximale pour le modal (43% de la hauteur de l'écran)
    final double maxHeight = MediaQuery.of(context).size.height * 0.43;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            // Barre grise horizontale centrée et bouton de fermeture
            Stack(
              children: [
                // Barre grise horizontale centrée
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Bouton de fermeture (croix) en haut à droite
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: sectionTitleSpacing),
            // Contenu défilable
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  child: SupaEmailAuth(
                    // URL de redirection pour les liens magiques
                    redirectTo:
                        kIsWeb ? null : 'app.sway.main://login-callback/',
                    // Callback après une connexion réussie
                    onSignInComplete: (response) {
                      if (response.session != null) {
                        Navigator.of(context).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Signed in successfully'),
                        ),
                      );
                    },
                    // Callback après une inscription réussie
                    onSignUpComplete: (response) {
                      if (response.session != null) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please confirm your signup by email'),
                          ),
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
                        validator: usernameValidator,
                      ),
                      BooleanMetaDataField(
                        label: 'I wish to receive marketing emails',
                        key: 'marketing_consent',
                        value: true,
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
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('$errorMessage'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
