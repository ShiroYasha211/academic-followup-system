part of 'student_content_screens.dart';

class StudentStudyCenterScreen extends ConsumerStatefulWidget {
  const StudentStudyCenterScreen({super.key});

  static const route = '/student/study-center';

  @override
  ConsumerState<StudentStudyCenterScreen> createState() =>
      _StudentStudyCenterScreenState();
}

class _StudentStudyCenterScreenState
    extends ConsumerState<StudentStudyCenterScreen> {
  String _tab = 'study';
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_studyProvider(_tab));
    final subjectsState = ref.watch(_subjectsProvider);

    return StudentShell(
      currentIndex: 4,
      title: 'مركز الدراسة',
      floatingActionButton: _tab == 'assignments'
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTask(subjectsState.asData?.value ?? []),
              backgroundColor: _studyTabColor(_tab),
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add_rounded, size: 32),
            ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_studyProvider(_tab)),
        builder: (data) {
          final stats = asMap(data['stats']);
          final allItems = asList(data['items']);
          final items = _filter == null
              ? allItems
              : allItems.where((it) {
                  final item = asMap(it);
                  if (_filter == 'overdue')
                    return text(item, 'status') == 'overdue';
                  if (_filter == 'today')
                    return dateOnly(text(item, 'scheduled_date')) ==
                        dateOnly(DateTime.now().toString());
                  if (_filter == 'high')
                    return text(item, 'priority') == 'high';
                  return true;
                }).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Column(
                    children: [
                      _StudyHero(
                        tab: _tab,
                        totalPending: text(
                          stats,
                          'total_pending',
                          fallback: '0',
                        ),
                        completionRate: number(
                          stats,
                          'completion_percentage',
                          fallback: 0,
                        ).toDouble(),
                      ),
                      const SizedBox(height: 20),
                      _StudyStats(
                        stats: stats,
                        activeFilter: _filter,
                        onFilterChanged: (f) =>
                            setState(() => _filter = (_filter == f ? null : f)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  height: 80,
                  child: Container(
                    color: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _StudyTabs(
                      value: _tab,
                      onChanged: (value) => setState(() {
                        _tab = value;
                        _filter = null;
                      }),
                    ),
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () async => ref.invalidate(_studyProvider(_tab)),
              child: items.isEmpty
                  ? EmptyState(
                      message: _filter != null
                          ? 'لا توجد نتائج مطابقة للفلتر.'
                          : 'لا توجد عناصر في هذا التبويب حالياً.',
                      icon: _filter != null
                          ? Icons.filter_list_off_rounded
                          : Icons.auto_awesome_motion_rounded,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _StudyItemCard(asMap(items[index]), tab: _tab),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddTask(List<dynamic> subjects) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final note = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    int? selectedSubjectId;
    String priority = 'medium';
    String repeat = 'none';
    final itemType = _tab == 'reminders'
        ? 'reminder'
        : (_tab == 'resources' ? 'resource' : 'study');

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'إضافة عنصر إلى مركز الدراسة',
      icon: _studyTabIcon(_tab),
      color: _studyTabColor(_tab),
      child: StatefulBuilder(
        builder: (context, setDialogState) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب عنوان العنصر.'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: AppColors.slate400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate == null
                            ? 'اختر التاريخ'
                            : dateOnly(selectedDate.toString()),
                        style: TextStyle(
                          color: selectedDate == null
                              ? AppColors.slate400
                              : AppColors.midnight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'المادة المرتبطة (اختياري)',
                  prefixIcon: Icon(Icons.auto_stories_rounded),
                ),
                items: subjects.map((it) {
                  final sub = asMap(it);
                  return DropdownMenuItem(
                    value: number(sub, 'id').toInt(),
                    child: Text(text(sub, 'name')),
                  );
                }).toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedSubjectId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'الأولوية'),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('عالية')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('متوسطة'),
                        ),
                        DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => priority = value ?? 'medium'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: repeat,
                      decoration: const InputDecoration(labelText: 'التكرار'),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('بدون')),
                        DropdownMenuItem(value: 'daily', child: Text('يومي')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('أسبوعي'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => repeat = value ?? 'none'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: note,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة إضافية',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'حفظ العنصر الآن',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _studyTabColor(_tab),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    await _runAction(
      () => ref.read(studentContentRepositoryProvider).addCustomStudyTask({
        'title': title.text.trim(),
        'scheduled_date': selectedDate?.toIso8601String().substring(0, 10),
        'note': note.text.trim(),
        'priority': priority,
        'repeat_type': repeat,
        'item_type': itemType,
        if (selectedSubjectId != null) 'subject_id': selectedSubjectId,
      }),
    );
    ref.invalidate(_studyProvider(_tab));
  }

  Future<void> _runAction(Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await action();
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
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

class _StudyHero extends StatelessWidget {
  const _StudyHero({
    required this.tab,
    required this.totalPending,
    required this.completionRate,
  });

  final String tab;
  final String totalPending;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final color = _studyTabColor(tab);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8), AppColors.midnight],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -30,
            child: Icon(
              _studyTabIcon(tab),
              color: Colors.white.withValues(alpha: 0.07),
              size: 160,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _studyTabTitle(tab),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _CompletionRing(rate: completionRate),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'مركز الدراسة الموحد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نظم مهامك ومواردك وتذكيراتك وتكليفاتك من لوحة واحدة احترافية.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _GlassPill(
                    icon: Icons.auto_awesome_rounded,
                    label: '$totalPending مهام متبقية',
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

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.rate});
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: rate / 100,
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          Text(
            '${rate.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyTabs extends StatelessWidget {
  const _StudyTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = {
      'study': ('مهام', Icons.local_library_rounded),
      'reminders': ('تذكيرات', Icons.notifications_active_rounded),
      'resources': ('موارد', Icons.folder_copy_rounded),
      'assignments': ('تكليفات', Icons.assignment_rounded),
    };
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: options.entries.map((entry) {
          final selected = entry.key == value;
          final color = _studyTabColor(entry.key);
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsetsDirectional.only(end: 6),
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.value.$2,
                    color: selected ? Colors.white : AppColors.slate500,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.value.$1,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.slate700,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
