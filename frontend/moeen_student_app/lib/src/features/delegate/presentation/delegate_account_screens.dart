part of 'delegate_screens.dart';

class DelegateSubscriptionScreen extends ConsumerStatefulWidget {
  const DelegateSubscriptionScreen({super.key});
  static const route = DelegateRoutes.subscription;

  @override
  ConsumerState<DelegateSubscriptionScreen> createState() =>
      _DelegateSubscriptionScreenState();
}

class _DelegateSubscriptionScreenState
    extends ConsumerState<DelegateSubscriptionScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delegateSubscriptionProvider);
    return DelegateShell(
      currentIndex: 18,
      title: 'الاشتراك والرصيد',
      child: _AsyncBody<SubscriptionOverview>(
        state: state,
        onRetry: () => ref.invalidate(delegateSubscriptionProvider),
        builder: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(delegateSubscriptionProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _BalanceHeader(overview: data),
              const SizedBox(height: 24),
              const _SectionHeader(
                title: 'شحن الرصيد',
                icon: Icons.add_card_rounded,
              ),
              const SizedBox(height: 12),
              _RedeemCard(
                controller: _codeController,
                loading: _loading,
                onRedeem: _redeem,
              ),
              const SizedBox(height: 24),
              _AutoRenewCard(
                value: data.autoRenew,
                loading: _loading,
                onChanged: (value) => _toggleAutoRenew(value),
              ),
              const SizedBox(height: 32),
              const _SectionHeader(
                title: 'باقات الاشتراك المتاحة',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 16),
              if (data.packages.isEmpty)
                const _EmptyState('لا توجد باقات متاحة حالياً.')
              else
                ...data.packages.map(
                  (package) => _PackageCard(
                    package: package,
                    disabled: data.isSubscribed || _loading,
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
      _toast(context, 'كود الكرت يجب أن يتكون من 12 حرفاً.');
      return;
    }
    setState(() => _loading = true);
    await _run(
      context,
      () => ref.read(delegateSubscriptionProvider.notifier).redeem(code),
      after: () {
        _codeController.clear();
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmSubscribe(SubscriptionPackage package) async {
    final price = package.priceDelegate > 0
        ? package.priceDelegate
        : package.displayPrice;
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الاشتراك',
      message:
          'سيتم خصم ${money(price)} لتفعيل باقة ${package.name} لمدة ${package.durationDays} يوم.',
      confirmLabel: 'اشترك الآن',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.goldDeep,
    );
    if (!approved) return;
    await _subscribe(package.id);
  }

  Future<void> _subscribe(int id) async {
    setState(() => _loading = true);
    await _run(
      context,
      () => ref.read(delegateSubscriptionProvider.notifier).subscribe(id),
      after: () {
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleAutoRenew(bool value) async {
    setState(() => _loading = true);
    await _run(
      context,
      () => ref
          .read(delegateSubscriptionProvider.notifier)
          .toggleAutoRenew(value),
      after: () {
        ref.invalidate(delegateSubscriptionProvider);
      },
    );
    if (mounted) setState(() => _loading = false);
  }
}

class DelegateLedgerScreen extends ConsumerStatefulWidget {
  const DelegateLedgerScreen({super.key});
  static const route = DelegateRoutes.ledger;

  @override
  ConsumerState<DelegateLedgerScreen> createState() =>
      _DelegateLedgerScreenState();
}

class _DelegateLedgerScreenState extends ConsumerState<DelegateLedgerScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delegateLedgerProvider);

    return DelegateShell(
      currentIndex: 19,
      title: 'كشف الحساب المالي',
      child: _AsyncBody<FinancialLedger>(
        state: state,
        onRetry: () => ref.invalidate(delegateLedgerProvider),
        builder: (ledger) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(delegateLedgerProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _LedgerHeader(
                ledger: ledger,
                onExport: () => _export(context),
                isLoading: _exporting,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(
                title: 'سجل العمليات الأحدث',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 16),
              if (ledger.transactions.isEmpty)
                const _EmptyState('لا توجد حركات مالية مسجلة بعد.')
              else ...[
                ...ledger.transactions.map(_TransactionTile.new),
                const SizedBox(height: 16),
                _Pagination(ledger: ledger),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final bytes = await ref.read(delegateLedgerProvider.notifier).exportPdf();
      if (bytes.isEmpty)
        throw const ApiException('لم يتم تحميل ملف كشف الحساب.');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/moeen_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) throw ApiException(result.message);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم فتح كشف الحساب المالي بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class DelegateProfileScreen extends ConsumerWidget {
  const DelegateProfileScreen({super.key});
  static const route = DelegateRoutes.profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateProfileProvider);
    return DelegateShell(
      currentIndex: 20,
      title: 'ملفي الشخصي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateProfileProvider),
        builder: (profile) {
          final raw = asMap(profile);
          final user = asMap(raw['user'] ?? raw);
          final major = asMap(user['major'] ?? raw['major']);
          final level = asMap(user['level'] ?? raw['level']);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_delegateProfileProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(profile: user),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'البيانات الأكاديمية',
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _AcademicCard(
                              icon: Icons.badge_rounded,
                              label: 'رقم القيد',
                              value: text(
                                user,
                                'student_number',
                                fallback: '-',
                              ),
                              color: AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AcademicCard(
                              icon: Icons.account_balance_rounded,
                              label: 'الجامعة',
                              value: text(
                                user,
                                'university',
                                fallback: text(
                                  raw,
                                  'university',
                                  fallback: '-',
                                ),
                              ),
                              color: AppColors.goldDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _AcademicCard(
                              icon: Icons.apartment_rounded,
                              label: 'الكلية',
                              value: text(
                                user,
                                'college',
                                fallback: text(raw, 'college', fallback: '-'),
                              ),
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AcademicCard(
                              icon: Icons.menu_book_rounded,
                              label: 'التخصص',
                              value: text(major, 'name', fallback: '-'),
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AcademicCard(
                        icon: Icons.layers_rounded,
                        label: 'المستوى الدراسي',
                        value: text(level, 'name', fallback: '-'),
                        color: AppColors.rose,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 32),
                      const _SectionHeader(
                        title: 'معلومات الحساب',
                        icon: Icons.manage_accounts_rounded,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.slate100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _AccountDetailRow(
                              icon: Icons.email_rounded,
                              label: 'البريد الإلكتروني',
                              value: text(user, 'email', fallback: '-'),
                              color: AppColors.royalBlue,
                            ),
                            const Divider(height: 32),
                            _AccountDetailRow(
                              icon: Icons.verified_user_rounded,
                              label: 'حالة الحساب',
                              value: _accountStatusLabel(text(user, 'status')),
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showChangePassword(context, ref),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
          );
        },
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context, WidgetRef ref) async {
    await showMoeenBottomSheet(
      context: context,
      title: 'تغيير كلمة المرور',
      icon: Icons.password_rounded,
      color: AppColors.royalBlue,
      child: _ChangePasswordForm(
        onSubmit: (current, password, confirm) => ref
            .read(delegateRepositoryProvider)
            .changePassword(
              currentPassword: current,
              newPassword: password,
              confirmation: confirm,
            ),
      ),
    );
  }
}
