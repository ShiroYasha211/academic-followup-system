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

class StudentShell extends ConsumerWidget {
  const StudentShell({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final int currentIndex;
  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final unreadNotifications =
        ref.watch(studentUnreadNotificationsCountProvider).valueOrNull ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        if (currentIndex != 0) {
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
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.cream,
        appBar: _PremiumAppBar(
          title: title,
          session: session,
          unreadNotifications: unreadNotifications,
        ),
        body: SafeArea(bottom: false, child: child),
        floatingActionButton: floatingActionButton,
        drawer: _StudentDrawer(currentIndex: currentIndex),
      ),
    );
  }
}

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PremiumAppBar({
    required this.title,
    required this.session,
    required this.unreadNotifications,
  });
  final String title;
  final AuthSession? session;
  final int unreadNotifications;

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
                onPressed: () => context.canPop()
                    ? context.pop()
                    : Scaffold.of(context).openDrawer(),
                icon: Icon(
                  context.canPop()
                      ? Icons.arrow_back_rounded
                      : Icons.menu_rounded,
                  color: AppColors.royalBlue,
                  size: 22,
                ),
                tooltip: context.canPop() ? 'رجوع' : 'القائمة',
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
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
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
                margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
    final unreadNotifications =
        ref.watch(studentUnreadNotificationsCountProvider).valueOrNull ?? 0;

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
        ),
        _DrawerItem(
          'التكاليف والواجبات',
          Icons.assignment_turned_in_rounded,
          14,
          StudentAssignmentsScreen.route,
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
        ),
        _DrawerItem(
          'نجومي',
          Icons.stars_rounded,
          8,
          StudentStarsScreen.route,
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
                    for (final group in groups) ...[
                      _DrawerGroupHeader(group.label),
                      for (final item in group.items)
                        _DrawerTile(
                          item: item,
                          isSubscribed: isSubscribed,
                          selected: item.index == widget.currentIndex,
                          badgeCount:
                              item.route == StudentNotificationsScreen.route
                              ? unreadNotifications
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

  Future<void> _go(_DrawerItem item) async {
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
            isSubscribed ? 'مميز' : 'أساسي',
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
    required this.badgeCount,
    required this.onTap,
  });

  final _DrawerItem item;
  final bool isSubscribed;
  final bool selected;
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
