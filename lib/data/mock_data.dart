import 'package:flutter/material.dart';

import '../models/models.dart';

/// Faux backend en mémoire, en attendant Supabase. La forme (groupes,
/// élèves, inscriptions, séances, présences, paiements) suit le schéma
/// SQL du README plutôt qu'une structure ad hoc : le solde n'est
/// JAMAIS stocké, il est recalculé depuis les présences et paiements à
/// chaque lecture — voir [ledgerFor] / [balanceFor], qui portent en
/// Dart la même logique que les vues `student_ledger` / `student_balance`
/// (README §7). C'est ce qui permet aux écrans de séance/paiement/
/// déplacement de se comporter correctement plutôt que d'être des
/// formulaires sans effet.
abstract final class MockData {
  static int _seq = 1000;
  static String _nextId(String prefix) => '$prefix${_seq++}';

  // ---------------------------------------------------------------------
  // Réglages prof — pour l'instant juste les niveaux/sections enseignés
  // (écran Réglages). Tout est sélectionné par défaut pour ne rien
  // casser des groupes existants tant que le prof n'a pas configuré ses
  // niveaux ; rien d'autre dans l'app ne filtre encore là-dessus.
  static final Set<Level> taughtLevels = {...Level.values};
  static final Set<Section> taughtSections = {...Section.values};

  static void setTaughtLevels(Set<Level> levels) {
    taughtLevels
      ..clear()
      ..addAll(levels);
    if (!levels.any((l) => l.hasSection)) {
      taughtSections.clear();
    }
  }

  static void setTaughtSections(Set<Section> sections) {
    taughtSections
      ..clear()
      ..addAll(sections);
  }

  static final List<Group> groups = [
    const Group(
      id: 'g1',
      level: Level.troisieme,
      section: null,
      pricePerSession: 25,
      weekday: 1, // lundi
      startTime: TimeOfDay(hour: 17, minute: 0),
    ),
    const Group(
      id: 'g2',
      level: Level.bac,
      section: Section.sciencesExp,
      pricePerSession: 35,
      weekday: 3, // mercredi
      startTime: TimeOfDay(hour: 18, minute: 30),
    ),
    const Group(
      id: 'g3',
      level: Level.bac,
      section: Section.maths,
      pricePerSession: 35,
      weekday: 5, // vendredi
      startTime: TimeOfDay(hour: 16, minute: 0),
    ),
    const Group(
      id: 'g4',
      level: Level.deuxieme,
      section: null,
      pricePerSession: 28,
      weekday: 2, // mardi
      startTime: TimeOfDay(hour: 15, minute: 30),
    ),
  ];

  static final List<Student> students = [
    const Student(
      id: 's1',
      name: 'Yassine Trabelsi',
      phone: '20123456',
      classLevel: Level.troisieme,
      classNumber: 2,
      school: 'Lycée Pilote de Tunis',
    ),
    const Student(
      id: 's2',
      name: 'Nour Bouazizi',
      phone: '25987654',
      classLevel: Level.troisieme,
      classNumber: 1,
      school: 'Lycée Pilote de Tunis',
    ),
    const Student(id: 's3', name: 'Mehdi Chaabane', phone: '22334455'),
    const Student(
      id: 's4',
      name: 'Sarra Gharbi',
      phone: '29112233',
      classLevel: Level.bac,
      classSection: Section.sciencesExp,
      classNumber: 3,
      school: 'Lycée Bourguiba',
    ),
    const Student(id: 's5', name: 'Wassim Belhaj', phone: '21445566'),
    const Student(
      id: 's6',
      name: 'Ines Mansour',
      phone: '23556677',
      // Section Maths au lycée, mais suit un groupe Bac Maths quand
      // même — exemple neutre. Voir s7 pour le cas "élève Maths dans
      // un groupe Technique".
      classLevel: Level.bac,
      classSection: Section.maths,
      classNumber: 1,
      school: 'Lycée Ariana',
    ),
    const Student(
      id: 's7',
      name: 'Ahmed Kammoun',
      phone: '24667788',
      // Section Maths au lycée mais inscrit dans le groupe Bac Maths
      // (g3) faute de groupe Technique disponible sur son créneau —
      // le classLabel garde la trace de sa vraie filière.
      classLevel: Level.bac,
      classSection: Section.technique,
      classNumber: 2,
      school: 'Lycée Ariana',
    ),
    const Student(id: 's8', name: 'Rania Jlassi', phone: '26778899'),
    const Student(id: 's9', name: 'Firas Aouadi', phone: '27889900'),
    // Rejoint g1 à sa 2e séance : démontre le cycle raccourci (3 au
    // lieu de 4) qui la resynchronise avec le reste du groupe.
    const Student(id: 's10', name: 'Yassmine Karoui', phone: '28901234'),
  ];

