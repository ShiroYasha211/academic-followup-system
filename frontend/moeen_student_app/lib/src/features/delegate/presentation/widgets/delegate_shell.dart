import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/moeen_dialogs.dart';
import '../../../../shared/widgets/moeen_logo.dart';
import '../../../auth/data/auth_session.dart';
import '../../../auth/logic/auth_controller.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../student/presentation/student_dashboard_screen.dart';
import '../../data/delegate_repositories.dart';
import '../../logic/delegate_controllers.dart';

class DelegateRoutes {
  static const dashboard = '/delegate/dashboard';
  static const news = '/delegate/news';
  static const notifications = '/delegate/notifications';
  static const students = '/delegate/students';
  static const subjects = '/delegate/subjects';
  static const schedules = '/delegate/schedules';
  static const exams = '/delegate/exams';
  static const assignments = '/delegate/assignments';
  static const resources = '/delegate/resources';
  static const libraryImport = '/delegate/resources/library';
  static const reminders = '/delegate/reminders';
  static const announcements = '/delegate/announcements';
  static const attendance = '/delegate/attendance';
  static const attendanceTracking = '/delegate/attendance/tracking';
  static const attendanceForm = '/delegate/attendance/form';
  static const qrAttendance = '/delegate/qr-attendance';
  static const qrSession = '/delegate/attendance/qr-session';
  static const absenceAlerts = '/delegate/absence-alerts';
  static const authorizedGrades = '/delegate/authorized-grades';
  static const gradeDelegations = '/delegate/grade-helper-delegations';
  static const messages = '/delegate/messages';
  static const doctorChats = '/delegate/doctor-chats';
  static const inquiries = '/delegate/inquiries';
  static const subscription = '/delegate/subscription';
  static const ledger = '/delegate/ledger';
  static const profile = '/delegate/profile';
}

class DelegateShell extends ConsumerWidget {
  const DelegateShell({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.bottom,
    this.actions,
  });

  final int currentIndex;
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (currentIndex != 0) {
          context.go(DelegateRoutes.dashboard);
          return;
        }
        final close = await showMoeenConfirmDialog(
          context: context,
          title: 'إغلاق التطبيق',
          message: 'هل تريد الخروج من تطبيق معين؟',
          confirmLabel: 'إغلاق',
          icon: Icons.power_settings_new_rounded,
          color: AppColors.royalBlue,
        );
        if (close) await SystemNavigator.pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.cream,
        appBar: _DelegateAppBar(
          title: title,
          session: session,
          bottom: bottom,
          actions: actions,
        ),
        body: SafeArea(child: child),
        floatingActionButton: floatingActionButton,
        drawer: _DelegateDrawer(currentIndex: currentIndex),
      ),
    );
  }
}

class _DelegateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DelegateAppBar({
    required this.title,
    this.session,
    this.bottom,
    this.actions,
  });

  final String title;
  final AuthSession? session;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + 8 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leadingWidth: 64,
          leading: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : Scaffold.of(context).openDrawer(),
                icon: Icon(
                  context.canPop()
                      ? Icons.arrow_back_rounded
                      : Icons.menu_rounded,
                  color: AppColors.royalBlue,
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              if (session != null)
                Text(
                  'لوحة المندوب - ${session!.name}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: actions ?? const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: _DelegateBadge(),
            ),
          ],
          bottom: bottom,
        ),
      ),
    );
  }
}

