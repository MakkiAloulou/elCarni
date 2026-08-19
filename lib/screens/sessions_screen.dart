import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/group_picker.dart';
import 'attendance_screen.dart';
import 'schedule_session_sheet.dart';

/// File d'attente des séances programmées, tous groupes confondus —
/// le prof programme depuis une fiche de groupe (ou ici même), puis
/// vient ici faire l'appel quand la séance a lieu.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  Future<void> _quickSchedule() async {
    final group = await pickGroup(context, title: 'Programmer pour quel groupe ?');
    if (group == null || !mounted) return;
    final scheduled = await showScheduleSessionSheet(context, group: group);
    if (scheduled != null) setState(() {});
  }

  Future<void> _open(Session session) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AttendanceScreen(session: session)),
    );
    if (saved == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheduled = MockData.scheduledSessions();

    // Déjà trié chronologiquement par scheduledSessions() : les séances
    // du même jour se retrouvent forcément consécutives, il suffit de
    // les regrouper au passage plutôt que de re-trier.
    final days = <DateTime>[];
    final byDay = <DateTime, List<Session>>{};
    for (final session in scheduled) {
      final day = DateTime(session.date.year, session.date.month, session.date.day);
      if (!byDay.containsKey(day)) {
        days.add(day);
        byDay[day] = [];
      }
      byDay[day]!.add(session);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Séances')),
      floatingActionButton: GlowingFab(onPressed: _quickSchedule),
      body: scheduled.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_note_outlined, size: 48, color: AppColors.inkFaint),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucune séance programmée',
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Programme-en une depuis un groupe, ou avec le bouton +.',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120),
              children: [
                for (var d = 0; d < days.length; d++) ...[
                  if (d > 0) const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(dayLabel(days[d]), style: textTheme.titleMedium),
                  ),
                  for (var i = 0; i < byDay[days[d]]!.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _ScheduledSessionCard(
                      session: byDay[days[d]]![i],
                      onTap: () => _open(byDay[days[d]]![i]),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

class _ScheduledSessionCard extends StatelessWidget {
  const _ScheduledSessionCard({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final group = MockData.groupById(session.groupId);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.event_available_outlined, size: 20, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group?.displayName ?? 'Groupe supprimé',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.startTime == null
                          ? 'Heure non précisée'
                          : formatTimeOfDay(session.startTime!),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
