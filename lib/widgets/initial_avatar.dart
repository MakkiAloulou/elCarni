import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar rond à initiale — remplace le disque gris quasi invisible
/// de la première passe (fond = canvas, aucun contraste réel).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink.withOpacity(0.07),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: 'TASAExplorer',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
