// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _FlashcardPacksPreview extends StatelessWidget {
  const _FlashcardPacksPreview({
    required this.packs,
    this.queue = const [],
    required this.onOpenAll,
    required this.onCreatePack,
  });

  final List<Map<String, dynamic>> packs;
  final List<Map<String, dynamic>> queue;
  final VoidCallback onOpenAll;
  final VoidCallback onCreatePack;

  @override
  Widget build(BuildContext context) {
    final visible = packs.take(3).toList();
    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: 'حزمي',
            subtitle: packs.isEmpty
                ? 'أنشئ أول حزمة مراجعة'
                : '${packs.length} حزمة في مكتبتك',
            icon: Icons.inventory_2_rounded,
            color: AppColors.midnight,
            trailing: TextButton.icon(
              onPressed: onOpenAll,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text(
                'كل الحزم',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.royalBlue,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            _ShotEmptyBlock(
              icon: Icons.add_box_rounded,
              title: 'لا توجد حزم بعد',
              message: 'أنشئ حزمة قصيرة وأضف كروتًا لتبدأ المراجعة.',
              actionLabel: 'إنشاء حزمة',
              onAction: onCreatePack,
            )
          else
            ...visible.map(
              (pack) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompactPackTile(pack: pack, queue: queue),
              ),
            ),
        ],
      ),
    );
  }
}

class _PacksDirectoryHero extends StatelessWidget {
  const _PacksDirectoryHero({required this.stats, required this.packs});

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> packs;

  @override
  Widget build(BuildContext context) {
    final totalCards = number(
      stats,
      'total_cards',
      fallback: number(stats, 'total_items'),
    ).toInt();
    final active = packs.where((pack) => boolValue(pack, 'is_active')).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
            blurRadius: 22,
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مكتبة الحزم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'ابحث، صفّي، وابدأ المراجعة من الحزمة المناسبة.',
                      style: TextStyle(
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShotStat(label: 'الحزم', value: '${packs.length}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'نشطة', value: '$active'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'الكروت', value: '$totalCards'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PacksFilterRow extends StatelessWidget {
  const _PacksFilterRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return _PackFilterChip(
            label: option.$2,
            selected: option.$1 == value,
            onTap: () => onChanged(option.$1),
          );
        },
      ),
    );
  }
}

class _PackFilterChip extends StatelessWidget {
  const _PackFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.midnight : AppColors.slate50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.midnight : AppColors.slate200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.slate600,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactPackTile extends StatelessWidget {
  const _CompactPackTile({required this.pack, required this.queue});

  final Map<String, dynamic> pack;
  final List<Map<String, dynamic>> queue;

  @override
  Widget build(BuildContext context) {
    final color = Color(_parseHex(text(pack, 'color', fallback: '#4338ca')));
    final count = number(pack, 'items_count').toInt();
    final id = number(pack, 'id').toInt();
    final isActive = boolValue(pack, 'is_active');
    final accuracy = number(pack, 'accuracy').toDouble();
    final displayMode = text(pack, 'display_mode', fallback: 'one_line');

    final dueCount = queue
        .where((item) => number(item, 'pack_id').toInt() == id)
        .length;

    return Material(
      color: AppColors.slate50,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(StudentFlashcardsScreen.detailsPath(id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_modeIcon(displayMode), color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                text(pack, 'title', fallback: 'حزمة مراجعة'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.midnight,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.slate200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'متوقفة',
                                  style: TextStyle(
                                    color: AppColors.slate600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            else if (dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$dueCount اليوم',
                                  style: const TextStyle(
                                    color: AppColors.goldDeep,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count كرت · ${_typeLabel(displayMode)}',
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.push(StudentFlashcardsScreen.reviewPath(id)),
                    icon: Icon(Icons.play_circle_fill_rounded, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (accuracy / 100).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.slate200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${accuracy.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

