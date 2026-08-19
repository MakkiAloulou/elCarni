import 'package:flutter/material.dart';

const List<String> weekdayNames = [
  'Dimanche',
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
];

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Prochaine occurrence d'un créneau (weekday 0=dimanche..6=samedi) après [after].
/// Calcul client, conformément au §10 du README : pas de génération auto,
/// la date proposée part de la dernière séance connue (ou "maintenant").
DateTime nextOccurrence(int weekday, TimeOfDay startTime, {DateTime? after}) {
  final base = after ?? DateTime.now();
  final targetDartWeekday = weekday == 0 ? DateTime.sunday : weekday;
  var candidate = DateTime(
    base.year,
    base.month,
    base.day,
    startTime.hour,
    startTime.minute,
  );
  final diff = (targetDartWeekday - base.weekday) % 7;
  candidate = candidate.add(Duration(days: diff));
  if (!candidate.isAfter(base)) {
    candidate = candidate.add(const Duration(days: 7));
  }
  return candidate;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Titre de regroupement pour une liste de séances triée par jour —
/// "Aujourd'hui"/"Demain" quand ça s'applique, sinon jour de semaine +
/// date courte.
String dayLabel(DateTime date) {
  final now = DateTime.now();
  final diff = DateTime(date.year, date.month, date.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Demain';
  return '${weekdayNames[date.weekday % 7]} ${formatShortDate(date)}';
}

String formatShortDate(DateTime date) {
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
