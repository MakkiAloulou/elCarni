import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Modifie les infos d'un élève existant — nom, téléphones, classe
/// réelle, statut gratuit. Le niveau reste verrouillé sur celui du
/// groupe où l'élève est actuellement inscrit, comme à la création
/// (voir add_student_sheet.dart) : éditer sa fiche ne peut pas faire
/// d'un 3ème un élève de Bac. Retourne true si modifié.
Future<bool?> showEditStudentSheet(BuildContext context, {required Student student}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditStudentSheet(student: student),
  );
}

class _EditStudentSheet extends StatefulWidget {
  const _EditStudentSheet({required this.student});

  final Student student;

  @override
  State<_EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends State<_EditStudentSheet> {
  late final Group? _group = MockData.groupsForStudent(widget.student.id).firstOrNull;
  late final Level? _level = _group?.level ?? widget.student.classLevel;

  late final _nameController = TextEditingController(text: widget.student.name);
  late final _phoneController = TextEditingController(text: widget.student.phone ?? '');
  late final _parentPhoneController =
      TextEditingController(text: widget.student.parentPhone ?? '');
  late final _classNumberController =
      TextEditingController(text: widget.student.classNumber?.toString() ?? '');
  late final _schoolController = TextEditingController(text: widget.student.school ?? '');
  late Section? _classSection = widget.student.classSection;
  late var _isFree = widget.student.isFree;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _classNumberController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final phone = _phoneController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();
    final classNumberText = _classNumberController.text.trim();
    final school = _schoolController.text.trim();

    final updated = widget.student.copyWith(
      name: name,
      phone: phone.isEmpty ? null : phone,
      clearPhone: phone.isEmpty,
      parentPhone: parentPhone.isEmpty ? null : parentPhone,
      clearParentPhone: parentPhone.isEmpty,
      classLevel: _level,
      clearClassLevel: _level == null,
      classSection: _level?.hasSection == true ? _classSection : null,
      clearClassSection: _level?.hasSection != true,
      classNumber: classNumberText.isEmpty ? null : int.tryParse(classNumberText),
      clearClassNumber: classNumberText.isEmpty,
      school: school.isEmpty ? null : school,
      clearSchool: school.isEmpty,
      isFree: _isFree,
    );
    MockData.updateStudent(updated);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modifier l\'élève', style: textTheme.titleLarge),
                if (_group != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_group.displayName, style: textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Nom complet'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Téléphone (optionnel)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _parentPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'Téléphone parent (optionnel)'),
                ),
                const SizedBox(height: AppSpacing.md),
                // Niveau verrouillé sur celui du groupe actuel — voir
                // add_student_sheet.dart, même règle à la création.
                if (_level?.hasSection == true) ...[
                  Text('Section', style: textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final section in Section.values)
                        ChoiceChip(
                          label: Text(section.label),
                          selected: _classSection == section,
                          onSelected: (_) => setState(() => _classSection = section),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextField(
                  controller: _classNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Numéro de classe (optionnel)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _schoolController,
                  decoration: const InputDecoration(hintText: 'Lycée (optionnel)'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v),
                  title: const Text('Élève gratuit'),
                  subtitle: const Text('Dispensé de paiement'),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
