// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardsDifficultyScreen extends ConsumerWidget {
  const StudentFlashcardsDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardDifficultyProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'تصنيف الصعوبات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardDifficultyProvider),
        builder: (data) {
          final groups = asMap(data['groups']);
          final summary = asMap(data['summary']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_flashcardDifficultyProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                _DifficultyHero(summary: summary),
                const SizedBox(height: 16),
                _DifficultyGroup(
                  title: 'صعبة',
                  subtitle: 'ابدأ بها لأنها تحتاج مراجعة أقرب',
                  icon: Icons.priority_high_rounded,
                  color: AppColors.rose,
                  items: asList(groups['hard']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _DifficultyGroup(
                  title: 'متوسطة',
                  subtitle: 'كروت تحتاج تثبيت إضافي',
                  icon: Icons.balance_rounded,
                  color: AppColors.goldDeep,
                  items: asList(groups['medium']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _DifficultyGroup(
                  title: 'سهلة',
                  subtitle: 'كروت مستقرة ويمكن مراجعتها بوتيرة أهدأ',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  items: asList(groups['easy']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _DifficultyGroup(
                  title: 'لم تُراجع',
                  subtitle: 'كروت جديدة لم تدخل دورة المراجعة بعد',
                  icon: Icons.fiber_new_rounded,
                  color: AppColors.royalBlue,
                  items: asList(groups['unreviewed']).map(asMap).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DifficultyHero extends StatelessWidget {
  const _DifficultyHero({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.royalBlueDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.16),
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
                  Icons.psychology_alt_rounded,
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
                      'تصنيف الصعوبات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'اعرف أين تحتاج تركيزك في المراجعة القادمة.',
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
                child: _ShotStat(
                  label: 'صعبة',
                  value: '${number(summary, 'hard').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'متوسطة',
                  value: '${number(summary, 'medium').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'جديدة',
                  value: '${number(summary, 'unreviewed').toInt()}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DifficultyGroup extends StatefulWidget {
  const _DifficultyGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> items;

  @override
  State<_DifficultyGroup> createState() => _DifficultyGroupState();
}

class _DifficultyGroupState extends State<_DifficultyGroup> {
  int _limit = 10;

  void _loadMore() {
    setState(() {
      _limit += 10;
    });
  }

  void _onReviewAllHard(BuildContext context) {
    final packIds = widget.items
        .map((item) => number(item, 'pack_id').toInt())
        .where((id) => id > 0)
        .toSet()
        .toList();
    if (packIds.isEmpty) return;

    if (packIds.length == 1) {
      context.push(StudentFlashcardsScreen.reviewPath(packIds.first));
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر الحزمة للمراجعة',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'لديك كروت صعبة في حزم متعددة، اختر حزمة للبدء بمراجعتها:',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: packIds.length,
                    itemBuilder: (context, index) {
                      final packId = packIds[index];
                      final representativeItem = widget.items.firstWhere(
                        (item) => number(item, 'pack_id').toInt() == packId,
                      );
                      final packTitle = text(
                        representativeItem,
                        'pack_title',
                        fallback: 'حزمة غير معروفة',
                      );
                      final packColor = Color(
                        _parseHex(
                          text(
                            representativeItem,
                            'item_color',
                            fallback: '#4338ca',
                          ),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                StudentFlashcardsScreen.reviewPath(packId),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: packColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      packTitle,
                                      style: const TextStyle(
                                        color: AppColors.midnight,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.slate400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = widget.items.take(_limit).toList();
    final remainingCount = widget.items.length - _limit;

    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: widget.title,
            subtitle: widget.items.isEmpty ? 'لا توجد عناصر' : widget.subtitle,
            icon: widget.icon,
            color: widget.color,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.title == 'صعبة' && widget.items.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => _onReviewAllHard(context),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                    label: const Text(
                      'راجع كل الصعبة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.color,
                      backgroundColor: widget.color.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _ShotDataPill(
                  label: 'عدد',
                  value: '${widget.items.length}',
                  color: widget.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            const _ShotSoftNote(text: 'لا توجد كروت في هذا التصنيف.')
          else
            ...displayedItems.map(
              (item) =>
                  _DifficultyCard(item: item, difficultyColor: widget.color),
            ),
          if (remainingCount > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  'عرض المزيد (متبقي $remainingCount)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: widget.color.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.item, required this.difficultyColor});

  final Map<String, dynamic> item;
  final Color difficultyColor;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      _parseHex(text(item, 'item_color', fallback: '#4338ca')),
    );
    final packId = number(item, 'pack_id').toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: packId > 0
              ? () => context.push(StudentFlashcardsScreen.reviewPath(packId))
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _modeIcon(_itemType(item)),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(item, 'front_content', fallback: 'كرت مراجعة'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _ShotTinyPill(
                            text(item, 'pack_title', fallback: 'حزمة'),
                          ),
                          _ShotTinyPill(
                            text(
                              item,
                              'last_response_label',
                              fallback: 'لم تُراجع',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: difficultyColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: difficultyColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'الدقة ${number(item, 'accuracy').toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: difficultyColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (packId > 0)
                  TextButton.icon(
                    onPressed: () => context.push(
                      StudentFlashcardsScreen.reviewPath(packId),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 14),
                    label: const Text(
                      'راجع الآن',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: difficultyColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_left_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

