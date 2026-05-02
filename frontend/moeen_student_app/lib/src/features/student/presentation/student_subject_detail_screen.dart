part of 'student_content_screens.dart';

class StudentSubjectDetailsScreen extends ConsumerWidget {
  const StudentSubjectDetailsScreen({super.key, required this.subjectId});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_subjectDetailsProvider(subjectId));
    return StudentShell(
      currentIndex: 3,
      title: 'تفاصيل المقرر',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_subjectDetailsProvider(subjectId)),
        builder: (data) {
          final subject = asMap(data['subject']);
          final doctor = asMap(subject['doctor']);
          final term = asMap(subject['term']);
          final semester = asMap(subject['semester']);
          final resources = asList(subject['resources']);
          final grades = asMap(data['grades']);
          final continuous = asMap(grades['continuous']);
          final finalGrade = asMap(grades['final']);
          final progress = asMap(data['progress']);
          final deprivation = asMap(data['deprivation_info']);
          final lectures = asList(data['lectures']);
          final assignments = asList(data['assignments']);
          final attendance = asList(data['attendance_history']);

          return DefaultTabController(
            length: 6,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _SubjectDetailHeader(
                    subject: subject,
                    doctor: doctor,
                    term: term,
                    semester: semester,
                    progress: progress,
                    totalLectures: lectures.length,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: AppColors.slate50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.slate600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.royalBlue,
                        ),
                        tabs: const [
                          Tab(text: 'نظرة عامة'),
                          Tab(text: 'الدرجات'),
                          Tab(text: 'المحاضرات'),
                          Tab(text: 'التكاليف'),
                          Tab(text: 'المصادر'),
                          Tab(text: 'سجل الحضور'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  // Overview Tab
                  _TabContent(
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                    children: [
                      _MetricGrid(
                        items: [
                          _Metric(
                            'الحضور',
                            '${text(progress, 'attendance_percentage', fallback: '0')}%',
                            Icons.fact_check_rounded,
                            AppColors.success,
                          ),
                          _Metric(
                            'الغياب',
                            text(progress, 'absences', fallback: '0'),
                            Icons.person_off_rounded,
                            AppColors.danger,
                          ),
                          _Metric(
                            'أعمال السنة',
                            _gradeLabel(continuous),
                            Icons.leaderboard_rounded,
                            const Color(0xFF7C3AED),
                          ),
                          _Metric(
                            'النهائي',
                            _gradeLabel(finalGrade),
                            Icons.workspace_premium_rounded,
                            const Color(0xFFBE123C),
                          ),
                          if (grades['total_percentage'] != null)
                            _Metric(
                              'المعدل الكلي',
                              '${grades['total_percentage']}%',
                              Icons.analytics_rounded,
                              AppColors.royalBlue,
                            ),
                          _Metric(
                            'الأعذار',
                            text(progress, 'excused', fallback: '0'),
                            Icons.verified_rounded,
                            AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DeprivationCard(info: deprivation),
                    ],
                  ),
                  // Grades Tab
                  _GradesTab(
                    grades: grades,
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                  ),
                  // Lectures Tab
                  _TabList(
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                    isEmpty: lectures.isEmpty,
                    emptyMessage: 'لا توجد محاضرات لهذا المقرر حالياً.',
                    children: lectures
                        .map(
                          (item) =>
                              _LectureTile(asMap(item), subjectId: subjectId),
                        )
                        .toList(),
                  ),
                  // Assignments Tab
                  _TabList(
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                    isEmpty: assignments.isEmpty,
                    emptyMessage: 'لا توجد تكاليف مرتبطة بهذا المقرر.',
                    children: assignments
                        .map((item) => _AssignmentTile(asMap(item)))
                        .toList(),
                  ),
                  // Resources Tab
                  _TabList(
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                    isEmpty: resources.isEmpty,
                    emptyMessage: 'لا توجد مصادر تعليمية متوفرة لهذا المقرر.',
                    children: resources
                        .map((item) => _ResourceMiniTile(asMap(item)))
                        .toList(),
                  ),
                  // Attendance History Tab
                  _TabList(
                    onRefresh: () async =>
                        ref.invalidate(_subjectDetailsProvider(subjectId)),
                    isEmpty: attendance.isEmpty,
                    emptyMessage: 'لا يوجد سجل حضور مسجل لهذه المادة.',
                    children: attendance
                        .map(
                          (item) => _AttendanceTile(
                            asMap(item),
                            subjectId: subjectId,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({required this.grades, required this.onRefresh});

  final Map<String, dynamic> grades;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final items = asList(grades['items']);
    final summary = asMap(grades['summary']);
    final totalScore = text(grades, 'total_score', fallback: '0');
    final maxPossible = text(grades, 'max_possible', fallback: '0');
    final percentage = text(grades, 'total_percentage', fallback: '-');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF172B4D),
                  Color(0xFF406AB4),
                  Color(0xFFF1C63B),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.grade_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'درجات المقرر',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'تفصيل الدرجات حسب التقسيم الذي حدده دكتور المادة.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _GradeHeroMetric(
                        'المجموع',
                        '$totalScore / $maxPossible',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradeHeroMetric(
                        'النسبة',
                        percentage == '-' ? '-' : '$percentage%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            items: [
              _Metric(
                'المدخلة',
                text(summary, 'entered_count', fallback: '0'),
                Icons.edit_note_rounded,
                AppColors.royalBlue,
              ),
              _Metric(
                'المعتمدة',
                text(summary, 'approved_count', fallback: '0'),
                Icons.verified_rounded,
                AppColors.success,
              ),
              _Metric(
                'قيد المراجعة',
                text(summary, 'pending_count', fallback: '0'),
                Icons.hourglass_top_rounded,
                AppColors.warning,
              ),
              _Metric(
                'غير مرصودة',
                text(summary, 'not_entered_count', fallback: '0'),
                Icons.pending_actions_rounded,
                AppColors.slate500,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const EmptyState(
              message: 'لم يتم إنشاء تقسيم درجات أو رصد درجات لهذه المادة بعد.',
            )
          else
            ...items.map((raw) => _GradeBreakdownCard(asMap(raw))),
        ],
      ),
    );
  }
}

class _GradeHeroMetric extends StatelessWidget {
  const _GradeHeroMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBreakdownCard extends StatelessWidget {
  const _GradeBreakdownCard(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final status = text(item, 'status', fallback: 'not_entered');
    final color = switch (status) {
      'approved' => AppColors.success,
      'pending' => AppColors.warning,
      'rejected' => AppColors.danger,
      _ => AppColors.slate500,
    };
    final score = item['score'] == null ? '-' : text(item, 'score');
    final max = text(item, 'max_score', fallback: '0');
    final percentage = item['percentage'] == null
        ? '-'
        : '${text(item, 'percentage')}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_gradeTypeIcon(text(item, 'type')), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(item, 'name', fallback: 'درجة'),
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'الحالة: ${_gradeStatusLabel(status)}${text(item, 'created_by').isNotEmpty ? ' • بواسطة ${text(item, 'created_by')}' : ''}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score / $max',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _gradeTypeIcon(String type) {
  return switch (type) {
    'final' => Icons.workspace_premium_rounded,
    'category' => Icons.category_rounded,
    'general_continuous' => Icons.leaderboard_rounded,
    _ => Icons.grade_rounded,
  };
}

String _gradeStatusLabel(String status) {
  return switch (status) {
    'approved' => 'معتمدة',
    'pending' => 'قيد المراجعة',
    'rejected' => 'مرفوضة',
    'not_entered' => 'لم ترصد بعد',
    _ => status,
  };
}

class _SubjectDetailHeader extends StatelessWidget {
  const _SubjectDetailHeader({
    required this.subject,
    required this.doctor,
    required this.term,
    required this.semester,
    required this.progress,
    required this.totalLectures,
  });

  final Map<String, dynamic> subject;
  final Map<String, dynamic> doctor;
  final Map<String, dynamic> term;
  final Map<String, dynamic> semester;
  final Map<String, dynamic> progress;
  final int totalLectures;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(subject, 'name', fallback: 'مقرر'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'د. ${text(doctor, 'name', fallback: 'لم يحدد')} • ${text(term, 'name', fallback: '')} ${text(semester, 'name', fallback: '')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStatDetail(
                label: 'نسبة الحضور',
                value:
                    '${text(progress, 'attendance_percentage', fallback: '0')}%',
              ),
              _HeaderStatDetail(
                label: 'الغياب',
                value: text(progress, 'absences', fallback: '0'),
              ),
              _HeaderStatDetail(
                label: 'المحاضرات',
                value: totalLectures.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStatDetail extends StatelessWidget {
  const _HeaderStatDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.onRefresh, required this.children});
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(padding: const EdgeInsets.all(20), children: children),
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({
    required this.onRefresh,
    required this.isEmpty,
    required this.emptyMessage,
    required this.children,
  });
  final Future<void> Function() onRefresh;
  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: 400,
                alignment: Alignment.center,
                child: EmptyState(message: emptyMessage),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: children.length,
              itemBuilder: (context, index) =>
                  _EntryAnimation(index: index, child: children[index]),
            ),
    );
  }
}
