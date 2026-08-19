import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pilule "Suspendu" — même langage visuel que [BalancePill] (pastille +
/// libellé), pour porter le statut sans dépendre d'un avatar en tête de
/// ligne.
class SuspendedPill extends StatelessWidget {
  const SuspendedPill({super.key});

  @override
  Widget build(BuildContext context) {
    const color = AppStatus.dueSoon;
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
            decoration: const BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Suspendu',
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
