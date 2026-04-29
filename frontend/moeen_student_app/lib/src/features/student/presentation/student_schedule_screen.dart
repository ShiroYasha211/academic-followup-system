part of 'student_content_screens.dart';

class StudentScheduleScreen extends ConsumerStatefulWidget {
  const StudentScheduleScreen({super.key});

  static const route = '/student/schedules';

  @override
  ConsumerState<StudentScheduleScreen> createState() =>
      _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends ConsumerState<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<int> _daysOrder = [6, 7, 1, 2, 3, 4, 5]; // Sat to Fri

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    int currentDay = now.weekday;
    int initialIndex = _daysOrder.indexOf(currentDay);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: _daysOrder.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_scheduleProvider);

    return StudentShell(
      currentIndex: 5,
      title: 'الجدول الدراسي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_scheduleProvider),
        builder: (data) {
          final rawGroups = asMap(data['schedules']).isNotEmpty
              ? asMap(data['schedules'])
              : data;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: _ScheduleHeader(data: rawGroups),
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
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.slate600,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        tabs: _daysOrder.map((d) {
                          final count = asList(rawGroups[d.toString()]).length;
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_dayLabel(d.toString())),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _daysOrder.map((day) {
                final lectures = asList(rawGroups[day.toString()]);
                if (lectures.isEmpty) {
                  return Center(
                    child: EmptyState(
                      message: 'لا توجد محاضرات يوم ${_dayLabel(day.toString())}',
                      icon: Icons.event_busy_rounded,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_scheduleProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                    itemCount: lectures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ScheduleCard(asMap(lectures[index]));
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    int totalLectures = 0;
    double totalHours = 0;
    final Set<int> uniqueSubjects = {};
    Map<String, dynamic>? nextLecture;
    final now = DateTime.now();

    data.forEach((day, items) {
      final list = asList(items);
      totalLectures += list.length;
      for (final item in list) {
        final map = asMap(item);
        uniqueSubjects.add(number(asMap(map['subject']), 'id').toInt());

        final startStr = text(map, 'start_time');
        final endStr = text(map, 'end_time');
        if (startStr.isNotEmpty && endStr.isNotEmpty) {
          try {
            final today = dateOnly(now.toString());
            final start = DateTime.parse('$today ${startStr.length == 5 ? "$startStr:00" : startStr}');
            final end = DateTime.parse('$today ${endStr.length == 5 ? "$endStr:00" : endStr}');
            
            final diff = end.difference(start).inMinutes;
            totalHours += diff / 60.0;

            if (day == now.weekday.toString() && start.isAfter(now)) {
              if (nextLecture == null) {
                nextLecture = map;
              } else {
                final currentNextStart = DateTime.parse('$today ${text(nextLecture!, "start_time").length == 5 ? "${text(nextLecture!, "start_time")}:00" : text(nextLecture!, "start_time")}');
                if (start.isBefore(currentNextStart)) {
                  nextLecture = map;
                }
              }
            }
          } catch (_) {}
        }
      }
    });

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroPanel(
            title: nextLecture != null 
                ? 'المحاضرة القادمة: ${text(asMap(nextLecture!["subject"]), "name")}'
                : 'الجدول الدراسي العام',
            subtitle: nextLecture != null 
                ? 'تبدأ في ${timeOnly(text(nextLecture!, "start_time"))}'
                : 'المحاضرات الرسمية مرتبة حسب أيام الأسبوع.',
            icon: Icons.calendar_month_rounded,
            colors: const [Color(0xFF0369A1), Color(0xFF0EA5E9)],
          ),
          const SizedBox(height: 16),
          _ScheduleStatsRow(
            totalLectures: totalLectures,
            totalHours: totalHours.toStringAsFixed(1),
            totalSubjects: uniqueSubjects.length,
          ),
        ],
      ),
    );
  }
}
