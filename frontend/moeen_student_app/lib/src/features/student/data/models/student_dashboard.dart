class StudentDashboard {
  const StudentDashboard({
    required this.overview,
    required this.alerts,
    required this.feed,
    this.nextExam,
  });

  final StudentOverview overview;
  final NextExam? nextExam;
  final StudentAlerts alerts;
  final StudentFeed feed;

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      overview: StudentOverview.fromJson(
        json['overview'] as Map<String, dynamic>? ?? const {},
      ),
      nextExam: json['next_exam'] == null
          ? null
          : NextExam.fromJson(json['next_exam'] as Map<String, dynamic>),
      alerts: StudentAlerts.fromJson(
        json['alerts'] as Map<String, dynamic>? ?? const {},
      ),
      feed: StudentFeed.fromJson(
        json['feed'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class StudentOverview {
  const StudentOverview({
    required this.activeAssignmentsCount,
    required this.totalAbsencesDays,
    required this.registeredSubjectsCount,
    required this.hasClinical,
  });

  final int activeAssignmentsCount;
  final int totalAbsencesDays;
  final int registeredSubjectsCount;
  final bool hasClinical;

  factory StudentOverview.fromJson(Map<String, dynamic> json) {
    return StudentOverview(
      activeAssignmentsCount: _int(json['active_assignments_count']),
      totalAbsencesDays: _int(json['total_absences_days']),
      registeredSubjectsCount: _int(json['registered_subjects_count']),
      hasClinical: json['has_clinical'] == true,
    );
  }
}

class NextExam {
  const NextExam({
    required this.subjectName,
    required this.examDate,
    required this.startTime,
    required this.daysRemaining,
    required this.isToday,
    this.location,
  });

  final String subjectName;
  final String examDate;
  final String startTime;
  final String? location;
  final int daysRemaining;
  final bool isToday;

  factory NextExam.fromJson(Map<String, dynamic> json) {
    return NextExam(
      subjectName: (json['subject_name'] ?? '').toString(),
      examDate: (json['exam_date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      location: json['location']?.toString(),
      daysRemaining: _int(json['days_remaining']),
      isToday: json['is_today'] == true,
    );
  }
}

class StudentAlerts {
  const StudentAlerts({
    required this.deprivationWarnings,
    required this.excuseDeadlines,
  });

  final List<DeprivationWarning> deprivationWarnings;
  final List<ExcuseDeadlineWarning> excuseDeadlines;

  factory StudentAlerts.fromJson(Map<String, dynamic> json) {
    return StudentAlerts(
      deprivationWarnings: _list(
        json['deprivation_warnings'],
      ).map(DeprivationWarning.fromJson).toList(),
      excuseDeadlines: _list(
        json['excuse_deadlines'],
      ).map(ExcuseDeadlineWarning.fromJson).toList(),
    );
  }
}

class DeprivationWarning {
  const DeprivationWarning({
    required this.subjectName,
    required this.absencesCount,
    required this.maxAllowed,
    required this.status,
    required this.message,
  });

  final String subjectName;
  final int absencesCount;
  final int maxAllowed;
  final String status;
  final String message;

  factory DeprivationWarning.fromJson(Map<String, dynamic> json) {
    return DeprivationWarning(
      subjectName: (json['subject_name'] ?? json['subject'] ?? '').toString(),
      absencesCount: _int(json['absences_count'] ?? json['absences']),
      maxAllowed: _int(json['max_allowed'] ?? json['max']),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class ExcuseDeadlineWarning {
  const ExcuseDeadlineWarning({
    required this.date,
    required this.subject,
    required this.message,
  });

  final String date;
  final String subject;
  final String message;

  factory ExcuseDeadlineWarning.fromJson(Map<String, dynamic> json) {
    return ExcuseDeadlineWarning(
      date: (json['date'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class StudentFeed {
  const StudentFeed({required this.announcements, required this.reminders});

  final List<DashboardAnnouncement> announcements;
  final List<DashboardReminder> reminders;

  factory StudentFeed.fromJson(Map<String, dynamic> json) {
    return StudentFeed(
      announcements: _list(
        json['announcements'],
      ).map(DashboardAnnouncement.fromJson).toList(),
      reminders: _list(
        json['reminders'],
      ).map(DashboardReminder.fromJson).toList(),
    );
  }
}

class DashboardAnnouncement {
  const DashboardAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String content;
  final String createdAt;

  factory DashboardAnnouncement.fromJson(Map<String, dynamic> json) {
    return DashboardAnnouncement(
      id: _int(json['id']),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? json['message'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class DashboardReminder {
  const DashboardReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.location,
  });

  final int id;
  final String title;
  final String description;
  final String eventDate;
  final String? location;

  factory DashboardReminder.fromJson(Map<String, dynamic> json) {
    return DashboardReminder(
      id: _int(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      eventDate: (json['event_date'] ?? '').toString(),
      location: json['location']?.toString(),
    );
  }
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;
