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

  /// Scheme+host déclarés dans AndroidManifest.xml / Info.plist — c'est
  /// là que le navigateur ramène l'utilisateur après le login Google.
  /// Le Client ID/Secret Google, eux, ne sont jamais dans l'app : ils
  /// vivent uniquement dans le dashboard Supabase (Auth > Providers >
  /// Google). Voir lib/auth/sign_in_screen.dart.
  static const String authRedirectUrl = 'com.elcarni.elcarni://login-callback';

  /// Numéro affiché sur l'écran d'attente (PendingScreen) pour qu'un
  /// compte 'new'/'renew' puisse joindre directement le créateur de
  /// l'app plutôt que d'attendre en silence.
  static const String creatorPhone = String.fromEnvironment('CREATOR_PHONE');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
