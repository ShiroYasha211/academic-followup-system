part of 'student_content_screens.dart';

class StudentFlashcardsScreen extends ConsumerWidget {
  const StudentFlashcardsScreen({super.key});

  static const route = '/student/flashcards';
  static String detailsPath(int id) => '/student/flashcards/$id';
  static String reviewPath(int id) => '/student/flashcards/$id/review';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardsProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'One Line Shot',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePack(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('حزمة'),
        backgroundColor: AppColors.midnight,
        foregroundColor: Colors.white,
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardsProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final packs = asList(data['packs']).map(asMap).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_flashcardsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                _MasteryHeader(stats: stats),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'حزم المراجعة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnight,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push(StudentFlashcardStoreScreen.route),
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: const Text('المتجر'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (packs.isEmpty)
                  const EmptyState(message: 'ابدأ بإنشاء أول حزمة مراجعة لك.')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: packs.length,
                    itemBuilder: (ctx, i) => _FlashcardPackCard(packs[i]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreatePack(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    String mode = 'one_line';
    String cycle = 'daily';
    String color = '#4338ca';
    bool notifications = true;
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'حزمة جديدة',
      icon: Icons.bolt_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب اسم الحزمة.'
                    : null,
                decoration: const InputDecoration(labelText: 'اسم الحزمة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف مختصر'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'نوع البطاقات'),
                items: const [
                  DropdownMenuItem(
                    value: 'one_line',
                    child: Text('One Line Shot'),
                  ),
                  DropdownMenuItem(
                    value: 'flash_card',
                    child: Text('بطاقة أمام/خلف'),
                  ),
                  DropdownMenuItem(value: 'qa', child: Text('سؤال وجواب')),
                  DropdownMenuItem(
                    value: 'mcq',
                    child: Text('اختيار من متعدد'),
                  ),
                ],
                onChanged: (value) =>
                    setLocal(() => mode = value ?? 'one_line'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: cycle,
                      decoration: const InputDecoration(labelText: 'التكرار'),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('يومي')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('أسبوعي'),
                        ),
                        DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                      ],
                      onChanged: (value) =>
                          setLocal(() => cycle = value ?? 'daily'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: color,
                      decoration: const InputDecoration(labelText: 'اللون'),
                      items: const [
                        DropdownMenuItem(value: '#4338ca', child: Text('أزرق')),
                        DropdownMenuItem(value: '#f59e0b', child: Text('ذهبي')),
                        DropdownMenuItem(value: '#0f766e', child: Text('أخضر')),
                        DropdownMenuItem(value: '#be123c', child: Text('أحمر')),
                      ],
                      onChanged: (value) =>
                          setLocal(() => color = value ?? '#4338ca'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: notifications,
                onChanged: (value) => setLocal(() => notifications = value),
                title: const Text('تفعيل التذكيرات اليومية'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref.read(studentContentRepositoryProvider).createFlashcardPack({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'color': color,
        'display_mode': mode,
        'notifications_enabled': notifications,
        'daily_notification_count': 5,
        'repeat_cycle': cycle,
      }),
      onDone: () => ref.invalidate(_flashcardsProvider),
    );
  }
}

class StudentFlashcardDetailsScreen extends ConsumerWidget {
  const StudentFlashcardDetailsScreen({super.key, required this.packId});

  final int packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardDetailsProvider(packId));
    return StudentShell(
      currentIndex: 15,
      title: 'تفاصيل الحزمة',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItem(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('عنصر'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardDetailsProvider(packId)),
        builder: (data) {
          final pack = asMap(data['pack']);
          final items = asList(data['items']).map(asMap).toList();
          final children = asList(data['child_packs']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
            children: [
              _HeroPanel(
                title: text(pack, 'title', fallback: 'حزمة'),
                subtitle:
                    '${items.length} عنصر • ${children.length} حزمة داخلية',
                icon: Icons.style_rounded,
                colors: const [AppColors.royalBlue, AppColors.goldDeep],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        StudentFlashcardsScreen.reviewPath(packId),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('بدء المراجعة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddChildPack(context, ref, pack),
                      icon: const Icon(Icons.account_tree_rounded),
                      label: const Text('حزمة داخلية'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (children.isNotEmpty) ...[
                StudentSection(
                  title: 'الحزم الداخلية',
                  icon: Icons.account_tree_rounded,
                  child: Column(
                    children: children
                        .map((pack) => _FlashcardPackCard(pack))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              StudentSection(
                title: 'العناصر',
                icon: Icons.list_alt_rounded,
                child: items.isEmpty
                    ? const EmptyState(message: 'لا توجد عناصر بعد.')
                    : Column(
                        children: items
                            .map(
                              (item) => _FlashcardItemTile(
                                item,
                                onDelete: () => _deleteItem(context, ref, item),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddItem(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final front = TextEditingController();
    final back = TextEditingController();
    String type = 'one_line';
    String priority = 'normal';
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'عنصر جديد',
      icon: Icons.note_add_rounded,
      color: AppColors.goldDeep,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: front,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب نص البطاقة.'
                    : null,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'النص / السؤال'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'نوع العنصر'),
                items: const [
                  DropdownMenuItem(value: 'one_line', child: Text('One Line')),
                  DropdownMenuItem(
                    value: 'flash_card',
                    child: Text('Flash Card'),
                  ),
                  DropdownMenuItem(value: 'qa', child: Text('Q/A')),
                ],
                onChanged: (value) =>
                    setLocal(() => type = value ?? 'one_line'),
              ),
              if (type != 'one_line') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: back,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب الإجابة.'
                      : null,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'الإجابة'),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'الأولوية'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('سهل')),
                  DropdownMenuItem(value: 'high', child: Text('متوسط')),
                  DropdownMenuItem(value: 'critical', child: Text('صعب')),
                ],
                onChanged: (value) =>
                    setLocal(() => priority = value ?? 'normal'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || front.text.trim().isEmpty) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .createFlashcardItem(packId, {
            'item_type': type,
            'front_content': front.text.trim(),
            if (type != 'one_line') 'back_content': back.text.trim(),
            'priority': priority,
          }),
      onDone: () => ref.invalidate(_flashcardDetailsProvider(packId)),
    );
  }

  Future<void> _showAddChildPack(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> parent,
  ) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    String mode = 'one_line';
    String color = text(parent, 'color', fallback: '#4338ca');
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'حزمة داخلية',
      icon: Icons.account_tree_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب اسم الحزمة.'
                    : null,
                decoration: const InputDecoration(labelText: 'اسم الحزمة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف مختصر'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'نوع البطاقات'),
                items: const [
                  DropdownMenuItem(
                    value: 'one_line',
                    child: Text('One Line Shot'),
                  ),
                  DropdownMenuItem(
                    value: 'flash_card',
                    child: Text('Flash Card'),
                  ),
                  DropdownMenuItem(value: 'qa', child: Text('Q/A')),
                  DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                ],
                onChanged: (value) =>
                    setLocal(() => mode = value ?? 'one_line'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: color,
                decoration: const InputDecoration(labelText: 'اللون'),
                items: const [
                  DropdownMenuItem(value: '#4338ca', child: Text('أزرق')),
                  DropdownMenuItem(value: '#f59e0b', child: Text('ذهبي')),
                  DropdownMenuItem(value: '#0f766e', child: Text('أخضر')),
                  DropdownMenuItem(value: '#be123c', child: Text('أحمر')),
                ],
                onChanged: (value) =>
                    setLocal(() => color = value ?? '#4338ca'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('إنشاء'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref.read(studentContentRepositoryProvider).createFlashcardPack({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'color': color,
        'display_mode': mode,
        'parent_id': packId,
        'notifications_enabled': true,
        'daily_notification_count': 5,
        'repeat_cycle': 'daily',
      }),
      onDone: () => ref.invalidate(_flashcardDetailsProvider(packId)),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف العنصر',
      message: 'هل تريد حذف هذا العنصر؟',
      danger: true,
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    if (!context.mounted) return;
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .deleteFlashcardItem(number(item, 'id').toInt()),
      onDone: () => ref.invalidate(_flashcardDetailsProvider(packId)),
    );
  }
}

class StudentFlashcardReviewScreen extends ConsumerStatefulWidget {
  const StudentFlashcardReviewScreen({super.key, required this.packId});

  final int packId;

  @override
  ConsumerState<StudentFlashcardReviewScreen> createState() =>
      _StudentFlashcardReviewScreenState();
}

class _StudentFlashcardReviewScreenState
    extends ConsumerState<StudentFlashcardReviewScreen> {
  int _index = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardReviewProvider(widget.packId));
    return StudentShell(
      currentIndex: 15,
      title: 'مراجعة One Line',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardReviewProvider(widget.packId)),
        builder: (data) {
          final items = asList(data['items']).map(asMap).toList();
          if (items.isEmpty) {
            return const Center(
              child: EmptyState(message: 'لا توجد عناصر للمراجعة اليوم.'),
            );
          }
          final item = items[_index.clamp(0, items.length - 1)];
          final color = Color(
            _parseHex(
              text(
                item,
                'item_color',
                fallback: text(
                  asMap(item['pack']),
                  'color',
                  fallback: '#4338ca',
                ),
              ),
            ),
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / items.length,
                            minHeight: 8,
                            backgroundColor: AppColors.slate200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_index + 1} / ${items.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _FlashCardPreview(
                    content: text(item, 'front_content'),
                    backContent: _showBack ? text(item, 'back_content') : null,
                    color: color,
                    onTap: () => setState(() => _showBack = !_showBack),
                  ),
                  const Spacer(),
                  if (!_showBack && text(item, 'back_content').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'اضغط على البطاقة لرؤية الإجابة',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _ReviewButton(
                          label: 'صعب',
                          color: AppColors.rose,
                          icon: Icons.sentiment_very_dissatisfied_rounded,
                          onTap: () => _record(item, 'hard', items.length),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ReviewButton(
                          label: 'متوسط',
                          color: AppColors.goldDeep,
                          icon: Icons.sentiment_neutral_rounded,
                          onTap: () => _record(item, 'medium', items.length),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ReviewButton(
                          label: 'سهل',
                          color: AppColors.success,
                          icon: Icons.sentiment_very_satisfied_rounded,
                          onTap: () => _record(item, 'easy', items.length),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _record(
    Map<String, dynamic> item,
    String level,
    int total,
  ) async {
    await ref
        .read(studentContentRepositoryProvider)
        .recordFlashcardProgress(
          itemId: number(item, 'id').toInt(),
          responseLevel: level,
        );
    if (!mounted) return;
    if (_index + 1 >= total) {
      await showMoeenInfoDialog(
        context: context,
        title: 'انتهت المراجعة',
        message: 'تم تسجيل إجاباتك لهذا اليوم.',
        icon: Icons.celebration_rounded,
        color: AppColors.success,
      );
      if (mounted) context.pop();
    } else {
      setState(() {
        _index++;
        _showBack = false;
      });
    }
  }
}

class StudentFlashcardStoreScreen extends ConsumerStatefulWidget {
  const StudentFlashcardStoreScreen({super.key});

  static const route = '/student/flashcards-store';

  @override
  ConsumerState<StudentFlashcardStoreScreen> createState() =>
      _StudentFlashcardStoreScreenState();
}

class _StudentFlashcardStoreScreenState
    extends ConsumerState<StudentFlashcardStoreScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardStoreProvider(_search.text));
    return StudentShell(
      currentIndex: 15,
      title: 'متجر One Line',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardStoreProvider(_search.text)),
        builder: (data) {
          final page = asMap(data['store_items']);
          final items = asList(page['data']).map(asMap).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'بحث',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const EmptyState(message: 'لا توجد حزم في المتجر.')
              else
                ...items.map((store) {
                  final pack = asMap(store['pack']);
                  return _FlashcardPackCard(
                    pack,
                    trailing: FilledButton(
                      onPressed: () => _clone(pack),
                      child: const Text('إضافة'),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clone(Map<String, dynamic> pack) async {
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .cloneFlashcardPack(number(pack, 'id').toInt()),
    );
  }
}

class _FlashcardPackCard extends ConsumerWidget {
  const _FlashcardPackCard(this.pack, {this.trailing});

  final Map<String, dynamic> pack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(_parseHex(text(pack, 'color', fallback: '#4338ca')));
    final count = text(pack, 'items_count', fallback: '0');
    final id = number(pack, 'id').toInt();

    return Stack(
      children: [
        // 3D Stack Effect
        Positioned(
          left: 10,
          right: 10,
          top: 4,
          bottom: 4,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 6,
          right: 6,
          top: 8,
          bottom: 8,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.push(StudentFlashcardsScreen.detailsPath(id)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (trailing == null)
                        _FlashcardPackMenu(pack: pack, isDark: true),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    text(pack, 'title', fallback: 'حزمة'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.style_rounded,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count بطاقة',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: trailing),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashcardPackMenu extends ConsumerWidget {
  const _FlashcardPackMenu({required this.pack, this.isDark = false});

  final Map<String, dynamic> pack;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.white70 : AppColors.slate500,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        final id = number(pack, 'id').toInt();
        if (value == 'review') {
          context.push(StudentFlashcardsScreen.reviewPath(id));
          return;
        }
        if (value == 'toggle') {
          await _runSnack(
            context,
            () => ref
                .read(studentContentRepositoryProvider)
                .toggleFlashcardPack(id),
            onDone: () => ref.invalidate(_flashcardsProvider),
          );
          return;
        }
        if (value == 'delete') {
          final ok = await showMoeenConfirmDialog(
            context: context,
            title: 'حذف الحزمة',
            message: 'سيتم حذف الحزمة وعناصرها. هل تريد المتابعة؟',
            danger: true,
            confirmLabel: 'حذف',
            icon: Icons.delete_rounded,
          );
          if (!ok || !context.mounted) return;
          await _runSnack(
            context,
            () => ref
                .read(studentContentRepositoryProvider)
                .deleteFlashcardPack(id),
            onDone: () => ref.invalidate(_flashcardsProvider),
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'review', child: Text('بدء المراجعة')),
        PopupMenuItem(value: 'toggle', child: Text('تفعيل / إيقاف')),
        PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
    );
  }
}

class _FlashcardItemTile extends StatelessWidget {
  const _FlashcardItemTile(this.item, {required this.onDelete});

  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _SoftTile(
      icon: Icons.short_text_rounded,
      color: AppColors.royalBlue,
      title: text(item, 'front_content', fallback: 'عنصر'),
      subtitle: _flashModeLabel(
        text(item, 'item_type', fallback: text(item, 'resolved_item_type')),
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryHeader extends StatelessWidget {
  const _MasteryHeader({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.midnight,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مستوى الإتقان 🔥',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أنت في سلسلة مراجعة منذ 5 أيام!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Shot X12',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatMini(
                label: 'الإجمالي',
                value: text(stats, 'total_cards', fallback: '0'),
                color: Colors.blue,
              ),
              _StatMini(label: 'المتقن', value: '85%', color: Colors.green),
              _StatMini(label: 'قيد التعلم', value: '12', color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashCardPreview extends StatelessWidget {
  const _FlashCardPreview({
    required this.content,
    this.backContent,
    required this.color,
    required this.onTap,
  });
  final String content;
  final String? backContent;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (backContent != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    backContent!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _flashModeLabel(String mode) {
  return switch (mode) {
    'flash_card' => 'Flash Card',
    'qa' => 'سؤال وجواب',
    'mcq' => 'اختيار من متعدد',
    _ => 'One Line',
  };
}

int _parseHex(String input) {
  final clean = input.replaceAll('#', '');
  return int.tryParse('FF$clean', radix: 16) ?? 0xFF4338CA;
}
