import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../student/presentation/widgets/student_shell.dart';
import '../data/practical_delegate_repository.dart';

final _practicalOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(practicalDelegateRepositoryProvider);
      final logbook = await repo.logbook();
      Map<String, dynamic> evaluations = {};
      Map<String, dynamic> mockExams = {};
      Map<String, dynamic> reviewCases = {};
      Map<String, dynamic> ownCases = {};

      try {
        evaluations = await repo.evaluations();
      } catch (_) {}
      try {
        mockExams = await repo.mockExams();
      } catch (_) {}
      try {
        reviewCases = await repo.reviewPendingCases();
      } on ApiException catch (error) {
        if (error.statusCode != 403) rethrow;
      }
      try {
        ownCases = await repo.ownPendingCases();
      } on ApiException catch (error) {
        if (error.statusCode != 403) rethrow;
      }

      return {
        'logbook': logbook,
        'evaluations': evaluations,
        'mock_exams': mockExams,
        'review_cases': reviewCases,
        'own_cases': ownCases,
      };
    });

final _practicalLogbookProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
      (ref) => ref.watch(practicalDelegateRepositoryProvider).logbook(),
    );

final _practicalCasesProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(practicalDelegateRepositoryProvider);
      Map<String, dynamic> review = {};
      Map<String, dynamic> own = {};
      try {
        review = await repo.reviewPendingCases();
      } on ApiException catch (error) {
        if (error.statusCode != 403) rethrow;
      }
      try {
        own = await repo.ownPendingCases();
      } on ApiException catch (error) {
        if (error.statusCode != 403) rethrow;
      }
      return {'review': review, 'own': own};
    });

final _practicalDelegationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final repo = ref.watch(practicalDelegateRepositoryProvider);
      final delegations = await repo.delegations();
      final students = await repo.eligibleStudents();
      return {'delegations': delegations, 'students': students};
    });

