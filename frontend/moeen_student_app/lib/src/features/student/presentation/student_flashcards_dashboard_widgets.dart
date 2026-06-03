// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _FlashcardsInsightSection extends StatelessWidget {
  const _FlashcardsInsightSection({
    required this.stats,
    required this.packs,
    required this.queue,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> packs;
  final List<Map<String, dynamic>> queue;

  @override
  Widget build(BuildContext context) {
    final totalCards = number(
      stats,
      'total_cards',
      fallback: number(stats, 'total_items'),
    ).toInt();
    final activePacks = number(stats, 'active_packs').toInt();
    final hardCount = queue
        .where((item) => text(item, 'priority', fallback: 'normal') != 'normal')
        .length;
    final modes = <String, int>{};
    for (final pack in packs) {
      final mode = text(pack, 'display_mode', fallback: 'one_line');
      modes[mode] = (modes[mode] ?? 0) + 1;
    }
    final totalModes = modes.values.fold(0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShotSectionHeader(
          title: 'ملخص سريع',
          subtitle: 'صورة واضحة عن حزمك وكروت اليوم',
          icon: Icons.insights_rounded,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _ShotMetricCard(
              label: 'الكروت',
              value: '$totalCards',
              icon: Icons.style_rounded,
              color: AppColors.royalBlue,
            ),
            _ShotMetricCard(
              label: 'الحزم النشطة',
              value: '$activePacks',
              icon: Icons.toggle_on_rounded,
              color: AppColors.success,
            ),
            _ShotMetricCard(
              label: 'مراجعة اليوم',
              value: '${queue.length}',
              icon: Icons.flash_on_rounded,
              color: AppColors.goldDeep,
            ),
            _ShotMetricCard(
              label: 'أولوية عالية',
              value: '$hardCount',
              icon: Icons.priority_high_rounded,
              color: AppColors.rose,
            ),
          ],
        ),
        if (modes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ShotPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'توزيع الأنواع',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: modes.entries.map((entry) {
                    final percentage = totalModes > 0
                        ? (entry.value / totalModes)
                        : 0.0;
                    final modeColor = _modeColor(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _typeLabel(entry.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.midnight,
                                ),
                              ),
                              Text(
                                '${entry.value} حزمة (${(percentage * 100).toInt()}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: AppColors.slate100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                modeColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FlashcardsQuickActions extends StatelessWidget {
  const _FlashcardsQuickActions({
    required this.onStart,
    required this.onCreatePack,
    required this.onOpenUpcoming,
    required this.onOpenHistory,
    required this.onOpenDifficulty,
    required this.onOpenAnalytics,
    required this.onOpenStore,
  });

  final VoidCallback onStart;
  final VoidCallback onCreatePack;
  final VoidCallback onOpenUpcoming;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenDifficulty;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Full Width Action
        _ShotActionCardLarge(
          label: 'ابدأ المراجعة اليومية السريعة',
          subtitle: 'راجع الكروت المجدولة حسب الأولوية الذكية',
          icon: Icons.play_arrow_rounded,
          color: AppColors.midnight,
          onTap: onStart,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            _ShotActionCard(
              label: 'حزمة جديدة',
              icon: Icons.add_rounded,
              color: AppColors.royalBlue,
              onTap: onCreatePack,
            ),
            _ShotActionCard(
              label: 'الكروت القادمة',
              icon: Icons.event_repeat_rounded,
              color: AppColors.goldDeep,
              onTap: onOpenUpcoming,
            ),
            _ShotActionCard(
              label: 'سجل المراجعة',
              icon: Icons.history_rounded,
              color: AppColors.rose,
              onTap: onOpenHistory,
            ),
            _ShotActionCard(
              label: 'الكروت الصعبة',
              icon: Icons.psychology_alt_rounded,
              color: AppColors.midnight,
              onTap: onOpenDifficulty,
            ),
            _ShotActionCard(
              label: 'النتائج والتحليلات',
              icon: Icons.query_stats_rounded,
              color: AppColors.royalBlue,
              onTap: onOpenAnalytics,
            ),
            _ShotActionCard(
              label: 'متجر الحزم',
              icon: Icons.storefront_rounded,
              color: AppColors.success,
              onTap: onOpenStore,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShotActionCardLarge extends StatelessWidget {
  const _ShotActionCardLarge({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayQueueTile extends StatelessWidget {
  const _TodayQueueTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      _parseHex(text(item, 'item_color', fallback: '#4338ca')),
    );
    final isAvailable = _boolValueFallback(item, 'available_now', true);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_modeIcon(_itemType(item)), color: color, size: 22),
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ShotTinyPill(text(item, 'pack_title', fallback: 'حزمة')),
                    _ShotTinyPill(
                      _flashcardPriorityLabel(text(item, 'priority')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text(
                  item,
                  'scheduled_time_label',
                  fallback: text(item, 'scheduled_time', fallback: '--:--'),
                ),
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: isAvailable
                    ? () {
                        final packId = number(item, 'pack_id').toInt();
                        if (packId > 0) {
                          context.push(
                            StudentFlashcardsScreen.reviewPath(packId),
                          );
                        }
                      }
                    : null,
                icon: Icon(
                  isAvailable
                      ? Icons.play_circle_fill_rounded
                      : Icons.schedule_rounded,
                ),
                color: isAvailable ? color : AppColors.slate400,
                iconSize: 26,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

