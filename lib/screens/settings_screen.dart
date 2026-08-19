import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';

/// Réglages prof — pour l'instant juste les niveaux et sections
/// enseignés (MockData.taughtLevels/taughtSections). Chaque tap
/// applique tout de suite, pas de bouton "Enregistrer" : c'est une
/// préférence, pas un formulaire à valider.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Set<Level> _levels = {...MockData.taughtLevels};
  late final Set<Section> _sections = {...MockData.taughtSections};

  bool get _needsSection => _levels.any((l) => l.hasSection);

  void _toggleLevel(Level level, bool selected) {
    setState(() {
      if (selected) {
        _levels.add(level);
      } else {
        _levels.remove(level);
      }
      MockData.setTaughtLevels(_levels);
      // Reflète tout de suite le nettoyage fait côté MockData si plus
      // aucun niveau à section n'est coché.
      _sections
        ..clear()
        ..addAll(MockData.taughtSections);
    });
  }

  void _toggleSection(Section section, bool selected) {
    setState(() {
      if (selected) {
        _sections.add(section);
      } else {
        _sections.remove(section);
      }
      MockData.setTaughtSections(_sections);
    });
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
    );
  }
}
