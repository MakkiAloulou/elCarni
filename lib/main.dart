import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    // publishableKey est le nom actuel de ce qu'on appelait "anon key" —
    // même valeur, celle du Table Editor Supabase (Project Settings > API).
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const ElCarniApp());
}

class ElCarniApp extends StatelessWidget {
  const ElCarniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'elCarni',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

/// Évite un crash silencieux si l'app est lancée sans
/// --dart-define-from-file=env.json (voir env.example.json).
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Configuration manquante.\n'
              'Lance avec : flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
