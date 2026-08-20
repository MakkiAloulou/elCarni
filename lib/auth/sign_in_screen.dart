import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../config/supabase_config.dart';
import '../theme/app_theme.dart';

/// Écran affiché quand personne n'est connecté. Flux "popup natif"
/// (compte déjà sur l'appareil, choisi via la boîte de dialogue système
/// Android) plutôt que le flux OAuth par navigateur externe
/// (signInWithOAuth) : ce dernier bloquait certains clients derrière
/// les écrans de première utilisation de Chrome (bienvenue,
/// notifications...) — voir historique de cette décision. Le popup
/// natif ne passe jamais par un navigateur, donc rien de tout ça.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    if (SupabaseConfig.googleWebClientId.isEmpty) {
      setState(() => _error =
          'GOOGLE_WEB_CLIENT_ID manquant dans env.json — voir env.example.json.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Annulé par l'utilisateur (fermeture du sélecteur de compte).
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw StateError(
            'idToken absent — vérifie que GOOGLE_WEB_CLIENT_ID est bien le client "Web application", pas le client Android.');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      // Pas de navigation manuelle : AuthGate écoute onAuthStateChange
      // et bascule tout seul une fois la session ouverte.
    } catch (e) {
      setState(() => _error = 'Connexion impossible : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('elCarni', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Gérez vos groupes, présences et paiements.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              FilledButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_loading ? 'Connexion...' : 'Continuer avec Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
