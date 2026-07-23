// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardsHistoryScreen extends ConsumerStatefulWidget {
  const StudentFlashcardsHistoryScreen({super.key});

  @override
  ConsumerState<StudentFlashcardsHistoryScreen> createState() =>
      _StudentFlashcardsHistoryScreenState();
}

class _StudentFlashcardsHistoryScreenState
    extends ConsumerState<StudentFlashcardsHistoryScreen> {
  String _responseFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardHistoryProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'سجل المراجعة',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardHistoryProvider),
        builder: (data) {
          final groups = asMap(data['groups']);
          final summary = asMap(data['summary']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_flashcardHistoryProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                _HistoryHero(summary: summary),
                const SizedBox(height: 16),
                _PacksFilterRow(
                  value: _responseFilter,
                  options: const [
                    ('all', 'كل الإجابات'),
                    ('easy', 'سهل'),
                    ('medium', 'متوسط'),
                    ('hard', 'صعب'),
                  ],
                  onChanged: (value) => setState(() => _responseFilter = value),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.slate200.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في محتوى الكروت أو أسماء الحزم...',
                      hintStyle: const TextStyle(
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.slate400,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.slate400,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _HistoryGroup(
                  title: 'اليوم',
                  subtitle: 'ما راجعته خلال اليوم',
                  icon: Icons.today_rounded,
                  color: AppColors.royalBlue,
                  items: _filterHistory(
                    asList(groups['today']).map(asMap).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _HistoryGroup(
                  title: 'أمس',
                  subtitle: 'آخر مراجعات اليوم السابق',
                  icon: Icons.history_toggle_off_rounded,
                  color: AppColors.goldDeep,
                  items: _filterHistory(
                    asList(groups['yesterday']).map(asMap).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _HistoryGroup(
                  title: 'هذا الأسبوع',
                  subtitle: 'مراجعات الأسبوع الحالي',
                  icon: Icons.calendar_view_week_rounded,
                  color: AppColors.success,
                  items: _filterHistory(
                    asList(groups['this_week']).map(asMap).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _HistoryGroup(
                  title: 'الأقدم',
                  subtitle: 'مراجعات محفوظة من فترات سابقة',
                  icon: Icons.archive_rounded,
                  color: AppColors.midnight,
                  items: _filterHistory(
                    asList(groups['older']).map(asMap).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterHistory(List<Map<String, dynamic>> items) {
    var filtered = items;
    if (_responseFilter != 'all') {
      filtered = filtered
          .where((item) => text(item, 'last_response') == _responseFilter)
          .toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((item) {
        final front = text(item, 'front_content').toLowerCase();
        final back = text(item, 'back_content').toLowerCase();
        final pack = text(item, 'pack_title').toLowerCase();
        return front.contains(query) ||
            back.contains(query) ||
            pack.contains(query);
      }).toList();
    }
    return filtered;
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.summary});

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
                  Icons.history_rounded,
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
                      'سجل المراجعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'راجع أداءك حسب آخر إجابة وموعد المراجعة القادم.',
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
                  label: 'الإجمالي',
                  value: '${number(summary, 'total').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'سهل',
                  value: '${number(summary, 'easy').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'صعب',
                  value: '${number(summary, 'hard').toInt()}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryGroup extends StatefulWidget {
  const _HistoryGroup({
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
  State<_HistoryGroup> createState() => _HistoryGroupState();
}

class _HistoryGroupState extends State<_HistoryGroup> {
  int _limit = 10;

  void _loadMore() {
    setState(() {
      _limit += 10;
    });
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
            trailing: _ShotDataPill(
              label: 'عدد',
              value: '${widget.items.length}',
              color: widget.color,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            const _ShotSoftNote(text: 'لا توجد مراجعات ضمن هذا القسم.')
          else
            ...displayedItems.map((item) => _HistoryCard(item: item)),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final color = _responseColor(text(item, 'last_response'));
    final packColor = Color(
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
                    color: packColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _modeIcon(_itemType(item)),
                    color: packColor,
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
                              fallback: 'غير محدد',
                            ),
                          ),
                          _ShotTinyPill(_historyDateLabel(item)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
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
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'الدقة ${number(item, 'accuracy').toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (packId > 0) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.push(
                          StudentFlashcardsScreen.reviewPath(packId),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 12),
                        label: const Text(
                          'راجع الآن',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: packColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Icon(Icons.chevron_left_rounded, color: packColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

