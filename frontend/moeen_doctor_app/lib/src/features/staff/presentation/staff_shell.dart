import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../auth/data/staff_auth_session.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../logic/staff_account_controllers.dart';
import 'staff_screens.dart';

class StaffShell extends ConsumerWidget {
  const StaffShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.floatingActionButton,
    this.onBackPressed,
    this.onBeforeNavigate,
  });

  final String title;
  final String currentRoute;
  final Widget child;
  final Widget? floatingActionButton;
  final Future<bool> Function()? onBackPressed;
  final Future<bool> Function(String route)? onBeforeNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final customBack = onBackPressed;
        if (customBack != null && await customBack()) return;
        if (!context.mounted) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (currentRoute != StaffDashboardScreen.route) {
          context.go(StaffDashboardScreen.route);
          return;
        }
        final close = await showMoeenConfirmDialog(
          context: context,
          title: 'إغلاق التطبيق',
          message: 'هل تريد الخروج من تطبيق معين؟',
          confirmLabel: 'إغلاق',
          icon: Icons.power_settings_new_rounded,
        );
        if (!context.mounted) return;
        if (close) await SystemNavigator.pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.cream,
        appBar: _StaffAppBar(
          title: title,
          session: session,
          onBackPressed: onBackPressed,
          currentRoute: currentRoute,
        ),
        drawer: _StaffDrawer(
          currentRoute: currentRoute,
          onBeforeNavigate: onBeforeNavigate,
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: child),
      ),
    );
  }
}

class _StaffAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StaffAppBar({
    required this.title,
    required this.session,
    required this.onBackPressed,
    required this.currentRoute,
  });

  final String title;
  final StaffAuthSession? session;
  final Future<bool> Function()? onBackPressed;
  final String currentRoute;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

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
                onPressed: () {
                  final customBack = onBackPressed;
                  if (customBack != null) {
                    customBack();
                    return;
                  }
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  Scaffold.of(context).openDrawer();
                },
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
              if (session != null && currentRoute == '/staff/dashboard')
                Text(
                  'أهلاً بك، ${session!.name}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _StaffBadge(workspace: session?.workspace),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDrawer extends ConsumerStatefulWidget {
  const _StaffDrawer({
    required this.currentRoute,
    required this.onBeforeNavigate,
  });

  final String currentRoute;
  final Future<bool> Function(String route)? onBeforeNavigate;

  @override
  ConsumerState<_StaffDrawer> createState() => _StaffDrawerState();
}

