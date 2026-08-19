import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bloc blanc à ombre portée — le vocabulaire de "carte" commun aux
/// trois écrans. Remplace les `Container` plats de la première passe :
/// c'est l'ombre, pas seulement le contraste de fond, qui sépare le
/// contenu du canvas gris.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}
