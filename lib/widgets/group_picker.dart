import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Demande de choisir un groupe — direct s'il n'y en a qu'un, sinon
/// une feuille de sélection. Utilisé par toute action rapide qui a
/// besoin d'un groupe sans venir d'une fiche de groupe déjà ouverte.
Future<Group?> pickGroup(BuildContext context, {required String title}) async {
  if (MockData.groups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crée d\'abord un groupe')),
    );
    return null;
  }
  if (MockData.groups.length == 1) return MockData.groups.first;
  return showModalBottomSheet<Group>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          for (final group in MockData.groups)
            ListTile(
              title: Text(group.displayName),
              onTap: () => Navigator.of(context).pop(group),
            ),
        ],
      ),
    ),
  );
}