class _DelegateBadge extends StatelessWidget {
  const _DelegateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDeep],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'مندوب',
        style: TextStyle(
          color: AppColors.royalBlueDark,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DelegateDrawer extends ConsumerStatefulWidget {
  const _DelegateDrawer({required this.currentIndex});

  final int currentIndex;

  @override
  ConsumerState<_DelegateDrawer> createState() => _DelegateDrawerState();
}

class _DelegateDrawerState extends ConsumerState<_DelegateDrawer> {
  bool _checkingSubscription = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final subscription = ref.watch(delegateSubscriptionProvider).valueOrNull;
    final isSubscribed = subscription?.isSubscribed == true;
    final unread =
        ref.watch(delegateUnreadNotificationsCountProvider).valueOrNull ?? 0;
    final groups = _groups();

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.sizeOf(context).width * 0.84,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 20,
                  20,
                  24,
                ),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const MoeenLogo(compact: true, onDark: true),
                        ),
                        const Spacer(),
                        _SubscriptionBadge(isSubscribed: isSubscribed),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      session?.name ?? 'مندوب الدفعة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      session?.email ?? 'إدارة الدفعة والتواصل الأكاديمي',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  children: [
                    if (session?.canAccessStudentWorkspace == true) ...[
                      _WorkspaceSwitchTile(
                        label: 'الانتقال إلى حساب الطالب',
                        subtitle: 'عرض المقررات والدرجات ومركز الدراسة',
                        icon: Icons.school_rounded,
                        color: AppColors.royalBlue,
                        onTap: () => _switchToStudent(context, ref),
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (final group in groups) ...[
                      _DrawerGroupHeader(group.label),
                      for (final item in group.items)
                        _DrawerTile(
                          item: item,
                          selected: item.index == widget.currentIndex,
                          isSubscribed: isSubscribed,
                          badgeCount: item.route == DelegateRoutes.notifications
                              ? unread
                              : 0,
                          onTap: () => _go(item),
                        ),
                      const SizedBox(height: 12),
                    ],
                    const Divider(height: 32, indent: 20, endIndent: 20),
                    // Logout Item
                    ListTile(
                      onTap: () => _confirmLogout(context, ref),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.slate300,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'نسخة التطبيق 1.2.0',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
          if (_checkingSubscription)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_DrawerGroup> _groups() => const [
    _DrawerGroup('القائمة الرئيسية', [
      _DrawerItem(
        'الرئيسية',
        Icons.dashboard_rounded,
        0,
        DelegateRoutes.dashboard,
        false,
      ),
    ]),
    _DrawerGroup('إدارة الحساب', [
      _DrawerItem(
        'الملف الشخصي',
        Icons.person_rounded,
        20,
        DelegateRoutes.profile,
        false,
      ),
      _DrawerItem(
        'الاشتراك والرصيد',
        Icons.workspace_premium_rounded,
        18,
        DelegateRoutes.subscription,
        false,
      ),
      _DrawerItem(
        'كشف الحساب',
        Icons.receipt_long_rounded,
        19,
        DelegateRoutes.ledger,
        false,
      ),
    ]),
    _DrawerGroup('إدارة الدفعة والمهام', [
      _DrawerItem(
        'الطلاب',
        Icons.groups_rounded,
        3,
        DelegateRoutes.students,
        true,
      ),
      _DrawerItem(
        'المواد',
        Icons.auto_stories_rounded,
        4,
        DelegateRoutes.subjects,
        true,
      ),
      _DrawerItem(
        'الجدول الدراسي',
        Icons.calendar_month_rounded,
        5,
        DelegateRoutes.schedules,
        true,
      ),
      _DrawerItem(
        'جداول الاختبارات',
        Icons.fact_check_rounded,
        6,
        DelegateRoutes.exams,
        true,
      ),
      _DrawerItem(
        'التكاليف والواجبات',
        Icons.assignment_turned_in_rounded,
        7,
        DelegateRoutes.assignments,
        true,
      ),
      _DrawerItem(
        'مصادر المقرر',
        Icons.folder_special_rounded,
        8,
        DelegateRoutes.resources,
        true,
      ),
      _DrawerItem(
        'المكتبة المشتركة',
        Icons.library_add_rounded,
        9,
        DelegateRoutes.libraryImport,
        true,
      ),
      _DrawerItem(
        'التذكيرات',
        Icons.event_note_rounded,
        10,
        DelegateRoutes.reminders,
        true,
      ),
      _DrawerItem(
        'إعلانات الدفعة',
        Icons.campaign_rounded,
        11,
        DelegateRoutes.announcements,
        true,
      ),
    ]),
    _DrawerGroup('الحضور والدرجات', [
      _DrawerItem(
        'رصد الحضور',
        Icons.how_to_reg_rounded,
        12,
        DelegateRoutes.attendance,
        true,
      ),
      _DrawerItem(
        'إنذارات الغياب',
        Icons.warning_rounded,
        13,
        DelegateRoutes.absenceAlerts,
        true,
      ),
      _DrawerItem(
        'الدرجات المفوضة',
        Icons.grade_rounded,
        14,
        DelegateRoutes.authorizedGrades,
        true,
      ),
    ]),
    _DrawerGroup('التواصل والتنبيهات', [
      _DrawerItem(
        'أخبار الدفعة',
        Icons.newspaper_rounded,
        1,
        DelegateRoutes.news,
        true,
      ),
      _DrawerItem(
        'التنبيهات',
        Icons.notifications_active_rounded,
        2,
        DelegateRoutes.notifications,
        true,
      ),
      _DrawerItem(
        'رسائل الطلاب',
        Icons.forum_rounded,
        15,
        DelegateRoutes.messages,
        true,
      ),
      _DrawerItem(
        'محادثات الدكاترة',
        Icons.medical_services_rounded,
        16,
        DelegateRoutes.doctorChats,
        true,
      ),
      _DrawerItem(
        'استفسارات الدكتور',
        Icons.contact_support_rounded,
        17,
        DelegateRoutes.inquiries,
        true,
      ),
    ]),
  ];

  Future<void> _go(_DrawerItem item) async {
    if (!item.requiresSubscription) {
      Navigator.pop(context);
      context.go(item.route);
      return;
    }

    setState(() => _checkingSubscription = true);
    try {
      final subscription = await ref
          .read(delegateSubscriptionRepositoryProvider)
          .fetch();
      if (!mounted) return;
      if (subscription.isSubscribed) {
        Navigator.pop(context);
        context.go(item.route);
      } else {
        final subscribe = await showMoeenConfirmDialog(
          context: context,
          title: 'هذه الميزة تحتاج اشتراك',
          message: 'يجب الاشتراك للوصول إلى هذه الصفحة.',
          confirmLabel: 'الاشتراك الآن',
          icon: Icons.lock_rounded,
          color: AppColors.goldDeep,
        );
        if (subscribe && mounted) {
          Navigator.pop(context);
          context.go(DelegateRoutes.subscription);
        }
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingSubscription = false);
    }
  }

  Future<void> _switchToStudent(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    await ref
        .read(authControllerProvider.notifier)
        .switchWorkspace(AuthWorkspace.student);
    if (mounted) Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(StudentDashboardScreen.route);
    });
  }
}

