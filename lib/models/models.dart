import 'package:flutter/material.dart';

/// `scheduled` = programmée, pas encore tenue (aucune présence encore
/// possible). `done` = tenue, présences saisies. Le passage
/// scheduled → done se fait en enregistrant les présences (voir
/// AppRepository.setAttendance / AttendanceScreen).
enum SessionStatus { scheduled, done, cancelled }

enum AttendanceStatus { present, absentJustified, absentUnjustified }

/// Niveau scolaire d'un groupe. Seuls [troisieme] et [bac] admettent une
/// [Section] (voir [hasSection]) — le collège (7ème-9ème) et 1ère/2ème
/// sont en tronc commun.
enum Level {
  septieme,
  huitieme,
  neuvieme,
  premiere,
  deuxieme,
  troisieme,
  bac;

  String get label => switch (this) {
        Level.septieme => '7ème',
        Level.huitieme => '8ème',
        Level.neuvieme => '9ème',
        Level.premiere => '1ère',
        Level.deuxieme => '2ème',
        Level.troisieme => '3ème',
        Level.bac => 'Bac',
      };

  bool get hasSection => this == Level.troisieme || this == Level.bac;
}

/// Filière, seulement pertinente pour un groupe de [Level.troisieme] ou
/// [Level.bac] (voir [Level.hasSection]).
enum Section {
  maths,
  sciencesExp,
  technique,
  info,
  eco,
  lettres;

  String get label => switch (this) {
        Section.maths => 'Maths',
        Section.sciencesExp => 'Sciences exp.',
        Section.technique => 'Technique',
        Section.info => 'Info',
        Section.eco => 'Éco',
        Section.lettres => 'Lettres',
      };
}

/// [weekday] suit la convention SQL du README : 0 = dimanche ... 6 = samedi.
///
/// [pricePerSession] reste l'unité de calcul interne (celle qui va sur
/// chaque [Session] et alimente le ledger) ; le prof, lui, raisonne en
/// tarif mensuel — voir [monthlyPrice], la seule valeur montrée dans
/// l'UI (formulaire de groupe, fiche groupe).
///
/// [groupNumber] distingue deux groupes de même niveau/section (un
/// prof peut avoir "Bac Maths 1" et "Bac Maths 2" en parallèle) —
/// jamais saisi à la main, voir [AppRepository.createGroup]. [note] est
/// l'inverse : un surnom libre et purement optionnel que le prof se
/// donne pour reconnaître le groupe (ex. "Les terminales du soir"),
/// sans valeur d'identification.
class Group {
  const Group({
    required this.id,
    required this.level,
    this.section,
    this.groupNumber,
    this.note,
    required this.pricePerSession,
    required this.weekday,
    required this.startTime,
    this.durationMinutes = 120,
  });

  final String id;
  final Level level;
  final Section? section;
  final int? groupNumber;
  final String? note;
  final double pricePerSession;
  final int weekday;
  final TimeOfDay startTime;
  final int durationMinutes;

  /// Prix d'un cycle complet de 4 séances — c'est ce que le prof
  /// appelle "le tarif", jamais le prix d'une séance isolée.
  double get monthlyPrice => pricePerSession * 4;

  String get displayName {
    final base = section == null ? level.label : '${level.label} · ${section!.label}';
    return groupNumber == null ? base : '$base · Groupe $groupNumber';
  }