class _StaffDrawerState extends ConsumerState<_StaffDrawer> {
  bool _checkingSubscription = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final workspace = session?.workspace ?? StaffWorkspace.doctor;
    final subscription = ref
        .watch(staffSubscriptionProvider(workspace))
        .valueOrNull;
    final isSubscribed = subscription?.isSubscribed == true;
    final groups = _groups(workspace);

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.sizeOf(context).width * 0.82,
      child: Stack(
        children: [
          Column(
            children: [
              // Premium Frosted Header with Curved Border
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 20,
                  20,
                  24,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
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
                      session?.name ?? 'الكادر الدراسي',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      session?.email ?? 'إدارة العملية الأكاديمية',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Menu List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    if (session != null &&
                        session.availableWorkspaces.length > 1) ...[
                      _WorkspaceSwitchTile(
                        label: workspace == StaffWorkspace.doctor
                            ? 'الانتقال إلى لوحة المسؤول الإداري'
                            : 'الانتقال إلى لوحة الدكتور',
                        subtitle: workspace == StaffWorkspace.doctor
                            ? 'إدارة الكلية والطلاب والمندوبين'
                            : 'متابعة المواد والحضور والتواصل',
                        icon: workspace == StaffWorkspace.doctor
                            ? Icons.admin_panel_settings_rounded
                            : Icons.school_rounded,
                        color: workspace == StaffWorkspace.doctor
                            ? AppColors.violet
                            : AppColors.royalBlue,
                        onTap: () => _switchWorkspace(
                          workspace == StaffWorkspace.doctor
                              ? StaffWorkspace.administrative
                              : StaffWorkspace.doctor,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final group in groups) ...[
                      _DrawerGroupHeader(group.label),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.slate100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            for (final item in group.items)
                              _DrawerTile(
                                item: item,
                                selected: item.route == widget.currentRoute,
                                isSubscribed: isSubscribed,
                                onTap: () => _go(item, workspace),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              // Pinned Footer Card for Logout
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.slate100)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ListTile(
                        onTap: _logout,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
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
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'نسخة التطبيق 1.2.0',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

  Future<void> _go(_DrawerItem item, StaffWorkspace workspace) async {
    if (item.route != widget.currentRoute) {
      final guard = widget.onBeforeNavigate;
      if (guard != null && !await guard(item.route)) return;
    }
    if (!mounted) return;

    if (!item.requiresSubscription) {
      Navigator.pop(context);
      context.go(item.route);
      return;
    }

    setState(() => _checkingSubscription = true);
    try {
      final subscription = await ref
          .read(staffAccountRepositoryProvider)
          .subscription(workspace);
      if (!mounted) return;
      if (subscription.isSubscribed) {
        Navigator.pop(context);
        context.go(item.route);
        return;
      }
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
        context.go(_subscriptionRoute(workspace));
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

  Future<void> _switchWorkspace(StaffWorkspace workspace) async {
    final targetRoute = StaffDashboardScreen.route;
    final guard = widget.onBeforeNavigate;
    if (guard != null && !await guard(targetRoute)) return;
    if (!mounted) return;

    final router = GoRouter.of(context);
    await ref.read(authControllerProvider.notifier).switchWorkspace(workspace);
    if (mounted) Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(StaffDashboardScreen.route);
    });
  }

  Future<void> _logout() async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تسجيل الخروج',
      message: 'هل تريد تسجيل الخروج من حسابك؟',
      confirmLabel: 'تسجيل الخروج',
      icon: Icons.logout_rounded,
      color: AppColors.danger,
    );
    if (!approved) return;
    final guard = widget.onBeforeNavigate;
    if (guard != null && !await guard(LoginScreen.route)) return;
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(LoginScreen.route);
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
    this.route,
    this.requiresSubscription,
  );

  final String label;
  final IconData icon;
  final String route;
  final bool requiresSubscription;
}

List<_DrawerGroup> _groups(StaffWorkspace workspace) {
  if (workspace == StaffWorkspace.administrative) {
    return const [
      _DrawerGroup('القائمة الرئيسية', [
        _DrawerItem(
          'الرئيسية',
          Icons.dashboard_rounded,
          StaffDashboardScreen.route,
          false,
        ),
      ]),
      _DrawerGroup('إدارة الحساب', [
        _DrawerItem(
          'الملف الشخصي',
          Icons.person_rounded,
          StaffProfileScreen.route,
          false,
        ),
        _DrawerItem(
          'الاشتراك والرصيد',
          Icons.workspace_premium_rounded,
          '/administrative/subscription',
          false,
        ),
        _DrawerItem(
          'كشف الحساب',
          Icons.receipt_long_rounded,
          '/administrative/ledger',
          false,
        ),
        _DrawerItem(
          'جداول الاختبارات',
          Icons.event_note_rounded,
          '/administrative/exams',
          false,
        ),
        _DrawerItem(
          'الجداول الدراسية',
          Icons.calendar_month_rounded,
          '/administrative/schedules',
          false,
        ),
      ]),
      _DrawerGroup('إعدادات الكلية', [
        _DrawerItem(
          'إعدادات الكلية',
          Icons.settings_rounded,
          '/administrative/settings',
          false,
        ),
      ]),
      _DrawerGroup('الشؤون الأكاديمية', [
        _DrawerItem(
          'التخصصات',
          Icons.account_tree_rounded,
          '/administrative/majors',
          true,
        ),
        _DrawerItem(
          'المواد',
          Icons.menu_book_rounded,
          '/administrative/subjects',
          true,
        ),
      ]),
      _DrawerGroup('إدارة الشؤون', [
        _DrawerItem(
          'الدكاترة',
          Icons.school_rounded,
          '/administrative/doctors',
          true,
        ),
        _DrawerItem(
          'الطلاب',
          Icons.groups_rounded,
          '/administrative/students',
          true,
        ),
        _DrawerItem(
          'المندوبون',
          Icons.admin_panel_settings_rounded,
          '/administrative/delegates',
          true,
        ),
        _DrawerItem(
          'الأعذار',
          Icons.verified_rounded,
          '/administrative/excuses',
          true,
        ),
      ]),
      _DrawerGroup('المحتوى والتقارير', [
        _DrawerItem(
          'إشعارات الكلية',
          Icons.notifications_active_rounded,
          '/administrative/notifications',
          true,
        ),
        _DrawerItem(
          'التقارير',
          Icons.analytics_rounded,
          '/administrative/reports',
          true,
        ),
      ]),
    ];
  }

  return const [
    _DrawerGroup('القائمة الرئيسية', [
      _DrawerItem(
        'الرئيسية',
        Icons.dashboard_rounded,
        StaffDashboardScreen.route,
        false,
      ),
    ]),
    _DrawerGroup('إدارة الحساب', [
      _DrawerItem(
        'الملف الشخصي',
        Icons.person_rounded,
        StaffProfileScreen.route,
        false,
      ),
      _DrawerItem(
        'الاشتراك والرصيد',
        Icons.workspace_premium_rounded,
        '/doctor/subscription',
        false,
      ),
      _DrawerItem(
        'كشف الحساب',
        Icons.receipt_long_rounded,
        '/doctor/ledger',
        false,
      ),
    ]),
    _DrawerGroup('الأكاديمية', [
      _DrawerItem(
        'الحضور',
        Icons.fact_check_rounded,
        '/doctor/attendance',
        true,
      ),
      _DrawerItem(
        'أعذار الغياب',
        Icons.verified_user_rounded,
        '/doctor/excuses',
        true,
      ),
      _DrawerItem(
        'التكاليف',
        Icons.assignment_rounded,
        '/doctor/assignments',
        true,
      ),
      _DrawerItem('الدرجات', Icons.grade_rounded, '/doctor/grades', true),
      _DrawerItem('التقارير', Icons.analytics_rounded, '/doctor/reports', true),
      _DrawerItem(
        'القسم السريري',
        Icons.medical_services_rounded,
        '/doctor/clinical',
        true,
      ),
    ]),
    _DrawerGroup('التواصل والمحتوى', [
      _DrawerItem(
        'استفسارات الطلاب',
        Icons.forum_rounded,
        '/doctor/inquiries',
        true,
      ),
      _DrawerItem(
        'إعلاناتي',
        Icons.campaign_rounded,
        '/doctor/announcements',
        true,
      ),
      _DrawerItem('الكويزات', Icons.quiz_rounded, '/doctor/quizzes', true),
      _DrawerItem('النجوم', Icons.stars_rounded, '/doctor/stars', true),
      _DrawerItem(
        'المكتبة المشتركة',
        Icons.local_library_rounded,
        '/doctor/library',
        true,
      ),
      _DrawerItem('الرسائل', Icons.chat_rounded, '/doctor/messages', true),
      _DrawerItem('الأخبار', Icons.newspaper_rounded, '/doctor/news', true),
      _DrawerItem(
        'الإشعارات',
        Icons.notifications_rounded,
        '/doctor/notifications',
        true,
      ),
    ]),
  ];
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
            ? AppColors.gold.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed
              ? AppColors.gold.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSubscribed
                ? Icons.workspace_premium_rounded
                : Icons.info_outline_rounded,
            color: isSubscribed ? AppColors.gold : Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isSubscribed ? 'مشترك' : 'أساسي',
            style: TextStyle(
              color: isSubscribed ? AppColors.gold : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
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
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.slate400,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
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
    required this.onTap,
  });

  final _DrawerItem item;
  final bool selected;
  final bool isSubscribed;
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
        border: selected
            ? const BorderDirectional(
                start: BorderSide(color: AppColors.royalBlue, width: 4),
              )
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          item.icon,
          color: selected ? AppColors.royalBlue : AppColors.slate500,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? AppColors.royalBlue : AppColors.midnight,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: item.requiresSubscription && !isSubscribed
            ? const Icon(
                Icons.lock_rounded,
                size: 16,
                color: AppColors.slate300,
              )
            : null,
      ),
    );
  }
}

class _StaffBadge extends StatelessWidget {
  const _StaffBadge({required this.workspace});

  final StaffWorkspace? workspace;

  @override
  Widget build(BuildContext context) {
    if (workspace == null) return const SizedBox.shrink();
    final isAdmin = workspace == StaffWorkspace.administrative;
    final color = isAdmin ? AppColors.violet : AppColors.royalBlue;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.school_rounded,
              color: color,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              _workspaceBadgeLabel(workspace),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _workspaceBadgeLabel(StaffWorkspace? workspace) {
  return workspace == StaffWorkspace.administrative ? 'إداري' : 'دكتور';
}

String _subscriptionRoute(StaffWorkspace workspace) {
  return workspace == StaffWorkspace.administrative
      ? '/administrative/subscription'
      : '/doctor/subscription';
}
