// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardsUpcomingScreen extends ConsumerWidget {
  const StudentFlashcardsUpcomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardUpcomingProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'الكروت القادمة',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardUpcomingProvider),
        builder: (data) {
          final groups = asMap(data['groups']);
          final summary = asMap(data['summary']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_flashcardUpcomingProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                _UpcomingHero(summary: summary),
                const SizedBox(height: 16),
                _UpcomingGroup(
                  title: 'اليوم',
                  subtitle: 'كروت مستحقة أو جاهزة الآن',
                  icon: Icons.today_rounded,
                  color: AppColors.royalBlue,
                  items: asList(groups['today']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _UpcomingGroup(
                  title: 'غدًا',
                  subtitle: 'كروت ستعود في اليوم التالي',
                  icon: Icons.wb_twilight_rounded,
                  color: AppColors.goldDeep,
                  items: asList(groups['tomorrow']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _UpcomingGroup(
                  title: 'هذا الأسبوع',
                  subtitle: 'مراجعات قريبة ضمن الأسبوع الحالي',
                  icon: Icons.calendar_view_week_rounded,
                  color: AppColors.success,
                  items: asList(groups['this_week']).map(asMap).toList(),
                ),
                const SizedBox(height: 14),
                _UpcomingGroup(
                  title: 'لاحقًا',
                  subtitle: 'كروت مؤجلة لما بعد هذا الأسبوع',
                  icon: Icons.event_available_rounded,
                  color: AppColors.midnight,
                  items: asList(groups['later']).map(asMap).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UpcomingHero extends StatelessWidget {
  const _UpcomingHero({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final total = number(summary, 'total').toInt();
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
                  Icons.event_repeat_rounded,
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
                      'القادمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'لا توجد مراجعات مجدولة بعد'
                          : '$total كرت موزعة حسب موعد المراجعة القادم',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShotStat(
                  label: 'اليوم',
                  value: '${number(summary, 'today').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'غدًا',
                  value: '${number(summary, 'tomorrow').toInt()}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'لاحقًا',
                  value:
                      '${number(summary, 'this_week').toInt() + number(summary, 'later').toInt()}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingGroup extends StatefulWidget {
  const _UpcomingGroup({
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
  State<_UpcomingGroup> createState() => _UpcomingGroupState();
}

class _UpcomingGroupState extends State<_UpcomingGroup> {
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
            const _ShotSoftNote(text: 'لا توجد كروت في هذا القسم حاليًا.')
          else
            ...displayedItems.map((item) => _UpcomingCard(item: item)),
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

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item});

  final Map<String, dynamic> item;

  Widget _buildPriorityBadge(String priority) {
    final (label, badgeColor) = switch (priority) {
      'critical' => ('أولوية حرجة', AppColors.rose),
      'high' => ('أولوية عالية', AppColors.goldDeep),
      _ => ('عادي', AppColors.slate500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

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
                          _buildPriorityBadge(text(item, 'priority')),
                          _ShotTinyPill(_upcomingDateLabel(item)),
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
                      backgroundColor: color,
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

