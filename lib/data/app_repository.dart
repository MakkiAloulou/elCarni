import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;

import '../models/models.dart';

/// Remplace mock_data.dart : même API (mêmes noms de méthodes, même
/// logique de facturation — voir ledgerFor/unpaidCycles, portés tels
/// quels), mais les listes sont un cache chargé depuis Supabase (voir
/// [load]) et les mutations écrivent d'abord en base avant de mettre à
/// jour le cache local. Le solde n'est toujours JAMAIS stocké : il est
/// recalculé depuis présences et paiements à chaque lecture, exactement
/// comme avant.
abstract final class AppRepository {
  static SupabaseClient get _db => Supabase.instance.client;
  static String get _teacherId => _db.auth.currentUser!.id;

  static final List<Group> groups = [];
  static final List<Student> students = [];
  static final List<Enrollment> enrollments = [];
  static final List<Session> sessions = [];
  static final List<Attendance> attendances = [];
  static final List<Payment> payments = [];

  // Vide = "tout est enseigné" — même convention que mock_data.dart,
  // conservée par tous les écrans qui lisaient déjà ce champ ainsi.
  static Set<Level> taughtLevels = {};
  static Set<Section> taughtSections = {};

  static Future<void>? _loadFuture;

  /// Charge (une seule fois par session app) toutes les données du prof
  /// connecté — RLS filtre déjà par teacher_id, inutile de le refaire
  /// ici. Appelé depuis AuthGate dès que teachers.status == 'valid'.
  static Future<void> ensureLoaded() => _loadFuture ??= load();

  /// Vide le cache et oublie le chargement précédent — appelé à la
  /// déconnexion (voir settings_screen.dart) pour qu'un login suivant,
  /// même sous un autre compte, reparte de zéro plutôt que de garder
  /// les données du prof précédent affichées un instant.
  static void reset() {
    _loadFuture = null;
    groups.clear();
    students.clear();
    enrollments.clear();
    sessions.clear();
    attendances.clear();
    payments.clear();
    taughtLevels = {};
    taughtSections = {};
  }

  static Future<void> load() async {
    final results = await Future.wait<dynamic>([
      _db.from('teachers').select().eq('id', _teacherId).single(),
      _db.from('groups').select(),
      _db.from('students').select(),
      _db.from('enrollments').select(),
      _db.from('sessions').select(),
      _db.from('attendances').select(),
      _db.from('payments').select(),
    ]);

    final teacherRow = results[0] as Map<String, dynamic>;
    final rawLevels = (teacherRow['taught_levels'] as List?)?.cast<String>();
    taughtLevels = rawLevels == null ? {} : rawLevels.map(_levelFromDb).toSet();
    final rawSections = (teacherRow['taught_sections'] as List?)?.cast<String>();
    taughtSections = rawSections == null ? {} : rawSections.map(_sectionFromDb).toSet();

    groups
      ..clear()
      ..addAll((results[1] as List).cast<Map<String, dynamic>>().map(_groupFromRow));
    students
      ..clear()
      ..addAll((results[2] as List).cast<Map<String, dynamic>>().map(_studentFromRow));
    enrollments
      ..clear()
      ..addAll((results[3] as List).cast<Map<String, dynamic>>().map(_enrollmentFromRow));
    sessions
      ..clear()
      ..addAll((results[4] as List).cast<Map<String, dynamic>>().map(_sessionFromRow));
    attendances
      ..clear()
      ..addAll((results[5] as List).cast<Map<String, dynamic>>().map(_attendanceFromRow));
    payments
      ..clear()
      ..addAll((results[6] as List).cast<Map<String, dynamic>>().map(_paymentFromRow));
  }

  // ---------------------------------------------------------------------
  // Enums <-> colonnes Postgres. Level/SessionStatus ont les mêmes noms
  // des deux côtés (.name suffit) ; Section/AttendanceStatus sont en
  // snake_case côté SQL (voir supabase/migrations/0001_init.sql) donc
  // ont besoin d'une table de correspondance explicite.
  // ---------------------------------------------------------------------

  static Level _levelFromDb(String s) => Level.values.byName(s);
  static String _levelToDb(Level l) => l.name;

  static SessionStatus _sessionStatusFromDb(String s) => SessionStatus.values.byName(s);
  static String _sessionStatusToDb(SessionStatus s) => s.name;

