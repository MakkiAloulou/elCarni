import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'balance_pill.dart';
import 'suspended_pill.dart';

class StudentRow extends StatelessWidget {
  const StudentRow({
    super.key,
    required this.student,
    required this.balance,
    this.onTap,
    this.onMenuTap,
  });

  final Student student;
  final StudentBalance? balance;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suspended = student.isSuspended;
    // Rangée assourdie plutôt que masquée : un suspendu reste visible
    // (en bas de liste, voir AppRepository.studentsForGroup) mais démoté
    // visuellement. Le solde continue d'être affiché normalement —
    // suspendre n'efface pas une dette déjà due.
    return Opacity(
      opacity: suspended ? 0.55 : 1,
      child: InkWell(
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
                    Text(student.name, style: textTheme.titleMedium),
                    if (student.phone != null)
                      Text(student.phone!, style: textTheme.bodySmall),
                  ],
                ),
              ),
              // "Suspendu" passe sous la pilule de solde plutôt qu'à côté
              // — même traitement que la liste "À relancer" du dashboard.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (balance != null) BalancePill(balance: balance!),
                  if (suspended) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const SuspendedPill(),
                  ],
                ],
              ),
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
