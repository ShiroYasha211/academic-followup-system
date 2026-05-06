import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/models/student_dashboard.dart';
import '../logic/student_controllers.dart';
import 'student_content_screens.dart';
import 'student_support_screen.dart';
import 'widgets/student_shell.dart';
import 'widgets/student_widgets.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  static const route = '/student/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentDashboardControllerProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;

    return StudentShell(
      currentIndex: 0,
      title: 'الرئيسية',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(studentDashboardControllerProvider),
        ),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(studentDashboardControllerProvider),
          displacement: 20,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              _WelcomeBanner(
                dashboard: dashboard,
                studentName: session?.name ?? 'طالبنا العزيز',
              ),
              const SizedBox(height: 20),
              const _QuickQrAttendanceCard(),
              const SizedBox(height: 24),
              _StatsGrid(overview: dashboard.overview),
              if (dashboard.nextExam != null) ...[
                const SizedBox(height: 24),
                _NextExamCard(exam: dashboard.nextExam!),
              ],
              const SizedBox(height: 24),
              _AlertsSection(alerts: dashboard.alerts),
              const SizedBox(height: 24),
              _QuickActions(),
              const SizedBox(height: 24),
              _FeedSection(feed: dashboard.feed),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.dashboard, required this.studentName});

  final StudentDashboard dashboard;
  final String studentName;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'طاب يومك';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark,
            const Color(0xFF1E3A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -20,
            bottom: -30,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}،',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'أنت تبلي بلاءً حسناً اليوم! حافظ على نشاطك.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickQrAttendanceCard extends StatelessWidget {
  const _QuickQrAttendanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: const Color(0xFF0F766E),
          child: InkWell(
            onTap: () => context.go(StudentQrScanScreen.route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFF0F766E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل حضور سريع',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'اضغط لمسح رمز الـ QR في القاعة',
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.overview});

  final StudentOverview overview;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        'المواد المسجلة',
        overview.registeredSubjectsCount.toString(),
        Icons.auto_stories_rounded,
        AppColors.royalBlue,
      ),
      _StatData(
        'التكليفات النشطة',
        overview.activeAssignmentsCount.toString(),
        Icons.task_alt_rounded,
        AppColors.success,
      ),
      _StatData(
        'أيام الغياب',
        overview.totalAbsencesDays.toString(),
        Icons.event_busy_rounded,
        AppColors.danger,
      ),
      _StatData(
        'المسار السريري',
        overview.hasClinical ? 'مفعل' : 'مغلق',
        Icons.medical_information_rounded,
        AppColors.info,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -10,
                  child: Icon(
                    stat.icon,
                    size: 60,
                    color: stat.color.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: stat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(stat.icon, color: stat.color, size: 20),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.value,
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            stat.label,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
        );
      },
    );
  }
}

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({required this.exam});

  final NextExam exam;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF991B1B), AppColors.danger],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'الاختبار القادم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      exam.subjectName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          exam.examDate,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exam.location ?? 'القاعة الكبرى',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      exam.isToday ? 'اليوم' : exam.daysRemaining.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      exam.isToday ? 'استعد' : 'أيام',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});

  final StudentAlerts alerts;

  @override
  Widget build(BuildContext context) {
    final hasAlerts =
        alerts.deprivationWarnings.isNotEmpty ||
        alerts.excuseDeadlines.isNotEmpty;
    if (!hasAlerts) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'تنبيهات هامة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final warning in alerts.deprivationWarnings)
          _AlertTile(
            title: warning.status == 'banned'
                ? 'قرار حرمان نهائي'
                : 'إنذار حرمان من المادة',
            message: warning.message,
            color: warning.status == 'banned'
                ? AppColors.danger
                : AppColors.warning,
          ),
        for (final warning in alerts.excuseDeadlines)
          _AlertTile(
            title: 'مهلة تقديم عذر غياب',
            message: warning.message,
            color: AppColors.warning,
            actionLabel: warning.subjectId > 0 ? 'تقديم عذر الآن' : null,
            onAction: warning.subjectId > 0
                ? () => context.go(
                    '${StudentSubjectsScreen.detailsPath(warning.subjectId)}?tab=attendance',
                  )
                : null,
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.priority_high_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.slate600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton.icon(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_moderator_rounded, size: 16),
                      label: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        'المقررات',
        Icons.auto_stories_rounded,
        StudentSubjectsScreen.route,
        AppColors.royalBlue,
      ),
      _ActionData(
        'الحضور',
        Icons.fact_check_rounded,
        'attendance',
        AppColors.success,
      ),
      _ActionData(
        'الأخبار',
        Icons.campaign_rounded,
        StudentNewsScreen.route,
        AppColors.orange,
      ),
      _ActionData(
        'مركز الدراسة',
        Icons.library_books_rounded,
        StudentStudyCenterScreen.route,
        AppColors.violet,
      ),
      _ActionData(
        'المساعدة',
        Icons.support_agent_rounded,
        StudentSupportScreen.route,
        AppColors.info,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'اختصارات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.go(action.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.midnight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FeedSection extends StatelessWidget {
  const _FeedSection({required this.feed});

  final StudentFeed feed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeedCategory(
          title: 'آخر الإعلانات',
          icon: Icons.campaign_rounded,
          color: AppColors.orange,
          items: feed.announcements.map((e) => (e.title, e.content)).toList(),
        ),
        const SizedBox(height: 24),
        _FeedCategory(
          title: 'التذكيرات',
          icon: Icons.notifications_active_rounded,
          color: AppColors.royalBlue,
          items: feed.reminders.map((e) => (e.title, e.description)).toList(),
        ),
      ],
    );
  }
}

class _FeedCategory extends StatelessWidget {
  const _FeedCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const EmptyState(message: 'لا توجد تحديثات جديدة حالياً.')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.slate100),
            ),
            child: ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => Divider(
                color: AppColors.slate100,
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: AppColors.midnight,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.key, this.color);
  final String label;
  final IconData icon;
  final String key;
  final Color color;
}