  static const _sectionToDbMap = {
    Section.maths: 'maths',
    Section.sciencesExp: 'sciences_exp',
    Section.technique: 'technique',
    Section.info: 'info',
    Section.eco: 'eco',
    Section.lettres: 'lettres',
  };
  static final _sectionFromDbMap = {
    for (final e in _sectionToDbMap.entries) e.value: e.key,
  };
  static Section _sectionFromDb(String s) => _sectionFromDbMap[s]!;
  static String _sectionToDb(Section s) => _sectionToDbMap[s]!;

  static const _attendanceToDbMap = {
    AttendanceStatus.present: 'present',
    AttendanceStatus.absentJustified: 'absent_justified',
    AttendanceStatus.absentUnjustified: 'absent_unjustified',
  };
  static final _attendanceFromDbMap = {
    for (final e in _attendanceToDbMap.entries) e.value: e.key,
  };
  static AttendanceStatus _attendanceStatusFromDb(String s) => _attendanceFromDbMap[s]!;
  static String _attendanceStatusToDb(AttendanceStatus s) => _attendanceToDbMap[s]!;

  static TimeOfDay _timeFromDb(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _timeToDb(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  static String _dateToDb(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // Ligne Postgres <-> modèle Dart.
  // ---------------------------------------------------------------------

  static Group _groupFromRow(Map<String, dynamic> row) => Group(
        id: row['id'] as String,
        level: _levelFromDb(row['level'] as String),
        section: row['section'] == null ? null : _sectionFromDb(row['section'] as String),
        groupNumber: row['group_number'] as int?,
        note: row['note'] as String?,
        pricePerSession: (row['price_per_session'] as num).toDouble(),
        weekday: row['weekday'] as int,
        startTime: _timeFromDb(row['start_time'] as String),
        durationMinutes: row['duration_minutes'] as int,
      );

  static Map<String, dynamic> _groupToRow(Group g) => {
        'level': _levelToDb(g.level),
        'section': g.section == null ? null : _sectionToDb(g.section!),
        'group_number': g.groupNumber,
        'note': g.note,
        'price_per_session': g.pricePerSession,
        'weekday': g.weekday,
        'start_time': _timeToDb(g.startTime),
        'duration_minutes': g.durationMinutes,
      };

  static Student _studentFromRow(Map<String, dynamic> row) => Student(
        id: row['id'] as String,
        name: row['name'] as String,
        phone: row['phone'] as String?,
        parentPhone: row['parent_phone'] as String?,
        classLevel: row['class_level'] == null ? null : _levelFromDb(row['class_level'] as String),
        classSection:
            row['class_section'] == null ? null : _sectionFromDb(row['class_section'] as String),
        classNumber: row['class_number'] as int?,
        school: row['school'] as String?,
        isFree: row['is_free'] as bool,
        suspendedAt:
            row['suspended_at'] == null ? null : DateTime.parse(row['suspended_at'] as String),
      );

  static Map<String, dynamic> _studentToRow(Student s) => {
        'name': s.name,
        'phone': s.phone,
        'parent_phone': s.parentPhone,
        'class_level': s.classLevel == null ? null : _levelToDb(s.classLevel!),
        'class_section': s.classSection == null ? null : _sectionToDb(s.classSection!),
        'class_number': s.classNumber,
        'school': s.school,
        'is_free': s.isFree,
        'suspended_at': s.suspendedAt?.toIso8601String(),
      };

  static Enrollment _enrollmentFromRow(Map<String, dynamic> row) => Enrollment(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        groupId: row['group_id'] as String,
        joinedAt: DateTime.parse(row['joined_at'] as String),
        leftAt: row['left_at'] == null ? null : DateTime.parse(row['left_at'] as String),
      );

  static Session _sessionFromRow(Map<String, dynamic> row) => Session(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        date: DateTime.parse(row['date'] as String),
        startTime: row['start_time'] == null ? null : _timeFromDb(row['start_time'] as String),
        isRescheduled: row['is_rescheduled'] as bool,
        status: _sessionStatusFromDb(row['status'] as String),
        price: (row['price'] as num).toDouble(),
      );

  static Attendance _attendanceFromRow(Map<String, dynamic> row) => Attendance(
        id: row['id'] as String,
        sessionId: row['session_id'] as String,
        studentId: row['student_id'] as String,
        status: _attendanceStatusFromDb(row['status'] as String),
      );

  static Payment _paymentFromRow(Map<String, dynamic> row) => Payment(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        amount: (row['amount'] as num).toDouble(),
        paidAt: DateTime.parse(row['paid_at'] as String),
        sessionsCovered: row['sessions_covered'] as int,
        note: row['note'] as String?,
      );

  // ---------------------------------------------------------------------
  // Requêtes — identiques à mock_data.dart, portées telles quelles :
  // seule la provenance des listes change.
  // ---------------------------------------------------------------------

  static List<Student> studentsForGroup(String groupId) {
    final ids = enrollments
        .where((e) => e.groupId == groupId && e.isActive)
        .map((e) => e.studentId)
        .toSet();
    final matched = students.where((s) => ids.contains(s.id));
    final active = matched.where((s) => !s.isSuspended).toList();
    final suspended = matched.where((s) => s.isSuspended).toList();
    return [...active, ...suspended];
  }

  static List<Group> groupsForStudent(String studentId) {
    final ids = enrollments
        .where((e) => e.studentId == studentId && e.isActive)
        .map((e) => e.groupId)
        .toSet();
    return groups.where((g) => ids.contains(g.id)).toList();
  }

  static Group? groupById(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  static Student? studentById(String id) {
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<Session> sessionsForGroup(String groupId) {
    final list = sessions.where((s) => s.groupId == groupId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static AttendanceSummary summaryForSession(String sessionId) {
    var present = 0, justified = 0, unjustified = 0;
    for (final a in attendances.where((a) => a.sessionId == sessionId)) {
      switch (a.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absentJustified:
          justified++;
        case AttendanceStatus.absentUnjustified:
          unjustified++;
      }
    }
    return AttendanceSummary(
      present: present,
      absentJustified: justified,
      absentUnjustified: unjustified,
    );
  }

  static Map<String, AttendanceStatus> attendanceForSession(String sessionId) {
    return {
      for (final a in attendances.where((a) => a.sessionId == sessionId))
        a.studentId: a.status,
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _groupSessionIndex(String groupId, String sessionId) {
    final groupSessions = sessions
        .where((s) => s.groupId == groupId && s.status == SessionStatus.done)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return groupSessions.indexWhere((s) => s.id == sessionId) + 1;
  }

  static List<LedgerLine> ledgerFor(String studentId) {
    final studentEnrollments = enrollments.where((e) => e.studentId == studentId).toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    final byEnrollment = <String, List<({DateTime date, double price, String sessionId})>>{};
    for (final a in attendances.where((a) => a.studentId == studentId && a.isBillable)) {
      final session = sessions.firstWhere((s) => s.id == a.sessionId);
      if (session.status != SessionStatus.done) continue;
      final sessionDay = _dateOnly(session.date);
      final enrollment = studentEnrollments.firstWhere(
        (e) =>
            e.groupId == session.groupId &&
            !sessionDay.isBefore(_dateOnly(e.joinedAt)) &&
            (e.leftAt == null || !sessionDay.isAfter(_dateOnly(e.leftAt!))),
        orElse: () => studentEnrollments.firstWhere((e) => e.groupId == session.groupId),
      );
      (byEnrollment[enrollment.id] ??= []).add(
        (date: session.date, price: session.price, sessionId: session.id),
      );
    }

    final tagged = <({
      DateTime date,
      double price,
      String sessionId,
      String groupId,
      int cycleSize,
      bool completesCycle,
    })>[];

    for (final entry in byEnrollment.entries) {
      final enrollment = studentEnrollments.firstWhere((e) => e.id == entry.key);
      final groupId = enrollment.groupId;
      final rows = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (rows.isEmpty) continue;

      final groupDoneCount = sessions
          .where((s) => s.groupId == groupId && s.status == SessionStatus.done)
          .length;
      final stillEnrolled = enrollment.isActive;

      final byCycle = <int, List<({DateTime date, double price, String sessionId})>>{};
      for (final r in rows) {
        final groupIndex = _groupSessionIndex(groupId, r.sessionId);
        (byCycle[(groupIndex - 1) ~/ 4] ??= []).add(r);
      }

      final firstGroupIndex = _groupSessionIndex(groupId, rows.first.sessionId);
      final firstCycleNumber = (firstGroupIndex - 1) ~/ 4;

      for (final cycleNumber in byCycle.keys.toList()..sort()) {
        final cycleRows = byCycle[cycleNumber]!;
        final cycleSize =
            cycleNumber == firstCycleNumber ? 4 - ((firstGroupIndex - 1) % 4) : 4;
        final calendarComplete = groupDoneCount >= (cycleNumber + 1) * 4 || !stillEnrolled;
        for (var i = 0; i < cycleRows.length; i++) {
          final r = cycleRows[i];
          tagged.add((
            date: r.date,
            price: r.price,
            sessionId: r.sessionId,
            groupId: groupId,
            cycleSize: cycleSize,
            completesCycle: calendarComplete && i == cycleRows.length - 1,
          ));
        }
      }
    }
    tagged.sort((a, b) => a.date.compareTo(b.date));

    final covered = payments
        .where((p) => p.studentId == studentId)
        .fold<int>(0, (sum, p) => sum + p.sessionsCovered);

    return [
      for (var i = 0; i < tagged.length; i++)
        LedgerLine(
          studentId: studentId,
          sessionId: tagged[i].sessionId,
          groupId: tagged[i].groupId,
          date: tagged[i].date,
          price: tagged[i].price,
          seq: i + 1,
          isPaid: (i + 1) <= covered,
          cycleSize: tagged[i].cycleSize,
          completesCycle: tagged[i].completesCycle,
        ),
    ];
  }

  static List<({DateTime date, String groupId, AttendanceStatus status, bool? isPaid})>
      attendanceHistoryFor(String studentId) {
    final ledgerBySessionId = {for (final l in ledgerFor(studentId)) l.sessionId: l};
    final result = <({DateTime date, String groupId, AttendanceStatus status, bool? isPaid})>[];
    for (final a in attendances.where((a) => a.studentId == studentId)) {
      final session = sessions.firstWhere((s) => s.id == a.sessionId);
      if (session.status != SessionStatus.done) continue;
      result.add((
        date: session.date,
        groupId: session.groupId,
        status: a.status,
        isPaid: ledgerBySessionId[a.sessionId]?.isPaid,
      ));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  static StudentBalance balanceFor(String studentId) {
    if (studentById(studentId)?.isFree ?? false) {
      return StudentBalance(
        studentId: studentId,
        unpaidSessions: 0,
        amountDue: 0,
        isDue: false,
        isFree: true,
        cycleSize: 4,
      );
    }

    // Le solde affiché est ce qui sera réellement facturé si le prof
    // encaisse maintenant — le ou les cycles réservés en entier (voir
    // unpaidCycles), pas seulement les séances déjà tenues. Un élève à
    // 2 séances sur un cycle de 4 doit donc afficher "4 séances dues",
    // pas "2" : le cycle est dû dès sa 1ère séance impayée, dans sa
    // totalité, même si le reste n'a pas encore eu lieu.
    final cycles = unpaidCycles(studentId);
    final unpaidSessions = cycles.fold<int>(0, (s, c) => s + c.sessions);
    final amountDue = cycles.fold<double>(0, (s, c) => s + c.amount);

    final unpaid = ledgerFor(studentId).where((l) => !l.isPaid).toList();

    return StudentBalance(
      studentId: studentId,
      unpaidSessions: unpaidSessions,
      amountDue: amountDue,
      isDue: cycles.isNotEmpty,
      isFree: false,
      cycleSize: unpaid.isEmpty ? 4 : unpaid.last.cycleSize,
      oldestUnpaid: unpaid.isEmpty ? null : unpaid.first.date,
    );
  }

  static List<Payment> paymentsFor(String studentId) {
    final list = payments.where((p) => p.studentId == studentId).toList();
    list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return list;
  }

  static int sessionsThisWeekCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return sessions
        .where((s) =>
            s.status != SessionStatus.cancelled &&
            !s.date.isBefore(startOfWeek) &&
            s.date.isBefore(endOfWeek))
        .length;
  }

  static List<({Student student, List<Group> groups, StudentBalance balance})>
      studentsWithDuePayments() {
    final result = <({Student student, List<Group> groups, StudentBalance balance})>[];
    for (final student in students) {
      final balance = balanceFor(student.id);
      if (balance.isDue) {
        result.add((student: student, groups: groupsForStudent(student.id), balance: balance));
      }
    }
    result.sort((a, b) => b.balance.unpaidSessions.compareTo(a.balance.unpaidSessions));
    return result;
  }

  static List<Session> scheduledSessions() {
    final list = sessions.where((s) => s.status == SessionStatus.scheduled).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  static List<({int sessions, double amount})> unpaidCycles(String studentId) {
    final cycles = <({int sessions, double amount})>[];
    var count = 0;
    var amount = 0.0;
    int? cycleSize;
    double? pricePerSession;
    String? groupId;
    String? sessionId;
    for (final line in ledgerFor(studentId).where((l) => !l.isPaid)) {
      count++;
      amount += line.price;
      cycleSize = line.cycleSize;
      pricePerSession = line.price;
      groupId = line.groupId;
      sessionId = line.sessionId;
      if (line.completesCycle) {
        cycles.add((sessions: count, amount: amount));
        count = 0;
        amount = 0;
        cycleSize = null;
        pricePerSession = null;
        groupId = null;
        sessionId = null;
      }
    }
    if (count > 0 && cycleSize != null && pricePerSession != null && groupId != null) {
      final cycleNumber = (_groupSessionIndex(groupId, sessionId!) - 1) ~/ 4;
      final justified = _justifiedAbsencesInCycle(studentId, groupId, cycleNumber);
      final billable = (cycleSize - justified).clamp(0, cycleSize);
      cycles.add((sessions: billable, amount: billable * pricePerSession));
    }
    return cycles;
  }

  static int _justifiedAbsencesInCycle(String studentId, String groupId, int cycleNumber) {
    final blockStart = cycleNumber * 4 + 1;
    final blockEnd = blockStart + 3;
    var count = 0;
    for (final a in attendances) {
      if (a.studentId != studentId || a.status != AttendanceStatus.absentJustified) continue;
      final session = sessions.firstWhere((s) => s.id == a.sessionId);
      if (session.groupId != groupId || session.status != SessionStatus.done) continue;
      final idx = _groupSessionIndex(groupId, session.id);
      if (idx >= blockStart && idx <= blockEnd) count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------
  // Mutations — écrivent d'abord en base, puis répliquent en local.
  // ---------------------------------------------------------------------

  static Future<void> setTaughtLevels(Set<Level> levels) async {
    taughtLevels = {...levels};
    if (!levels.any((l) => l.hasSection)) {
      taughtSections = {};
    }
    await _db.from('teachers').update({
      'taught_levels': taughtLevels.map(_levelToDb).toList(),
      'taught_sections': taughtSections.map(_sectionToDb).toList(),
    }).eq('id', _teacherId);
  }

  static Future<void> setTaughtSections(Set<Section> sections) async {
    taughtSections = {...sections};
    await _db
        .from('teachers')
        .update({'taught_sections': taughtSections.map(_sectionToDb).toList()}).eq(
            'id', _teacherId);
  }

  static Future<Group> createGroup({
    required Level level,
    Section? section,
    String? note,
    required double pricePerSession,
    required int weekday,
    required TimeOfDay startTime,
    int durationMinutes = 120,
  }) async {
    final siblings = groups.where((g) => g.level == level && g.section == section).toList();
    int? groupNumber;
    if (siblings.isNotEmpty) {
      final highest = siblings.fold<int>(0, (max, g) {
        final n = g.groupNumber ?? 1;
        return n > max ? n : max;
      });
      groupNumber = highest + 1;
      if (siblings.length == 1 && siblings.first.groupNumber == null) {
        final i = groups.indexOf(siblings.first);
        await _db.from('groups').update({'group_number': 1}).eq('id', siblings.first.id);
        groups[i] = groups[i].copyWith(groupNumber: 1);
      }
    }

    final row = await _db.from('groups').insert({
      'teacher_id': _teacherId,
      'level': _levelToDb(level),
      'section': section == null ? null : _sectionToDb(section),
      'group_number': groupNumber,
      'note': note,
      'price_per_session': pricePerSession,
      'weekday': weekday,
      'start_time': _timeToDb(startTime),
      'duration_minutes': durationMinutes,
    }).select().single();
    final group = _groupFromRow(row);
    groups.add(group);
    return group;
  }

  static Future<void> updateGroup(Group updated) async {
    await _db.from('groups').update(_groupToRow(updated)).eq('id', updated.id);
    final i = groups.indexWhere((g) => g.id == updated.id);
    if (i != -1) groups[i] = updated;
  }

  static Future<Student> createStudent({
    required String name,
    String? phone,
    String? parentPhone,
    Level? classLevel,
    Section? classSection,
    int? classNumber,
    String? school,
    bool isFree = false,
  }) async {
    final row = await _db.from('students').insert({
      'teacher_id': _teacherId,
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
      'class_level': classLevel == null ? null : _levelToDb(classLevel),
      'class_section': classSection == null ? null : _sectionToDb(classSection),
      'class_number': classNumber,
      'school': school,
      'is_free': isFree,
    }).select().single();
    final student = _studentFromRow(row);
    students.add(student);
    return student;
  }

  static Future<void> updateStudent(Student updated) async {
    await _db.from('students').update(_studentToRow(updated)).eq('id', updated.id);
    final i = students.indexWhere((s) => s.id == updated.id);
    if (i != -1) students[i] = updated;
  }

  static Future<bool> enrollStudent(String studentId, String groupId) async {
    final alreadyEnrolled = enrollments.any((e) => e.studentId == studentId && e.isActive);
    if (alreadyEnrolled) return false;
    final student = studentById(studentId);
    final group = groupById(groupId);
    if (student?.classLevel != null && group != null && student!.classLevel != group.level) {
      return false;
    }
    final now = DateTime.now();
    final row = await _db.from('enrollments').insert({
      'student_id': studentId,
      'group_id': groupId,
      'joined_at': _dateToDb(now),
    }).select().single();
    enrollments.add(_enrollmentFromRow(row));
    return true;
  }

  static Future<void> moveStudent(String studentId, String fromGroupId, String toGroupId) async {
    final i = enrollments.indexWhere(
      (e) => e.studentId == studentId && e.groupId == fromGroupId && e.isActive,
    );
    if (i != -1) {
      final now = DateTime.now();
      await _db
          .from('enrollments')
          .update({'left_at': _dateToDb(now)}).eq('id', enrollments[i].id);
      enrollments[i] = enrollments[i].close(now);
    }
    await enrollStudent(studentId, toGroupId);
  }

  static Future<void> suspendStudent(String studentId) async {
    final now = DateTime.now();
    await _db
        .from('students')
        .update({'suspended_at': now.toIso8601String()}).eq('id', studentId);
    final i = students.indexWhere((s) => s.id == studentId);
    if (i != -1) students[i] = students[i].copyWith(suspendedAt: now);
  }

  static Future<void> reactivateStudent(String studentId) async {
    await _db.from('students').update({'suspended_at': null}).eq('id', studentId);
    final i = students.indexWhere((s) => s.id == studentId);
    if (i != -1) students[i] = students[i].copyWith(clearSuspendedAt: true);
  }

  static Future<bool> deleteStudent(String studentId) async {
    if (balanceFor(studentId).unpaidSessions > 0) return false;
    await _db.from('students').delete().eq('id', studentId);
    students.removeWhere((s) => s.id == studentId);
    enrollments.removeWhere((e) => e.studentId == studentId);
    attendances.removeWhere((a) => a.studentId == studentId);
    payments.removeWhere((p) => p.studentId == studentId);
    return true;
  }

  /// Refuse aussi si le groupe a déjà des séances tenues — contrairement
  /// à mock_data.dart, qui les laissait survivre à la suppression du
  /// groupe. Côté Supabase, sessions.group_id est `on delete cascade`
  /// (voir 0001_init.sql) : les laisser survivre demanderait une FK
  /// nullable + une policy RLS qui tienne compte d'un group_id absent,
  /// pour un cas limite rare. Simplification assumée : un groupe qui a
  /// déjà servi n'est plus supprimable, seulement vidable de ses élèves.
  static Future<bool> deleteGroup(String groupId) async {
    if (studentsForGroup(groupId).isNotEmpty) return false;
    final hasHistory =
        sessions.any((s) => s.groupId == groupId && s.status == SessionStatus.done);
    if (hasHistory) return false;
    await _db.from('groups').delete().eq('id', groupId);
    groups.removeWhere((g) => g.id == groupId);
    sessions.removeWhere((s) => s.groupId == groupId);
    return true;
  }

  static Future<Session> createSession({
    required String groupId,
    required DateTime date,
    TimeOfDay? startTime,
    bool isRescheduled = false,
    required double price,
    required SessionStatus status,
  }) async {
    final row = await _db.from('sessions').insert({
      'group_id': groupId,
      'date': _dateToDb(date),
      'start_time': startTime == null ? null : _timeToDb(startTime),
      'is_rescheduled': isRescheduled,
      'status': _sessionStatusToDb(status),
      'price': price,
    }).select().single();
    final session = _sessionFromRow(row);
    sessions.add(session);
    return session;
  }

  static Future<Session?> updateSession(
    String sessionId, {
    required DateTime date,
    TimeOfDay? startTime,
    required bool isRescheduled,
  }) async {
    final i = sessions.indexWhere((s) => s.id == sessionId);
    if (i == -1 || sessions[i].status != SessionStatus.scheduled) return null;
    await _db.from('sessions').update({
      'date': _dateToDb(date),
      'start_time': startTime == null ? null : _timeToDb(startTime),
      'is_rescheduled': isRescheduled,
    }).eq('id', sessionId);
    final updated =
        sessions[i].copyWith(date: date, startTime: startTime, isRescheduled: isRescheduled);
    sessions[i] = updated;
    return updated;
  }

  static Future<void> markSessionDone(String sessionId) async {
    final i = sessions.indexWhere((s) => s.id == sessionId);
    if (i != -1 && sessions[i].status == SessionStatus.scheduled) {
      await _db.from('sessions').update({'status': 'done'}).eq('id', sessionId);
      sessions[i] = sessions[i].copyWith(status: SessionStatus.done);
    }
  }

  static Future<void> cancelSession(String sessionId) async {
    final stillScheduled = sessions
        .any((s) => s.id == sessionId && s.status == SessionStatus.scheduled);
    if (!stillScheduled) return;
    await _db.from('sessions').delete().eq('id', sessionId);
    sessions.removeWhere((s) => s.id == sessionId && s.status == SessionStatus.scheduled);
  }

  static Future<void> setAttendance(
    String sessionId,
    String studentId,
    AttendanceStatus status,
  ) async {
    final i =
        attendances.indexWhere((a) => a.sessionId == sessionId && a.studentId == studentId);
    final row = await _db.from('attendances').upsert(
      {
        if (i != -1) 'id': attendances[i].id,
        'session_id': sessionId,
        'student_id': studentId,
        'status': _attendanceStatusToDb(status),
      },
      onConflict: 'session_id,student_id',
    ).select().single();
    final record = _attendanceFromRow(row);
    if (i == -1) {
      attendances.add(record);
    } else {
      attendances[i] = record;
    }
  }

  /// Supprime toutes les données métier du prof connecté — groupes,
  /// élèves, et tout ce qui en dépend (inscriptions, séances,
  /// présences, paiements) via les `on delete cascade` de
  /// 0001_init.sql. Ne touche jamais à la ligne teachers elle-même :
  /// le compte et son status restent intacts. Irréversible — voir la
  /// confirmation dans settings_screen.dart.
  static Future<void> deleteAllData() async {
    await _db.from('groups').delete().eq('teacher_id', _teacherId);
    await _db.from('students').delete().eq('teacher_id', _teacherId);
    groups.clear();
    students.clear();
    enrollments.clear();
    sessions.clear();
    attendances.clear();
    payments.clear();
  }

  static Future<Payment> recordCyclePayment(String studentId, {int cycleCount = 1}) async {
    final cycles = unpaidCycles(studentId).take(cycleCount).toList();
    final sessionsCovered = cycles.fold<int>(0, (s, c) => s + c.sessions);
    final amount = cycles.fold<double>(0, (s, c) => s + c.amount);
    final now = DateTime.now();
    final row = await _db.from('payments').insert({
      'student_id': studentId,
      'amount': amount,
      'paid_at': _dateToDb(now),
      'sessions_covered': sessionsCovered,
    }).select().single();
    final payment = _paymentFromRow(row);
    payments.add(payment);
    return payment;
  }
}
