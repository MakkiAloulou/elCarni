import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Pilule de solde — paid / due / gratuit. Ne réutilise jamais
/// l'accent : c'est une couleur sémantique, pas une action.
class BalancePill extends StatelessWidget {
  const BalancePill({super.key, required this.balance});

  final StudentBalance balance;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (balance.isFree) {
      color = AppColors.inkMuted;
      label = 'Gratuit';
    } else if (balance.isDue) {
      color = AppStatus.due;
      label = balance.unpaidSessions == 1
          ? '1 séance due'
          : '${balance.unpaidSessions} séances dues';
    } else {
      color = AppStatus.paid;
      label = 'À jour';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
