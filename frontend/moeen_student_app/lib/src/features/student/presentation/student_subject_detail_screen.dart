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
            length: 5,
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
                          _Metric('الحضور', '${text(progress, 'attendance_percentage', fallback: '0')}%', Icons.fact_check_rounded, AppColors.success),
                          _Metric('الغياب', text(progress, 'absences', fallback: '0'), Icons.person_off_rounded, AppColors.danger),
                          _Metric('أعمال السنة', _gradeLabel(continuous), Icons.leaderboard_rounded, const Color(0xFF7C3AED)),
                          _Metric('النهائي', _gradeLabel(finalGrade), Icons.workspace_premium_rounded, const Color(0xFFBE123C)),
                          if (grades['total_percentage'] != null)
                            _Metric('المعدل الكلي', '${grades['total_percentage']}%', Icons.analytics_rounded, AppColors.royalBlue),
                          _Metric('الأعذار', text(progress, 'excused', fallback: '0'), Icons.verified_rounded, AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DeprivationCard(info: deprivation),
                    ],
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
                          (item) =>
                              _AttendanceTile(asMap(item), subjectId: subjectId),
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
