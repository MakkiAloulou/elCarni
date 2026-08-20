/// URL et clé anon du projet Supabase, injectées à la compilation via
/// `--dart-define-from-file=env.json` (voir env.example.json) plutôt que
/// codées en dur — même si la clé anon n'est pas un secret (elle est
/// protégée par les policies RLS, voir supabase/migrations/0001_init.sql),
/// ça évite d'avoir une valeur différente par environnement à changer
/// dans le code.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Client ID OAuth "Web application" (Google Cloud Console) — passé à
  /// GoogleSignIn(serverClientId: ...) même sur Android, pour que Google
  /// renvoie un idToken vérifiable par Supabase. Le client "Android"
  /// (package + empreinte SHA-1) n'a besoin d'exister dans Google Cloud
  /// que pour que Google accepte de délivrer ce token à cette app —
  /// aucun de ses identifiants n'est utilisé côté code. Voir
  /// lib/auth/sign_in_screen.dart.
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Numéro affiché sur l'écran d'attente (PendingScreen) pour qu'un
  /// compte 'new'/'renew' puisse joindre directement le créateur de
  /// l'app plutôt que d'attendre en silence.
  static const String creatorPhone = String.fromEnvironment('CREATOR_PHONE');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
