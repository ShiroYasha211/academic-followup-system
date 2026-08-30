import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../auth/logic/auth_controller.dart';
import '../data/models/card_generation_models.dart';
import '../logic/student_controllers.dart';
import 'widgets/student_shell.dart';
import 'widgets/student_widgets.dart';

class StudentCardGenerationScreen extends ConsumerStatefulWidget {
  const StudentCardGenerationScreen({super.key});

  static const route = '/student/cards-generate';

  @override
  ConsumerState<StudentCardGenerationScreen> createState() =>
      _StudentCardGenerationScreenState();
}

class _StudentCardGenerationScreenState
    extends ConsumerState<StudentCardGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '1');
  final _amountController = TextEditingController();
  bool _generating = false;

  int get _count => int.tryParse(_countController.text.trim()) ?? 0;
  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get _totalCost => _count * _amount;

  @override
  void initState() {
    super.initState();
    _countController.addListener(_refreshCalculator);
    _amountController.addListener(_refreshCalculator);
  }

  @override
  void dispose() {
    _countController
      ..removeListener(_refreshCalculator)
      ..dispose();
    _amountController
      ..removeListener(_refreshCalculator)
      ..dispose();
    super.dispose();
  }

  void _refreshCalculator() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final access = ref.watch(cardGenerationAccessProvider);
    final canGenerate =
        session?.hasPermissionSlug('generate_cards') == true ||
        access.valueOrNull == true;

    return StudentShell(
      currentIndex: 37,
      title: 'توليد كروت الشحن',
      child: canGenerate
          ? _buildAuthorizedContent()
          : access.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const _PermissionRequiredState(),
    );
  }

  Widget _buildAuthorizedContent() {
    final state = ref.watch(cardGenerationControllerProvider);

    return state.when(
      loading: () => const _CardGenerationLoading(),
      error: (error, _) => ErrorState(
        message: error is ApiException ? error.message : error.toString(),
        onRetry: () =>
            ref.read(cardGenerationControllerProvider.notifier).refresh(),
      ),
      data: (overview) => RefreshIndicator(
        onRefresh: () =>
            ref.read(cardGenerationControllerProvider.notifier).refresh(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          children: [
            _GenerationHero(overview: overview),
            const SizedBox(height: 18),
            _GenerationForm(
              formKey: _formKey,
              countController: _countController,
              amountController: _amountController,
              totalCost: _totalCost,
              balance: overview.balance,
              generating: _generating,
              onGenerate: () => _generate(overview),
            ),
            const SizedBox(height: 28),
            const SectionTitle(
              title: 'سجل الكروت التي أنشأتها',
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: 14),
            if (overview.cards.isEmpty)
              const _EmptyCardsState()
            else
              ...overview.cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GeneratedCardTile(
                    card: card,
                    onCopy: () => _copyCode(card.code),
                  ),
                ),
              ),
            if (overview.lastPage > 1) ...[
              const SizedBox(height: 8),
              _CardsPagination(overview: overview),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate(CardGenerationOverview overview) async {
    if (_generating || _formKey.currentState?.validate() != true) return;
    if (_totalCost > overview.balance) {
      _showMessage('رصيدك الحالي لا يكفي لتغطية تكلفة الكروت.', error: true);
      return;
    }

    final approved = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد توليد الكروت',
      message:
          'سيتم إنشاء $_count كرت بقيمة ${money(_amount)} للكرت، وخصم ${money(_totalCost)} من رصيدك.',
      confirmLabel: 'تأكيد وتوليد',
      icon: Icons.confirmation_number_rounded,
      color: AppColors.royalBlue,
    );
    if (!approved || !mounted) return;

    setState(() => _generating = true);
    try {
      final message = await ref
          .read(cardGenerationControllerProvider.notifier)
          .generate(count: _count, amount: _amount);
      _countController.text = '1';
      _amountController.clear();
      _showMessage(message);
    } on ApiException catch (error) {
      _showMessage(error.message, error: true);
    } catch (_) {
      _showMessage('تعذر توليد الكروت حاليًا. حاول مرة أخرى.', error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    _showMessage('تم نسخ كود الكرت.');
  }

  void _showMessage(String message, {bool error = false}) {
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

class _GenerationHero extends StatelessWidget {
  const _GenerationHero({required this.overview});

  final CardGenerationOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24,
            bottom: -38,
            child: Icon(
              Icons.confirmation_number_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الرصيد المتاح للتوليد',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          money(overview.balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'إجمالي الكروت',
                      value: '${overview.total}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _HeroMetric(
                      label: 'جاهز في الصفحة',
                      value: '${overview.availableCount}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: _HeroMetric(
                      label: 'مستخدم في الصفحة',
                      value: '${overview.usedCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GenerationForm extends StatelessWidget {
  const _GenerationForm({
    required this.formKey,
    required this.countController,
    required this.amountController,
    required this.totalCost,
    required this.balance,
    required this.generating,
    required this.onGenerate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController countController;
  final TextEditingController amountController;
  final double totalCost;
  final double balance;
  final bool generating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final exceedsBalance = totalCost > balance;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'إعداد الكروت', icon: Icons.tune_rounded),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    controller: countController,
                    label: 'عدد الكروت',
                    suffix: 'كرت',
                    validator: (value) {
                      final count = int.tryParse(value?.trim() ?? '');
                      if (count == null) return 'أدخل عددًا صحيحًا';
                      if (count < 1 || count > 100) {
                        return 'من 1 إلى 100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: amountController,
                    label: 'قيمة الكرت',
                    suffix: 'ريال',
                    decimal: true,
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount < 1) {
                        return 'القيمة 1 على الأقل';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: (exceedsBalance ? AppColors.danger : AppColors.royalBlue)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      (exceedsBalance ? AppColors.danger : AppColors.royalBlue)
                          .withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    exceedsBalance
                        ? Icons.error_outline_rounded
                        : Icons.calculate_rounded,
                    color: exceedsBalance
                        ? AppColors.danger
                        : AppColors.royalBlue,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'التكلفة الإجمالية',
                      style: TextStyle(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    money(totalCost),
                    style: TextStyle(
                      color: exceedsBalance
                          ? AppColors.danger
                          : AppColors.midnight,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (exceedsBalance) ...[
              const SizedBox(height: 8),
              const Text(
                'التكلفة تتجاوز رصيدك الحالي.',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: generating ? null : onGenerate,
                icon: generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(generating ? 'جاري التوليد...' : 'توليد الكروت'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final FormFieldValidator<String> validator;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        alignLabelWithHint: true,
      ),
    );
  }
}

class _GeneratedCardTile extends StatelessWidget {
  const _GeneratedCardTile({required this.card, required this.onCopy});

  final GeneratedCard card;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final statusColor = card.isUsed ? AppColors.slate500 : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              card.isUsed
                  ? Icons.check_circle_outline_rounded
                  : Icons.confirmation_number_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  card.code,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      money(card.amount),
                      style: const TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card.isUsed ? 'تم استخدامه' : 'جاهز للاستخدام',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatCardDate(card.createdAt),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'نسخ الكود',
            icon: const Icon(Icons.copy_rounded),
            color: AppColors.royalBlue,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardsPagination extends ConsumerWidget {
  const _CardsPagination({required this.overview});

  final CardGenerationOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cardGenerationControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: overview.currentPage > 1
              ? () => controller.goToPage(overview.currentPage - 1)
              : null,
          tooltip: 'الصفحة السابقة',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${overview.currentPage} من ${overview.lastPage}',
            style: const TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: overview.currentPage < overview.lastPage
              ? () => controller.goToPage(overview.currentPage + 1)
              : null,
          tooltip: 'الصفحة التالية',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const EmptyState(
        message: 'لم تنشئ أي كروت بعد. استخدم النموذج أعلاه لإنشاء أول دفعة.',
        icon: Icons.confirmation_number_outlined,
      ),
    );
  }
}

class _PermissionRequiredState extends StatelessWidget {
  const _PermissionRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.warning,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'هذه الصفحة تحتاج صلاحية',
              style: TextStyle(
                color: AppColors.midnight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اطلب من إدارة النظام منحك صلاحية توليد كروت الشحن من الرصيد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.slate600,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGenerationLoading extends StatelessWidget {
  const _CardGenerationLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: List.generate(
        4,
        (index) => Container(
          height: index == 0 ? 170 : 92,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

String _formatCardDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour >= 12 ? 'م' : 'ص';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}/${local.month}/${local.day} - $hour:$minute $period';
}