  static final List<Enrollment> enrollments = [
    Enrollment(id: 'e1', studentId: 's1', groupId: 'g1', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e2', studentId: 's2', groupId: 'g1', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e3', studentId: 's3', groupId: 'g1', joinedAt: _daysAgo(90)),
    Enrollment(id: 'e4', studentId: 's4', groupId: 'g2', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e5', studentId: 's5', groupId: 'g2', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e7', studentId: 's6', groupId: 'g3', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e8', studentId: 's7', groupId: 'g3', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e9', studentId: 's8', groupId: 'g3', joinedAt: _daysAgo(120)),
    Enrollment(id: 'e10', studentId: 's9', groupId: 'g4', joinedAt: _daysAgo(10)),
    Enrollment(id: 'e11', studentId: 's10', groupId: 'g1', joinedAt: _daysAgo(22)),
  ];

  static final List<Session> sessions = [
    Session(id: 'se1', groupId: 'g1', date: _daysAgo(28), price: 25),
    Session(id: 'se2', groupId: 'g1', date: _daysAgo(21), price: 25),
    Session(id: 'se3', groupId: 'g1', date: _daysAgo(14), price: 25),
    Session(id: 'se4', groupId: 'g1', date: _daysAgo(5), price: 25),
    Session(id: 'se5', groupId: 'g2', date: _daysAgo(21), price: 35),
    Session(id: 'se6', groupId: 'g2', date: _daysAgo(14), price: 35),
    Session(id: 'se7', groupId: 'g2', date: _daysAgo(7), price: 35),
    Session(id: 'se8', groupId: 'g3', date: _daysAgo(24), price: 35),
    Session(id: 'se9', groupId: 'g3', date: _daysAgo(17), price: 35),
    Session(id: 'se10', groupId: 'g3', date: _daysAgo(10), price: 35),
    Session(id: 'se11', groupId: 'g3', date: _daysAgo(3), price: 35),
    // Séances programmées (pas encore tenues) — alimente l'onglet
    // "Séances", groupées par jour (voir sessions_screen.dart).
    Session(
      id: 'se12',
      groupId: 'g1',
      date: _daysFromNow(0),
      startTime: const TimeOfDay(hour: 17, minute: 0),
      price: 25,
      status: SessionStatus.scheduled,
    ),
    Session(
      id: 'se13',
      groupId: 'g2',
      date: _daysFromNow(0),
      startTime: const TimeOfDay(hour: 18, minute: 30),
      price: 35,
      status: SessionStatus.scheduled,
    ),
    Session(
      id: 'se14',
      groupId: 'g3',
      date: _daysFromNow(2),
      startTime: const TimeOfDay(hour: 16, minute: 0),
      price: 35,
      status: SessionStatus.scheduled,
    ),
  ];

