import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/app_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';

/// Réglages prof — pour l'instant juste les niveaux et sections
/// enseignés (AppRepository.taughtLevels/taughtSections). Chaque tap
/// applique tout de suite, pas de bouton "Enregistrer" : c'est une
/// préférence, pas un formulaire à valider.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Set<Level> _levels = {...AppRepository.taughtLevels};
  late final Set<Section> _sections = {...AppRepository.taughtSections};

  bool get _needsSection => _levels.any((l) => l.hasSection);

  void _toggleLevel(Level level, bool selected) {
    setState(() {
      if (selected) {
        _levels.add(level);
      } else {
        _levels.remove(level);
      }
      // Persistance en tâche de fond : setTaughtLevels met déjà à jour
      // AppRepository.taughtLevels/taughtSections de façon synchrone
      // avant son premier await, donc les relire juste en dessous est
      // sûr même sans attendre l'écriture réseau.
      unawaited(AppRepository.setTaughtLevels(_levels));
      // Reflète tout de suite le nettoyage fait côté AppRepository si plus
      // aucun niveau à section n'est coché.
      _sections
        ..clear()
        ..addAll(AppRepository.taughtSections);
    });
  }

  void _toggleSection(Section section, bool selected) {
    setState(() {
      if (selected) {
        _sections.add(section);
      } else {
        _sections.remove(section);
      }
      unawaited(AppRepository.setTaughtSections(_sections));
    });
  }

  Future<void> _signOut() async {
    // Vide le cache avant de couper la session : AuthGate va démonter
    // RootScaffold dès que onAuthStateChange émet, mais autant ne pas
    // laisser les données de ce prof en mémoire entre-temps.
    AppRepository.reset();
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer toutes les données ?'),
        content: const Text(
          'Tous les groupes, élèves, séances, présences et paiements seront '
          'définitivement supprimés. Ton compte reste actif, mais cette '
          'action est irréversible.',
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 40),
              backgroundColor: AppStatus.due,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppRepository.deleteAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les données ont été supprimées.')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120),
        children: [
          const SectionHeader(icon: Icons.school_outlined, title: 'Niveaux enseignés'),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Les niveaux que tu coches sont ceux proposés à la création d\'un groupe.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final level in Level.values)
                      FilterChip(
                        label: Text(level.label),
                        selected: _levels.contains(level),
                        onSelected: (selected) => _toggleLevel(level, selected),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_needsSection) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(icon: Icons.workspaces_outlined, title: 'Sections enseignées'),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uniquement pertinent en 3ème et Bac.',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final section in Section.values)
                        FilterChip(
                          label: Text(section.label),
                          selected: _sections.contains(section),
                          onSelected: (selected) => _toggleSection(section, selected),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _deleteAllData,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.ink,
              ),
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: const Text('Supprimer toutes les données'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
