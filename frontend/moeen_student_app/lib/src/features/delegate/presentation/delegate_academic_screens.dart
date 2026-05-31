part of 'delegate_screens.dart';

class DelegateSchedulesScreen extends ConsumerStatefulWidget {
  const DelegateSchedulesScreen({super.key});
  static const route = DelegateRoutes.schedules;

  @override
  ConsumerState<DelegateSchedulesScreen> createState() =>
      _DelegateSchedulesScreenState();
}

class _DelegateSchedulesScreenState
    extends ConsumerState<DelegateSchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<int> _days = [6, 7, 1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final canCreate = session?.hasPermission('schedules', 'create') ?? false;
    final canUpdate = session?.hasPermission('schedules', 'update') ?? false;
    final canDelete = session?.hasPermission('schedules', 'delete') ?? false;
    final state = ref.watch(_delegateSchedulesProvider);

    return DelegateShell(
      currentIndex: 5,
      title: 'الجدول الدراسي',
      floatingActionButton: _AddScheduleFAB(
        onPressed: () => _scheduleSheet(context, ref),
        isEnabled: canCreate,
        onUnauthorized: () => _showNoPermissionSnackBar(context),
      ),
      child: _AsyncBody<List<dynamic>>(
        state: state,
        onRetry: () => ref.invalidate(_delegateSchedulesProvider),
        builder: (data) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _ScheduleHeader(data: data),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  height: 64,
                  child: Container(
                    color: AppColors.ghostWhite,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.slate500,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      tabs: _days
                          .map((d) => Tab(text: _dayLabel(d.toString())))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final dayItems = data
                    .where((item) => number(item, 'day_of_week').toInt() == day)
                    .toList();

                if (dayItems.isEmpty) {
                  return const _EmptyState(
                    'لا توجد محاضرات مجدولة لهذا اليوم.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                  itemCount: dayItems.length,
                  itemBuilder: (context, index) {
                    final item = asMap(dayItems[index]);
                    return _DelegateScheduleCard(
                      item: item,
                      canUpdate: canUpdate,
                      canDelete: canDelete,
                      onUnauthorized: () => _showNoPermissionSnackBar(context),
                      onEdit: () => _scheduleSheet(context, ref, item: item),
                      onDelete: () => _delete(
                        context,
                        () => ref
                            .read(delegateRepositoryProvider)
                            .deleteSchedule(number(item, 'id').toInt()),
                        () => ref.invalidate(_delegateSchedulesProvider),
                      ),
                    );
                  },
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
  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final totalLectures = data.length;
    final subjects = data
        .map((e) => number(asMap(e['subject']), 'id'))
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.royalBlue, AppColors.violet],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.25),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نظرة عامة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'متابعة وتنظيم المحاضرات الأسبوعية',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScheduleStatItem(
                label: 'محاضرة',
                value: totalLectures.toString(),
                icon: Icons.play_lesson_rounded,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _ScheduleStatItem(
                label: 'مادة',
                value: subjects.toString(),
                icon: Icons.auto_stories_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleStatItem extends StatelessWidget {
  const _ScheduleStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DelegateScheduleCard extends StatelessWidget {
  const _DelegateScheduleCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    final startTime = text(item, 'start_time');
    final endTime = text(item, 'end_time');
    final isLive = isTimeInRange(startTime, endTime);
    final subject = asMap(item['subject']);
    final doctorObj = asMap(item['doctor']).isNotEmpty
        ? asMap(item['doctor'])
        : asMap(subject['doctor']);

    final doctorName = text(doctorObj, 'name').isNotEmpty
        ? text(doctorObj, 'name')
        : (item['doctor'] is String
              ? item['doctor'].toString()
              : (subject['doctor'] is String
                    ? subject['doctor'].toString()
                    : ''));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive ? AppColors.primary : AppColors.slate200,
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isLive
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.slate50,
                border: BorderDirectional(
                  end: BorderSide(
                    color: isLive
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.slate200,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeOnly(startTime),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isLive ? AppColors.primary : AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 20,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isLive ? AppColors.primary : AppColors.slate300,
                          isLive
                              ? AppColors.primary.withValues(alpha: 0)
                              : AppColors.slate200.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeOnly(endTime),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            text(subject, 'name', fallback: 'محاضرة'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              height: 1.2,
                            ),
                          ),
                        ),
                        _ActionMenu(
                          onEdit: onEdit,
                          onDelete: onDelete,
                          canUpdate: canUpdate,
                          canDelete: canDelete,
                          onUnauthorized: onUnauthorized,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _IconInfo(
                      icon: Icons.account_circle_rounded,
                      text: doctorName.isNotEmpty
                          ? doctorName
                          : text(
                              item,
                              'doctor_name',
                              fallback: text(
                                subject,
                                'doctor_name',
                                fallback: 'دكتور غير محدد',
                              ),
                            ),
                      color: AppColors.slate600,
                    ),
                    const SizedBox(height: 6),
                    _IconInfo(
                      icon: Icons.room_preferences_rounded,
                      text: text(item, 'hall_name', fallback: 'قاعة غير محددة'),
                      color: AppColors.goldDeep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.onEdit,
    required this.onDelete,
    this.iconColor = AppColors.slate400,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color iconColor;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert_rounded, color: iconColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: canUpdate ? onEdit : onUnauthorized,
          child: Opacity(
            opacity: canUpdate ? 1.0 : 0.5,
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Text('تعديل'),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          onTap: canDelete ? onDelete : onUnauthorized,
          child: Opacity(
            opacity: canDelete ? 1.0 : 0.5,
            child: const Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                SizedBox(width: 10),
                Text('حذف', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddScheduleFAB extends StatelessWidget {
  const _AddScheduleFAB({
    required this.onPressed,
    this.isEnabled = true,
    this.onUnauthorized,
  });
  final VoidCallback onPressed;
  final bool isEnabled;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: isEnabled ? onPressed : onUnauthorized,
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          label: const Text(
            'إضافة للجدول',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconInfo extends StatelessWidget {
  const _IconInfo({
    required this.icon,
    required this.text,
    this.color = AppColors.slate500,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class DelegateExamSchedulesScreen extends ConsumerWidget {
  const DelegateExamSchedulesScreen({super.key});
  static const route = DelegateRoutes.exams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final canCreate = session?.hasPermission('exams', 'create') ?? false;
    final canUpdate = session?.hasPermission('exams', 'update') ?? false;
    final canDelete = session?.hasPermission('exams', 'delete') ?? false;
    final state = ref.watch(_delegateExamsProvider);

    return DelegateShell(
      currentIndex: 6,
      title: 'جداول الاختبارات',
      floatingActionButton: _AddExamFAB(
        onPressed: () => _examSheet(context, ref),
        isEnabled: canCreate,
        onUnauthorized: () => _showNoPermissionSnackBar(context),
      ),
      child: _AsyncBody<List<dynamic>>(
        state: state,
        onRetry: () => ref.invalidate(_delegateExamsProvider),
        builder: (data) {
          final schedules = data.map(asMap).toList();

          // Find nearest exam across all schedules
          Map<String, dynamic>? nearestExam;
          for (final schedule in schedules) {
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

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      if (nearestExam != null) ...[
                        _ExamSpotlight(exam: nearestExam),
                        const SizedBox(height: 20),
                      ],
                      _HeroPanel(
                        title: 'إدارة جداول الاختبارات',
                        subtitle:
                            'تنظيم وتعديل جداول الاختبارات الفصلية للطلاب في تخصصك.',
                        icon: Icons.fact_check_rounded,
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
            ],
            body: RefreshIndicator(
              onRefresh: () async => ref.invalidate(_delegateExamsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return _DelegateExamScheduleCard(
                    schedule: schedule,
                    canUpdate: canUpdate,
                    canDelete: canDelete,
                    onUnauthorized: () => _showNoPermissionSnackBar(context),
                    onEdit: () => _examSheet(context, ref, item: schedule),
                    onDelete: () => _delete(
                      context,
                      () => ref
                          .read(delegateRepositoryProvider)
                          .deleteExamSchedule(number(schedule, 'id').toInt()),
                      () => ref.invalidate(_delegateExamsProvider),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddExamFAB extends StatelessWidget {
  const _AddExamFAB({
    required this.onPressed,
    this.isEnabled = true,
    this.onUnauthorized,
  });
  final VoidCallback onPressed;
  final bool isEnabled;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    const fabColor = Color(0xFF8B1E3F);
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: fabColor.withValues(alpha: isEnabled ? 0.35 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: isEnabled ? onPressed : onUnauthorized,
          backgroundColor: fabColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          label: const Text(
            'جدول اختبار',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamSpotlight extends StatelessWidget {
  const _ExamSpotlight({required this.exam});
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
          colors: [Color(0xFF8B1E3F), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.2),
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
                      text(
                        exam,
                        'location',
                        fallback: text(
                          exam,
                          'hall_name',
                          fallback: 'قاعة الاختبار',
                        ),
                      ),
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

class DelegateAssignmentsScreen extends ConsumerStatefulWidget {
  const DelegateAssignmentsScreen({super.key});
  static const route = DelegateRoutes.assignments;

  @override
  ConsumerState<DelegateAssignmentsScreen> createState() =>
      _DelegateAssignmentsScreenState();
}

class _DelegateAssignmentsScreenState
    extends ConsumerState<DelegateAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_delegateAssignmentsProvider);
    final permissionsState = ref.watch(_delegateAssignmentPermissionsProvider);
    final creatableSubjectIds = permissionsState.maybeWhen(
      data: _creatableSubjectIds,
      orElse: () => const <int>{},
    );
    final canCreate = creatableSubjectIds.isNotEmpty;

    return DelegateShell(
      currentIndex: 7,
      title: 'التكاليف الدراسية',
      floatingActionButton: Opacity(
        opacity: canCreate ? 1.0 : 0.45,
        child: FloatingActionButton.extended(
          onPressed: canCreate
              ? () => _assignmentSheet(
                  context,
                  ref,
                  creatableSubjectIds: creatableSubjectIds,
                )
              : () => _showNoPermissionSnackBar(context),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text(
            'تكليف جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      child: _AsyncBody<List<dynamic>>(
        state: state,
        onRetry: () {
          ref.invalidate(_delegateAssignmentsProvider);
          ref.invalidate(_delegateAssignmentPermissionsProvider);
        },
        builder: (data) {
          final now = DateTime.now();
          final allAssignments = data.map(asMap).toList();

          final active = allAssignments.where((a) {
            final date = DateTime.tryParse(text(a, 'due_date'));
            return date == null || date.isAfter(now);
          }).toList();

          final past = allAssignments.where((a) {
            final date = DateTime.tryParse(text(a, 'due_date'));
            return date != null && date.isBefore(now);
          }).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Column(
                    children: [
                      _AssignmentsStatsHeader(
                        active: active.length,
                        total: allAssignments.length,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: AppColors.midnight,
                          unselectedLabelColor: AppColors.slate500,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                          tabs: [
                            Tab(text: 'نشطة (${active.length})'),
                            Tab(text: 'منتهية (${past.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _AssignmentListView(items: active, ref: ref),
                _AssignmentListView(items: past, ref: ref),
              ],
            ),
          );
        },
      ),
    );
  }

  Set<int> _creatableSubjectIds(Map<String, dynamic> payload) {
    return asList(payload['subjects'])
        .map(asMap)
        .where((item) => boolValue(asMap(item['permissions']), 'can_create'))
        .map((item) => number(asMap(item['subject']), 'id').toInt())
        .where((id) => id > 0)
        .toSet();
  }
}

class _AssignmentsStatsHeader extends StatelessWidget {
  const _AssignmentsStatsHeader({required this.active, required this.total});
  final int active;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.goldDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  'مركز الإنجاز 📝',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لديك $active تكاليف نشطة حالياً',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : (total - active) / total,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentListView extends StatelessWidget {
  const _AssignmentListView({required this.items, required this.ref});
  final List<Map<String, dynamic>> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.slate300,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد تكاليف في هذا القسم',
              style: TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _DelegateAssignmentCard(
          item: item,
          ref: ref,
          canUpdate: boolValue(item, 'can_edit'),
          canDelete: boolValue(item, 'can_delete'),
          onUnauthorized: () => _showNoPermissionSnackBar(context),
        );
      },
    );
  }
}

class _DelegateAssignmentCard extends StatelessWidget {
  const _DelegateAssignmentCard({
    required this.item,
    required this.ref,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> item;
  final WidgetRef ref;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final dueDateStr = text(item, 'due_date');
    final dueDate = DateTime.tryParse(dueDateStr);
    final requiresFile =
        boolValue(item, 'requires_file') ||
        boolValue(item, 'requires_submission');

    final isPast = dueDate != null && dueDate.isBefore(DateTime.now());
    final isUrgent =
        !isPast &&
        dueDate != null &&
        dueDate.difference(DateTime.now()).inHours < 48;

    final color = isPast
        ? AppColors.slate400
        : (isUrgent ? AppColors.orange : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUrgent
              ? AppColors.orange.withValues(alpha: 0.3)
              : AppColors.slate200,
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? AppColors.orange : AppColors.slate200)
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canUpdate
            ? () => _assignmentSheet(context, ref, item: item)
            : onUnauthorized,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(item, 'title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          text(subject, 'name', fallback: 'مادة دراسية'),
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ActionMenu(
                    onEdit: () => _assignmentSheet(context, ref, item: item),
                    onDelete: () => _delete(
                      context,
                      () => ref
                          .read(delegateRepositoryProvider)
                          .deleteAssignment(number(item, 'id').toInt()),
                      () => ref.invalidate(_delegateAssignmentsProvider),
                    ),
                    canUpdate: canUpdate,
                    canDelete: canDelete,
                    onUnauthorized: onUnauthorized,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _AssignmentOwnerChip(label: text(item, 'owner_label')),
              const SizedBox(height: 16),
              if (isUrgent)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_rounded,
                        color: AppColors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'متبقي ${_getTimeLeft(dueDate)}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isPast ? AppColors.slate400 : AppColors.slate600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateOnly(dueDateStr),
                        style: TextStyle(
                          color: isPast
                              ? AppColors.slate400
                              : AppColors.slate700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (requiresFile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 12,
                            color: AppColors.royalBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'يتطلب ملف',
                            style: TextStyle(
                              color: AppColors.royalBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPast ? 'منتهي' : 'نشط',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeLeft(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    return '${diff.inMinutes} دقيقة';
  }
}

class DelegateResourcesScreen extends ConsumerStatefulWidget {
  const DelegateResourcesScreen({super.key});
  static const route = DelegateRoutes.resources;

  @override
  ConsumerState<DelegateResourcesScreen> createState() =>
      _DelegateResourcesScreenState();
}

class _DelegateResourcesScreenState
    extends ConsumerState<DelegateResourcesScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late TabController _tabController;
  bool _isGrid = false;
  int? _subjectId;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'الكل'},
    {'value': 'book', 'label': 'الكتب'},
    {'value': 'lecture', 'label': 'المحاضرات'},
    {'value': 'summary', 'label': 'الملخصات'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_delegateResourcesProvider);

    const canUpdate = true;
    const canDelete = true;

    return DelegateShell(
      currentIndex: 8,
      title: 'مصادر المقرر',
      floatingActionButton: Opacity(
        opacity: 1.0,
        child: FloatingActionButton.extended(
          onPressed: () => _resourceSheet(context, ref),
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text(
            'رفع ملف',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
        ),
      ),
      child: _AsyncBody<Map<String, dynamic>>(
        state: state,
        onRetry: () => ref.invalidate(_delegateResourcesProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final subjects = asList(data['subjects']).map(asMap).toList();
          final allResources = asList(data['resources']).map(asMap).toList();

          // Local Filtering
          final catValue = _categories[_tabController.index]['value'];
          final filtered = allResources.where((r) {
            final matchesSearch =
                _search.text.isEmpty ||
                text(
                  r,
                  'title',
                ).toLowerCase().contains(_search.text.toLowerCase()) ||
                text(
                  asMap(r['subject']),
                  'name',
                ).toLowerCase().contains(_search.text.toLowerCase());

            final matchesSubject =
                _subjectId == null ||
                number(r, 'subject_id').toInt() == _subjectId;

            final matchesCategory =
                catValue == 'all' || text(r, 'category') == catValue;

            return matchesSearch && matchesSubject && matchesCategory;
          }).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _ResourcesStatsHeader(
                        total: number(stats, 'total_files').toInt(),
                        subjects: subjects.length,
                      ),
                      const SizedBox(height: 16),
                      _ResourceSearchRow(
                        controller: _search,
                        isGrid: _isGrid,
                        onSearch: () => setState(() {}),
                        onToggleView: () => setState(() => _isGrid = !_isGrid),
                        onFilter: () => _showFilterDialog(context, subjects),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  height: 68,
                  child: Container(
                    color: AppColors.ghostWhite,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.slate600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0D9488,
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
                        tabs: _categories
                            .map((c) => Tab(text: c['label']))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: AppColors.slate300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد ملفات تطابق بحثك',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGrid) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(18),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _DelegateResourceGridCard(
                      resource: filtered[i],
                      ref: ref,
                      canUpdate: canUpdate,
                      canDelete: canDelete,
                      onUnauthorized: () => _showNoPermissionSnackBar(context),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _DelegateResourceCard(
                    resource: filtered[i],
                    ref: ref,
                    canUpdate: canUpdate,
                    canDelete: canDelete,
                    onUnauthorized: () => _showNoPermissionSnackBar(context),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    List<Map<String, dynamic>> subjects,
  ) async {
    int? selected = _subjectId;
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تصفية حسب المادة',
      icon: Icons.filter_list_rounded,
      color: const Color(0xFF0D9488),
      child: Column(
        children: [
          DropdownButtonFormField<int?>(
            value: selected,
            items: [
              const DropdownMenuItem(value: null, child: Text('كل المواد')),
              ...subjects.map(
                (s) => DropdownMenuItem(
                  value: number(s, 'id').toInt(),
                  child: Text(text(s, 'name')),
                ),
              ),
            ],
            onChanged: (v) => selected = v,
            decoration: const InputDecoration(labelText: 'اختر المادة'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            child: const Text('تطبيق الفلترة'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _subjectId = selected);
  }
}

class _ResourcesStatsHeader extends StatelessWidget {
  const _ResourcesStatsHeader({required this.total, required this.subjects});
  final int total;
  final int subjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المكتبة الرقمية 📚',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'إجمالي $total ملف متاح في $subjects مواد دراسية',
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceSearchRow extends StatelessWidget {
  const _ResourceSearchRow({
    required this.controller,
    required this.isGrid,
    required this.onSearch,
    required this.onToggleView,
    required this.onFilter,
  });
  final TextEditingController controller;
  final bool isGrid;
  final VoidCallback onSearch;
  final VoidCallback onToggleView;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: 'بحث في المصادر...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _ResourceIconButton(
          icon: isGrid
              ? Icons.format_list_bulleted_rounded
              : Icons.grid_view_rounded,
          onTap: onToggleView,
        ),
        const SizedBox(width: 8),
        _ResourceIconButton(icon: Icons.tune_rounded, onTap: onFilter),
      ],
    );
  }
}

class _ResourceIconButton extends StatelessWidget {
  const _ResourceIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.slate600, size: 24),
      ),
    );
  }
}

class _AssignmentOwnerChip extends StatelessWidget {
  const _AssignmentOwnerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDoctor = label.contains('الدكتور');
    final color = isDoctor ? AppColors.primary : AppColors.orange;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDoctor ? Icons.school_rounded : Icons.person_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label.isEmpty ? 'مصدر التكليف' : label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelegateResourceCard extends StatelessWidget {
  const _DelegateResourceCard({
    required this.resource,
    required this.ref,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> resource;
  final WidgetRef ref;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(resource['subject']);
    final category = text(resource, 'category');
    final color = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDelegateResourceDetails(
          context,
          resource,
          section: 'DelegateCourseResources',
          onEdit: canUpdate
              ? () => _resourceSheet(context, ref, item: resource)
              : onUnauthorized,
          onDelete: canDelete
              ? () => _delete(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .deleteResource(number(resource, 'id').toInt()),
                  () => ref.invalidate(_delegateResourcesProvider),
                )
              : onUnauthorized,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getCategoryIcon(category), color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(resource, 'title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text(subject, 'name', fallback: 'مادة'),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ActionMenu(
                onEdit: () => _resourceSheet(context, ref, item: resource),
                onDelete: () => _delete(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .deleteResource(number(resource, 'id').toInt()),
                  () => ref.invalidate(_delegateResourcesProvider),
                ),
                canUpdate: canUpdate,
                canDelete: canDelete,
                onUnauthorized: onUnauthorized,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DelegateResourceGridCard extends StatelessWidget {
  const _DelegateResourceGridCard({
    required this.resource,
    required this.ref,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> resource;
  final WidgetRef ref;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(resource['subject']);
    final category = text(resource, 'category');
    final color = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showDelegateResourceDetails(
          context,
          resource,
          section: 'DelegateCourseResources',
          onEdit: canUpdate
              ? () => _resourceSheet(context, ref, item: resource)
              : onUnauthorized,
          onDelete: canDelete
              ? () => _delete(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .deleteResource(number(resource, 'id').toInt()),
                  () => ref.invalidate(_delegateResourcesProvider),
                )
              : onUnauthorized,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text(resource, 'title'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text(subject, 'name', fallback: 'مادة'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: _ActionMenu(
                onEdit: () => _resourceSheet(context, ref, item: resource),
                onDelete: () => _delete(
                  context,
                  () => ref
                      .read(delegateRepositoryProvider)
                      .deleteResource(number(resource, 'id').toInt()),
                  () => ref.invalidate(_delegateResourcesProvider),
                ),
                canUpdate: canUpdate,
                canDelete: canDelete,
                onUnauthorized: onUnauthorized,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getCategoryColor(String cat) {
  return switch (cat) {
    'book' => AppColors.royalBlue,
    'lecture' => AppColors.orange,
    'summary' => AppColors.success,
    'other' => AppColors.slate500,
    _ => AppColors.primary,
  };
}

IconData _getCategoryIcon(String cat) {
  return switch (cat) {
    'book' => Icons.menu_book_rounded,
    'lecture' => Icons.video_library_rounded,
    'summary' => Icons.description_rounded,
    'other' => Icons.insert_drive_file_rounded,
    _ => Icons.folder_rounded,
  };
}

class _DelegateExamScheduleCard extends StatefulWidget {
  const _DelegateExamScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });

  final Map<String, dynamic> schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  State<_DelegateExamScheduleCard> createState() =>
      _DelegateExamScheduleCardState();
}

class _DelegateExamScheduleCardState extends State<_DelegateExamScheduleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final items = asList(widget.schedule['items']).map(asMap).toList()
      ..sort((a, b) => text(a, 'exam_date').compareTo(text(b, 'exam_date')));
    final term = asMap(widget.schedule['term']);
    final isOfficial = boolValue(widget.schedule, 'is_official');
    final color = isOfficial
        ? const Color(0xFF0F172A)
        : const Color(0xFF8B1E3F);

    int daysDiff = -1;
    if (items.isNotEmpty) {
      final nextExam = items.first;
      final examDate = DateTime.tryParse(text(nextExam, 'exam_date'));
      if (examDate != null) {
        daysDiff = examDate.difference(DateTime.now()).inDays;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: isOfficial ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.85)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOfficial
                                      ? Icons.verified_rounded
                                      : Icons.person_pin_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOfficial ? 'جدول معتمد' : 'بواسطة المندوب',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionMenu(
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                            iconColor: Colors.white,
                            canUpdate: widget.canUpdate,
                            canDelete: widget.canDelete,
                            onUnauthorized: widget.onUnauthorized,
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text(widget.schedule, 'title'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _HeaderStat(
                        icon: Icons.school_rounded,
                        text: text(term, 'name', fallback: 'الفصل الحالي'),
                      ),
                      _HeaderStat(
                        icon: Icons.auto_stories_rounded,
                        text: '${items.length} مقرر',
                      ),
                      if (daysDiff >= 0)
                        _HeaderStat(
                          icon: Icons.timer_rounded,
                          text: daysDiff == 0 ? 'اليوم' : 'بقي $daysDiff يوم',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (text(widget.schedule, 'description').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text(widget.schedule, 'description'),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _ExamTimelineItem(
                        items[index],
                        isLast: index == items.length - 1,
                        color: color,
                      );
                    },
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }
}

class _ExamTimelineItem extends StatelessWidget {
  const _ExamTimelineItem(
    this.item, {
    this.isLast = false,
    required this.color,
  });
  final Map<String, dynamic> item;
  final bool isLast;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final dateStr = text(item, 'exam_date');
    final date = DateTime.tryParse(dateStr);
    final day = date != null ? date.day.toString().padLeft(2, '0') : '--';
    final month = _monthName(date?.month ?? 0);
    final dayLabel = _dayLabel(date?.weekday.toString() ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 50,
            margin: const EdgeInsetsDirectional.only(start: 16),
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 3),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsetsDirectional.only(
                bottom: isLast ? 10 : 20,
                start: 20,
                end: 4,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.midnight.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          child: Text(
                            dayLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              Text(
                                month,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(subject, 'name', fallback: 'مقرر دراسي'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppColors.slate500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${timeOnly(text(item, 'start_time'))} - ${timeOnly(text(item, 'end_time'))}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppColors.slate500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              text(
                                item,
                                'location',
                                fallback: text(
                                  item,
                                  'hall_name',
                                  fallback: 'قاعة الاختبار',
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
