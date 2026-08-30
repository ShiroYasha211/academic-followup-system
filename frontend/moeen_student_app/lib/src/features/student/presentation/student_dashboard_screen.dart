import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_variant.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/models/student_dashboard.dart';
import '../data/student_repositories.dart';
import '../logic/student_controllers.dart';
import 'student_content_screens.dart';
import 'student_support_screen.dart';
import 'student_subscription_screen.dart';
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
          color: StudentBrandColors.primary,
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
    final bannerColors = [
      AppColors.royalBlue,
      AppColors.royalBlueDark,
      const Color(0xFF1E3A8A),
    ];
    final bannerBaseColor = AppColors.royalBlue;
    final badgeIconColor = AppColors.gold;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bannerColors,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: bannerBaseColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              left: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bannerBaseColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
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
                              '${_getGreeting()}،',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 24,
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
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: badgeIconColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'أنت تبلي بلاءً حسناً اليوم! حافظ على نشاطك.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickQrAttendanceCard extends ConsumerWidget {
  const _QuickQrAttendanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionControllerProvider).valueOrNull;
    final supportSettings =
        ref.watch(studentSupportSettingsProvider).valueOrNull ??
        const <String, dynamic>{};
    final qrScanFreeEnabled = _studentDashboardBoolSetting(
      supportSettings['student_qr_scan_free_enabled'],
      fallback: true,
    );
    final canOpen = qrScanFreeEnabled || subscription?.isSubscribed == true;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (canOpen) {
                context.go(StudentQrScanScreen.route);
                return;
              }
              final subscribe = await showMoeenConfirmDialog(
                context: context,
                title: 'هذه الميزة تحتاج اشتراك',
                message:
                    'تصوير QR الحضور غير مفتوح مجانًا حاليًا. اشترك للوصول إلى هذه الميزة.',
                confirmLabel: 'الاشتراك الآن',
                icon: Icons.lock_rounded,
                color: StudentBrandColors.accentDeep,
              );
              if (subscribe && context.mounted) {
                context.go(StudentSubscriptionScreen.route);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF0F766E),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل حضور سريع',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'اضغط لمسح رمز الـ QR في القاعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
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

bool _studentDashboardBoolSetting(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].contains(normalized)) return true;
  if (['0', 'false', 'no', 'off'].contains(normalized)) return false;
  return fallback;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.overview});

  final StudentOverview overview;

  @override
  Widget build(BuildContext context) {
    final registered = _StatData(
      'المقررات المسجلة',
      overview.registeredSubjectsCount.toString(),
      Icons.auto_stories_rounded,
      StudentBrandColors.primary,
    );
    final assignments = _StatData(
      'التكليفات النشطة',
      overview.activeAssignmentsCount.toString(),
      Icons.task_alt_rounded,
      AppColors.success,
    );
    final absences = _StatData(
      'أيام الغياب',
      overview.totalAbsencesDays.toString(),
      Icons.event_busy_rounded,
      AppColors.danger,
    );
    final clinical = _StatData(
      'المسار السريري',
      overview.hasClinical ? 'مفعل' : 'مغلق',
      Icons.medical_information_rounded,
      AppColors.info,
    );

    Widget buildBentoCard(_StatData stat, {required double flex}) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  stat.label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: buildBentoCard(registered, flex: 3)),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: buildBentoCard(assignments, flex: 2)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(flex: 2, child: buildBentoCard(absences, flex: 2)),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: buildBentoCard(clinical, flex: 3)),
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF991B1B), // dark red
            Color(0xFFDC2626), // red-600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Icon(
              Icons.alarm_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Text(
                          '🚨 الاختبار القادم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
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
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                exam.examDate,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                exam.location ?? 'القاعة الكبرى',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exam.isToday ? 'اليوم' : exam.daysRemaining.toString(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        exam.isToday ? 'استعد' : 'أيام متبقية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
              fontFamily: 'Cairo',
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
                    fontFamily: 'Cairo',
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Cairo',
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
                          fontFamily: 'Cairo',
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
        StudentBrandColors.primary,
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
              fontFamily: 'Cairo',
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
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.012),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => context.go(action.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.midnight,
                          ),
                        ),
                      ],
                    ),
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
        _AnnouncementsPreview(items: feed.announcements.take(3).toList()),
        const SizedBox(height: 24),
        _FeedCategory(
          title: 'التذكيرات',
          icon: Icons.notifications_active_rounded,
          color: StudentBrandColors.primary,
          items: feed.reminders.map((e) => (e.title, e.description)).toList(),
        ),
      ],
    );
  }
}

class _AnnouncementsPreview extends StatelessWidget {
  const _AnnouncementsPreview({required this.items});

  final List<DashboardAnnouncement> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'آخر الإعلانات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go(StudentNewsScreen.route),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text(
                  'رؤية المزيد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const EmptyState(message: 'لا توجد إعلانات جديدة حاليًا.')
        else
          ...items.map((item) => _DashboardAnnouncementCard(item: item)),
      ],
    );
  }
}

class _DashboardAnnouncementCard extends StatelessWidget {
  const _DashboardAnnouncementCard({required this.item});

  final DashboardAnnouncement item;

  @override
  Widget build(BuildContext context) {
    final dateStr = item.createdAt.isNotEmpty ? dateOnly(item.createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDashboardAnnouncementDetails(context, item),
            child: Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(
                    color: AppColors.orange.withValues(alpha: 0.8),
                    width: 4.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.campaign_rounded,
                              color: AppColors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'إعلان إداري',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.slate400,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.slate500,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'عرض تفاصيل الإعلان كاملة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: StudentBrandColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: StudentBrandColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: StudentBrandColors.primary,
                          size: 14,
                        ),
                      ),
                    ],
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

void _showDashboardAnnouncementDetails(
  BuildContext context,
  DashboardAnnouncement item,
) {
  showMoeenBottomSheet(
    context: context,
    title: item.title,
    icon: Icons.campaign_rounded,
    color: AppColors.orange,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.content,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.slate700,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item.createdAt.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            item.createdAt,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.slate400,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    ),
  );
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
                  fontFamily: 'Cairo',
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => Divider(
                color: const Color(0xFFF1F5F9),
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
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
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
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
