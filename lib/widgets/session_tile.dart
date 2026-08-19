import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.onTap});

  final Session session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cancelled = session.status == SessionStatus.cancelled;
    final scheduled = session.status == SessionStatus.scheduled;
    final summary = MockData.summaryForSession(session.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(formatShortDate(session.date), style: textTheme.titleMedium),
                      if (session.isRescheduled) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.schedule, size: 14, color: AppColors.inkFaint),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (cancelled)
                    Text('Annulée', style: textTheme.bodySmall?.copyWith(color: AppStatus.due))
                  else if (scheduled)
                    Text(
                      'Programmée — appel à faire',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '${summary.present} présent(s) · '
                      '${summary.absentUnjustified} absent(s) non just. · '
                      '${summary.absentJustified} justifié(s)',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.inkFaint),
            ],
          ],
        ),
      ),
    );
  }
}
