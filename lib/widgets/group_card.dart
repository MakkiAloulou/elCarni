import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.studentCount,
    required this.dueCount,
    required this.onTap,
  });

  final Group group;
  final int studentCount;
  final int dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
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
                  child: const Icon(Icons.menu_book_outlined,
                      size: 20, color: AppColors.ink),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.displayName, style: textTheme.titleLarge),
                      if (group.note != null)
                        Text(group.note!, style: textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${weekdayNames[group.weekday]} · ${formatTimeOfDay(group.startTime)} · '
                        '${group.durationMinutes} min',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.people_outline,
                              size: 16, color: AppColors.inkMuted),
                          const SizedBox(width: 4),
                          Text(
                            studentCount == 1 ? '1 élève' : '$studentCount élèves',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (dueCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppStatus.due.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '$dueCount dû${dueCount > 1 ? 's' : ''}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppStatus.due,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
