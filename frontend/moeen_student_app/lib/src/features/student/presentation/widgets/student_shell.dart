import 'dart:async';
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
import '../../../delegate/presentation/widgets/delegate_shell.dart';
import '../../../practical_delegate/presentation/practical_delegate_screens.dart';
import '../../data/student_repositories.dart';
import '../../logic/student_controllers.dart';
import '../student_content_screens.dart';
import '../student_dashboard_screen.dart';
import '../student_ledger_screen.dart';
import '../student_placeholder_screen.dart';
import '../student_subscription_screen.dart';

final studentUnreadNotificationsCountProvider = FutureProvider.autoDispose<int>(
  (ref) async {
    final data = await ref
        .watch(studentContentRepositoryProvider)
        .unreadNotificationsCount();
    final value = data['count'] ?? data['unread_count'] ?? data['total'] ?? 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  },
);

final studentUnreadScreenCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final data = await ref
          .watch(studentContentRepositoryProvider)
          .unreadNotificationsCount();
      final raw = data['by_screen'];
      if (raw is! Map) return const <String, int>{};
      return raw.map((key, value) {
        final count = value is num
            ? value.toInt()
            : int.tryParse('$value') ?? 0;
        return MapEntry(key.toString(), count);
      });
    });

final studentUnreadMessagesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final data = await ref.watch(studentContentRepositoryProvider).messages();
  final value = data['unread_count'] ?? data['count'] ?? data['total'] ?? 0;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value.toString());
  if (parsed != null) return parsed;
  final conversations = data['conversations'];
  if (conversations is! List) return 0;
  return conversations.fold<int>(0, (sum, item) {
    if (item is! Map) return sum;
    final unread = item['unread_count'] ?? 0;
    if (unread is num) return sum + unread.toInt();
    return sum + (int.tryParse(unread.toString()) ?? 0);
  });
});

final studentStarsBalanceProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final data = await ref.watch(studentContentRepositoryProvider).stars();
  final rawBalance = data['balance'];
  final balance = rawBalance is Map
      ? rawBalance.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
  final raw =
      balance['available'] ??
      balance['current'] ??
      balance['balance'] ??
      data['available'] ??
      data['current'] ??
      data['balance'] ??
      data['stars'] ??
      0;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
});

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.safeAreaBottom = true,
    this.parentRoute,
    this.onBackPressed,
    this.resizeToAvoidBottomInset,
    this.disableDrawer = false,
  });

  final int currentIndex;
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final bool safeAreaBottom;
  final String? parentRoute;
  final Future<bool> Function()? onBackPressed;
  final bool? resizeToAvoidBottomInset;
  final bool disableDrawer;

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _flashcardPromptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshBadges();
      _maybeShowFlashcardPrompt();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFlashcardPrompt();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      final session = ref.read(authControllerProvider).valueOrNull;
      if (session?.isSecondaryDevice != true) {
        unawaited(scheduleStudentFlashcardSmartReviewNotification(ref));
      }
    }
    if (state == AppLifecycleState.resumed) {
      _refreshBadges();
      _maybeShowFlashcardPrompt();
    }
  }

  void _refreshBadges() {
    ref.invalidate(studentUnreadNotificationsCountProvider);
    ref.invalidate(studentUnreadScreenCountsProvider);
    ref.invalidate(studentUnreadMessagesCountProvider);
    ref.invalidate(studentStarsBalanceProvider);
  }

  Future<void> _maybeShowFlashcardPrompt() async {
    if (!mounted || _flashcardPromptOpen) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session?.isSecondaryDevice == true) return;
    final path = GoRouterState.of(context).uri.path;
    if (path == StudentFlashcardsScreen.quickReviewRoute ||
        path.endsWith('/review') ||
        path.startsWith('/student/quizzes')) {
      return;
    }
    _flashcardPromptOpen = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await showStudentFlashcardSmartReviewPrompt(context: context, ref: ref);
    } finally {
      _flashcardPromptOpen = false;
    }
  }

  Future<void> _handleSystemBack() async {
    final customBack = widget.onBackPressed;
    if (customBack != null && await customBack()) {
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    final parentRoute = widget.parentRoute;
    if (parentRoute != null && parentRoute.isNotEmpty) {
      context.go(parentRoute);
      return;
    }
    if (widget.currentIndex != 0) {
      context.go(StudentDashboardScreen.route);
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
  }

  Future<void> _handleAppBarLeading() async {
    final customBack = widget.onBackPressed;
    if (customBack != null && await customBack()) {
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    final parentRoute = widget.parentRoute;
    if (parentRoute != null && parentRoute.isNotEmpty) {
      context.go(parentRoute);
      return;
    }
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final unreadNotifications =
        ref.watch(studentUnreadNotificationsCountProvider).valueOrNull ?? 0;
    final starsBalance =
        ref.watch(studentStarsBalanceProvider).valueOrNull ?? 0;
    final hasBackTarget =
        context.canPop() ||
        widget.onBackPressed != null ||
        (widget.parentRoute != null && widget.parentRoute!.isNotEmpty);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleSystemBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.cream,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        appBar: _PremiumAppBar(
          title: widget.title,
          session: session,
          unreadNotifications: unreadNotifications,
          starsBalance: starsBalance,
          hasBackTarget: hasBackTarget,
          onLeadingPressed: () => unawaited(_handleAppBarLeading()),
          disableActions: widget.disableDrawer,
        ),
        body: SafeArea(bottom: widget.safeAreaBottom, child: widget.child),
        floatingActionButton: widget.floatingActionButton,
        drawer: widget.disableDrawer
            ? null
            : _StudentDrawer(currentIndex: widget.currentIndex),
        drawerEnableOpenDragGesture: !widget.disableDrawer,
      ),
    );
  }
}

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PremiumAppBar({
    required this.title,
    required this.session,
    required this.unreadNotifications,
    required this.starsBalance,
    required this.hasBackTarget,
    required this.onLeadingPressed,
    this.disableActions = false,
  });
  final String title;
  final AuthSession? session;
  final int unreadNotifications;
  final int starsBalance;
  final bool hasBackTarget;
  final VoidCallback onLeadingPressed;
  final bool disableActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
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
                onPressed: onLeadingPressed,
                icon: Icon(
                  hasBackTarget ? Icons.arrow_back_rounded : Icons.menu_rounded,
                  color: AppColors.royalBlue,
                  size: 22,
                ),
                tooltip: hasBackTarget ? 'رجوع' : 'القائمة',
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
                  letterSpacing: -0.5,
                ),
              ),
              if (session != null)
                Text(
                  'مرحباً بك، ${session!.name}',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: disableActions
              ? const []
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: InkWell(
                      onTap: () => context.go(StudentStarsScreen.route),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: AppColors.goldDeep,
                              size: 19,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              starsBalance > 999
                                  ? '999+'
                                  : starsBalance.toString(),
                              style: const TextStyle(
                                color: AppColors.royalBlueDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.18),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                context.go(StudentNotificationsScreen.route),
                            icon: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.goldDeep,
                              size: 21,
                            ),
                            tooltip: 'التنبيهات',
                          ),
                        ),
                        if (unreadNotifications > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 19,
                                minHeight: 19,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadNotifications > 99
                                    ? '99+'
                                    : unreadNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (session?.isPracticalDelegate == true)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldDeep],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    ),
                  const SizedBox(width: 8),
                ],
        ),
      ),
    );
  }
}

