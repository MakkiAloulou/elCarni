import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/initial_avatar.dart';
import '../widgets/section_card.dart';
import 'schedule_session_sheet.dart';

/// Prise (ou correction) de présence pour une séance qui existe déjà —
/// programmée pas encore tenue, ou déjà tenue et à corriger. La
/// contrainte unique `(session_id, student_id)` rend l'upsert
/// idempotent dans les deux cas (README §9.2). Enregistrer les
/// présences d'une séance programmée la fait passer à "done"
/// (voir MockData.markSessionDone).
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.session});

  final Session session;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Session _session = widget.session;
  late final Group _group = MockData.groupById(_session.groupId)!;
  late final List<Student> _students = MockData.studentsForGroup(_group.id);
  late final Map<String, AttendanceStatus> _attendance =
      MockData.attendanceForSession(_session.id);

  bool get _wasScheduled => _session.status == SessionStatus.scheduled;

  @override
  void initState() {
    super.initState();
    // Absent justifié par défaut, pas présent : un oubli du prof ne doit
    // jamais facturer un élève qui n'était pas là — il faut marquer
    // "présent" explicitement pour que la séance devienne facturable.
    for (final s in _students) {
      _attendance.putIfAbsent(s.id, () => AttendanceStatus.absentJustified);
    }
  }

  void _save() {
    for (final entry in _attendance.entries) {
      MockData.setAttendance(_session.id, entry.key, entry.value);
    }
    if (_wasScheduled) {
      MockData.markSessionDone(_session.id);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _editSession() async {
    final updated = await showEditSessionSheet(context, group: _group, session: _session);
    if (updated != null) setState(() => _session = updated);
  }

  Future<void> _cancelSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler cette séance ?'),
        content: const Text('La séance sera supprimée. Aucune présence ne sera prise.'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      MockData.cancelSession(_session.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_wasScheduled ? 'Faire l\'appel' : 'Modifier les présences'),
        // Modifier/Annuler n'ont de sens qu'avant que la séance soit
        // tenue — une fois "done", la date/les présences/la facturation
        // sont déjà actées.
        actions: [
          if (_wasScheduled) ...[
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: IconButton(
                onPressed: _editSession,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                onPressed: _cancelSession,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 140),
        children: [
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_group.displayName, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${formatShortDate(_session.date)}'
                        '${_session.startTime == null ? '' : ' · ${formatTimeOfDay(_session.startTime!)}'}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_session.isRescheduled)
                  const Icon(Icons.schedule, size: 16, color: AppColors.inkFaint),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Présences', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (_students.isEmpty)
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Aucun élève actif dans ce groupe.',
                style: textTheme.bodySmall,
              ),
            )
          else
            SectionCard(
              child: Column(
                children: [
                  for (var i = 0; i < _students.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 64, endIndent: AppSpacing.md),
                    _AttendanceRow(
                      student: _students[i],
                      status: _attendance[_students[i].id]!,
                      onChanged: (status) =>
                          setState(() => _attendance[_students[i].id] = status),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton(
          onPressed: _students.isEmpty ? null : _save,
          child: const Text('Enregistrer les présences'),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.onChanged,
  });

  final Student student;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          InitialAvatar(name: student.name, size: 36),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(student.name, style: textTheme.titleMedium)),
          _StatusButton(
            icon: Icons.check,
            color: AppStatus.present,
            selected: status == AttendanceStatus.present,
            tooltip: 'Présent',
            onTap: () => onChanged(AttendanceStatus.present),
          ),
          _StatusButton(
            icon: Icons.info_outline,
            color: AppStatus.excused,
            selected: status == AttendanceStatus.absentJustified,
            tooltip: 'Absent justifié',
            onTap: () => onChanged(AttendanceStatus.absentJustified),
          ),
          _StatusButton(
            icon: Icons.close,
            color: AppStatus.unexcused,
            selected: status == AttendanceStatus.absentUnjustified,
            tooltip: 'Absent non justifié',
            onTap: () => onChanged(AttendanceStatus.absentUnjustified),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.icon,
    required this.color,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.14) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: selected ? color : AppColors.inkFaint),
        ),
      ),
    );
  }
}
