import 'package:flutter/material.dart';

import '../data/app_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Avertit des séances impayées qui suivront l'élève avant de
/// confirmer — le cycle est global à l'élève, pas au couple
/// élève/groupe (README §9.4).
Future<bool?> showMoveStudentSheet(
  BuildContext context, {
  required Student student,
  required String fromGroupId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MoveStudentSheet(student: student, fromGroupId: fromGroupId),
  );
}

class _MoveStudentSheet extends StatefulWidget {
  const _MoveStudentSheet({required this.student, required this.fromGroupId});

  final Student student;
  final String fromGroupId;

  @override
  State<_MoveStudentSheet> createState() => _MoveStudentSheetState();
}

class _MoveStudentSheetState extends State<_MoveStudentSheet> {
  Group? _target;

  Future<void> _confirm(String targetGroupId) async {
    await AppRepository.moveStudent(widget.student.id, widget.fromGroupId, targetGroupId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentGroup = AppRepository.groupById(widget.fromGroupId);
    // Un déplacement reste dans le même niveau — passer de Bac à 3ème
    // n'a pas de sens pédagogique, même si le solde suivrait techniquement.
    final candidates = AppRepository.groups
        .where((g) => g.id != widget.fromGroupId && g.level == currentGroup?.level)
        .toList();
    final unpaid = AppRepository.balanceFor(widget.student.id).unpaidSessions;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Déplacer ${widget.student.name}', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (candidates.isEmpty)
              Text(
                'Aucun autre groupe de niveau ${currentGroup?.level.label ?? ''} disponible.',
                style: textTheme.bodySmall,
              )
            else
              Column(
                children: [
                  for (final group in candidates)
                    RadioListTile<Group>(
                      contentPadding: EdgeInsets.zero,
                      value: group,
                      groupValue: _target,
                      onChanged: (g) => setState(() => _target = g),
                      title: Text(group.displayName),
                    ),
                ],
              ),
            if (_target != null && unpaid > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppStatus.dueSoon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(
                  '$unpaid séance${unpaid > 1 ? 's' : ''} impayée${unpaid > 1 ? 's' : ''} '
                  'suivront ${widget.student.name} dans le nouveau groupe.',
                  style: textTheme.bodySmall?.copyWith(color: AppStatus.dueSoon),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _target == null ? null : () => _confirm(_target!.id),
              child: const Text('Confirmer le déplacement'),
            ),
          ],
        ),
      ),
    );
  }
}