  static final List<Attendance> attendances = [
    // g1 : quatre séances, s3 absent non justifié une fois (facturable
    // quand même) — le reste présent.
    for (final s in ['se1', 'se2', 'se3'])
      ..._presentFor(s, ['s1', 's2', 's3']),
    const Attendance(id: 'a_se4_s1', sessionId: 'se4', studentId: 's1', status: AttendanceStatus.present),
    const Attendance(id: 'a_se4_s2', sessionId: 'se4', studentId: 's2', status: AttendanceStatus.present),
    const Attendance(id: 'a_se4_s3', sessionId: 'se4', studentId: 's3', status: AttendanceStatus.absentUnjustified),
    // s10 rejoint à se2 (2e séance du groupe) : cycle 1 = se2+se3+se4
    // (3 séances), pas 4 — voir ledgerFor.
    const Attendance(id: 'a_se2_s10', sessionId: 'se2', studentId: 's10', status: AttendanceStatus.present),
    const Attendance(id: 'a_se3_s10', sessionId: 'se3', studentId: 's10', status: AttendanceStatus.present),
    const Attendance(id: 'a_se4_s10', sessionId: 'se4', studentId: 's10', status: AttendanceStatus.present),

    // g2
    for (final s in ['se5', 'se6', 'se7']) ..._presentFor(s, ['s4', 's5']),

    // g3 : s8 absente justifiée sur la plus ancienne (non facturable).
    const Attendance(id: 'a_se8_s6', sessionId: 'se8', studentId: 's6', status: AttendanceStatus.present),
    const Attendance(id: 'a_se8_s7', sessionId: 'se8', studentId: 's7', status: AttendanceStatus.present),
    const Attendance(id: 'a_se8_s8', sessionId: 'se8', studentId: 's8', status: AttendanceStatus.absentJustified),
    for (final s in ['se9', 'se10', 'se11']) ..._presentFor(s, ['s6', 's7', 's8']),
  ];

  // Un paiement couvre toujours un cycle complet (4 séances, ou la
  // taille du premier cycle raccourci d'un élève arrivé en cours de
  // route) — jamais un compte partiel arbitraire. Voir
  // recordCyclePayment et record_payment_sheet.dart, qui n'offrent
  // plus que ce choix.
  static final List<Payment> payments = [
    Payment(id: 'p1', studentId: 's2', amount: 100, paidAt: _daysAgo(15), sessionsCovered: 4),
    Payment(id: 'p4', studentId: 's6', amount: 140, paidAt: _daysAgo(15), sessionsCovered: 4),
    Payment(id: 'p5', studentId: 's7', amount: 140, paidAt: _daysAgo(15), sessionsCovered: 4),
  ];

