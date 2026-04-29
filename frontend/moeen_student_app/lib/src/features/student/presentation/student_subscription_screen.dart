import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../data/models/subscription_models.dart';
import '../logic/student_controllers.dart';
import 'widgets/student_shell.dart';
import 'widgets/student_widgets.dart';

String _dateOnly(String value) {
  if (value.length >= 10) return value.substring(0, 10);
  return value.isEmpty ? '-' : value;
}

class StudentSubscriptionScreen extends ConsumerStatefulWidget {
  const StudentSubscriptionScreen({super.key});

  static const route = '/student/subscription';

  @override
  ConsumerState<StudentSubscriptionScreen> createState() =>
      _StudentSubscriptionScreenState();
}

class _StudentSubscriptionScreenState
    extends ConsumerState<StudentSubscriptionScreen> {
  final _codeController = TextEditingController();
  bool _actionLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionControllerProvider);

    return StudentShell(
      currentIndex: 1,
      title: 'الاشتراك والرصيد',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(subscriptionControllerProvider),
        ),
        data: (overview) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(subscriptionControllerProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _BalanceHeader(overview: overview),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'شحن الرصيد',
                icon: Icons.add_card_rounded,
              ),
              const SizedBox(height: 12),
              _RedeemCard(
                controller: _codeController,
                loading: _actionLoading,
                onRedeem: _redeem,
              ),
              const SizedBox(height: 24),
              _AutoRenewCard(
                value: overview.autoRenew,
                loading: _actionLoading,
                onChanged: (value) => _run(
                  () => ref
                      .read(subscriptionControllerProvider.notifier)
                      .toggleAutoRenew(value),
                ),
              ),
              const SizedBox(height: 32),
              const _SectionTitle(
                title: 'باقات الاشتراك المتاحة',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 16),
              if (overview.packages.isEmpty)
                const EmptyState(message: 'لا توجد باقات متاحة حاليًا.')
              else
                ...overview.packages.map(
                  (package) => _PackageCard(
                    package: package,
                    disabled: overview.isSubscribed || _actionLoading,
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
      () => ref.read(subscriptionControllerProvider.notifier).redeem(code),
    );
    _codeController.clear();
  }

  Future<void> _confirmSubscribe(SubscriptionPackage package) async {
    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الاشتراك',
      message:
          'سيتم خصم ${money(package.displayPrice)} لتفعيل باقة ${package.name} لمدة ${package.durationDays} يوم.',
      confirmLabel: 'اشترك الآن',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.goldDeep,
    );
    if (!approved) return;
    await _run(
      () => ref
          .read(subscriptionControllerProvider.notifier)
          .subscribe(package.id),
    );
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      final message = await action();
      if (message != null) _show(message);
    } on ApiException catch (error) {
      _show(error.message, error: true);
    } catch (error) {
      _show(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.overview});
  final SubscriptionOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الرصيد المتاح',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                money(overview.userBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
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
                  size: 24,
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
                          : 'صلاحية الاشتراك حتى: ${_dateOnly(overview.subscribedUntil!)}',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
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
          'سيتم تجديد اشتراكك تلقائياً عند انتهاء المدة.',
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
  final SubscriptionPackage package;
  final bool disabled;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            package.description,
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _PackageInfoItem(
                icon: Icons.calendar_month_rounded,
                label: '${package.durationDays} يوم',
              ),
              const SizedBox(width: 20),
              _PackageInfoItem(
                icon: Icons.payments_rounded,
                label: money(package.displayPrice),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled ? null : onSubscribe,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.midnight, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.midnight,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