  Group copyWith({
    Level? level,
    Section? section,
    bool clearSection = false,
    int? groupNumber,
    bool clearGroupNumber = false,
    String? note,
    bool clearNote = false,
    double? pricePerSession,
    int? weekday,
    TimeOfDay? startTime,
    int? durationMinutes,
  }) {
    return Group(
      id: id,
      level: level ?? this.level,
      section: clearSection ? null : (section ?? this.section),
      groupNumber: clearGroupNumber ? null : (groupNumber ?? this.groupNumber),
      note: clearNote ? null : (note ?? this.note),
      pricePerSession: pricePerSession ?? this.pricePerSession,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

/// [classLevel]/[classSection]/[classNumber]/[school] décrivent la
/// classe RÉELLE de l'élève dans son lycée — indépendante du groupe de
/// soutien où il est inscrit (un élève de section Maths peut très bien
/// suivre un groupe Technique, par exemple pour des raisons d'horaire).
/// [classLevel] en revanche doit TOUJOURS correspondre au niveau du
/// groupe où l'élève est inscrit — un 3ème ne rejoint pas un groupe de
/// Bac — voir add_student_sheet.dart / edit_student_sheet.dart, qui le
/// verrouillent sur le niveau du groupe plutôt que d'en faire un choix
/// libre.
///
/// [suspendedAt] met l'élève en pause (absence prolongée...) sans le
/// désinscrire : il reste dans son groupe (voir
/// [AppRepository.studentsForGroup], qui le montre en bas de liste) et son
/// solde continue d'exister — contrairement à une suppression,
/// réversible via [AppRepository.reactivateStudent]. [isFree] dispense
/// l'élève de tout paiement (voir [AppRepository.balanceFor]).
class Student {
  const Student({
    required this.id,
    required this.name,
    this.phone,
    this.parentPhone,
    this.classLevel,
    this.classSection,
    this.classNumber,
    this.school,
    this.isFree = false,
    this.suspendedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? parentPhone;
  final Level? classLevel;
  final Section? classSection;
  final int? classNumber;
  final String? school;
  final bool isFree;
  final DateTime? suspendedAt;

  bool get isSuspended => suspendedAt != null;

  /// "3ème Maths 2 — Lycée Pilote" par exemple ; null si aucune info
  /// de classe n'a été saisie.
  String? get classLabel {
    if (classLevel == null) return null;
    final parts = [
      classLevel!.label,
      if (classSection != null) classSection!.label,
      if (classNumber != null) '$classNumber',
    ];
    final label = parts.join(' ');
    return school == null ? label : '$label — $school';
  }

  Student copyWith({
    String? name,
    String? phone,
    bool clearPhone = false,
    String? parentPhone,
    bool clearParentPhone = false,
    Level? classLevel,
    bool clearClassLevel = false,
    Section? classSection,
    bool clearClassSection = false,
    int? classNumber,
    bool clearClassNumber = false,
    String? school,
    bool clearSchool = false,
    bool? isFree,
    DateTime? suspendedAt,
    bool clearSuspendedAt = false,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      phone: clearPhone ? null : (phone ?? this.phone),
      parentPhone: clearParentPhone ? null : (parentPhone ?? this.parentPhone),
      classLevel: clearClassLevel ? null : (classLevel ?? this.classLevel),
      classSection: clearClassSection ? null : (classSection ?? this.classSection),
      classNumber: clearClassNumber ? null : (classNumber ?? this.classNumber),
      school: clearSchool ? null : (school ?? this.school),
      isFree: isFree ?? this.isFree,
      suspendedAt: clearSuspendedAt ? null : (suspendedAt ?? this.suspendedAt),
    );
  }
}

/// Classe d'association élève <-> groupe, historisée : un déplacement
/// ferme l'inscription (leftAt) et en ouvre une nouvelle, plutôt que de
/// réécrire un simple group_id. Voir README §4 "Choix structurants".
class Enrollment {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.joinedAt,
    this.leftAt,
  });

  final String id;
  final String studentId;
  final String groupId;
  final DateTime joinedAt;
  final DateTime? leftAt;

  bool get isActive => leftAt == null;

  Enrollment close(DateTime date) => Enrollment(
        id: id,
        studentId: studentId,
        groupId: groupId,
        joinedAt: joinedAt,
        leftAt: date,
      );
}

class Session {
  const Session({
    required this.id,
    required this.groupId,
    required this.date,
    this.startTime,
    this.isRescheduled = false,
    this.status = SessionStatus.done,
    required this.price,
  });

  final String id;
  final String groupId;
  final DateTime date;
  final TimeOfDay? startTime;
  final bool isRescheduled;
  final SessionStatus status;
  final double price;

  Session copyWith({
    DateTime? date,
    TimeOfDay? startTime,
    bool? isRescheduled,
    SessionStatus? status,
  }) {
    return Session(
      id: id,
      groupId: groupId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      isRescheduled: isRescheduled ?? this.isRescheduled,
      status: status ?? this.status,
      price: price,
    );
  }
}

class Attendance {
  const Attendance({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
  });

  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;

  bool get isBillable =>
      status == AttendanceStatus.present ||
      status == AttendanceStatus.absentUnjustified;
}

class Payment {
  const Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.paidAt,
    this.sessionsCovered = 4,
    this.note,
  });

  final String id;
  final String studentId;
  final double amount;
  final DateTime paidAt;
  final int sessionsCovered;
  final String? note;
}

/// Une ligne de la vue `student_ledger` : une séance facturable pour un
/// élève donné, numérotée et marquée payée ou non. Jamais stockée —
/// voir [MockRepository.ledgerFor].
///
/// [cycleSize] et [completesCycle] portent la règle "même mois pour tout
/// le groupe" : un élève qui rejoint en cours de cycle a un premier
/// cycle raccourci (moins de 4 séances) pour que ses échéances suivantes
/// retombent sur les mêmes séances que le reste du groupe.
class LedgerLine {
  const LedgerLine({
    required this.studentId,
    required this.sessionId,
    required this.groupId,
    required this.date,
    required this.price,
    required this.seq,
    required this.isPaid,
    required this.cycleSize,
    required this.completesCycle,
  });

  final String studentId;
  final String sessionId;
  final String groupId;
  final DateTime date;
  final double price;
  final int seq;
  final bool isPaid;
  final int cycleSize;
  final bool completesCycle;
}

/// Vue `student_balance` — jamais stockée, toujours dérivée depuis le
/// ledger. Voir [MockRepository.balanceFor].
class StudentBalance {
  const StudentBalance({
    required this.studentId,
    required this.unpaidSessions,
    required this.amountDue,
    required this.isDue,
    required this.isFree,
    required this.cycleSize,
    this.oldestUnpaid,
  });

  final String studentId;
  final int unpaidSessions;
  final double amountDue;

  /// Vrai dès qu'une séance du cycle en cours reste impayée — pas
  /// besoin d'attendre que le groupe boucle les 4 séances, voir
  /// [AppRepository.unpaidCycles]. Toujours faux pour un élève [isFree].
  final bool isDue;

  /// Copié de [Student.isFree] pour que l'UI (BalancePill) n'ait pas à
  /// relire le Student séparément.
  final bool isFree;

  /// Taille du cycle en cours (4, ou moins pour un premier cycle
  /// raccourci) — sert d'affichage "X/N séances", N n'est pas toujours 4.
  final int cycleSize;
  final DateTime? oldestUnpaid;
}

class AttendanceSummary {
  const AttendanceSummary({
    this.present = 0,
    this.absentJustified = 0,
    this.absentUnjustified = 0,
  });

  final int present;
  final int absentJustified;
  final int absentUnjustified;
}
