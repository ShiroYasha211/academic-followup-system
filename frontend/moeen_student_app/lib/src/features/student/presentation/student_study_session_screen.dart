part of 'student_content_screens.dart';

class StudentStudySessionScreen extends ConsumerWidget {
  const StudentStudySessionScreen({super.key, required this.itemId});

  final int itemId;

  static String path(int id) => '/student/study-center/$id/session';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_studySessionProvider(itemId));
    return StudentShell(
      currentIndex: 4,
      title: 'تفاصيل المذاكرة',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_studySessionProvider(itemId)),
        builder: (data) {
          final item = asMap(data['item']);
          final reference = asMap(item['reference']);
          final subject = asMap(reference['subject']);
          final owner = asMap(reference['owner']);
          final meta = asMap(reference['meta']);
          final columns = asList(data['columns']).map(asMap).toList();
          final totalActions = number(data, 'total_actions').toInt();
          final completed =
              boolValue(item, 'is_completed') ||
              text(item, 'status') == 'completed';
          final tab = _studyTabFromItemType(text(item, 'item_type'));

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_studySessionProvider(itemId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                _StudySessionHero(
                  item: item,
                  subject: subject,
                  owner: owner,
                  meta: meta,
                  totalActions: totalActions,
                ),
                const SizedBox(height: 16),
                _StudySessionToolbar(
                  completed: completed,
                  onAddColumn: () => _showColumnSheet(context, ref),
                  onToggleCompleted: () =>
                      _toggleCompleted(context, ref, completed, tab),
                ),
                const SizedBox(height: 18),
                if (columns.isEmpty)
                  const EmptyState(message: 'لا توجد أعمدة مذاكرة بعد.')
                else
                  ...columns.map(
                    (column) => _StudySessionColumnCard(
                      itemId: itemId,
                      column: column,
                      canDelete: columns.length > 1,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showColumnSheet(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? column,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: text(column ?? {}, 'name'));
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: column == null ? 'إضافة عمود مذاكرة' : 'تعديل العمود',
      icon: Icons.view_column_rounded,
      color: AppColors.teal,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اكتب اسم العمود.'
                  : null,
              decoration: const InputDecoration(
                labelText: 'اسم العمود',
                hintText: 'مثال: مذاكرة، استماع، مراجعة',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'حفظ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    await _runStudySessionAction(context, ref, () {
      final repo = ref.read(studentContentRepositoryProvider);
      if (column == null) {
        return repo.addStudySessionColumn(
          itemId: itemId,
          name: controller.text.trim(),
        );
      }
      return repo.updateStudySessionColumn(
        columnId: number(column, 'id').toInt(),
        name: controller.text.trim(),
      );
    });
  }

  Future<void> _toggleCompleted(
    BuildContext context,
    WidgetRef ref,
    bool completed,
    String tab,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(studentContentRepositoryProvider).updateStudyItem(itemId, {
        'is_completed': !completed,
      });
      ref.invalidate(_studySessionProvider(itemId));
      ref.invalidate(_studyProvider(tab));
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _StudySessionHero extends StatelessWidget {
  const _StudySessionHero({
    required this.item,
    required this.subject,
    required this.owner,
    required this.meta,
    required this.totalActions,
  });

  final Map<String, dynamic> item;
  final Map<String, dynamic> subject;
  final Map<String, dynamic> owner;
  final Map<String, dynamic> meta;
  final int totalActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.midnight, AppColors.royalBlue, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(item, 'title', fallback: 'محاضرة للمذاكرة'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (text(subject, 'name').isNotEmpty)
                          text(subject, 'name'),
                        if (text(owner, 'name').isNotEmpty)
                          text(owner, 'name'),
                      ].join(' | '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StudySessionChip(
                icon: Icons.touch_app_rounded,
                label: '$totalActions تنفيذ',
              ),
              if (text(meta, 'lecture_number').isNotEmpty)
                _StudySessionChip(
                  icon: Icons.numbers_rounded,
                  label: 'محاضرة ${text(meta, 'lecture_number')}',
                ),
              if (text(meta, 'date').isNotEmpty)
                _StudySessionChip(
                  icon: Icons.calendar_today_rounded,
                  label: dateOnly(text(meta, 'date')),
                ),
              if (text(item, 'scheduled_date').isNotEmpty)
                _StudySessionChip(
                  icon: Icons.event_available_rounded,
                  label: 'مجدولة ${dateOnly(text(item, 'scheduled_date'))}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudySessionToolbar extends StatelessWidget {
  const _StudySessionToolbar({
    required this.completed,
    required this.onAddColumn,
    required this.onToggleCompleted,
  });

  final bool completed;
  final VoidCallback onAddColumn;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAddColumn,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'إضافة عمود',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onToggleCompleted,
            icon: Icon(
              completed
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.verified_rounded,
            ),
            label: Text(
              completed ? 'إلغاء علامة الاكتمال' : 'تمييز العنصر كمكتمل',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudySessionColumnCard extends ConsumerWidget {
  const _StudySessionColumnCard({
    required this.itemId,
    required this.column,
    required this.canDelete,
  });

  final int itemId;
  final Map<String, dynamic> column;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = number(column, 'actions_count').toInt();
    final canUndo = boolValue(column, 'can_undo') || count > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate200.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.view_column_rounded,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text(column, 'name', fallback: 'مذاكرة'),
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => StudentStudySessionScreen(itemId: itemId)
                    ._showColumnSheet(context, ref, column: column),
                icon: const Icon(Icons.edit_rounded),
                color: AppColors.royalBlue,
              ),
              IconButton(
                onPressed: canDelete ? () => _deleteColumn(context, ref) : null,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عدد مرات التنفيذ',
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        count.toString(),
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 78,
                child: FilledButton(
                  onPressed: () => _increment(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_task_rounded),
                      SizedBox(height: 4),
                      Text(
                        'تنفيذ',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canUndo ? () => _undoColumn(context, ref) : null,
              icon: const Icon(Icons.undo_rounded),
              label: Text(
                canUndo ? 'تراجع آخر تنفيذ في هذا العمود' : 'لا يوجد تنفيذ للتراجع',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (text(column, 'last_action_at').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'آخر تنفيذ: ${timeAgo(text(column, 'last_action_at'))}',
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _increment(BuildContext context, WidgetRef ref) async {
    await _runStudySessionAction(
      context,
      ref,
      () => ref
          .read(studentContentRepositoryProvider)
          .incrementStudySessionColumn(number(column, 'id').toInt()),
    );
  }

  Future<void> _undoColumn(BuildContext context, WidgetRef ref) async {
    await _runStudySessionAction(
      context,
      ref,
      () => ref
          .read(studentContentRepositoryProvider)
          .undoStudySessionColumnAction(number(column, 'id').toInt()),
    );
  }

  Future<void> _deleteColumn(BuildContext context, WidgetRef ref) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف العمود',
      message: 'سيتم حذف العمود وسجل التنفيذ الخاص به. هل تريد المتابعة؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;

    await _runStudySessionAction(
      context,
      ref,
      () => ref
          .read(studentContentRepositoryProvider)
          .deleteStudySessionColumn(number(column, 'id').toInt()),
    );
  }
}

class _StudySessionChip extends StatelessWidget {
  const _StudySessionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _runStudySessionAction(
  BuildContext context,
  WidgetRef ref,
  Future<Map<String, dynamic>> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    ref.invalidate(_studySessionProvider);
    ref.invalidate(_studyProvider('study'));
  } on ApiException catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
    );
  }
}

String _studyTabFromItemType(String itemType) {
  return switch (itemType) {
    'reminder' => 'reminders',
    'resource' => 'resources',
    'assignment' => 'assignments',
    _ => 'study',
  };
}
