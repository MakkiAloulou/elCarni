import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';

/// Ouvre la feuille de création/modification de groupe. Retourne le
/// groupe créé/modifié, ou null si annulé.
Future<Group?> showGroupFormSheet(BuildContext context, {Group? editing}) {
  return showModalBottomSheet<Group>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GroupFormSheet(editing: editing),
  );
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({this.editing});

  final Group? editing;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Restreint aux niveaux/sections cochés dans Réglages (voir
  // AppRepository.taughtLevels/taughtSections) — mais en modification, le
  // niveau/section déjà en place du groupe reste proposé même s'il n'est
  // plus coché, pour ne pas le faire disparaître sous les pieds du prof.
  // Si rien n'est coché du tout, retombe sur la liste complète plutôt
  // que de bloquer la création de groupe.
  List<Level> get _availableLevels {
    final taught = AppRepository.taughtLevels;
    final base = taught.isEmpty ? Level.values.toSet() : taught;
    final allowed = {...base, if (widget.editing != null) widget.editing!.level};
    return Level.values.where(allowed.contains).toList();
  }

  List<Section> get _availableSections {
    final taught = AppRepository.taughtSections;
    final base = taught.isEmpty ? Section.values.toSet() : taught;
    final allowed = {...base, if (widget.editing?.section != null) widget.editing!.section!};
    return Section.values.where(allowed.contains).toList();
  }

  late Level _level = widget.editing?.level ?? _availableLevels.first;
  // Dès qu'un niveau à section existe (3ème/Bac), une section est
  // obligatoire — jamais laissée vide, voir _selectLevel.
  late Section? _section = widget.editing?.section ??
      (_level.hasSection ? _availableSections.first : null);
  late final _noteController =
      TextEditingController(text: widget.editing?.note ?? '');
  // Le prof raisonne en tarif mensuel (voir Group.monthlyPrice) — la
  // conversion vers le prix par séance interne se fait à la soumission.
  late final _priceController = TextEditingController(
    text: widget.editing == null
        ? ''
        : widget.editing!.monthlyPrice.toStringAsFixed(0),
  );
  late int _weekday = widget.editing?.weekday ?? 1;
  late TimeOfDay _startTime =
      widget.editing?.startTime ?? const TimeOfDay(hour: 17, minute: 0);
  late int _duration = widget.editing?.durationMinutes ?? 120;

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _selectLevel(Level level) {
    setState(() {
      _level = level;
      // La section n'a de sens qu'en 3ème/Bac (voir Level.hasSection),
      // mais dès que le niveau l'exige elle est obligatoire — jamais
      // laissée vide comme le prix ou le créneau.
      _section = level.hasSection ? (_section ?? _availableSections.first) : null;
    });
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final monthlyPrice =
        double.parse(_priceController.text.replaceAll(',', '.'));
    final pricePerSession = monthlyPrice / 4;
    final noteText = _noteController.text.trim();
    final note = noteText.isEmpty ? null : noteText;

    final Group result;
    if (widget.editing == null) {
      // Pas de numéro saisi à la main : createGroup l'attribue tout
      // seul si un autre groupe du même niveau/section existe déjà —
      // voir AppRepository.createGroup.
      result = await AppRepository.createGroup(
        level: _level,
        section: _section,
        note: note,
        pricePerSession: pricePerSession,
        weekday: _weekday,
        startTime: _startTime,
        durationMinutes: _duration,
      );
    } else {
      result = widget.editing!.copyWith(
        level: _level,
        section: _section,
        note: note,
        clearNote: note == null,
        pricePerSession: pricePerSession,
        weekday: _weekday,
        startTime: _startTime,
        durationMinutes: _duration,
      );
      await AppRepository.updateGroup(result);
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.editing != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Modifier le groupe' : 'Nouveau groupe',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Niveau', style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final level in _availableLevels)
                        ChoiceChip(
                          label: Text(level.label),
                          selected: _level == level,
                          onSelected: (_) => _selectLevel(level),
                        ),
                    ],
                  ),
                  // La section ne s'applique qu'en 3ème/Bac — voir
                  // Level.hasSection.
                  if (_level.hasSection) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Section', style: textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final section in _availableSections)
                          ChoiceChip(
                            label: Text(section.label),
                            selected: _section == section,
                            onSelected: (_) =>
                                setState(() => _section = section),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  // Un surnom libre, purement pour le prof — le numéro
                  // qui distingue deux groupes identiques (Group.groupNumber)
                  // est attribué tout seul, jamais saisi ici.
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Surnom du groupe (optionnel)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(hintText: 'Tarif mensuel (DT)'),
                    validator: (v) {
                      final value =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (value == null || value <= 0) {
                        return 'Montant invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Créneau', style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var d = 0; d < 7; d++)
                        ChoiceChip(
                          label: Text(weekdayNames[d].substring(0, 3)),
                          selected: _weekday == d,
                          onSelected: (_) => setState(() => _weekday = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule, size: 18),
                          label: Text(formatTimeOfDay(_startTime)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _duration,
                          decoration: const InputDecoration(hintText: 'Durée'),
                          items: const [60, 90, 120, 150, 180]
                              .map((m) => DropdownMenuItem(
                                  value: m, child: Text('$m min')))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _duration = v ?? _duration),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(isEditing ? 'Enregistrer' : 'Créer le groupe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
