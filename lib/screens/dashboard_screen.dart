import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/balance_pill.dart';
import '../widgets/group_picker.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';
import '../widgets/suspended_pill.dart';
import 'add_student_sheet.dart';
import 'group_detail_screen.dart';
import 'group_form_sheet.dart';
import 'settings_screen.dart';
import 'student_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Future<void> _quickCreate() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Nouveau groupe'),
              onTap: () => Navigator.of(context).pop('group'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: const Text('Nouvel élève'),
              onTap: () => Navigator.of(context).pop('student'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case 'group':
        final created = await showGroupFormSheet(context);
        if (created != null) setState(() {});
      case 'student':
        final group = await pickGroup(context, title: 'Ajouter à quel groupe ?');
        if (group == null || !mounted) return;
        final added = await showAddStudentSheet(context, groupId: group.id);
        if (added == true) setState(() {});
    }
  }

  Widget _upcomingTile(BuildContext context, Group group, DateTime now, TextTheme textTheme) {
    final occurrence = nextOccurrence(group.weekday, group.startTime);
    // La séance d'aujourd'hui se distingue par l'accent — c'est celle
    // qui compte pour la journée en cours, le reste de la semaine
    // reste neutre.
    final today = isSameDay(occurrence, now);
    return ListTile(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        );
        if (mounted) setState(() {});
      },
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: today ? AppColors.accent : AppColors.ink.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.ink),
      ),
      title: Text(group.displayName),
      subtitle: Text(
        '${dayLabel(occurrence)} · ${formatTimeOfDay(group.startTime)}',
        style: today
            ? textTheme.bodySmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)
            : null,
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkFaint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final watchlist = MockData.studentsWithDuePayments();

    final upcoming = [...MockData.groups]
      ..sort((a, b) => nextOccurrence(a.weekday, a.startTime)
          .compareTo(nextOccurrence(b.weekday, b.startTime)));

    final now = DateTime.now();
    final isEmpty = watchlist.isEmpty && upcoming.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (mounted) setState(() {});
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
          ),
        ],
      ),
      floatingActionButton: GlowingFab(onPressed: _quickCreate),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          120,
        ),
        children: [
          _StatsOverview(
            groupCount: MockData.groups.length,
            unpaidStudentCount: watchlist.length,
            sessionsThisWeek: MockData.sessionsThisWeekCount(),
          ),
          if (isEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const _AllCaughtUp(),
          ],
          if (watchlist.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(icon: Icons.payments_outlined, title: 'À relancer'),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              child: Column(
                children: [
                  for (var i = 0; i < watchlist.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                    // Rangée maison plutôt que ListTile : ListTile fixe la
                    // hauteur de la tuile d'après title/subtitle et centre
                    // trailing dedans, donc un trailing sur deux lignes
                    // (solde + "Suspendu" empilés) déborde silencieusement
                    // au lieu de s'afficher sous la pilule de solde.
                    //
                    // Suspendu assourdi (opacité) plutôt que masqué — même
                    // traitement que StudentRow (écran Groupe) : la dette
                    // due reste visible, juste démotée visuellement.
                    Opacity(
                      opacity: watchlist[i].student.isSuspended ? 0.55 : 1,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailScreen(studentId: watchlist[i].student.id),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
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
                                    Text(watchlist[i].student.name, style: textTheme.titleMedium),
                                    Text(
                                      watchlist[i].groups.map((g) => g.displayName).join(' + '),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  BalancePill(balance: watchlist[i].balance),
                                  if (watchlist[i].student.isSuspended) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    const SuspendedPill(),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(icon: Icons.event_outlined, title: 'Cette semaine'),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              child: Column(
                children: [
                  for (var i = 0; i < upcoming.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 72, endIndent: AppSpacing.md),
                    _upcomingTile(context, upcoming[i], now, textTheme),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aperçu à l'ouverture — pas l'argent en premier : la charge de
/// travail (groupes, relances, séances cette semaine) reste aussi
/// visible que l'argent, pas noyée dessous. Trois cartes séparées et
/// alignées sur leur base plutôt qu'un seul bloc : "impayés", la carte
/// du milieu — la plus actionnable —, est plus haute que les deux
/// autres et porte le vert de marque en dégradé ; les cartes encre de
/// part et d'autre restent neutres, mêmes fondations.
class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.groupCount,
    required this.unpaidStudentCount,
    required this.sessionsThisWeek,
  });

  final int groupCount;
  final int unpaidStudentCount;
  final int sessionsThisWeek;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_outlined,
            value: '$groupCount',
            label: groupCount == 1 ? 'Groupe' : 'Groupes',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Au milieu — la carte la plus haute, donc la seule avec assez de
        // place pour un libellé sur deux mots sans que ça tasse.
        Expanded(
          child: _StatCard(
            icon: Icons.event_outlined,
            value: '$sessionsThisWeek',
            label: sessionsThisWeek == 1
                ? 'Séance cette semaine'
                : 'Séances cette semaine',
            hero: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.payments_outlined,
            value: '$unpaidStudentCount',
            label: unpaidStudentCount == 1 ? 'Impayé' : 'Impayés',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.hero = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Même règle qu'ailleurs dans l'app : jamais de blanc ni de noir
    // mélangés au vert de marque, seulement teinte/luminosité — d'où
    // ce dégradé resserré plutôt qu'un simple accent -> blanc.
    const highlight = HSLColor.fromAHSL(1, 104, 0.55, 0.78);
    const deep = HSLColor.fromAHSL(1, 140, 0.5, 0.55);
    final chipColor = hero ? AppColors.ink : Colors.white;
    final textColor = hero ? AppColors.ink : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: hero ? AppSpacing.lg : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: hero ? null : AppColors.ink,
        gradient: hero
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [highlight.toColor(), AppColors.accent, deep.toColor()],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: hero ? AppShadows.glow(AppColors.accent) : AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: hero ? 40 : 32,
            height: hero ? 40 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: hero ? 20 : 16, color: textColor),
          ),
          SizedBox(height: hero ? 10 : 8),
          Text(
            value,
            style: (hero
                    ? textTheme.displayLarge?.copyWith(fontSize: 34)
                    : textTheme.headlineMedium)
                ?.copyWith(color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

/// Rien à relancer et aucune séance cette semaine — plutôt qu'un grand
/// vide sous la carte de stats, un petit état positif : la charge du
/// jour est vraiment nulle, pas juste "pas encore chargé".
class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tout est calme', style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Aucune relance en attente, aucune séance cette semaine.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