class _WorkspaceSwitchTile extends StatelessWidget {
  const _WorkspaceSwitchTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            AppColors.gold.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.midnight,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        trailing: const Icon(
          Icons.swap_horiz_rounded,
          color: AppColors.slate400,
        ),
      ),
    );
  }
}

class _SubscriptionBadge extends StatelessWidget {
  const _SubscriptionBadge({required this.isSubscribed});

  final bool isSubscribed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSubscribed
            ? AppColors.gold.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isSubscribed ? 'مفعل' : 'أساسي',
        style: TextStyle(
          color: isSubscribed ? AppColors.gold : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DrawerGroupHeader extends StatelessWidget {
  const _DrawerGroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.slate400,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.isSubscribed,
    required this.badgeCount,
    required this.onTap,
  });

  final _DrawerItem item;
  final bool selected;
  final bool isSubscribed;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.royalBlue.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          item.icon,
          color: selected ? AppColors.royalBlue : AppColors.slate500,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? AppColors.royalBlue : AppColors.midnight,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : (item.requiresSubscription && !isSubscribed
                  ? const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.slate300,
                    )
                  : null),
      ),
    );
  }
}

class _DrawerGroup {
  const _DrawerGroup(this.label, this.items);
  final String label;
  final List<_DrawerItem> items;
}

class _DrawerItem {
  const _DrawerItem(
    this.label,
    this.icon,
    this.index,
    this.route,
    this.requiresSubscription,
  );
  final String label;
  final IconData icon;
  final int index;
  final String route;
  final bool requiresSubscription;
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showMoeenConfirmDialog(
    context: context,
    title: 'تسجيل الخروج',
    message: 'هل تريد تسجيل الخروج من حساب المندوب؟',
    confirmLabel: 'تسجيل الخروج',
    icon: Icons.logout_rounded,
    color: AppColors.rose,
    danger: true,
  );
  if (!confirmed) return;
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) context.go(LoginScreen.route);
}