class _StudentDrawer extends ConsumerStatefulWidget {
  const _StudentDrawer({required this.currentIndex});

  final int currentIndex;

  @override
  ConsumerState<_StudentDrawer> createState() => _StudentDrawerState();
}

class _StudentDrawerState extends ConsumerState<_StudentDrawer> {
  bool _checkingSubscription = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final subscription = ref.watch(subscriptionControllerProvider).valueOrNull;
    final isSubscribed = subscription?.isSubscribed == true;
    final dashboardClinical = ref
        .watch(studentDashboardControllerProvider)
        .valueOrNull
        ?.overview
        .hasClinical;
    final hasClinical = dashboardClinical ?? session?.hasClinical == true;
    final unreadNotifications =
        ref.watch(studentUnreadNotificationsCountProvider).valueOrNull ?? 0;
    final unreadByScreen =
        ref.watch(studentUnreadScreenCountsProvider).valueOrNull ??
        const <String, int>{};
    final unreadMessages =
        ref.watch(studentUnreadMessagesCountProvider).valueOrNull ?? 0;
    final isSecondaryDevice = session?.isSecondaryDevice == true;

    final groups = [
      _DrawerGroup('القائمة الرئيسية', [
        _DrawerItem(
          'الرئيسية',
          Icons.dashboard_rounded,
          0,
          StudentDashboardScreen.route,
          false,
        ),
        _DrawerItem(
          'تحضير QR سريع',
          Icons.qr_code_scanner_rounded,
          20,
          StudentQrScanScreen.route,
          false,
          true,
        ),
      ]),
      _DrawerGroup('حساب الطالب', [
        _DrawerItem(
          'الملف الشخصي',
          Icons.person_rounded,
          18,
          StudentProfileScreen.route,
          false,
        ),
        _DrawerItem(
          'الاشتراك والرصيد',
          Icons.workspace_premium_rounded,
          1,
          StudentSubscriptionScreen.route,
          false,
        ),
        _DrawerItem(
          'السجل المالي',
          Icons.receipt_long_rounded,
          2,
          StudentLedgerScreen.route,
          false,
        ),
      ]),
      _DrawerGroup('الأدوات الدراسية', [
        _DrawerItem(
          'المقررات الدراسية',
          Icons.auto_stories_rounded,
          3,
          StudentSubjectsScreen.route,
          true,
        ),
        _DrawerItem(
          'مركز الدراسة',
          Icons.local_library_rounded,
          4,
          StudentStudyCenterScreen.route,
          true,
        ),
        _DrawerItem(
          'الجدول الدراسي',
          Icons.calendar_month_rounded,
          5,
          StudentScheduleScreen.route,
          true,
        ),
        _DrawerItem(
          'جداول الاختبارات',
          Icons.fact_check_rounded,
          10,
          StudentExamsScreen.route,
          true,
        ),
        _DrawerItem(
          'مصادر المقرر',
          Icons.folder_special_rounded,
          11,
          StudentResourcesScreen.route,
          true,
        ),
        _DrawerItem(
          'One Line Shot',
          Icons.bolt_rounded,
          15,
          StudentFlashcardsScreen.route,
          true,
          true,
        ),
        _DrawerItem(
          'التكاليف والواجبات',
          Icons.assignment_turned_in_rounded,
          14,
          StudentAssignmentsScreen.route,
          true,
        ),
        _DrawerItem(
          'الدرجات المفوضة',
          Icons.assignment_ind_rounded,
          36,
          StudentAuthorizedGradesScreen.route,
          true,
        ),
        _DrawerItem(
          'التذكيرات',
          Icons.event_note_rounded,
          13,
          StudentRemindersScreen.route,
          true,
        ),
        _DrawerItem(
          'المكتبة المشتركة',
          Icons.library_books_rounded,
          12,
          StudentLibraryScreen.route,
          true,
        ),
        if (hasClinical)
          _DrawerItem(
            'القسم العملي والسريري',
            Icons.local_hospital_rounded,
            34,
            StudentClinicalScreen.route,
            true,
          ),
      ]),
      _DrawerGroup('التواصل والدعم', [
        _DrawerItem(
          'الأخبار والإعلانات',
          Icons.campaign_rounded,
          6,
          StudentNewsScreen.route,
          true,
        ),
        _DrawerItem(
          'التنبيهات',
          Icons.notifications_active_rounded,
          9,
          StudentNotificationsScreen.route,
          true,
        ),
        _DrawerItem(
          'الرسائل',
          Icons.forum_rounded,
          16,
          StudentMessagesScreen.route,
          true,
        ),
        _DrawerItem(
          'استفسارات الدكتور',
          Icons.contact_support_rounded,
          17,
          StudentInquiriesScreen.route,
          true,
        ),
      ]),
      _DrawerGroup('المكافآت والتقييم', [
        _DrawerItem(
          'الكويزات',
          Icons.quiz_rounded,
          7,
          StudentQuizzesScreen.route,
          true,
          true,
        ),
        _DrawerItem(
          'نجومي',
          Icons.stars_rounded,
          8,
          StudentStarsScreen.route,
          true,
        ),
        _DrawerItem(
          'مزرعة الأشجار',
          Icons.park_rounded,
          35,
          StudentTreeFarmScreen.route,
          true,
        ),
      ]),
      if (session?.isPracticalDelegate == true)
        _DrawerGroup('العملي والسريري', [
          _DrawerItem(
            'مركز المندوب العملي',
            Icons.local_hospital_rounded,
            30,
            PracticalDelegateHomeScreen.route,
            true,
          ),
          _DrawerItem(
            'السجل العملي',
            Icons.menu_book_rounded,
            31,
            PracticalLogbookScreen.route,
            true,
          ),
          _DrawerItem(
            'مراجعة الحالات',
            Icons.rule_rounded,
            32,
            PracticalCasesScreen.route,
            true,
          ),
          _DrawerItem(
            'تفويض مساعدين',
            Icons.group_add_rounded,
            33,
            PracticalDelegationsScreen.route,
            true,
          ),
        ]),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.sizeOf(context).width * 0.82,
      child: Stack(
        children: [
          Column(
            children: [
              // Premium Header
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
                      session?.name ?? 'طالب معين',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      session?.email ?? 'مرحباً بك في تطبيقك التعليمي',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  children: [
                    if (session?.canAccessDelegateWorkspace == true) ...[
                      _WorkspaceSwitchTile(
                        label: 'الانتقال إلى لوحة المندوب',
                        subtitle: 'إدارة الدفعة والمهام من نفس الحساب',
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppColors.teal,
                        onTap: () => _switchToDelegate(context, ref),
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (final group in groups) ...[
                      _DrawerGroupHeader(group.label),
                      for (final item in group.items)
                        _DrawerTile(
                          item: item,
                          isSubscribed: isSubscribed,
                          selected: item.index == widget.currentIndex,
                          blockedBySecondaryDevice:
                              isSecondaryDevice && item.requiresPrimaryDevice,
                          badgeCount:
                              item.route == StudentNotificationsScreen.route
                              ? unreadNotifications
                              : (item.route == StudentMessagesScreen.route
                                    ? unreadMessages
                                    : _badgeForRoute(
                                        item.route,
                                        unreadByScreen,
                                      )),
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

  Future<void> _go(_DrawerItem item) async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (item.requiresPrimaryDevice && session?.isSecondaryDevice == true) {
      await showMoeenInfoDialog(
        context: context,
        title: 'متاح من الجهاز الأساسي فقط',
        message:
            'هذه الميزة لا تعمل من الجهاز الفرعي. استخدم الجهاز الأساسي للحضور، الكويزات، وOne Line Shot.',
        icon: Icons.phone_android_rounded,
        color: AppColors.orange,
      );
      return;
    }

    if (!item.requiresSubscription) {
      Navigator.pop(context);
      _navigate(item);
      return;
    }

    setState(() => _checkingSubscription = true);
    try {
      final subscription = await ref
          .read(subscriptionRepositoryProvider)
          .fetch();
      if (!mounted) return;
      if (subscription.isSubscribed) {
        Navigator.pop(context);
        _navigate(item);
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
          context.go(StudentSubscriptionScreen.route);
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

  void _navigate(_DrawerItem item) {
    if (item.route.startsWith('/student/')) {
      context.go(item.route);
    } else {
      context.go(StudentPlaceholderScreen.path(item.route));
    }
  }

  Future<void> _switchToDelegate(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    await ref
        .read(authControllerProvider.notifier)
        .switchWorkspace(AuthWorkspace.delegate);
    if (mounted) Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(DelegateRoutes.dashboard);
    });
  }
}

int _badgeForRoute(String route, Map<String, int> unreadByScreen) {
  final screen = switch (route) {
    StudentQuizzesScreen.route => 'quizzes',
    StudentAssignmentsScreen.route => 'assignments',
    StudentScheduleScreen.route => 'schedule',
    StudentRemindersScreen.route => 'reminders',
    StudentResourcesScreen.route => 'resources',
    StudentLibraryScreen.route => 'library',
    StudentAuthorizedGradesScreen.route => 'authorized_grades',
    StudentStarsScreen.route => 'stars',
    StudentInquiriesScreen.route => 'inquiries',
    StudentNewsScreen.route => 'news_hub',
    _ => null,
  };
  if (screen == null) return 0;
  return unreadByScreen[screen] ?? 0;
}

String _drawerLabel(_DrawerItem item) {
  if (item.index == 12) {
    return String.fromCharCodes([
      1575,
      1604,
      1605,
      1603,
      1578,
      1576,
      1577,
      32,
      1575,
      1604,
      1605,
      1588,
      1578,
      1585,
      1603,
      1577,
    ]);
  }
  return item.label;
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
    final item = _DrawerItem(this.label, icon, 0, '', false);
    final label = item.index == 12 ? 'المكتبة المشتركة' : item.label;
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
        style: TextStyle(
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
    required this.isSubscribed,
    required this.selected,
    required this.blockedBySecondaryDevice,
    required this.badgeCount,
    required this.onTap,
  });

  final _DrawerItem item;
  final bool isSubscribed;
  final bool selected;
  final bool blockedBySecondaryDevice;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final label = item.index == 12 ? 'المكتبة المشتركة' : item.label;
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
          size: 22,
        ),
        title: Text(
          _drawerLabel(item),
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
            : (blockedBySecondaryDevice
                  ? const Icon(
                      Icons.phone_locked_rounded,
                      size: 16,
                      color: AppColors.slate300,
                    )
                  : (item.requiresSubscription && !isSubscribed
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: AppColors.slate300,
                          )
                        : null)),
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
    this.requiresSubscription, [
    this.requiresPrimaryDevice = false,
  ]);
  final String label;
  final IconData icon;
  final int index;
  final String route;
  final bool requiresSubscription;
  final bool requiresPrimaryDevice;
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showMoeenConfirmDialog(
    context: context,
    title: 'تسجيل الخروج',
    message: 'هل تريد تسجيل الخروج من حسابك؟',
    confirmLabel: 'تسجيل الخروج',
    icon: Icons.logout_rounded,
    color: AppColors.rose,
    danger: true,
  );
  if (!confirmed) return;
  await ref.read(authControllerProvider.notifier).logout();
  if (context.mounted) context.go(LoginScreen.route);
}
