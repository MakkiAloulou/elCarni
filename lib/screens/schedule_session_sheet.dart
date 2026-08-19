import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';

/// Programme une séance — date et heure seulement, aucune présence.
/// La prise de présence est une étape séparée, plus tard, depuis la
/// page Séances ou la fiche du groupe (voir AttendanceScreen).
Future<Session?> showScheduleSessionSheet(BuildContext context, {required Group group}) {
  return showModalBottomSheet<Session>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ScheduleSessionSheet(group: group),
  );
}

/// Modifie la date/l'heure d'une séance déjà programmée — même feuille,
/// pré-remplie, mais qui met à jour au lieu d'en créer une nouvelle.
Future<Session?> showEditSessionSheet(
  BuildContext context, {
  required Group group,
  required Session session,
}) {
  return showModalBottomSheet<Session>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ScheduleSessionSheet(group: group, session: session),
  );
}

class _ScheduleSessionSheet extends StatefulWidget {
  const _ScheduleSessionSheet({required this.group, this.session});

  final Group group;
  final Session? session;

  @override
  State<_ScheduleSessionSheet> createState() => _ScheduleSessionSheetState();
}

class _ScheduleSessionSheetState extends State<_ScheduleSessionSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  var _isRescheduled = false;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    if (session != null) {
      _date = session.date;
      _time = session.startTime ?? widget.group.startTime;
      _isRescheduled = session.isRescheduled;
      return;
    }
    final sessions = MockData.sessionsForGroup(widget.group.id);
    final lastDate = sessions.isEmpty ? null : sessions.first.date;
    _date = nextOccurrence(widget.group.weekday, widget.group.startTime, after: lastDate);
    _time = widget.group.startTime;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _isRescheduled = true;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
      _isRescheduled = true;
    });
  }

  void _confirm() {
    final session = widget.session;
    final result = session == null
        ? MockData.createSession(
            groupId: widget.group.id,
            date: _date,
            startTime: _time,
            isRescheduled: _isRescheduled,
            price: widget.group.pricePerSession,
            status: SessionStatus.scheduled,
          )
        : MockData.updateSession(
            session.id,
            date: _date,
            startTime: _time,
            isRescheduled: _isRescheduled,
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Modifier la séance' : 'Programmer une séance',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.group.displayName, style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(formatShortDate(_date)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 16),
                    label: Text(formatTimeOfDay(_time)),
                  ),
                ),
              ],
            ),
            if (_isRescheduled) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Séance déplacée exceptionnellement — le créneau du groupe ne change pas.',
                style: textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _confirm,
              child: Text(_isEditing ? 'Enregistrer' : 'Programmer'),
            ),
          ],
        ),
      ),
    );
  }
}
