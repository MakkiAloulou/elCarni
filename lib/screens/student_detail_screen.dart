import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/schedule.dart';
import '../widgets/balance_pill.dart';
import '../widgets/initial_avatar.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';
import 'edit_student_sheet.dart';
import 'record_payment_sheet.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Future<void> _recordPayment() async {
    final changed = await showRecordPaymentSheet(context, studentId: widget.studentId);
    if (changed == true) setState(() {});
  }

  Future<void> _editStudent() async {
    final student = AppRepository.studentById(widget.studentId)!;
    final changed = await showEditStudentSheet(context, student: student);
    if (changed == true) setState(() {});
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer l\'appel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final student = AppRepository.studentById(widget.studentId);
    if (student == null) {
      return const Scaffold(body: Center(child: Text('Élève introuvable')));
    }

    final groups = AppRepository.groupsForStudent(widget.studentId);
    final balance = AppRepository.balanceFor(widget.studentId);
    final history = AppRepository.attendanceHistoryFor(widget.studentId).reversed.toList();
    final payments = AppRepository.paymentsFor(widget.studentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              onPressed: _editStudent,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 140),
        children: [
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialAvatar(name: student.name, size: 48),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            groups.isEmpty
                                ? 'Aucun groupe actif'
                                : groups.map((g) => g.displayName).join(' · '),
                            style: textTheme.bodySmall,
                          ),
                          // Classe réelle au lycée — indépendante du groupe
                          // de soutien ci-dessus, voir Student.classLabel.
                          if (student.classLabel != null)
                            Text(student.classLabel!, style: textTheme.bodySmall),
                          if (student.isSuspended)
                            Text(
                              'Suspendu',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppStatus.dueSoon,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (student.phone != null || student.parentPhone != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (student.phone != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _call(student.phone!),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.ink,
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Élève'),
                          ),
                        ),
                      if (student.phone != null && student.parentPhone != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (student.parentPhone != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _call(student.parentPhone!),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.ink,
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Parent'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solde', style: textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${balance.amountDue.toStringAsFixed(0)} DT',
                        style: textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      BalancePill(balance: balance),
                    ],
                  ),
                ),
                FilledButton(
                  // Actif dès qu'une séance du cycle en cours reste
                  // impayée — pas besoin d'attendre qu'il soit terminé,
                  // voir unpaidCycles.
                  onPressed: balance.isDue ? _recordPayment : null,
                  // Le style par défaut du thème vise les boutons pleine
                  // largeur (minimumSize: Size.fromHeight — largeur
                  // infinie) : posé tel quel dans un Row sans Expanded,
                  // ça casse le layout de toute la liste parente en
                  // silence (aucune exception visible). Toujours borner
                  // explicitement un FilledButton compact comme celui-ci.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text('Encaisser'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(icon: Icons.receipt_long_outlined, title: 'Séances'),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            child: history.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Aucune séance pour le moment.', style: textTheme.bodySmall),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < history.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                        _AttendanceHistoryTile(entry: history[i]),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(icon: Icons.history, title: 'Paiements'),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            child: payments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Aucun paiement enregistré.', style: textTheme.bodySmall),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < payments.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                        ListTile(
                          leading: const Icon(Icons.payments_outlined, color: AppColors.inkMuted),
                          title: Text('${payments[i].amount.toStringAsFixed(0)} DT'),
                          subtitle: Text(
                            '${payments[i].sessionsCovered} séances · ${formatShortDate(payments[i].paidAt)}',
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryTile extends StatelessWidget {
  const _AttendanceHistoryTile({required this.entry});

  final ({DateTime date, String groupId, AttendanceStatus status, bool? isPaid}) entry;

  @override
  Widget build(BuildContext context) {
    final justified = entry.status == AttendanceStatus.absentJustified;

    final IconData icon;
    final Color color;
    if (justified) {
      // Ni payée ni due : une absence justifiée n'est jamais facturée,
      // voir Attendance.isBillable.
      icon = Icons.event_busy_outlined;
      color = AppColors.inkMuted;
    } else if (entry.isPaid ?? false) {
      icon = Icons.check_circle;
      color = AppStatus.paid;
    } else {
      icon = Icons.radio_button_unchecked;
      color = AppStatus.due;
    }

    final statusLabel = switch (entry.status) {
      AttendanceStatus.present => 'Présent',
      AttendanceStatus.absentJustified => 'Absent justifié',
      AttendanceStatus.absentUnjustified => 'Absent non justifié',
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(formatShortDate(entry.date)),
      subtitle: Text(
        '${AppRepository.groupById(entry.groupId)?.displayName ?? ''} · $statusLabel',
      ),
    );
  }
}
