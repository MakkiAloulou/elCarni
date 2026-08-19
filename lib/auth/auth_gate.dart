import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_repository.dart';
import '../screens/root_scaffold.dart';
import 'pending_screen.dart';
import 'sign_in_screen.dart';

/// Racine de l'app une fois Supabase initialisé (voir main.dart) :
/// pas de session → SignInScreen ; session mais teachers.status != 'valid'
/// → PendingScreen ; sinon l'app réelle.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const SignInScreen();
        }
        return _TeacherStatusGate(userId: session.user.id);
      },
    );
  }
}

/// Écoute la ligne `teachers` de l'utilisateur en direct (Realtime) pour
/// que le passage 'new'/'renew' → 'valid' fait depuis le Table Editor
/// Supabase débloque l'app sans reconnexion.
class _TeacherStatusGate extends StatelessWidget {
  const _TeacherStatusGate({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = Supabase.instance.client
        .from('teachers')
        .stream(primaryKey: ['id']).eq('id', userId);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (snapshot.hasError) {
          return _ErrorScreen(message: '${snapshot.error}');
        }

        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          // Le trigger on_auth_user_created insère la ligne teacher au
          // premier login — bref délai possible juste après signup.
          return const _LoadingScreen();
        }

        final status = rows.first['status'] as String? ?? 'new';
        return switch (status) {
          'valid' => const _DataGate(),
          'renew' => const PendingScreen(kind: PendingKind.renew),
          _ => const PendingScreen(kind: PendingKind.newAccount),
        };
      },
    );
  }
}

/// Charge groupes/élèves/séances/paiements une seule fois par session
/// app avant d'afficher l'app réelle — AppRepository.ensureLoaded()
/// met en cache son Future, donc les rebuilds répétés du StreamBuilder
/// parent (chaque mise à jour Realtime de la ligne teacher) ne
/// redéclenchent pas un rechargement complet.
class _DataGate extends StatelessWidget {
  const _DataGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AppRepository.ensureLoaded(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorScreen(message: 'Chargement impossible : ${snapshot.error}');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }
        return const RootScaffold();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
