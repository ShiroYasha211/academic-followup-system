// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _OneLineShotHero extends StatelessWidget {
  const _OneLineShotHero({
    required this.stats,
    required this.queue,
    required this.pendingSync,
    required this.onStart,
    this.reviewedTodayCount = 0,
    this.loading = false,
    this.offlineMode = false,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> queue;
  final int pendingSync;
  final VoidCallback onStart;
  final int reviewedTodayCount;
  final bool loading;
  final bool offlineMode;

  @override
  Widget build(BuildContext context) {
    final dueCount = queue.length;
    final totalToday = reviewedTodayCount + dueCount;
    final progress = totalToday > 0 ? (reviewedTodayCount / totalToday) : 0.0;

    final total = number(
      stats,
      'total_cards',
      fallback: number(stats, 'total_items'),
    ).toInt();
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

          // Daily Progress bar
          if (totalToday > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تقدم اليوم: $reviewedTodayCount من $totalToday كرت',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? AppColors.success : AppColors.gold,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

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
                child: _ShotStat(
                  label: 'اليوم',
                  value: '$dueCount',
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'الكروت',
                  value: '$total',
                  icon: Icons.style_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(
                  label: 'الحزم',
                  value: '$packs',
                  icon: Icons.inventory_2_rounded,
                ),
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
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.3),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextShotPreview extends StatefulWidget {
  const _NextShotPreview({required this.item});

  final Map<String, dynamic> item;

  @override
  State<_NextShotPreview> createState() => _NextShotPreviewState();
}

class _NextShotPreviewState extends State<_NextShotPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorHex = text(widget.item, 'pack_color', fallback: '#4338ca');
    final packColor = Color(_parseHex(colorHex));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: packColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ShotTypeChip(type: _itemType(widget.item)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: AppColors.royalBlue,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'التالي',
                                    style: TextStyle(
                                      color: AppColors.royalBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              text(
                                widget.item,
                                'scheduled_time_label',
                                fallback: text(
                                  widget.item,
                                  'scheduled_time',
                                  fallback: '--:--',
                                ),
                              ),
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          text(
                            widget.item,
                            'front_content',
                            fallback: 'كرت مراجعة',
                          ),
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
                          text(
                            widget.item,
                            'pack_title',
                            fallback: 'حزمة مراجعة',
                          ),
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShotStat extends StatelessWidget {
  const _ShotStat({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

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
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 6),
          ],
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

