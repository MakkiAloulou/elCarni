import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'groups_screen.dart';
import 'sessions_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  // Accueil est au milieu de la barre (index 1) mais reste l'onglet
  // d'ouverture par défaut de l'app.
  var _index = 1;

  // Volontairement PAS const : IndexedStack ne rebuild un enfant que si
  // son identité de widget change. Avec des instances const partagées,
  // changer d'onglet ne relit jamais MockData — un ajout fait depuis un
  // autre onglet (ex. programmer une séance depuis le tableau de bord)
  // restait invisible dans l'onglet Séances tant qu'on ne le quittait
  // pas et n'y revenait pas autrement. Des instances fraîches à chaque
  // build forcent Flutter à rebuild tous les onglets à chaque switch.
  // Accueil au milieu — c'est l'onglet le plus utilisé, le pouce y
  // accède le plus naturellement au centre de la barre.
  List<Widget> get _screens => [
        // ignore: prefer_const_constructors
        GroupsScreen(),
        // ignore: prefer_const_constructors
        DashboardScreen(),
        // ignore: prefer_const_constructors
        SessionsScreen(),
      ];

  static const _items = [
    (icon: Icons.groups, label: 'Groupes'),
    (icon: Icons.home_filled, label: 'Accueil'),
    (icon: Icons.event_note, label: 'Séances'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      // FloatingNavBar centers itself within whatever height Scaffold hands
      // it (Center has no intrinsic size), and bottomNavigationBar gets
      // loose 0..screenHeight constraints — so it must be pinned to a fixed
      // height here, or it centers in the whole screen instead of the
      // bottom band.
      bottomNavigationBar: SizedBox(
        height: 68 + AppSpacing.md,
        child: FloatingNavBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: _items,
        ),
      ),
    );
  }
}
