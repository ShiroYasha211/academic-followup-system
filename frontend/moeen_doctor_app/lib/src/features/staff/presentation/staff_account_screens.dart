import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/downloads/download_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/refresh/staff_refresh_coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/status_message.dart';
import '../../auth/data/staff_auth_session.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/staff_account_models.dart';
import '../logic/staff_account_controllers.dart';
import 'staff_shell.dart';

class StaffAccountDashboardScreen extends ConsumerWidget {
  const StaffAccountDashboardScreen({super.key});

  static const route = '/staff/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final workspace = session?.workspace ?? StaffWorkspace.doctor;
    final state = ref.watch(staffDashboardProvider(workspace));
    final refreshState = ref.watch(staffRefreshCoordinatorProvider);

    return StaffShell(
      title: 'لوحة التحكم',
      currentRoute: route,
      child: state.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(error: error),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffDashboardProvider(workspace)),
          child: dashboard.isAdministrative
              ? _AdministrativeDashboardView(
                  data: dashboard.raw,
                  offlineBanner: _DashboardOfflineBanner(
                    dashboard: dashboard,
                    online: refreshState.online,
                    refreshing: refreshState.refreshing,
                  ),
                )
              : _DoctorDashboardView(
                  data: dashboard.raw,
                  offlineBanner: _DashboardOfflineBanner(
                    dashboard: dashboard,
                    online: refreshState.online,
                    refreshing: refreshState.refreshing,
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashboardOfflineBanner extends StatelessWidget {
  const _DashboardOfflineBanner({
    required this.dashboard,
    required this.online,
    required this.refreshing,
  });

  final StaffDashboardData dashboard;
  final bool online;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    if (online && !dashboard.fromCache && !refreshing) {
      return const SizedBox.shrink();
    }
    final color = dashboard.fromCache || !online
        ? AppColors.warning
        : AppColors.royalBlue;
    final message = dashboard.fromCache
        ? 'تعمل الآن على آخر بيانات محفوظة${_cachedAtText(dashboard.cachedAt)}'
        : refreshing
        ? 'جاري تحديث بيانات الصفحة...'
        : 'لا يوجد اتصال بالإنترنت';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            dashboard.fromCache || !online
                ? Icons.cloud_off_rounded
                : Icons.sync_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cachedAtText(DateTime? value) {
    if (value == null ||
        value.millisecondsSinceEpoch == 0 ||
        value.year < 2001) {
      return '';
    }
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return ' منذ لحظات';
    if (diff.inHours < 1) return ' منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return ' منذ ${diff.inHours} ساعة';
    return ' منذ ${diff.inDays} يوم';
  }
}

class StaffSubscriptionScreen extends ConsumerStatefulWidget {
  const StaffSubscriptionScreen({
    super.key,
    required this.workspace,
    required this.currentRoute,
  });

  final StaffWorkspace workspace;
  final String currentRoute;

  @override
  ConsumerState<StaffSubscriptionScreen> createState() =>
      _StaffSubscriptionScreenState();
}

class _StaffSubscriptionScreenState
    extends ConsumerState<StaffSubscriptionScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffSubscriptionProvider(widget.workspace));
    return StaffShell(
      title: 'الاشتراك والرصيد',
      currentRoute: widget.currentRoute,
      child: state.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(error: error),
        data: (overview) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffSubscriptionProvider(widget.workspace)),
          child: ListView(
            padding: AppDimensions.pagePadding,
            children: [
              _BalanceHeader(overview: overview),
              const SizedBox(height: AppDimensions.sectionGapLarge),
              const _SectionTitle(
                title: 'شحن الرصيد',
                icon: Icons.add_card_rounded,
              ),
              const SizedBox(height: 12),
              _RedeemCard(
                controller: _codeController,
                loading: _loading,
                onRedeem: _redeem,
              ),
              const SizedBox(height: AppDimensions.sectionGapLarge),
              _AutoRenewCard(
                value: overview.autoRenew,
                loading: _loading,
                onChanged: _toggleAutoRenew,
              ),
              const SizedBox(height: AppDimensions.sectionGapLarge),
              const _SectionTitle(
                title: 'باقات الاشتراك المتاحة',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 14),
              if (overview.packages.isEmpty)
                const _EmptyCard(message: 'لا توجد باقات متاحة حاليًا.')
              else
                ...overview.packages.map(
                  (package) => _PackageCard(
                    package: package,
                    disabled: overview.isSubscribed || _loading,
                    onSubscribe: () => _confirmSubscribe(package),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim().replaceAll('-', '').toUpperCase();
    if (code.length != 12) {
      _show('كود الكرت يجب أن يتكون من 12 حرفًا.', error: true);
      return;
    }
    await _run(
      () => ref
          .read(staffSubscriptionProvider(widget.workspace).notifier)
          .redeem(code),
    );
    _codeController.clear();
  }

  Future<void> _confirmSubscribe(StaffSubscriptionPackage package) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الاشتراك',
      message:
          'سيتم خصم ${_money(package.effectivePrice)} لتفعيل باقة ${package.name} لمدة ${package.durationDays} يوم.',
      confirmLabel: 'اشترك الآن',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.goldDeep,
    );
    if (!approved) return;
    await _run(
      () => ref
          .read(staffSubscriptionProvider(widget.workspace).notifier)
          .subscribe(package.id),
    );
  }

  Future<void> _toggleAutoRenew(bool value) {
    return _run(
      () => ref
          .read(staffSubscriptionProvider(widget.workspace).notifier)
          .toggleAutoRenew(value),
    );
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _loading = true);
    try {
      final message = await action();
      _show(message);
    } on ApiException catch (error) {
      _show(error.message, error: true);
    } catch (error) {
      _show(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class StaffLedgerScreen extends ConsumerStatefulWidget {
  const StaffLedgerScreen({
    super.key,
    required this.workspace,
    required this.currentRoute,
  });

  final StaffWorkspace workspace;
  final String currentRoute;

  @override
  ConsumerState<StaffLedgerScreen> createState() => _StaffLedgerScreenState();
}

class _StaffLedgerScreenState extends ConsumerState<StaffLedgerScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffLedgerProvider(widget.workspace));
    return StaffShell(
      title: 'كشف الحساب المالي',
      currentRoute: widget.currentRoute,
      child: state.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(error: error),
        data: (ledger) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffLedgerProvider(widget.workspace)),
          child: ListView(
            padding: AppDimensions.pagePadding,
            children: [
              _LedgerHeader(
                ledger: ledger,
                exporting: _exporting,
                onExport: _export,
              ),
              const SizedBox(height: AppDimensions.sectionGapLarge),
              const _SectionTitle(
                title: 'سجل العمليات الأحدث',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 14),
              if (ledger.transactions.isEmpty)
                const _EmptyCard(message: 'لا توجد حركات مالية مسجلة بعد.')
              else ...[
                ...ledger.transactions.map(_TransactionTile.new),
                const SizedBox(height: 16),
                _LedgerPagination(ledger: ledger, workspace: widget.workspace),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffLedgerProvider(widget.workspace).notifier)
          .exportPdf();
      if (bytes.isEmpty) {
        throw const ApiException('لم يتم تحميل ملف كشف الحساب.');
      }
      if (!_looksLikePdf(bytes)) {
        throw const ApiException(
          'الملف الذي أعاده الخادم ليس ملف PDF صالحًا. يرجى مراجعة الخادم.',
        );
      }
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName:
            'moeen_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
        section: widget.workspace == StaffWorkspace.administrative
            ? 'AdministrativeLedger'
            : 'DoctorLedger',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل كشف الحساب',
        message: result.opened
            ? 'تم تحميل وفتح ملف PDF بنجاح.\n${result.path}'
            : 'تم تحميل الملف في:\n${result.path}\nلكن تعذر فتحه تلقائيًا على هذا الجهاز.',
        icon: result.opened ? Icons.check_circle_rounded : Icons.folder_rounded,
        color: result.opened ? AppColors.success : AppColors.goldDeep,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر تحميل كشف الحساب',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class StaffAdministrativeSettingsScreen extends ConsumerStatefulWidget {
  const StaffAdministrativeSettingsScreen({super.key});

  static const route = '/administrative/settings';

  @override
  ConsumerState<StaffAdministrativeSettingsScreen> createState() =>
      _StaffAdministrativeSettingsScreenState();
}

class _StaffAdministrativeSettingsScreenState
    extends ConsumerState<StaffAdministrativeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _absenceController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _qrRotationController = TextEditingController();
  String _excuseReceiver = 'administrative';
  int? _loadedSettingsId;
  bool _saving = false;

  @override
  void dispose() {
    _absenceController.dispose();
    _deadlineController.dispose();
    _qrRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffAdministrativeSettingsProvider);
    return StaffShell(
      title: 'إعدادات الكلية',
      currentRoute: StaffAdministrativeSettingsScreen.route,
      child: state.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(error: error),
        data: (settings) {
          _sync(settings);
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(staffAdministrativeSettingsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _DashboardHero(
                  title: settings.name.isEmpty
                      ? 'إعدادات النظام'
                      : 'إعدادات ${settings.name}',
                  subtitle:
                      'تحديد قواعد الحضور، الأعذار، وتجدد رموز QR الخاصة بالكلية.',
                  icon: Icons.settings_rounded,
                  compact: false,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'نسبة الحرمان',
                      value: '${settings.absenceDeprivationPercentage}%',
                      icon: Icons.block_rounded,
                      color: AppColors.danger,
                    ),
                    _StatCard(
                      label: 'مهلة الأعذار',
                      value: '${settings.excusesDeadlineDays} يوم',
                      icon: Icons.verified_rounded,
                      color: AppColors.teal,
                    ),
                    _StatCard(
                      label: 'تجدد QR',
                      value: '${settings.qrRotationSeconds} ثانية',
                      icon: Icons.qr_code_2_rounded,
                      color: AppColors.royalBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(radius: 24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: 'القواعد التنظيمية',
                          icon: Icons.tune_rounded,
                        ),
                        const SizedBox(height: 18),
                        _SettingsNumberField(
                          controller: _absenceController,
                          label: 'نسبة الحرمان من المادة',
                          suffix: '%',
                          helper:
                              'النسبة التي يحرم بعدها الطالب من المادة بسبب الغياب.',
                          min: 1,
                          max: 100,
                        ),
                        const SizedBox(height: 16),
                        _SettingsNumberField(
                          controller: _deadlineController,
                          label: 'آخر موعد لتقديم العذر',
                          suffix: 'يوم',
                          helper:
                              'عدد الأيام المسموح بها لتقديم عذر بعد تاريخ الغياب.',
                          min: 1,
                          max: 30,
                        ),
                        const SizedBox(height: 16),
                        _SettingsNumberField(
                          controller: _qrRotationController,
                          label: 'مدة تجدد رمز QR',
                          suffix: 'ثانية',
                          helper:
                              'الفترة بين كل رمز QR والرمز التالي في جلسات التحضير.',
                          min: 5,
                          max: 300,
                        ),
                        const SizedBox(height: 22),
                        const _SectionTitle(
                          title: 'استقبال الأعذار',
                          icon: Icons.assignment_turned_in_rounded,
                        ),
                        const SizedBox(height: 14),
                        _ReceiverChoice(
                          value: _excuseReceiver,
                          onChanged: (value) =>
                              setState(() => _excuseReceiver = value),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              backgroundColor: AppColors.royalBlue,
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _saving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _sync(StaffAdministrativeSettings settings) {
    if (_loadedSettingsId == settings.id) return;
    _loadedSettingsId = settings.id;
    _absenceController.text = settings.absenceDeprivationPercentage.toString();
    _deadlineController.text = settings.excusesDeadlineDays.toString();
    _qrRotationController.text = settings.qrRotationSeconds.toString();
    _excuseReceiver = settings.excuseReceiver;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final message = await ref
          .read(staffAdministrativeSettingsProvider.notifier)
          .save(
            absenceDeprivationPercentage: int.parse(_absenceController.text),
            excusesDeadlineDays: int.parse(_deadlineController.text),
            excuseReceiver: _excuseReceiver,
            qrRotationSeconds: int.parse(_qrRotationController.text),
          );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ الإعدادات',
        message: message,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'subscription_required' || error.statusCode == 402) {
        final approved = await showMoeenConfirmDialog(
          context: context,
          title: 'هذه الميزة تحتاج اشتراك',
          message: error.message,
          confirmLabel: 'الاشتراك الآن',
          cancelLabel: 'لاحقًا',
          icon: Icons.lock_rounded,
          color: AppColors.goldDeep,
        );
        if (approved && mounted) context.go('/administrative/subscription');
      } else {
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر حفظ الإعدادات',
          message: error.message,
          icon: Icons.error_rounded,
          color: AppColors.danger,
        );
      }
    } catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر حفظ الإعدادات',
        message: error.toString(),
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

bool _looksLikePdf(List<int> bytes) {
  if (bytes.length < 5) return false;
  for (var index = 0; index <= bytes.length - 5 && index < 32; index++) {
    if (bytes[index] == 0x25 &&
        bytes[index + 1] == 0x50 &&
        bytes[index + 2] == 0x44 &&
        bytes[index + 3] == 0x46 &&
        bytes[index + 4] == 0x2D) {
      return true;
    }
  }
  return false;
}

class StaffAccountProfileScreen extends ConsumerWidget {
  const StaffAccountProfileScreen({super.key});

  static const route = '/staff/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final workspace = session?.workspace ?? StaffWorkspace.doctor;
    final state = ref.watch(staffProfileProvider(workspace));
    return StaffShell(
      title: 'ملفي الشخصي',
      currentRoute: route,
      child: state.when(
        loading: () => const _LoadingView(),
        error: (error, _) => _ErrorView(error: error),
        data: (profile) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffProfileProvider(workspace)),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHeader(profile: profile),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pageHorizontal,
                  AppDimensions.sectionGapLarge,
                  AppDimensions.pageHorizontal,
                  AppDimensions.pageBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      title: 'البيانات الأكاديمية',
                      icon: Icons.school_rounded,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AcademicCard(
                            icon: Icons.account_balance_rounded,
                            label: 'الجامعة',
                            value: profile.university ?? '-',
                            color: AppColors.goldDeep,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.gridGap),
                        Expanded(
                          child: _AcademicCard(
                            icon: Icons.apartment_rounded,
                            label: 'الكلية',
                            value: profile.college ?? '-',
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sectionGapLarge),
                    const _SectionTitle(
                      title: 'معلومات الحساب',
                      icon: Icons.manage_accounts_rounded,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.cardPadding),
                      decoration: _cardDecoration(
                        radius: AppDimensions.cardRadiusLarge,
                      ),
                      child: Column(
                        children: [
                          _AccountDetailRow(
                            icon: Icons.email_rounded,
                            label: 'البريد الإلكتروني',
                            value: profile.email,
                            color: AppColors.royalBlue,
                          ),
                          const Divider(height: 32),
                          _AccountDetailRow(
                            icon: Icons.badge_rounded,
                            label: 'الدور',
                            value: _roleLabel(profile.role),
                            color: AppColors.violet,
                          ),
                          const Divider(height: 32),
                          _AccountDetailRow(
                            icon: Icons.verified_user_rounded,
                            label: 'حالة الحساب',
                            value: _statusLabel(profile.status),
                            color: AppColors.success,
                          ),
                          const Divider(height: 32),
                          _AccountDetailRow(
                            icon: Icons.dashboard_customize_rounded,
                            label: 'المساحات المتاحة',
                            value: profile.availableWorkspaces
                                .map(_workspaceLabel)
                                .join('، '),
                            color: AppColors.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sectionGapLarge),
                    if (workspace == StaffWorkspace.doctor) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showChangeEmail(
                            context,
                            ref,
                            workspace,
                            profile.email,
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppColors.royalBlue,
                          ),
                          icon: const Icon(Icons.alternate_email_rounded),
                          label: const Text(
                            'تعديل البريد الإلكتروني',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _showChangePassword(context, ref, workspace),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppColors.midnight,
                        ),
                        icon: const Icon(Icons.password_rounded),
                        label: const Text(
                          'تغيير كلمة المرور',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
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

  Future<void> _showChangePassword(
    BuildContext context,
    WidgetRef ref,
    StaffWorkspace workspace,
  ) {
    return showMoeenBottomSheet(
      context: context,
      title: 'تغيير كلمة المرور',
      icon: Icons.password_rounded,
      color: AppColors.royalBlue,
      child: _ChangePasswordForm(
        onSubmit: (current, password, confirmation) => ref
            .read(staffAccountRepositoryProvider)
            .changePassword(
              workspace: workspace,
              currentPassword: current,
              password: password,
              confirmation: confirmation,
            ),
      ),
    );
  }

  Future<void> _showChangeEmail(
    BuildContext context,
    WidgetRef ref,
    StaffWorkspace workspace,
    String currentEmail,
  ) {
    return showMoeenBottomSheet(
      context: context,
      title: 'تعديل البريد الإلكتروني',
      icon: Icons.alternate_email_rounded,
      color: AppColors.royalBlue,
      child: _ChangeEmailForm(
        currentEmail: currentEmail,
        onSubmit: (email, currentPassword) async {
          final updated = await ref
              .read(staffAccountRepositoryProvider)
              .updateEmail(
                workspace: workspace,
                email: email,
                currentPassword: currentPassword,
              );
          final newEmail = (updated['email'] ?? email).toString();
          await ref.read(authControllerProvider.notifier).updateEmail(newEmail);
          ref.invalidate(staffProfileProvider(workspace));
          return newEmail;
        },
      ),
    );
  }
}

class _DoctorDashboardView extends ConsumerWidget {
  const _DoctorDashboardView({required this.data, required this.offlineBanner});

  final Map<String, dynamic> data;
  final Widget offlineBanner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = _listOfMaps(data['subjects']);
    final todaySchedule = _listOfMaps(data['today_schedule']);
    final activities = _listOfMaps(data['recent_activities']);
    final announcements = _listOfMaps(data['admin_announcements']);

    final session = ref.watch(authControllerProvider).valueOrNull;
    final doctorName = session?.name ?? 'دكتورنا العزيز';

    return ListView(
      padding: AppDimensions.pagePadding,
      children: [
        offlineBanner,
        _DoctorWelcomeBanner(doctorName: doctorName),
        const SizedBox(height: AppDimensions.sectionGapLarge),
        // Premium Quick Actions Panel
        const _DoctorQuickActions(compact: true),
        const SizedBox(height: AppDimensions.sectionGapLarge),
        // Refactored Statistical Grid
        Wrap(
          spacing: AppDimensions.gridGap,
          runSpacing: AppDimensions.gridGap,
          children: [
            _StatCard(
              label: 'المواد',
              value: _int(data['subjects_count']).toString(),
              icon: Icons.menu_book_rounded,
              color: AppColors.royalBlue,
              compact: true,
            ),
            _StatCard(
              label: 'الطلاب',
              value: _int(data['students_count']).toString(),
              icon: Icons.groups_rounded,
              color: AppColors.info,
              compact: true,
            ),
            _StatCard(
              label: 'الأعذار المعلقة',
              value: _int(data['pending_excuses']).toString(),
              icon: Icons.verified_rounded,
              color: AppColors.warning,
              compact: true,
            ),
            _StatCard(
              label: 'الاستفسارات',
              value: _int(data['pending_inquiries']).toString(),
              icon: Icons.forum_rounded,
              color: AppColors.teal,
              compact: true,
            ),
            _StatCard(
              label: 'الرسائل غير المقروءة',
              value: _int(data['unread_messages']).toString(),
              icon: Icons.chat_rounded,
              color: AppColors.rose,
              compact: true,
            ),
            _StatCard(
              label: 'طلاب لديهم درجات',
              value: _int(data['grades_entered']).toString(),
              icon: Icons.grade_rounded,
              color: AppColors.goldDeep,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sectionGapLarge),
        // Premium Today's Lecture Timeline
        _DoctorTodaySchedule(items: todaySchedule),
        const SizedBox(height: 28),
        const _SectionTitle(
          title: 'المواد الدراسية',
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(height: 14),
        if (subjects.isEmpty)
          const _EmptyCard(message: 'لا توجد مواد مرتبطة بك حاليًا.')
        else
          ...subjects.map(_SubjectCard.new),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'أحدث النشاطات',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 14),
        if (activities.isEmpty)
          const _EmptyCard(message: 'لا توجد نشاطات حديثة.')
        else
          ...activities.map(_ActivityTile.new),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'الإعلانات الإدارية',
          icon: Icons.campaign_rounded,
        ),
        const SizedBox(height: 14),
        if (announcements.isEmpty)
          const _EmptyCard(message: 'لا توجد إعلانات جديدة.')
        else
          ...announcements.map(_AnnouncementTile.new),
      ],
    );
  }
}

class _AdministrativeDashboardView extends StatelessWidget {
  const _AdministrativeDashboardView({
    required this.data,
    required this.offlineBanner,
  });

  final Map<String, dynamic> data;
  final Widget offlineBanner;

  @override
  Widget build(BuildContext context) {
    final college = _map(data['college']);
    final stats = _map(data['stats']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        offlineBanner,
        _DashboardHero(
          title: college['name']?.toString() ?? 'لوحة الكلية',
          subtitle: 'إدارة بيانات الكلية ومتابعة مؤشرات التشغيل الأساسية.',
          icon: Icons.apartment_rounded,
          compact: false,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'الدكاترة',
              value: _int(stats['doctors_count']).toString(),
              icon: Icons.school_rounded,
              color: AppColors.royalBlue,
            ),
            _StatCard(
              label: 'المندوبون',
              value: _int(stats['delegates_count']).toString(),
              icon: Icons.admin_panel_settings_rounded,
              color: AppColors.teal,
            ),
            _StatCard(
              label: 'الطلاب',
              value: _int(stats['students_count']).toString(),
              icon: Icons.groups_rounded,
              color: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SectionTitle(
          title: 'إعدادات الكلية',
          icon: Icons.settings_rounded,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(radius: 24),
          child: Column(
            children: [
              _InlineInfo(
                label: 'نسبة الحرمان',
                value: '${_int(college['absence_deprivation_percentage'])}%',
              ),
              const Divider(height: 28),
              _InlineInfo(
                label: 'مهلة الأعذار',
                value: '${_int(college['excuses_deadline_days'])} يوم',
              ),
              const Divider(height: 28),
              _InlineInfo(
                label: 'مستقبل الأعذار',
                value: college['excuse_receiver']?.toString() ?? '-',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(title: 'وصول سريع', icon: Icons.bolt_rounded),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionCard(
              label: 'الإشعارات',
              icon: Icons.notifications_active_rounded,
              onTap: () => context.go('/administrative/notifications'),
            ),
            _QuickActionCard(
              label: 'المندوبون',
              icon: Icons.admin_panel_settings_rounded,
              onTap: () => context.go('/administrative/delegates'),
            ),
            _QuickActionCard(
              label: 'التقارير',
              icon: Icons.analytics_rounded,
              onTap: () => context.go('/administrative/reports'),
            ),
            _QuickActionCard(
              label: 'الإعدادات',
              icon: Icons.settings_rounded,
              onTap: () => context.go('/administrative/settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.overview});

  final StaffSubscriptionOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.heroRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.heroRadius),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.heroPaddingHorizontal,
                    vertical: AppDimensions.heroPaddingVertical,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرصيد المتاح',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _money(overview.userBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLarge),
            border: Border.all(
              color: overview.isSubscribed
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.danger.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                      (overview.isSubscribed
                              ? AppColors.success
                              : AppColors.danger)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  overview.isSubscribed
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  color: overview.isSubscribed
                      ? AppColors.success
                      : AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.isSubscribed
                          ? 'اشتراكك نشط حاليًا'
                          : 'حسابك غير مشترك',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      overview.subscribedUntil == null
                          ? 'قم بشحن رصيدك وتفعيل إحدى الباقات.'
                          : 'صلاحية الاشتراك حتى: ${_dateOnly(overview.subscribedUntil)}',
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RedeemCard extends StatelessWidget {
  const _RedeemCard({
    required this.controller,
    required this.loading,
    required this.onRedeem,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLarge),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLength: 12,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'XXXX - XXXX - XXXX',
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.slate50,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onRedeem,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded),
              label: Text(
                loading ? 'جاري التحقق...' : 'تفعيل الكرت الآن',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRenewCard extends StatelessWidget {
  const _AutoRenewCard({
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: loading ? null : onChanged,
        title: const Text(
          'التجديد التلقائي',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: const Text(
          'سيتم تجديد اشتراكك تلقائيًا عند انتهاء المدة.',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        activeThumbColor: AppColors.royalBlue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.disabled,
    required this.onSubscribe,
  });

  final StaffSubscriptionPackage package;
  final bool disabled;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusLarge),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            package.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            package.description,
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PackageInfoItem(
                icon: Icons.calendar_month_rounded,
                label: '${package.durationDays} يوم',
              ),
              const SizedBox(width: 16),
              _PackageInfoItem(
                icon: Icons.payments_rounded,
                label: _money(package.effectivePrice),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled ? null : onSubscribe,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppColors.midnight,
              ),
              child: const Text(
                'اشتراك في هذه الباقة',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageInfoItem extends StatelessWidget {
  const _PackageInfoItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.royalBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({
    required this.ledger,
    required this.exporting,
    required this.onExport,
  });

  final StaffFinancialLedger ledger;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.heroRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.heroPaddingHorizontal,
          vertical: AppDimensions.heroPaddingVertical,
        ),
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
                        'إجمالي الرصيد الحالي',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _money(ledger.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: exporting ? null : onExport,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  icon: exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${ledger.total} عملية مسجلة',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.transaction);

  final StaffFinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final positive = transaction.amount >= 0;
    final color = positive ? AppColors.success : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: AppDimensions.cardRadius),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              positive ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_dateOnly(transaction.createdAt)} • ${_typeLabel(transaction.type)}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _money(transaction.amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _LedgerPagination extends ConsumerWidget {
  const _LedgerPagination({required this.ledger, required this.workspace});

  final StaffFinancialLedger ledger;
  final StaffWorkspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: ledger.currentPage > 1
              ? () => ref
                    .read(staffLedgerProvider(workspace).notifier)
                    .goToPage(ledger.currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Text(
          '${ledger.currentPage} / ${ledger.lastPage}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        IconButton(
          onPressed: ledger.currentPage < ledger.lastPage
              ? () => ref
                    .read(staffLedgerProvider(workspace).notifier)
                    .goToPage(ledger.currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        MediaQuery.paddingOf(context).top + 34,
        AppDimensions.pageHorizontal,
        30,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(
                    profile.name.isEmpty ? '-' : profile.name.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _HeaderBadge(
            label: _roleLabel(profile.role),
            icon: Icons.verified_user_rounded,
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeEmailForm extends StatefulWidget {
  const _ChangeEmailForm({required this.currentEmail, required this.onSubmit});

  final String currentEmail;
  final Future<String> Function(String email, String currentPassword) onSubmit;

  @override
  State<_ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<_ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'اكتب البريد الإلكتروني الجديد.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'اكتب بريدًا إلكترونيًا صحيحًا.';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني الجديد',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) => value == null || value.isEmpty
                ? 'اكتب كلمة المرور الحالية.'
                : null,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _handleSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'حفظ البريد الإلكتروني',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      final newEmail = await widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تغيير البريد الإلكتروني بنجاح',
        message: 'البريد الجديد: $newEmail',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر تغيير البريد الإلكتروني',
        message: error.message,
        icon: Icons.error_rounded,
        color: AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.onSubmit});

  final Future<String> Function(String current, String password, String confirm)
  onSubmit;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _showCurrent = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordField(
            controller: _currentController,
            label: 'كلمة المرور الحالية',
            visible: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            visible: _showPassword,
            onToggle: () => setState(() => _showPassword = !_showPassword),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            controller: _confirmController,
            label: 'تأكيد كلمة المرور الجديدة',
            visible: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
            validator: (value) {
              if (value == null || value.isEmpty) return 'هذا الحقل مطلوب.';
              if (value != _passwordController.text) {
                return 'كلمة المرور غير متطابقة.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('حفظ التغييرات'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب أن تكون 8 أحرف على الأقل.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final message = await widget.onSubmit(
        _currentController.text,
        _passwordController.text,
        _confirmController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator:
          validator ??
          (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب.' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
    );
  }
}

class _DoctorWelcomeBanner extends StatelessWidget {
  const _DoctorWelcomeBanner({required this.doctorName});

  final String doctorName;

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlueDark,
            Color(0xFF1E3A8A),
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
                          'د. $doctorName',
                          style: const TextStyle(
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
                    Flexible(
                      child: Text(
                        'شكراً لعطائك المستمر وتوجيهك لطلابنا الأعزاء.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? AppDimensions.heroRadius : 32.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Decorative background glowing circles
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 60,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppDimensions.heroPaddingHorizontal : 24,
                vertical: compact ? AppDimensions.heroPaddingVertical : 28,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? AppDimensions.heroIconBox : 56,
                    height: compact ? AppDimensions.heroIconBox : 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: compact ? AppDimensions.heroIcon : 28,
                    ),
                  ),
                  SizedBox(width: compact ? 14 : 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? AppDimensions.heroTitle : 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? AppDimensions.heroSubtitle : 13,
                            height: 1.4,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.royalBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.midnight,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact
        ? (MediaQuery.sizeOf(context).width -
                  (AppDimensions.pageHorizontal * 2) -
                  (AppDimensions.gridGap * 2)) /
              3
        : (MediaQuery.sizeOf(context).width - 52) / 2;
    final radius = compact ? AppDimensions.cardRadius : 24.0;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: compact ? Colors.white : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: compact ? AppColors.slate100 : color.withValues(alpha: 0.12),
            width: compact ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: compact ? 0.08 : 0.06),
              blurRadius: compact ? 16 : 12,
              offset: Offset(0, compact ? 8 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              if (compact)
                PositionedDirectional(
                  end: -10,
                  top: -8,
                  child: Icon(
                    icon,
                    size: AppDimensions.statBackgroundIcon,
                    color: color.withValues(alpha: 0.055),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(
                  compact ? AppDimensions.statPadding : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compact ? 7 : 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: compact ? 0.12 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: compact ? AppDimensions.statIcon : 20,
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 14),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? AppDimensions.statValue : 26,
                        fontWeight: FontWeight.w900,
                        color: compact
                            ? AppColors.midnight
                            : color.withValues(alpha: 0.9),
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 4),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? AppDimensions.statLabel : 12,
                        height: 1.25,
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

class _SubjectCard extends StatelessWidget {
  const _SubjectCard(this.subject);

  final Map<String, dynamic> subject;

  @override
  Widget build(BuildContext context) {
    final attendance = _int(subject['attendance_rate']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.import_contacts_rounded,
                  color: AppColors.royalBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['name']?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject['major'] ?? '-'} • ${subject['level'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniPill(
                label: '${_int(subject['students_count'])} طالب',
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              _MiniPill(label: '$attendance% حضور', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          // Elegant visual progress bar for attendance rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'معدل انضباط الحضور',
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$attendance%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: attendance / 100.0,
                  backgroundColor: AppColors.slate100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorQuickActions extends StatelessWidget {
  const _DoctorQuickActions({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'تحضير',
        icon: Icons.qr_code_2_rounded,
        color: AppColors.teal,
        route: '/doctor/attendance',
      ),
      _QuickActionData(
        label: 'إعلان جديد',
        icon: Icons.campaign_rounded,
        color: AppColors.rose,
        route: '/doctor/announcements',
      ),
      _QuickActionData(
        label: 'الأعذار المعلقة',
        icon: Icons.verified_user_rounded,
        color: AppColors.warning,
        route: '/doctor/excuses',
      ),
      _QuickActionData(
        label: 'رصد الدرجات',
        icon: Icons.grade_rounded,
        color: AppColors.goldDeep,
        route: '/doctor/grades',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'إجراءات سريعة', icon: Icons.bolt_rounded),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go(action.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: action.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              action.icon,
                              color: action.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              action.label,
                              style: const TextStyle(
                                color: AppColors.midnight,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _DoctorTodaySchedule extends StatelessWidget {
  const _DoctorTodaySchedule({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'جدول محاضرات اليوم',
          icon: Icons.calendar_today_rounded,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          decoration: _cardDecoration(radius: AppDimensions.cardRadiusLarge),
          child: items.isEmpty
              ? const _EmptyCard(message: 'لا توجد محاضرات مجدولة لليوم.')
              : Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final subject = {
                      ..._map(item['subject']),
                      'major': _text(item, 'major', fallback: '-'),
                      'level': _text(item, 'level', fallback: '-'),
                    };
                    final isFirst = index == 0;
                    final subjectName = _text(
                      item,
                      'subject_name',
                      fallback: _text(subject, 'name', fallback: '-'),
                    );
                    final major = _text(item, 'major', fallback: '-');
                    final level = _text(item, 'level', fallback: '-');
                    final start = _text(
                      item,
                      'start_time_label',
                      fallback: _text(item, 'start_time', fallback: '--'),
                    );
                    final end = _text(
                      item,
                      'end_time_label',
                      fallback: _text(item, 'end_time', fallback: '--'),
                    );
                    final hall = _text(item, 'hall_name', fallback: '--');

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline indicator
                            Column(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? AppColors.teal
                                        : AppColors.royalBlue.withValues(
                                            alpha: 0.3,
                                          ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isFirst
                                          ? AppColors.teal.withValues(
                                              alpha: 0.25,
                                            )
                                          : Colors.transparent,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                if (index < items.length - 1)
                                  Container(
                                    width: 2,
                                    height: 50,
                                    color: AppColors.slate200,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            // Lecture details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        subjectName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: isFirst
                                              ? AppColors.teal
                                              : AppColors.midnight,
                                        ),
                                      ),
                                      if (isFirst)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.teal.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'المحاضرة القادمة',
                                            style: TextStyle(
                                              color: AppColors.teal,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$major • $level',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$start - $end',
                                        style: const TextStyle(
                                          color: AppColors.slate400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          hall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (index < items.length - 1)
                          const SizedBox(height: 12),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.activity);

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final inquiry = activity['type'] == 'inquiry';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          Icon(
            inquiry ? Icons.forum_rounded : Icons.verified_rounded,
            color: inquiry ? AppColors.teal : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  activity['subtitle']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.slate500,
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

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile(this.announcement);

  final Map<String, dynamic> announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: AppColors.rose),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              announcement['title']?.toString() ??
                  announcement['message']?.toString() ??
                  'إعلان إداري',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicCard extends StatelessWidget {
  const _AcademicCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: AppDimensions.cardRadius),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(radius: 22),
          child: Row(
            children: [
              Icon(icon, color: AppColors.royalBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.slate500,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsNumberField extends StatelessWidget {
  const _SettingsNumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.helper,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final String helper;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (value) {
        final number = int.tryParse((value ?? '').trim());
        if (number == null) return 'أدخل رقمًا صحيحًا.';
        if (number < min || number > max) {
          return 'القيمة يجب أن تكون بين $min و $max.';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
        prefixIcon: const Icon(Icons.numbers_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ReceiverChoice extends StatelessWidget {
  const _ReceiverChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ReceiverTile(
          selected: value == 'administrative',
          title: 'المسؤول الإداري',
          subtitle: 'الأعذار تصل إلى إدارة الكلية للمراجعة والاعتماد.',
          icon: Icons.admin_panel_settings_rounded,
          onTap: () => onChanged('administrative'),
        ),
        const SizedBox(height: 10),
        _ReceiverTile(
          selected: value == 'doctor',
          title: 'الدكتور',
          subtitle: 'الأعذار تصل إلى دكتور المادة حسب المادة والمحاضرة.',
          icon: Icons.school_rounded,
          onTap: () => onChanged('doctor'),
        ),
      ],
    );
  }
}

class _ReceiverTile extends StatelessWidget {
  const _ReceiverTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.royalBlue : AppColors.slate500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.royalBlue.withValues(alpha: 0.08)
              : AppColors.slate50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.royalBlue.withValues(alpha: 0.45)
                : AppColors.slate200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isSubscriptionRequired =
        error is ApiException &&
        (((error as ApiException).code == 'subscription_required') ||
            (error as ApiException).statusCode == 402);
    return StatusMessage(
      title: isSubscriptionRequired ? 'تحتاج إلى اشتراك' : 'حدث خطأ',
      message: error is ApiException
          ? (error as ApiException).message
          : 'تعذر تحميل البيانات.',
      icon: isSubscriptionRequired
          ? Icons.lock_rounded
          : Icons.error_outline_rounded,
      action: isSubscriptionRequired
          ? FilledButton.icon(
              onPressed: () {
                final path = GoRouterState.of(context).uri.path;
                context.go(
                  path.startsWith('/administrative')
                      ? '/administrative/subscription'
                      : '/doctor/subscription',
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('الاشتراك الآن'),
            )
          : null,
    );
  }
}

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.slate100),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  return (value is List ? value : const [])
      .whereType<Map>()
      .map((item) => _map(item))
      .toList();
}

String _text(Map<String, dynamic> map, String key, {String fallback = ''}) {
  final value = map[key];
  if (value == null || value.toString().isEmpty) return fallback;
  return value.toString();
}

int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return '-';
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _money(num value) => '${value.toStringAsFixed(0)} ريال';

String _typeLabel(String type) {
  return switch (type) {
    'deposit' => 'إيداع',
    'payment' => 'دفع',
    'refund' => 'استرداد',
    _ => type.isEmpty ? '-' : type,
  };
}

String _roleLabel(String role) {
  return switch (role) {
    'doctor' => 'دكتور',
    'administrative' => 'مسؤول إداري',
    _ => role.isEmpty ? '-' : role,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'active' => 'مفعل',
    'pending' => 'قيد المراجعة',
    'inactive' => 'غير مفعل',
    _ => status.isEmpty ? '-' : status,
  };
}

String _workspaceLabel(String workspace) {
  return switch (workspace) {
    'doctor' => 'الدكتور',
    'administrative' => 'المسؤول الإداري',
    _ => workspace,
  };
}
