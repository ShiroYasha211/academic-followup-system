import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/financial_ledger.dart';
import '../logic/student_controllers.dart';
import 'widgets/student_shell.dart';
import 'widgets/student_widgets.dart';

String _dateOnly(String value) {
  if (value.length >= 10) return value.substring(0, 10);
  return value.isEmpty ? '-' : value;
}

class StudentLedgerScreen extends ConsumerStatefulWidget {
  const StudentLedgerScreen({super.key});

  static const route = '/student/ledger';

  @override
  ConsumerState<StudentLedgerScreen> createState() => _StudentLedgerScreenState();
}

class _StudentLedgerScreenState extends ConsumerState<StudentLedgerScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerControllerProvider);

    return StudentShell(
      currentIndex: 2,
      title: 'كشف الحساب المالي',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(ledgerControllerProvider),
        ),
        data: (ledger) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(ledgerControllerProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _LedgerHeader(ledger: ledger, onExport: () => _export(context), isLoading: _exporting),
              const SizedBox(height: 24),
              const SectionTitle(title: 'سجل العمليات الأحدث', icon: Icons.history_rounded),
              const SizedBox(height: 16),
              if (ledger.transactions.isEmpty)
                const EmptyState(message: 'لا توجد حركات مالية مسجلة بعد.')
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
      final bytes = await ref.read(ledgerControllerProvider.notifier).exportPdf();
      if (bytes.isEmpty) throw const ApiException('لم يتم تحميل ملف كشف الحساب.');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/moeen_statement_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) throw ApiException(result.message);

      messenger.showSnackBar(
        const SnackBar(content: Text('تم فتح كشف الحساب المالي بنجاح'), backgroundColor: AppColors.success),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({required this.ledger, required this.onExport, required this.isLoading});
  final FinancialLedger ledger;
  final VoidCallback onExport;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              bottom: -40,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
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
                            'إجمالي الرصيد الحالي',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            money(ledger.balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onExport,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ledger.total} عملية مسجلة',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
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
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.transaction);
  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final positive = transaction.amount >= 0;
    final color = _typeColor(transaction.type, positive);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(_typeIcon(transaction.type, positive), color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _typeLabel(transaction.type),
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.slate300)),
                    const SizedBox(width: 6),
                    Text(
                      _dateOnly(transaction.createdAt),
                      style: const TextStyle(color: AppColors.slate400, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'الرصيد: ${money(transaction.balanceBefore)} ← ${money(transaction.balanceAfter)}',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : ''}${money(transaction.amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15),
              ),
              if (!positive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                  child: const Text('خصم', style: TextStyle(color: AppColors.danger, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type, bool positive) {
    return switch (type) {
      'deposit' => AppColors.success,
      'payment' => AppColors.danger,
      'refund' => AppColors.info,
      _ => positive ? AppColors.success : AppColors.slate500,
    };
  }

  IconData _typeIcon(String type, bool positive) {
    return switch (type) {
      'deposit' => Icons.add_card_rounded,
      'payment' => Icons.payments_rounded,
      'refund' => Icons.replay_circle_filled_rounded,
      _ => positive ? Icons.trending_up_rounded : Icons.tune_rounded,
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'deposit' => 'إيداع',
      'payment' => 'مدفوعات',
      'refund' => 'مستردات',
      _ => 'عملية رصيد',
    };
  }
}

class _Pagination extends ConsumerWidget {
  const _Pagination({required this.ledger});
  final FinancialLedger ledger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ledger.lastPage <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            active: ledger.currentPage > 1,
            onTap: () => ref.read(ledgerControllerProvider.notifier).goToPage(ledger.currentPage - 1),
          ),
          Text(
            'الصفحة ${ledger.currentPage} من ${ledger.lastPage}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.midnight),
          ),
          _PageBtn(
            icon: Icons.arrow_forward_ios_rounded,
            active: ledger.currentPage < ledger.lastPage,
            onTap: () => ref.read(ledgerControllerProvider.notifier).goToPage(ledger.currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.icon, required this.active, required this.onTap});
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14), boxShadow: [
          if (active) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ]),
        child: Icon(icon, size: 18, color: active ? AppColors.midnight : AppColors.slate300),
      ),
    );
  }
}

