import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/group_card.dart';
import 'group_detail_screen.dart';
import 'group_form_sheet.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  // null = "Tous" ; sinon filtre sur Group.level.
  Level? _levelFilter;
  // Section ne s'applique qu'en 3ème/Bac — voir Level.hasSection ;
  // remise à null dès que le niveau change pour un niveau sans section.
  Section? _sectionFilter;

  // Restreint aux niveaux/sections cochés dans Réglages — mais un
  // niveau/section porté par un groupe déjà existant reste toujours
  // proposé, même s'il n'est plus coché, pour ne jamais rendre un
  // groupe existant introuvable via le filtre.
  List<Level> get _availableLevels {
    final taught = AppRepository.taughtLevels;
    final base = taught.isEmpty ? Level.values.toSet() : taught;
    final allowed = {...base, ...AppRepository.groups.map((g) => g.level)};
    return Level.values.where(allowed.contains).toList();
  }

  List<Section> get _availableSections {
    final taught = AppRepository.taughtSections;
    final base = taught.isEmpty ? Section.values.toSet() : taught;
    final allowed = {
      ...base,
      ...AppRepository.groups.map((g) => g.section).whereType<Section>(),
    };
    return Section.values.where(allowed.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = AppRepository.groups.where((group) {
      if (_levelFilter != null && group.level != _levelFilter) return false;
      if (_sectionFilter != null && group.section != _sectionFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Groupes')),
      floatingActionButton: GlowingFab(
        onPressed: () async {
          final created = await showGroupFormSheet(context);
          if (created != null) setState(() {});
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterDropdown<Level?>(
                    value: _levelFilter,
                    itemLabel: (level) => level?.label ?? 'Tous',
                    items: [null, ..._availableLevels],
                    onChanged: (level) => setState(() {
                      _levelFilter = level;
                      if (_levelFilter?.hasSection != true) _sectionFilter = null;
                    }),
                  ),
                  if (_levelFilter?.hasSection ?? false) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _FilterDropdown<Section?>(
                      value: _sectionFilter,
                      itemLabel: (section) => section?.label ?? 'Toutes sections',
                      items: [null, ..._availableSections],
                      onChanged: (section) => setState(() => _sectionFilter = section),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: groups.isEmpty
                ? _EmptyState(filtered: _levelFilter != null || _sectionFilter != null)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      120,
                    ),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final students = AppRepository.studentsForGroup(group.id);
                      final dueCount = students
                          .where((s) => AppRepository.balanceFor(s.id).isDue)
                          .length;
                      return GroupCard(
                        group: group,
                        studentCount: students.length,
                        dueCount: dueCount,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(group: group),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Pilule verte accent — PopupMenuButton plutôt que DropdownButton :
/// DropdownButton positionne son menu pour aligner l'item SÉLECTIONNÉ
/// sur le bouton (comme un <select> natif), donc le menu semblait
/// s'ouvrir au-dessus dès que la sélection n'était pas "Tous" ;
/// PopupMenuButton ouvre toujours son menu juste sous le bouton.
///
/// Le menu est indexé par position (PopupMenuButton<int>), jamais par
/// la valeur T elle-même : PopupMenuButton ne distingue pas en interne
/// "item de valeur null sélectionné" de "menu fermé sans choix" (les
/// deux remontent `null` via Navigator.pop), donc "Tous" — dont la
/// valeur T est justement null — ne déclenchait jamais onSelected tant
/// que l'index n'était pas utilisé comme valeur porteuse à la place.
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (index) => onChanged(items[index]),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem(value: i, child: Text(itemLabel(items[i]))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemLabel(value),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 48, color: AppColors.inkFaint),
            const SizedBox(height: AppSpacing.md),
            Text(
              filtered ? 'Aucun groupe pour ce niveau' : 'Aucun groupe pour le moment',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (!filtered) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Crée ton premier groupe avec le bouton +',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
