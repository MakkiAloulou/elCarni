import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tokens dérivés du branding TASA Explorer.
/// Quatre couleurs de marque, aucune autre. Les couleurs sémantiques
/// (présence, paiement) sont volontairement séparées : voir [AppStatus].
abstract final class AppColors {
  // Marque
  static const surface = Color(0xFFFFFFFF); // cartes, feuilles
  static const canvas = Color(0xFFF4F4F4); // fond d'écran
  static const ink = Color(0xFF050505); // texte, nav flottante
  static const accent = Color(0xFF88E788); // sélection, action primaire

  // Dérivés (opacités de l'encre, pas de nouvelles teintes)
  static const inkMuted = Color(0xFF6E6E6E); // libellés secondaires
  static const inkFaint = Color(0xFFB0B0B0); // placeholders, désactivé
  static const hairline = Color(0xFFE6E6E6); // séparateurs
}

/// Couleurs sémantiques — jamais l'orange de marque.
///
/// L'accent est déjà saturé d'usage : filtre actif, onglet courant,
/// bouton primaire. S'en servir aussi pour « paiement dû » rendrait
/// l'alerte invisible dans un écran qui en contient déjà cinq.
abstract final class AppStatus {
  static const present = Color(0xFF1B9C5A); // présent
  static const excused = Color(0xFF6E6E6E); // absence justifiée, non facturée
  static const unexcused = Color(0xFFD93A3A); // absence non justifiée, facturée

  static const paid = Color(0xFF1B9C5A);
  static const due = Color(0xFFD93A3A);
  static const dueSoon = Color(0xFFE08A00); // 3 séances sur 4
}

abstract final class AppRadius {
  static const card = 20.0;
  static const chip = 999.0; // pilule
  static const sheet = 28.0;
  static const nav = 999.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

/// Ombres portées — jamais `Card`'s elevation (tonal, verdâtre en
/// Material 3). Deux calques : un flou large et doux pour le "lift",
/// un flou serré pour ancrer le bord au sol. C'est ce qui donne du
/// poids aux cartes sur un fond gris uni, sans dessiner de bordure.
abstract final class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.ink.withOpacity(0.05),
          blurRadius: 28,
          offset: const Offset(0, 14),
          spreadRadius: -12,
        ),
        BoxShadow(
          color: AppColors.ink.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: -1,
        ),
      ];

  /// Halo coloré sous un élément posé sur l'accent (FAB, bouton primaire).
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.32),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -8,
        ),
      ];

  /// La nav flottante doit se détacher franchement du contenu qu'elle
  /// survole : ombre plus sombre et plus large que celle des cartes.
  static List<BoxShadow> get nav => [
        BoxShadow(
          color: AppColors.ink.withOpacity(0.25),
          blurRadius: 30,
          offset: const Offset(0, 14),
          spreadRadius: -10,
        ),
      ];
}

/// Le vrai TASAExplorer n'est pas sur Google Fonts : remplace les .ttf
/// dans assets/fonts/ par les siens le moment venu, même nom de
/// famille, aucun autre changement requis. Poppins (OFL) tient lieu de
/// gabarit en attendant.
const _display = 'TASAExplorer';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.accent,
    onPrimary: AppColors.ink,
    secondary: AppColors.ink,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppStatus.due,
    outlineVariant: AppColors.hairline,
  );

  final text = const TextTheme(
    // Chiffres de tableau de bord : gros, serrés, sans libellé redondant
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.0,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.inkMuted,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.inkMuted,
    ),
  ).apply(fontFamily: _display);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: _display,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: _display,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
    ),

    // Cartes blanches sur fond gris, ombre quasi nulle : la séparation
    // vient du contraste de fond, pas d'une élévation.
    cardTheme: CardTheme(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    // Filtres Aujourd'hui / Semaine / Mois — pilule pleine quand actif
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent,
      side: BorderSide.none,
      showCheckmark: false,
      labelStyle: const TextStyle(
        fontFamily: _display,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      // L'accent est un vert clair : texte encre dessus, jamais blanc.
      secondaryLabelStyle: const TextStyle(
        fontFamily: _display,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: const StadiumBorder(),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: _display,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    ),

    // Sans ceci, TextButton retombe sur colorScheme.primary (l'accent)
    // par défaut — illisible en texte sur fond blanc pour un vert
    // aussi clair. Encre partout où l'accent sert de libellé, pas de
    // fond : "+ Séance", "+ Ajouter", etc.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(
          fontFamily: _display,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Élévation à 0 : le glow coloré sous le FAB est peint à la main
    // (voir GlowingFab dans ce fichier) pour rester teinté plutôt que
    // gris, l'ombre Material par défaut n'acceptant pas de teinte ici.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      shape: CircleBorder(),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(
        fontFamily: _display,
        color: AppColors.inkFaint,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
  );
}

/// Barre de navigation flottante noire, onglet actif en pilule vert clair.
/// Reprend le motif du branding : capsule sombre détachée du fond,
/// posée au-dessus du contenu plutôt qu'ancrée au bord.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.nav),
            boxShadow: AppShadows.nav,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                Semantics(
                  label: items[i].label,
                  selected: i == currentIndex,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == currentIndex
                            ? AppColors.accent
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        items[i].icon,
                        // Cercle actif = vert clair : icône encre. Le
                        // reste de la capsule est noir : icône blanche.
                        color: i == currentIndex ? AppColors.ink : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAB avec halo coloré peint à la main — l'ombre Material par défaut
/// est toujours grise, ce qui aplatit un bouton d'accent sur un fond
/// clair. Le glow coloré est ce qui donne le "posé, pas collé".
class GlowingFab extends StatelessWidget {
  const GlowingFab({super.key, required this.onPressed, this.icon = Icons.add});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.glow(AppColors.accent),
      ),
      child: FloatingActionButton(
        // IndexedStack keeps every tab's Scaffold mounted at once (to
        // preserve state), so their FABs coexist in the tree — without
        // this, Flutter's implicit per-FAB Hero collides on the shared
        // default tag ("multiple heroes … same tag").
        heroTag: null,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
