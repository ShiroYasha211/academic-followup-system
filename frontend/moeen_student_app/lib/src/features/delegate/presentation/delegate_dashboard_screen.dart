part of 'delegate_screens.dart';

class DelegateDashboardScreen extends ConsumerWidget {
  const DelegateDashboardScreen({super.key});
  static const route = DelegateRoutes.dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(delegateDashboardProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;

    String greetingPrefix() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'صباح الخير';
      if (hour < 17) return 'طاب يومك';
      return 'مساء الخير';
    }

    return DelegateShell(
      currentIndex: 0,
      title: 'الرئيسية',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(delegateDashboardProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final subjects = asList(data['subjects']);
          final topAbsent = asList(data['top_absent_students']);
          final risk = asList(data['at_risk_students']);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(delegateDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _HeroPanel(
                  title:
                      '${greetingPrefix()}، ${session?.name.split(' ').first ?? 'يا مندوب'}',
                  subtitle:
                      'إليك نظرة سريعة على حالة الدفعة اليوم وما يمكنك القيام به.',
                  icon: Icons.dashboard_customize_rounded,
                  colors: const [AppColors.royalBlueDark, AppColors.royalBlue],
                ),
                const SizedBox(height: 24),
                _ActionGrid(
                  onQrTap: () => context.go(DelegateRoutes.qrAttendance),
                  onStudentsTap: () => context.go(DelegateRoutes.students),
                  onSubjectsTap: () => context.go(DelegateRoutes.subjects),
                  onAttendanceTap: () => context.go(DelegateRoutes.attendance),
                  onGradesTap: () =>
                      context.go(DelegateRoutes.authorizedGrades),
                  onMessagesTap: () => context.go(DelegateRoutes.messages),
                ),
                const SizedBox(height: 32),
                const _SectionHeader(
                  title: 'أهم الإحصائيات',
                  icon: Icons.analytics_rounded,
                ),
                const SizedBox(height: 12),
                _StatsGrid(
                  items: [
                    _StatItem(
                      'المواد',
                      value(stats, 'total_subjects'),
                      Icons.auto_stories_rounded,
                      AppColors.royalBlue,
                    ),
                    _StatItem(
                      'الطلاب',
                      value(stats, 'total_students'),
                      Icons.groups_rounded,
                      AppColors.teal,
                    ),
                    _StatItem(
                      'تنبيهات غياب',
                      value(stats, 'absence_alerts'),
                      Icons.warning_rounded,
                      AppColors.warning,
                    ),
                    _StatItem(
                      'محاضرات اليوم',
                      value(stats, 'today_lectures'),
                      Icons.today_rounded,
                      AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _SubjectsStrip(subjects: subjects),
                const SizedBox(height: 32),
                _StudentsStrip(
                  title: 'الأكثر غيابًا',
                  icon: Icons.person_off_rounded,
                  items: topAbsent,
                  color: AppColors.warning,
                  empty: 'لا توجد بيانات غياب حالية.',
                ),
                const SizedBox(height: 32),
                _StudentsStrip(
                  title: 'طلاب معرضون للخطر',
                  icon: Icons.report_rounded,
                  items: risk,
                  color: AppColors.danger,
                  empty: 'لا توجد مؤشرات خطورة حالية.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
