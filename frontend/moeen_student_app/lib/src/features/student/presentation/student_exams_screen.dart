part of 'student_content_screens.dart';

class StudentExamsScreen extends ConsumerWidget {
  const StudentExamsScreen({super.key});

  static const route = '/student/exams';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_examsProvider);
    return StudentShell(
      currentIndex: 10,
      title: 'جداول الاختبارات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_examsProvider),
        builder: (data) {
          final schedules = asList(data['schedules']).map(asMap).toList();
          final officialSchedules = schedules
              .where((s) => boolValue(s, 'is_official'))
              .toList();
          final delegateSchedules = schedules
              .where((s) => !boolValue(s, 'is_official'))
              .toList();

          // Find nearest exam across all schedules (or just official)
          Map<String, dynamic>? nearestExam;
          for (final schedule in officialSchedules) {
            final items = asList(schedule['items']).map(asMap).toList();
            for (final item in items) {
              final date = DateTime.tryParse(text(item, 'exam_date'));
              if (date != null && date.isAfter(DateTime.now())) {
                if (nearestExam == null) {
                  nearestExam = item;
                } else {
                  final nearestDate = DateTime.tryParse(
                    text(nearestExam, 'exam_date'),
                  );
                  if (nearestDate != null && date.isBefore(nearestDate)) {
                    nearestExam = item;
                  }
                }
              }
            }
          }

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        if (nearestExam != null) ...[
                          _NextExamSpotlight(exam: nearestExam),
                          const SizedBox(height: 20),
                        ],
                        _HeroPanel(
                          title: 'جداول الاختبارات',
                          subtitle:
                              'قائمة جداول الاختبارات المعتمدة والمنظمة بواسطة المندوب للفصل الدراسي الحالي.',
                          icon: Icons.assignment_turned_in_rounded,
                          colors: const [
                            Color(0xFF8B1E3F), // Deep Crimson
                            Color(0xFF2E1065), // Dark Indigo
                            Color(0xFF0F172A), // Midnight Navy
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    height: 74,
                    child: Container(
                      color: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slate200.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.slate600,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1E293B), // Midnight Slate
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1E293B,
                                ).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'الجداول الرسمية'),
                            Tab(text: 'بواسطة المندوب'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _ExamScheduleList(
                    items: officialSchedules,
                    emptyMessage: 'لا توجد جداول اختبارات رسمية منشورة حالياً.',
                  ),
                  _ExamScheduleList(
                    items: delegateSchedules,
                    emptyMessage: 'لا توجد جداول مقترحة من قبل المندوب حالياً.',
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

class _ExamScheduleList extends ConsumerWidget {
  const _ExamScheduleList({required this.items, required this.emptyMessage});
  final List<Map<String, dynamic>> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: EmptyState(
          message: emptyMessage,
          icon: Icons.calendar_today_rounded,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_examsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
        itemCount: items.length,
        itemBuilder: (context, index) => _ExamScheduleCard(items[index]),
      ),
    );
  }
}

class _NextExamSpotlight extends StatelessWidget {
  const _NextExamSpotlight({required this.exam});
  final Map<String, dynamic> exam;

  @override
  Widget build(BuildContext context) {
    final dateStr = text(exam, 'exam_date');
    final date = DateTime.tryParse(dateStr);
    final subject = asMap(exam['subject']);

    int daysDiff = -1;
    if (date != null) {
      daysDiff = date.difference(DateTime.now()).inDays;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الاختبار القادم',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text(subject, 'name', fallback: 'مقرر دراسي'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      text(exam, 'hall_name', fallback: 'قاعة الاختبار'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  daysDiff == 0 ? 'اليوم' : daysDiff.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                if (daysDiff > 0)
                  const Text(
                    'أيام متبقية',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
