part of 'student_content_screens.dart';

class StudentFlashcardsScreen extends ConsumerWidget {
  const StudentFlashcardsScreen({super.key});

  static const route = '/student/flashcards';
  static String detailsPath(int id) => '/student/flashcards/$id';
  static String reviewPath(int id) => '/student/flashcards/$id/review';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardsProvider);
    final queueState = ref.watch(_flashcardDailyQueueProvider);
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
        onRetry: () {
          ref.invalidate(_flashcardsProvider);
          ref.invalidate(_flashcardDailyQueueProvider);
        },
        builder: (data) {
          final stats = asMap(data['stats']);
          final packs = asList(data['packs']).map(asMap).toList();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_flashcardsProvider);
              ref.invalidate(_flashcardDailyQueueProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                queueState.when(
                  data: (queueData) {
                    final queue = asList(
                      queueData['queue'],
                    ).map(asMap).toList();
                    return FutureBuilder<FlashcardLocalState>(
                      future: ref.read(flashcardLocalStoreProvider).load(),
                      builder: (context, snapshot) {
                        return _OneLineShotHero(
                          stats: stats,
                          queue: queue,
                          pendingSync:
                              snapshot.data?.pendingProgress.length ?? 0,
                          onStart: () {
                            final packId = queue.isNotEmpty
                                ? number(queue.first, 'pack_id').toInt()
                                : packs.isNotEmpty
                                ? number(packs.first, 'id').toInt()
                                : 0;
                            if (packId > 0) {
                              context.push(
                                StudentFlashcardsScreen.reviewPath(packId),
                              );
                            } else {
                              _showCreatePack(context, ref);
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => _OneLineShotHero(
                    stats: stats,
                    queue: const [],
                    pendingSync: 0,
                    loading: true,
                    onStart: packs.isEmpty
                        ? () => _showCreatePack(context, ref)
                        : () => context.push(
                            StudentFlashcardsScreen.reviewPath(
                              number(packs.first, 'id').toInt(),
                            ),
                          ),
                  ),
                  error: (_, _) => _OneLineShotHero(
                    stats: stats,
                    queue: const [],
                    pendingSync: 0,
                    offlineMode: true,
                    onStart: packs.isEmpty
                        ? () => _showCreatePack(context, ref)
                        : () => context.push(
                            StudentFlashcardsScreen.reviewPath(
                              number(packs.first, 'id').toInt(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _ShotModeStrip(),
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: packs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _ShotPackListTile(packs[i]),
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

class _OneLineShotHero extends StatelessWidget {
  const _OneLineShotHero({
    required this.stats,
    required this.queue,
    required this.pendingSync,
    required this.onStart,
    this.loading = false,
    this.offlineMode = false,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> queue;
  final int pendingSync;
  final VoidCallback onStart;
  final bool loading;
  final bool offlineMode;

  @override
  Widget build(BuildContext context) {
    final dueCount = queue.length;
    final total = number(stats, 'total_items').toInt();
    final packs = number(stats, 'total_packs').toInt();
    final next = queue.isNotEmpty ? queue.first : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'One Line Shot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      offlineMode
                          ? 'سيتم عرض البيانات المحفوظة ومزامنة التقدم لاحقًا'
                          : 'مراجعة سريعة بكروت تظهر لك حسب الأولوية',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (next != null)
            _NextShotPreview(item: next)
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                loading
                    ? 'جاري تجهيز كروت اليوم...'
                    : 'لا توجد كروت مجدولة الآن. يمكنك البدء من أي حزمة.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShotStat(label: 'اليوم', value: '$dueCount'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'الكروت', value: '$total'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'الحزم', value: '$packs'),
              ),
            ],
          ),
          if (pendingSync > 0) ...[
            const SizedBox(height: 10),
            _PendingSyncBadge(count: pendingSync),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(dueCount > 0 ? 'ابدأ كروت اليوم' : 'ابدأ المراجعة'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.midnight,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextShotPreview extends StatelessWidget {
  const _NextShotPreview({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShotTypeChip(type: _itemType(item)),
              const Spacer(),
              Text(
                text(item, 'scheduled_time', fallback: '--:--'),
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text(item, 'front_content', fallback: 'كرت مراجعة'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text(item, 'pack_title', fallback: 'حزمة مراجعة'),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotStat extends StatelessWidget {
  const _ShotStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingSyncBadge extends StatelessWidget {
  const _PendingSyncBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count مراجعة محفوظة محليًا بانتظار المزامنة',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotModeStrip extends StatelessWidget {
  const _ShotModeStrip();

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('قراءة', Icons.article_rounded),
      ('اقلب الكرت', Icons.flip_rounded),
      ('سؤال وجواب', Icons.question_answer_rounded),
      ('اختيارات', Icons.checklist_rounded),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = modes[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Icon(mode.$2, size: 18, color: AppColors.royalBlue),
                const SizedBox(width: 6),
                Text(
                  mode.$1,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShotPackListTile extends ConsumerWidget {
  const _ShotPackListTile(this.pack);

  final Map<String, dynamic> pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(_parseHex(text(pack, 'color', fallback: '#4338ca')));
    final id = number(pack, 'id').toInt();
    final count = number(pack, 'items_count').toInt();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(StudentFlashcardsScreen.detailsPath(id)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.style_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(pack, 'title', fallback: 'حزمة مراجعة'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count كرت • ${_typeLabel(text(pack, 'display_mode', fallback: 'one_line'))}',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'مراجعة',
                onPressed: () =>
                    context.push(StudentFlashcardsScreen.reviewPath(id)),
                icon: const Icon(Icons.play_circle_fill_rounded),
                color: color,
              ),
              _FlashcardPackMenu(pack: pack),
            ],
          ),
        ),
      ),
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
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncPendingProgress);
  }

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
                  _ShotReviewCard(
                    item: item,
                    color: color,
                    showBack: _showBack,
                    onToggleBack: () => setState(() => _showBack = !_showBack),
                    onAnswer: (level) => _record(item, level, items.length),
                    recording: _recording,
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
                  if (_itemType(item) != 'mcq')
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
    if (_recording) return;
    setState(() => _recording = true);
    final itemId = number(item, 'id').toInt();
    var savedOffline = false;
    try {
      final isOnline = await ref.read(connectivityServiceProvider).isOnline();
      if (!isOnline) {
        await ref
            .read(flashcardLocalStoreProvider)
            .addPendingProgress(itemId: itemId, responseLevel: level);
        savedOffline = true;
      } else {
        await ref
            .read(studentContentRepositoryProvider)
            .recordFlashcardProgress(itemId: itemId, responseLevel: level);
      }
    } on ApiException catch (error) {
      if (error.isOffline) {
        await ref
            .read(flashcardLocalStoreProvider)
            .addPendingProgress(itemId: itemId, responseLevel: level);
        savedOffline = true;
      } else {
        if (mounted) {
          await showMoeenInfoDialog(
            context: context,
            title: 'تعذر تسجيل المراجعة',
            message: error.message,
            icon: Icons.error_outline_rounded,
            color: AppColors.rose,
          );
        }
        if (mounted) setState(() => _recording = false);
        return;
      }
    } catch (_) {
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(itemId: itemId, responseLevel: level);
      savedOffline = true;
    }
    if (!mounted) return;
    setState(() => _recording = false);
    if (savedOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المراجعة محليًا للمزامنة لاحقًا.'),
        ),
      );
    }
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

  Future<void> _syncPendingProgress() async {
    final isOnline = await ref.read(connectivityServiceProvider).isOnline();
    if (!isOnline) return;
    final store = ref.read(flashcardLocalStoreProvider);
    final state = await store.load();
    if (state.pendingProgress.isEmpty) return;
    final repo = ref.read(studentContentRepositoryProvider);
    final remaining = <Map<String, dynamic>>[];
    for (final entry in state.pendingProgress) {
      final itemId = int.tryParse(entry['item_id']?.toString() ?? '');
      final level = entry['response_level']?.toString();
      if (itemId == null || level == null || level.isEmpty) continue;
      try {
        await repo.recordFlashcardProgress(
          itemId: itemId,
          responseLevel: level,
        );
      } catch (_) {
        remaining.add(entry);
      }
    }
    await store.save(state.copyWith(pendingProgress: remaining));
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

// ignore: unused_element
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

class _ShotReviewCard extends StatefulWidget {
  const _ShotReviewCard({
    required this.item,
    required this.color,
    required this.showBack,
    required this.onToggleBack,
    required this.onAnswer,
    required this.recording,
  });

  final Map<String, dynamic> item;
  final Color color;
  final bool showBack;
  final VoidCallback onToggleBack;
  final ValueChanged<String> onAnswer;
  final bool recording;

  @override
  State<_ShotReviewCard> createState() => _ShotReviewCardState();
}

class _ShotReviewCardState extends State<_ShotReviewCard> {
  int? _selectedOption;

  @override
  void didUpdateWidget(covariant _ShotReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (number(oldWidget.item, 'id') != number(widget.item, 'id')) {
      _selectedOption = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _itemType(widget.item);
    final options = _flashcardOptions(widget.item);
    final back = text(widget.item, 'back_content');
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: type == 'mcq' ? null : widget.onToggleBack,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _ShotTypeChip(type: type),
              ),
              const SizedBox(height: 20),
              Text(
                text(widget.item, 'front_content', fallback: 'كرت مراجعة'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
              if (type == 'mcq') ...[
                const SizedBox(height: 24),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ShotOptionTile(
                      label: entry.value,
                      selected: _selectedOption == index,
                      color: widget.color,
                      onTap: widget.recording
                          ? null
                          : () {
                              setState(() => _selectedOption = index);
                              final correct = _correctOptionIndex(widget.item);
                              widget.onAnswer(
                                index == correct ? 'easy' : 'hard',
                              );
                            },
                    ),
                  );
                }),
              ] else if (back.isNotEmpty && widget.showBack) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  back,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ] else if (back.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: widget.color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'اضغط على الكرت لرؤية الإجابة',
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotOptionTile extends StatelessWidget {
  const _ShotOptionTile({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : AppColors.slate50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.slate200,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? color : AppColors.slate400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.midnight : AppColors.slate700,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotTypeChip extends StatelessWidget {
  const _ShotTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _typeLabel(type),
        style: const TextStyle(
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FlashCardPreview extends StatelessWidget {
  // ignore: unused_element_parameter
  const _FlashCardPreview({
    required this.content,
    // ignore: unused_element_parameter
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

String _typeLabel(String mode) {
  return switch (mode) {
    'flash_card' => 'اقلب الكرت',
    'qa' => 'سؤال وجواب',
    'mcq' => 'اختيارات',
    _ => 'قراءة سريعة',
  };
}

String _itemType(Map<String, dynamic> item) {
  final direct = text(item, 'item_type');
  if (direct.isNotEmpty) return direct;
  final resolved = text(item, 'resolved_item_type');
  if (resolved.isNotEmpty) return resolved;
  return text(asMap(item['pack']), 'display_mode', fallback: 'one_line');
}

List<String> _flashcardOptions(Map<String, dynamic> item) {
  final raw = item['options'];
  if (raw is List) {
    return raw
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

int _correctOptionIndex(Map<String, dynamic> item) {
  final parsed = int.tryParse(item['correct_option']?.toString() ?? '') ?? 0;
  return parsed > 0 ? parsed - 1 : parsed;
}

int _parseHex(String input) {
  final clean = input.replaceAll('#', '');
  return int.tryParse('FF$clean', radix: 16) ?? 0xFF4338CA;
}
