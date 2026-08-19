import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../theme/app_theme.dart';

enum PendingKind { newAccount, renew }

/// Affiché tant que teachers.status vaut 'new' ou 'renew'. Pas de bouton
/// "rafraîchir" : AuthGate écoute la ligne teacher en direct (Realtime),
/// donc l'app bascule seule dès que le status passe à 'valid' dans le
/// Table Editor Supabase — voir supabase/migrations/0002_realtime.sql.
class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.kind});

  final PendingKind kind;

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  Future<void> _callCreator() async {
    final uri = Uri(scheme: 'tel', path: SupabaseConfig.creatorPhone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer l\'appel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final isRenew = kind == PendingKind.renew;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRenew ? Icons.autorenew : Icons.hourglass_top,
                size: 56,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isRenew
                    ? 'Renouvellement en attente'
                    : 'Compte en attente de validation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isRenew
                    ? "Votre accès doit être renouvelé. L'app se débloquera automatiquement dès que ce sera fait."
                    : "Votre inscription est en cours de validation. L'app se débloquera automatiquement dès qu'elle sera approuvée.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: _callCreator,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.call),
                label: const Text('Appeler le créateur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