  static DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));
  static DateTime _daysFromNow(int days) => DateTime.now().add(Duration(days: days));

  static List<Attendance> _presentFor(String sessionId, List<String> studentIds) => [
        for (final id in studentIds)
          Attendance(
            id: 'a_${sessionId}_$id',
            sessionId: sessionId,
            studentId: id,
            status: AttendanceStatus.present,
          ),
      ];

  // ---------------------------------------------------------------------
  // Requêtes
  // ---------------------------------------------------------------------

  /// Les suspendus restent dans la liste (juste en bas, voir
  /// [suspendStudent]) — seule une suppression les retire vraiment.
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

  /// Rang chronologique (1-based) d'une séance parmi les séances
  /// `done` de son groupe — c'est l'horloge sur laquelle les cycles de
  /// facturation sont calés, pas l'assiduité propre de chaque élève.
  static int _groupSessionIndex(String groupId, String sessionId) {
    final groupSessions = sessions
        .where((s) => s.groupId == groupId && s.status == SessionStatus.done)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return groupSessions.indexWhere((s) => s.id == sessionId) + 1;
  }

  /// Port Dart de la vue SQL `student_ledger` (README §7), étendu pour
  /// que tous les élèves d'un groupe soient dus au même moment plutôt
  /// que chacun sur son propre compteur de 4 depuis son inscription.
  ///
  /// Le cycle de facturation est calé sur le rang de la séance dans le
  /// GROUPE, pas sur le nombre de séances propres à l'élève : un élève
  /// qui rejoint à la 2e séance d'un cycle n'a que 3 séances à payer
  /// pour boucler ce premier cycle (séances 2, 3, 4 du groupe), puis
  /// retombe sur des cycles pleins de 4, synchronisés avec le reste du
  /// groupe.
  ///
  /// Un élève n'est jamais inscrit que dans un seul groupe à la fois
  /// (voir [enrollStudent]), mais son historique peut traverser
  /// plusieurs groupes dans le temps via [moveStudent] — d'où le
  /// regroupement par groupId ici : chaque segment de son parcours a
  /// son propre calage de cycle, et le ledger final reste fusionné et
  /// trié par date.
  static List<LedgerLine> ledgerFor(String studentId) {
    // Regroupe par INSCRIPTION, pas juste par groupe : un élève qui
    // quitte un groupe puis y revient plus tard (enrollStudent crée une
    // nouvelle Enrollment, l'ancienne reste fermée avec son leftAt) a
    // deux passages distincts, chacun avec son propre calage de cycle.
    // Grouper par groupId seul mélangeait le reliquat abandonné du
    // premier passage avec les séances du second — le premier passage
    // redevenait "encore inscrit" dès le retour et son cycle interrompu
    // ne se refermait plus jamais tout seul (cas Wassim Belhaj : 5
    // séances Bac SC, 2 Bac Math, retour Bac SC — sans ce découpage le
    // reliquat de 1 séance du premier passage Bac SC restait ouvert et
    // se faisait absorber dans le cycle du second passage).
    final studentEnrollments = enrollments.where((e) => e.studentId == studentId).toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    final byEnrollment = <String, List<({DateTime date, double price, String sessionId})>>{};
    for (final a in attendances.where((a) => a.studentId == studentId && a.isBillable)) {
      final session = sessions.firstWhere((s) => s.id == a.sessionId);
      if (session.status != SessionStatus.done) continue;
      // Comparaison en jour civil, pas en instant exact : joinedAt/leftAt
      // portent l'heure réelle du clic (DateTime.now()), alors qu'une
      // séance porte l'heure fixe du créneau du groupe — les deux
      // peuvent diverger sur un même jour (ex. déplacé à 23h, séance de
      // 10h ce jour-là) et faisaient sinon rattacher la séance du
      // retour à l'ancienne inscription au lieu de la nouvelle.
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
      // A quitté ce groupe pendant CE passage précis (voir moveStudent) :
      // plus aucune séance n'y viendra jamais pour cet élève tant qu'il
      // n'est pas revenu, donc le cycle en cours de ce passage ne doit
      // pas attendre que le groupe atteigne sa 4e séance pour se
      // boucler — sinon il resterait facturé d'avance pour des séances
      // qu'il n'aura jamais eues à ce passage-là.
      final stillEnrolled = enrollment.isActive;

      // Cale les cycles sur le rang calendaire de chaque séance dans le
      // groupe (_groupSessionIndex), pas sur un simple compte des lignes
      // facturables restantes : une absence justifiée saute une ligne
      // sans sauter de rang, et compter les lignes au lieu des rangs
      // faisait dériver les bornes de cycle — jusqu'à sur-facturer le
      // cycle en cours (deux absences justifiées sur deux mois
      // différents faisaient demander une séance de trop en tout).
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
        // Un cycle n'est "bouclé" que si le groupe a bien dépassé ses 4
        // séances calendaires — pas dès que l'élève a cumulé assez de
        // lignes facturables, sinon une absence justifiée empêcherait
        // jamais un cycle amputé d'une séance de se refermer.
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

  /// Historique complet des séances d'un élève, contrairement à
  /// [ledgerFor] qui ne garde que les séances facturables (présent ou
  /// absent non justifié) — ici une absence justifiée apparaît aussi,
  /// avec [isPaid] à null puisque la question ne se pose pas pour une
  /// séance jamais facturée.
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

    final ledger = ledgerFor(studentId);
    final unpaid = ledger.where((l) => !l.isPaid).toList();

    // Dû dès la première séance impayée du cycle en cours — un élève
    // peut régler d'avance en plein mois, pas besoin d'attendre que le
    // groupe boucle les 4 séances (voir unpaidCycles, qui facture le
    // cycle entier même si seules 1-3 séances ont déjà eu lieu).
    final isDue = unpaid.isNotEmpty;

    return StudentBalance(
      studentId: studentId,
      unpaidSessions: unpaid.length,
      amountDue: unpaid.fold<double>(0, (s, l) => s + l.price),
      isDue: isDue,
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

  /// Séances (tenues ou programmées, pas annulées) tombant dans la
  /// semaine calendaire courante (lundi -> dimanche).
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

  /// `groups` a toujours 0 ou 1 élément : un élève n'est jamais inscrit
  /// que dans un seul groupe actif à la fois (voir [enrollStudent]).
  /// Compte aussi les suspendus et gratuits — la suspension ne change
  /// rien à une dette déjà due (voir [suspendStudent]), et un élève
  /// gratuit n'est de toute façon jamais "dû" (voir [balanceFor]).
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

  // ---------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------

  /// [groupNumber] n'est jamais un paramètre ici : dès qu'un groupe de
  /// même niveau/section existe déjà, celui-ci ET le nouveau reçoivent
  /// un numéro (le premier existant est renuméroté 1 rétroactivement
  /// s'il n'en avait pas encore) — voir Group.groupNumber. Avec un
  /// seul groupe du genre, pas de numéro : rien à distinguer.
  static Group createGroup({
    required Level level,
    Section? section,
    String? note,
    required double pricePerSession,
    required int weekday,
    required TimeOfDay startTime,
    int durationMinutes = 120,
  }) {
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
        groups[i] = groups[i].copyWith(groupNumber: 1);
      }
    }

    final group = Group(
      id: _nextId('g'),
      level: level,
      section: section,
      groupNumber: groupNumber,
      note: note,
      pricePerSession: pricePerSession,
      weekday: weekday,
      startTime: startTime,
      durationMinutes: durationMinutes,
    );
    groups.add(group);
    return group;
  }

  static void updateGroup(Group updated) {
    final i = groups.indexWhere((g) => g.id == updated.id);
    if (i != -1) groups[i] = updated;
  }

  static Student createStudent({
    required String name,
    String? phone,
    String? parentPhone,
    Level? classLevel,
    Section? classSection,
    int? classNumber,
    String? school,
    bool isFree = false,
  }) {
    final student = Student(
      id: _nextId('s'),
      name: name,
      phone: phone,
      parentPhone: parentPhone,
      classLevel: classLevel,
      classSection: classSection,
      classNumber: classNumber,
      school: school,
      isFree: isFree,
    );
    students.add(student);
    return student;
  }

  static void updateStudent(Student updated) {
    final i = students.indexWhere((s) => s.id == updated.id);
    if (i != -1) students[i] = updated;
  }

  /// Un élève n'est jamais inscrit que dans un seul groupe actif à la
  /// fois — retourne false s'il en a déjà un (peu importe lequel), y
  /// compris suspendu (la suspension ne ferme pas l'inscription, voir
  /// [suspendStudent]). Passer par [moveStudent] pour le changer de
  /// groupe. Refuse aussi si le niveau réel de l'élève ne correspond
  /// pas à celui du groupe — filet de sécurité, l'UI (add_student_sheet)
  /// verrouille déjà le niveau sur celui du groupe à la création.
  static bool enrollStudent(String studentId, String groupId) {
    final alreadyEnrolled = enrollments.any((e) => e.studentId == studentId && e.isActive);
    if (alreadyEnrolled) return false;
    final student = studentById(studentId);
    final group = groupById(groupId);
    if (student?.classLevel != null && group != null && student!.classLevel != group.level) {
      return false;
    }
    enrollments.add(Enrollment(
      id: _nextId('e'),
      studentId: studentId,
      groupId: groupId,
      joinedAt: DateTime.now(),
    ));
    return true;
  }

  /// Port de `move_student()` (README §6) : ferme l'inscription active
  /// dans [fromGroupId] et en ouvre une nouvelle dans [toGroupId]. Les
  /// séances impayées suivent l'élève automatiquement puisque le
  /// ledger est calculé par élève, jamais par couple élève/groupe.
  static void moveStudent(String studentId, String fromGroupId, String toGroupId) {
    final i = enrollments.indexWhere(
      (e) => e.studentId == studentId && e.groupId == fromGroupId && e.isActive,
    );
    if (i != -1) {
      enrollments[i] = enrollments[i].close(DateTime.now());
    }
    enrollStudent(studentId, toGroupId);
  }

  /// Met l'élève en pause : son inscription reste active (il ne peut
  /// donc pas être inscrit ailleurs entre-temps) mais il tombe en bas
  /// de studentsForGroup et sort du décompte "actif" — voir
  /// [Student.suspendedAt]. Réversible via [reactivateStudent].
  static void suspendStudent(String studentId) {
    final i = students.indexWhere((s) => s.id == studentId);
    if (i != -1) {
      students[i] = students[i].copyWith(suspendedAt: DateTime.now());
    }
  }

  static void reactivateStudent(String studentId) {
    final i = students.indexWhere((s) => s.id == studentId);
    if (i != -1) {
      students[i] = students[i].copyWith(clearSuspendedAt: true);
    }
  }

  /// Refuse si des séances restent impayées, comme `delete_student()`
  /// côté SQL (README §6). Retourne false dans ce cas plutôt que de
  /// lever une exception — c'est à l'appelant de décider quoi afficher.
  static bool deleteStudent(String studentId) {
    if (balanceFor(studentId).unpaidSessions > 0) return false;
    students.removeWhere((s) => s.id == studentId);
    enrollments.removeWhere((e) => e.studentId == studentId);
    attendances.removeWhere((a) => a.studentId == studentId);
    payments.removeWhere((p) => p.studentId == studentId);
    return true;
  }

  /// Refuse si des élèves (actifs ou suspendus) sont encore inscrits —
  /// il faut d'abord les déplacer ou les supprimer, comme pour
  /// [deleteStudent] avec les impayés. Les séances déjà tenues restent
  /// en historique (le ledger des élèves concernés y fait toujours
  /// référence — groupById retombe alors sur "Groupe supprimé" côté
  /// UI) ; seules les séances encore programmées pour ce groupe sont
  /// nettoyées, elles n'ont aucune présence ni facturation attachée.
  static bool deleteGroup(String groupId) {
    if (studentsForGroup(groupId).isNotEmpty) return false;
    groups.removeWhere((g) => g.id == groupId);
    sessions.removeWhere((s) => s.groupId == groupId && s.status == SessionStatus.scheduled);
    return true;
  }

  /// [status] est requis explicitement — pas de valeur par défaut —
  /// pour qu'on ne puisse pas créer une séance "done" par inadvertance
  /// sans être passé par la prise de présence.
  static Session createSession({
    required String groupId,
    required DateTime date,
    TimeOfDay? startTime,
    bool isRescheduled = false,
    required double price,
    required SessionStatus status,
  }) {
    final session = Session(
      id: _nextId('se'),
      groupId: groupId,
      date: date,
      startTime: startTime,
      isRescheduled: isRescheduled,
      status: status,
      price: price,
    );
    sessions.add(session);
    return session;
  }

  /// Corrige la date/l'heure d'une séance programmée — sans effet si
  /// elle n'est plus "scheduled" (une séance tenue est déjà actée pour
  /// la facturation, voir ledgerFor/_groupSessionIndex : la déplacer
  /// après coup romprait le calage des cycles pour tout le groupe).
  static Session? updateSession(
    String sessionId, {
    required DateTime date,
    TimeOfDay? startTime,
    required bool isRescheduled,
  }) {
    final i = sessions.indexWhere((s) => s.id == sessionId);
    if (i == -1 || sessions[i].status != SessionStatus.scheduled) return null;
    final updated = sessions[i].copyWith(
      date: date,
      startTime: startTime,
      isRescheduled: isRescheduled,
    );
    sessions[i] = updated;
    return updated;
  }

  /// Programmée -> tenue. Appelé en enregistrant les présences d'une
  /// séance programmée (voir AttendanceScreen) ; sans effet si la
  /// séance est déjà "done".
  static void markSessionDone(String sessionId) {
    final i = sessions.indexWhere((s) => s.id == sessionId);
    if (i != -1 && sessions[i].status == SessionStatus.scheduled) {
      sessions[i] = sessions[i].copyWith(status: SessionStatus.done);
    }
  }

  /// Supprime une séance programmée. Comme [markSessionDone], sans effet
  /// si la séance n'est plus "scheduled" — une séance déjà tenue ne
  /// s'annule pas après coup, ses présences/facturation sont déjà actées.
  static void cancelSession(String sessionId) {
    sessions.removeWhere(
      (s) => s.id == sessionId && s.status == SessionStatus.scheduled,
    );
  }

  /// Séances programmées, toutes groupes confondus, triées par date —
  /// c'est la file d'attente "à faire" de la page Séances.
  static List<Session> scheduledSessions() {
    final list = sessions.where((s) => s.status == SessionStatus.scheduled).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Upsert idempotent : la contrainte unique `(session_id, student_id)`
  /// autorise à corriger une présence après coup (README §9.2).
  static void setAttendance(String sessionId, String studentId, AttendanceStatus status) {
    final i = attendances.indexWhere(
      (a) => a.sessionId == sessionId && a.studentId == studentId,
    );
    final record = Attendance(
      id: i == -1 ? _nextId('a') : attendances[i].id,
      sessionId: sessionId,
      studentId: studentId,
      status: status,
    );
    if (i == -1) {
      attendances.add(record);
    } else {
      attendances[i] = record;
    }
  }

  /// Cycles impayés, encaissables un cycle entier à la fois — jamais un
  /// compte de séances choisi à la main. Un élève peut régler en plein
  /// mois, dès la 1ère ou 2e séance du cycle : le cycle en cours (pas
  /// encore bouclé côté groupe) est donc inclus lui aussi, pour la
  /// totalité de ses séances (4, ou moins pour un premier cycle
  /// raccourci) — pas seulement celles déjà tenues. `sessionsCovered`
  /// sur le paiement qui en résulte "réserve" les séances pas encore
  /// jouées : quand elles auront lieu, leurs lignes de ledger tomberont
  /// automatiquement dans les séances déjà couvertes (voir ledgerFor).
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
    // Le cycle en cours n'a pas été bouclé par l'assiduité (sinon il
    // aurait déjà été ajouté ci-dessus), mais il reste facturable dès
    // maintenant pour le reste de ses séances — moins celles déjà
    // connues comme absence justifiée dans ce même cycle : inutile
    // d'attendre que le cycle se boucle pour les déduire, on sait déjà
    // qu'elles ne seront jamais facturables.
    if (count > 0 && cycleSize != null && pricePerSession != null && groupId != null) {
      final cycleNumber = (_groupSessionIndex(groupId, sessionId!) - 1) ~/ 4;
      final justified = _justifiedAbsencesInCycle(studentId, groupId, cycleNumber);
      final billable = (cycleSize - justified).clamp(0, cycleSize);
      cycles.add((sessions: billable, amount: billable * pricePerSession));
    }
    return cycles;
  }

  /// Absences justifiées déjà connues dans le bloc calendaire d'un
  /// cycle donné (séances `done` du groupe dont le rang tombe dans ce
  /// bloc de 4) — sert à ne pas facturer d'avance une séance dont on
  /// sait déjà qu'elle ne sera jamais facturable.
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

  /// Encaisse les [cycleCount] plus anciens cycles impayés — jamais un
  /// nombre de séances choisi à la main.
  static Payment recordCyclePayment(String studentId, {int cycleCount = 1}) {
    final cycles = unpaidCycles(studentId).take(cycleCount).toList();
    final sessions = cycles.fold<int>(0, (s, c) => s + c.sessions);
    final amount = cycles.fold<double>(0, (s, c) => s + c.amount);
    final payment = Payment(
      id: _nextId('p'),
      studentId: studentId,
      amount: amount,
      paidAt: DateTime.now(),
      sessionsCovered: sessions,
    );
    payments.add(payment);
    return payment;
  }
}