class PracticalDelegateHomeScreen extends ConsumerWidget {
  const PracticalDelegateHomeScreen({super.key});
  static const route = '/student/practical';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_practicalOverviewProvider);
    return StudentShell(
      currentIndex: 30,
      title: 'المندوب العملي',
      child: _AsyncClinicalBody(
        state: state,
        onRetry: () => ref.invalidate(_practicalOverviewProvider),
        builder: (data) {
          final logbook = asMap(data['logbook']);
          final stats = asMap(logbook['stats']);
          final assignments = asList(logbook['assignments']);
          final logs = asList(logbook['logs']);
          final reviewCases = asList(asMap(data['review_cases'])['data']);
          final ownCases = asList(asMap(data['own_cases'])['data']);
          final evaluations = asMap(data['evaluations']);
          final evalStats = asMap(evaluations['stats']);
          final mock = asMap(data['mock_exams']);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_practicalOverviewProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                const _ClinicalHero(),
                const SizedBox(height: 18),
                _ClinicalStatsGrid(
                  items: [
                    _ClinicalStat(
                      'سجلات معتمدة',
                      value(stats, 'confirmed_logs'),
                      Icons.verified_rounded,
                      AppColors.success,
                    ),
                    _ClinicalStat(
                      'قيد المراجعة',
                      value(stats, 'pending_logs'),
                      Icons.hourglass_top_rounded,
                      AppColors.warning,
                    ),
                    _ClinicalStat(
                      'مهام سريرية',
                      assignments.length.toString(),
                      Icons.assignment_rounded,
                      AppColors.royalBlue,
                    ),
                    _ClinicalStat(
                      'تقييماتي',
                      value(evalStats, 'total_evaluations'),
                      Icons.radar_rounded,
                      AppColors.violet,
                    ),
                    _ClinicalStat(
                      'نماذج تدريب',
                      asList(mock['available_checklists']).length.toString(),
                      Icons.fact_check_rounded,
                      AppColors.teal,
                    ),
                    _ClinicalStat(
                      'حالات للمراجعة',
                      (reviewCases.length + ownCases.length).toString(),
                      Icons.medical_services_rounded,
                      AppColors.rose,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ActionPanel(
                  actions: [
                    _ClinicalAction(
                      'السجل العملي',
                      'عرض السجلات والمهام',
                      Icons.menu_book_rounded,
                      PracticalLogbookScreen.route,
                      AppColors.royalBlue,
                    ),
                    _ClinicalAction(
                      'مراجعة الحالات',
                      'اعتماد أو متابعة الحالات',
                      Icons.rule_rounded,
                      PracticalCasesScreen.route,
                      AppColors.rose,
                    ),
                    _ClinicalAction(
                      'تفويض مساعدين',
                      'منح صلاحية مؤقتة',
                      Icons.group_add_rounded,
                      PracticalDelegationsScreen.route,
                      AppColors.goldDeep,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionTitle('آخر السجلات', Icons.history_rounded),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const _EmptyClinicalState('لا توجد سجلات عملية حتى الآن.')
                else
                  ...logs.take(4).map((raw) => _LogCard(log: asMap(raw))),
                const SizedBox(height: 22),
                _SectionTitle('المهام السريرية', Icons.task_alt_rounded),
                const SizedBox(height: 10),
                if (assignments.isEmpty)
                  const _EmptyClinicalState(
                    'لا توجد مهام سريرية مرتبطة بحسابك.',
                  )
                else
                  ...assignments
                      .take(4)
                      .map((raw) => _AssignmentCard(item: asMap(raw))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PracticalLogbookScreen extends ConsumerWidget {
  const PracticalLogbookScreen({super.key});
  static const route = '/student/practical/logbook';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_practicalLogbookProvider);
    return StudentShell(
      currentIndex: 31,
      title: 'السجل العملي',
      child: _AsyncClinicalBody(
        state: state,
        onRetry: () => ref.invalidate(_practicalLogbookProvider),
        builder: (data) {
          final logs = asList(data['logs']);
          final assignments = asList(data['assignments']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _CompactHeader(
                title: 'سجل اليوم العملي',
                subtitle:
                    'هنا تظهر سجلاتك العملية وما تم اعتماده فعليًا من الدكتور.',
                icon: Icons.menu_book_rounded,
                colors: const [AppColors.royalBlue, AppColors.teal],
              ),
              const SizedBox(height: 18),
              _SectionTitle('سجلات اليوم', Icons.event_available_rounded),
              const SizedBox(height: 10),
              if (logs.isEmpty)
                const _EmptyClinicalState('لا توجد سجلات عملية.')
              else
                ...logs.map((raw) => _LogCard(log: asMap(raw), detailed: true)),
              const SizedBox(height: 20),
              _SectionTitle(
                'مهام الإنجاز السريري',
                Icons.assignment_turned_in_rounded,
              ),
              const SizedBox(height: 10),
              if (assignments.isEmpty)
                const _EmptyClinicalState('لا توجد مهام حالية.')
              else
                ...assignments.map((raw) => _AssignmentCard(item: asMap(raw))),
            ],
          );
        },
      ),
    );
  }
}

class PracticalCasesScreen extends ConsumerWidget {
  const PracticalCasesScreen({super.key});
  static const route = '/student/practical/cases';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_practicalCasesProvider);
    return StudentShell(
      currentIndex: 32,
      title: 'مراجعة الحالات',
      child: _AsyncClinicalBody(
        state: state,
        onRetry: () => ref.invalidate(_practicalCasesProvider),
        builder: (data) {
          final review = asList(asMap(data['review'])['data']);
          final own = asList(asMap(data['own'])['data']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              _CompactHeader(
                title: 'بوابة الحالات العملية',
                subtitle:
                    'المندوب العملي الرئيسي يعتمد الحالات، والمساعد يرى حالاته المرسلة أو المرفوضة.',
                icon: Icons.medical_services_rounded,
                colors: const [AppColors.rose, AppColors.orange],
              ),
              const SizedBox(height: 18),
              _SectionTitle('حالات تنتظر اعتمادك', Icons.rule_rounded),
              const SizedBox(height: 10),
              if (review.isEmpty)
                const _EmptyClinicalState(
                  'لا توجد حالات تنتظر الاعتماد أو لا تملك صلاحية اعتماد رئيسية.',
                )
              else
                ...review.map(
                  (raw) => _CaseCard(
                    item: asMap(raw),
                    canReview: true,
                    onApproved: () => ref.invalidate(_practicalCasesProvider),
                  ),
                ),
              const SizedBox(height: 20),
              _SectionTitle('حالاتي كمساعد عملي', Icons.person_search_rounded),
              const SizedBox(height: 10),
              if (own.isEmpty)
                const _EmptyClinicalState(
                  'لا توجد حالات مرسلة منك قيد المراجعة.',
                )
              else
                ...own.map((raw) => _CaseCard(item: asMap(raw))),
            ],
          );
        },
      ),
    );
  }
}

class PracticalDelegationsScreen extends ConsumerWidget {
  const PracticalDelegationsScreen({super.key});
  static const route = '/student/practical/delegations';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_practicalDelegationsProvider);
    return StudentShell(
      currentIndex: 33,
      title: 'تفويض مساعدين',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _delegationSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('تفويض'),
      ),
      child: _AsyncClinicalBody(
        state: state,
        onRetry: () => ref.invalidate(_practicalDelegationsProvider),
        builder: (data) {
          final page = asMap(data['delegations']);
          final items = asList(page['data']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
            children: [
              _CompactHeader(
                title: 'مساعدو العملي',
                subtitle:
                    'منح صلاحية مؤقتة لطالب من نفس الدفعة لمراجعة حالاته العملية.',
                icon: Icons.group_add_rounded,
                colors: const [AppColors.goldDeep, AppColors.royalBlue],
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const _EmptyClinicalState(
                  'لا توجد تفويضات فعالة، أو أن هذه الصلاحية متاحة للمندوب العملي الرئيسي فقط.',
                )
              else
                ...items.map((raw) => _DelegationCard(item: asMap(raw))),
            ],
          );
        },
      ),
    );
  }
}

class _CaseCard extends ConsumerWidget {
  const _CaseCard({
    required this.item,
    this.canReview = false,
    this.onApproved,
  });
  final Map<String, dynamic> item;
  final bool canReview;
  final VoidCallback? onApproved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = asMap(item['training_center']);
    final department = asMap(item['clinical_department']);
    final body = asMap(item['body_system']);
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(Icons.medical_information_rounded, AppColors.rose),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text(item, 'patient_name', fallback: 'حالة بدون اسم'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              _StatusPill(text(item, 'approval_status', fallback: 'pending')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${text(center, 'name', fallback: 'مركز غير محدد')} | ${text(department, 'name', fallback: 'قسم غير محدد')} | ${text(body, 'name', fallback: 'جهاز غير محدد')}',
            style: const TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (text(item, 'diagnosis_or_description').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text(item, 'diagnosis_or_description'),
              style: const TextStyle(height: 1.5),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context, ref),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('اعتماد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await _runAction(
      context,
      () => ref
          .read(practicalDelegateRepositoryProvider)
          .approveCase(number(item, 'id').toInt()),
      after: onApproved,
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'رفض الحالة',
      icon: Icons.report_rounded,
      color: AppColors.rose,
      child: Column(
        children: [
          const Text(
            'سبب الرفض إجباري حتى يعرف الطالب ما المطلوب تعديله.',
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reason,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'سبب الرفض'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                if (reason.text.trim().isEmpty) return;
                await ref
                    .read(practicalDelegateRepositoryProvider)
                    .rejectCase(
                      id: number(item, 'id').toInt(),
                      reason: reason.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
                onApproved?.call();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
              icon: const Icon(Icons.close_rounded),
              label: const Text('رفض الحالة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegationCard extends ConsumerWidget {
  const _DelegationCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = asMap(item['student']);
    final revoked = item['is_revoked'] == true;
    return _ClinicalCard(
      child: Row(
        children: [
          _IconBubble(
            revoked ? Icons.block_rounded : Icons.verified_user_rounded,
            revoked ? AppColors.slate400 : AppColors.goldDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(student, 'name', fallback: 'طالب'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text('ينتهي: ${text(item, 'expires_at', fallback: '-')}'),
              ],
            ),
          ),
          if (!revoked)
            IconButton(
              onPressed: () => _runAction(
                context,
                () => ref
                    .read(practicalDelegateRepositoryProvider)
                    .revokeDelegation(number(item, 'id').toInt()),
                after: () => ref.invalidate(_practicalDelegationsProvider),
              ),
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log, this.detailed = false});
  final Map<String, dynamic> log;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final center = asMap(log['training_center']);
    final department = asMap(log['department']);
    final doctor = asMap(log['doctor']);
    final activities = asList(log['activities']);
    return _ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBubble(Icons.fact_check_rounded, AppColors.royalBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text(department, 'name', fallback: 'قسم عملي'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              _StatusPill(text(log, 'status', fallback: 'pending')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${text(center, 'name', fallback: 'مركز غير محدد')} | ${text(doctor, 'name', fallback: 'دكتور غير محدد')}',
            style: const TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetric('قصص', value(log, 'history_count')),
              _MiniMetric('فحوصات', value(log, 'exam_count')),
              _MiniMetric('مرور', log['did_round'] == true ? 'نعم' : 'لا'),
              _MiniMetric('أنشطة', activities.length.toString()),
            ],
          ),
          if (detailed && activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...activities.map((raw) {
              final activity = asMap(raw);
              final body = asMap(activity['body_system']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_activityLabel(text(activity, 'activity_type'))}: ${text(body, 'name', fallback: text(activity, 'case_name', fallback: '-'))}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final clinicalCase = asMap(item['clinical_case']);
    return _ClinicalCard(
      child: Row(
        children: [
          _IconBubble(Icons.assignment_rounded, AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(
                    clinicalCase,
                    'patient_name',
                    fallback: text(item, 'task_type', fallback: 'مهمة سريرية'),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_activityLabel(text(item, 'task_type'))} | ${_assignmentStatus(text(item, 'status', fallback: 'assigned'))}',
                ),
                if (text(item, 'review_notes').isNotEmpty)
                  Text(
                    'ملاحظة الدكتور: ${text(item, 'review_notes')}',
                    style: const TextStyle(color: AppColors.rose),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalHero extends StatelessWidget {
  const _ClinicalHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.royalBlueDark,
            AppColors.royalBlue,
            AppColors.teal,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مساحة المندوب العملي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'صلاحيات سريرية فوق حساب الطالب: متابعة السجل، مراجعة الحالات، وتفويض مساعدين بدون فتح صلاحيات إدارة الدفعة.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.gold,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
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

class _ClinicalStatsGrid extends StatelessWidget {
  const _ClinicalStatsGrid({required this.items});
  final List<_ClinicalStat> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ClinicalCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBubble(item.icon, item.color),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.actions});
  final List<_ClinicalAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: actions
          .map(
            (action) => _ClinicalCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconBubble(action.icon, action.color),
                title: Text(
                  action.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(action.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () => context.go(action.route),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ClinicalCard extends StatelessWidget {
  const _ClinicalCard({required this.child, this.margin});
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' || 'confirmed' => AppColors.success,
      'rejected' => AppColors.danger,
      'submitted_for_review' ||
      'pending' ||
      'partially_confirmed' => AppColors.warning,
      _ => AppColors.slate500,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.slate700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);
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
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
      ],
    );
  }
}

class _EmptyClinicalState extends StatelessWidget {
  const _EmptyClinicalState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return _ClinicalCard(
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.slate400, size: 42),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AsyncClinicalBody<T> extends StatelessWidget {
  const _AsyncClinicalBody({
    required this.state,
    required this.builder,
    required this.onRetry,
  });
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _CompactHeader(
            title: 'تعذر تحميل القسم العملي',
            subtitle: error is ApiException ? error.message : error.toString(),
            icon: Icons.error_outline_rounded,
            colors: const [AppColors.danger, AppColors.rose],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
      data: builder,
    );
  }
}

Future<void> _delegationSheet(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(practicalDelegateRepositoryProvider);
  List<dynamic> students;
  try {
    students = await repo.eligibleStudents();
  } catch (error) {
    if (context.mounted) _showError(context, error);
    return;
  }
  if (!context.mounted) return;
  if (students.isEmpty) {
    _showError(context, const ApiException('لا يوجد طلاب متاحون للتفويض.'));
    return;
  }

  var selectedStudent = number(students.first, 'id').toInt();
  final hours = TextEditingController(text: '24');
  await showMoeenBottomSheet<void>(
    context: context,
    title: 'تفويض مساعد عملي',
    icon: Icons.group_add_rounded,
    color: AppColors.goldDeep,
    child: Column(
      children: [
        const Text(
          'اختر طالبًا من نفس الدفعة وحدد مدة الصلاحية بالساعات.',
          style: TextStyle(
            color: AppColors.slate600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: selectedStudent,
          items: [
            for (final raw in students)
              DropdownMenuItem(
                value: number(raw, 'id').toInt(),
                child: Text(text(raw, 'name', fallback: 'طالب')),
              ),
          ],
          onChanged: (value) => selectedStudent = value ?? selectedStudent,
          decoration: const InputDecoration(labelText: 'الطالب'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: hours,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مدة التفويض بالساعات'),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              await repo.createDelegation(
                studentId: selectedStudent,
                durationHours: int.tryParse(hours.text) ?? 24,
              );
              ref.invalidate(_practicalDelegationsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.verified_user_rounded),
            label: const Text('منح الصلاحية'),
          ),
        ),
      ],
    ),
  );
}

Future<void> _runAction(
  BuildContext context,
  Future<String> Function() action, {
  VoidCallback? after,
}) async {
  try {
    final message = await action();
    after?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

void _showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.danger),
  );
}

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}

List<dynamic> asList(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final data = value['data'];
    if (data is List) return data;
  }
  return const [];
}

String text(Object? source, String key, {String fallback = ''}) {
  final map = asMap(source);
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

num number(Object? source, String key, {num fallback = 0}) {
  final map = asMap(source);
  final value = map[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

String value(Object? source, String key, {String fallback = '0'}) {
  final raw = asMap(source)[key];
  if (raw == null || raw.toString().isEmpty) return fallback;
  return raw.toString();
}

String _statusLabel(String value) => switch (value) {
  'approved' => 'معتمد',
  'rejected' => 'مرفوض',
  'pending' => 'قيد المراجعة',
  'confirmed' => 'مؤكد',
  'partially_confirmed' => 'مؤكد جزئيًا',
  'submitted_for_review' => 'بانتظار الدكتور',
  'assigned' => 'مكلف',
  _ => value,
};

String _assignmentStatus(String value) => switch (value) {
  'approved' => 'منجز ومعتمد',
  'rejected' => 'مرفوض ويحتاج إعادة إرسال',
  'submitted_for_review' => 'قيد مراجعة الدكتور',
  'assigned' => 'مطلوب التنفيذ',
  _ => value,
};

String _activityLabel(String value) => switch (value) {
  'history_taking' => 'أخذ قصة مرضية',
  'clinical_examination' => 'فحص سريري',
  'follow_up' => 'متابعة',
  'round' => 'مرور سريري',
  _ => value,
};

class _ClinicalStat {
  const _ClinicalStat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ClinicalAction {
  const _ClinicalAction(
    this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.color,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
