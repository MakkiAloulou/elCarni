import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';
import '../widgets/session_tile.dart';
import '../widgets/student_row.dart';
import 'add_student_sheet.dart';
import 'attendance_screen.dart';
import 'group_form_sheet.dart';
import 'move_student_sheet.dart';
import 'schedule_session_sheet.dart';
import 'student_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late String _groupId = widget.group.id;

  Group get _group => MockData.groupById(_groupId)!;

  Future<void> _editGroup() async {
    final updated = await showGroupFormSheet(context, editing: _group);
    if (updated != null) setState(() => _groupId = updated.id);
  }

  Future<void> _addStudent() async {
    final added = await showAddStudentSheet(context, groupId: _groupId);
    if (added == true) setState(() {});
  }

  Future<void> _scheduleSession() async {
    final scheduled = await showScheduleSessionSheet(context, group: _group);
    if (scheduled != null) setState(() {});
  }

  Future<void> _openSession(Session session) async {
    if (session.status == SessionStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette séance est annulée.')),
      );
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AttendanceScreen(session: session)),
    );
    if (saved == true) setState(() {});
  }

  Future<void> _deleteGroup() async {
    final students = MockData.studentsForGroup(_groupId);
    if (students.isNotEmpty) {
      final plural = students.length > 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Il reste ${students.length} élève${plural ? 's' : ''} dans ce groupe — '
            '${plural ? 'déplacez-les ou supprimez-les' : 'déplacez-le ou supprimez-le'} '
            'd\'abord.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: Text('${_group.displayName} sera définitivement supprimé. Irréversible.'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      MockData.deleteGroup(_groupId);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _openStudent(Student student) async {
    // Rafraîchit toujours au retour, même sans résultat explicite : un
    // paiement encaissé sur la fiche élève ne "pop" pas avec true (seul
    // l'archivage le fait), mais doit quand même se refléter ici.
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: student.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _studentActions(Student student) async {
    // Suppression proposée seulement si l'élève est à jour — même règle
    // que deleteStudent, qui la refuserait de toute façon silencieusement.
    final canDelete = MockData.balanceFor(student.id).unpaidSessions == 0;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Déplacer vers un autre groupe'),
              onTap: () => Navigator.of(context).pop('move'),
            ),
            ListTile(
              leading: Icon(
                student.isSuspended ? Icons.play_circle_outline : Icons.pause_circle_outline,
              ),
              title: Text(student.isSuspended ? 'Réactiver' : 'Suspendre'),
              onTap: () => Navigator.of(context).pop(student.isSuspended ? 'reactivate' : 'suspend'),
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'move':
        final moved =
            await showMoveStudentSheet(context, student: student, fromGroupId: _groupId);
        if (moved == true) setState(() {});
      case 'suspend':
        MockData.suspendStudent(student.id);
        setState(() {});
      case 'reactivate':
        MockData.reactivateStudent(student.id);
        setState(() {});
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer cet élève ?'),
            content: Text('${student.name} sera définitivement supprimé. Irréversible.'),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          MockData.deleteStudent(student.id);
          if (mounted) setState(() {});
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final group = _group;
    final students = MockData.studentsForGroup(group.id);
    final sessions = MockData.sessionsForGroup(group.id);
    final lastSessionDate = sessions.isEmpty
        ? null
        : sessions.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final proposedNext = nextOccurrence(
      group.weekday,
      group.startTime,
      after: lastSessionDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(group.displayName),
            // Surnom libre du prof (Group.note) — purement décoratif,
            // jamais utilisé pour identifier le groupe ailleurs.
            if (group.note != null)
              Text(group.note!, style: textTheme.bodySmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: IconButton(
              onPressed: _editGroup,
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
              onPressed: _deleteGroup,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          120,
        ),
        children: [
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _InfoColumn(
                    label: 'Créneau',
                    value:
                        '${weekdayNames[group.weekday]} · ${formatTimeOfDay(group.startTime)}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _InfoColumn(
                    label: 'Tarif',
                    value: '${group.monthlyPrice.toStringAsFixed(0)} DT',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: _InfoColumn(
                    label: 'Effectif',
                    value: students.length == 1
                        ? '1 élève'
                        : '${students.length} élèves',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            icon: Icons.groups_outlined,
            title: 'Élèves',
            action: TextButton.icon(
              onPressed: _addStudent,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            child: students.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Aucun élève dans ce groupe pour le moment.',
                      style: textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < students.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                        StudentRow(
                          student: students[i],
                          balance: MockData.balanceFor(students[i].id),
                          onTap: () => _openStudent(students[i]),
                          onMenuTap: () => _studentActions(students[i]),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            icon: Icons.event_outlined,
            title: 'Séances',
            action: TextButton.icon(
              onPressed: _scheduleSession,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Séance'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prochaine proposée : ${formatShortDate(proposedNext)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            child: sessions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Aucune séance enregistrée pour ce groupe.',
                      style: textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < sessions.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                        SessionTile(
                          session: sessions[i],
                          onTap: () => _openSession(sessions[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
