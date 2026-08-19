import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Un élève est toujours créé DANS un groupe, et son niveau réel doit
/// forcément correspondre à celui de ce groupe — un 3ème ne rejoint
/// pas un groupe de Bac. Le niveau n'est donc pas un choix ici, juste
/// verrouillé sur celui du groupe (voir [Student.classLevel]). Retourne
/// true si l'élève a été créé et ajouté au groupe.
Future<bool?> showAddStudentSheet(BuildContext context, {required String groupId}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddStudentSheet(groupId: groupId),
  );
}

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet({required this.groupId});

  final String groupId;

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  late final Group _group = MockData.groupById(widget.groupId)!;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _classNumberController = TextEditingController();
  final _schoolController = TextEditingController();
  Section? _classSection;
  var _isFree = false;

  @override
  void initState() {
    super.initState();
    if (_group.level.hasSection) _classSection = Section.values.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _classNumberController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _createAndEnroll() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final classNumberText = _classNumberController.text.trim();
    final school = _schoolController.text.trim();
    final student = MockData.createStudent(
      name: name,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      parentPhone:
          _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
      classLevel: _group.level,
      classSection: _group.level.hasSection ? _classSection : null,
      classNumber: classNumberText.isEmpty ? null : int.tryParse(classNumberText),
      school: school.isEmpty ? null : school,
      isFree: _isFree,
    );
    MockData.enrollStudent(student.id, widget.groupId);
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
                Text('Ajouter un élève', style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(_group.displayName, style: textTheme.bodySmall),
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
                // La section reste un choix libre (un élève de section
                // Maths peut suivre un groupe Technique), mais le niveau
                // ci-dessus est fixé sur celui du groupe — jamais les
                // deux à la fois libres.
                if (_group.level.hasSection) ...[
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
                  onPressed: _createAndEnroll,
                  child: const Text('Ajouter au groupe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
