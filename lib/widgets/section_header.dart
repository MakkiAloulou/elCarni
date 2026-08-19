import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// En-tête de section — badge d'icône teinté encre + titre. Le badge
/// reste neutre (encre à faible opacité) délibérément : l'accent est
/// réservé aux actions, pas à la décoration (voir AppStatus).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: textTheme.titleLarge),
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}
