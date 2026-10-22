// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _TodayReviewHero extends StatelessWidget {
  const _TodayReviewHero({
    required this.queue,
    required this.availableQueue,
    required this.pendingSync,
    required this.reviewedTodayCount,
    required this.onStart,
  });

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> availableQueue;
  final int pendingSync;
  final int reviewedTodayCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final next = availableQueue.isNotEmpty ? availableQueue.first : null;
    final totalToday = reviewedTodayCount + queue.length;
    final progress = totalToday > 0 ? (reviewedTodayCount / totalToday) : 0.0;

    // Countdown calculation till midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final countdownStr = 'ينتهي اليوم بعد $hours س و $minutes د';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlue, AppColors.success],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مراجعة اليوم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      availableQueue.isEmpty
                          ? 'لا توجد كروت متاحة الآن. ستظهر الكروت حسب جدولها.'
                          : '$countdownStr • متاح الآن ${availableQueue.length} من ${queue.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (next != null)
            _NextShotPreview(item: next)
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'عند وجود كروت مستحقة ستظهر هنا مع وقتها والحزمة التابعة لها.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
          if (pendingSync > 0) ...[
            const SizedBox(height: 12),
            _PendingSyncBadge(count: pendingSync),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: availableQueue.isEmpty ? null : onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('ابدأ مراجعة اليوم'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.midnight,
              disabledBackgroundColor: Colors.white24,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayReviewStats extends StatelessWidget {
  const _TodayReviewStats({
    required this.queue,
    required this.availableQueue,
    required this.pendingSync,
  });

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> availableQueue;
  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    final packIds = queue
        .map((item) => number(item, 'pack_id').toInt())
        .where((id) => id > 0)
        .toSet();
    final highPriority = queue
        .where((item) => text(item, 'priority', fallback: 'normal') != 'normal')
        .length;

    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 2),
        children: [
          _buildStatItem(
            label: 'متاح الآن',
            value: '${availableQueue.length}',
            icon: Icons.play_circle_fill_rounded,
            color: AppColors.royalBlue,
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            label: 'كروت اليوم',
            value: '${queue.length}',
            icon: Icons.style_rounded,
            color: AppColors.royalBlue,
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            label: 'عدد الحزم',
            value: '${packIds.length}',
            icon: Icons.inventory_2_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            label: 'أولوية عالية',
            value: '$highPriority',
            icon: Icons.priority_high_rounded,
            color: AppColors.rose,
            flash: highPriority > 0,
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            label: 'بانتظار المزامنة',
            value: '$pendingSync',
            icon: Icons.cloud_sync_rounded,
            color: AppColors.goldDeep,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool flash = false,
  }) {
    final cardBg = flash
        ? AppColors.rose.withValues(alpha: 0.08)
        : Colors.white;
    final cardBorder = flash
        ? AppColors.rose.withValues(alpha: 0.45)
        : AppColors.slate200;

    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: flash ? 1.8 : 1.0),
        boxShadow: [
          if (flash)
            BoxShadow(
              color: AppColors.rose.withValues(alpha: 0.12),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: flash ? AppColors.rose : color, size: 20),
              if (flash) const _PulsingDot(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: flash ? AppColors.rose : AppColors.midnight,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.rose,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TodayPackBreakdown extends StatelessWidget {
  const _TodayPackBreakdown({required this.queue});

  final List<Map<String, dynamic>> queue;

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) return const SizedBox.shrink();
    final grouped = <int, _TodayPackSummary>{};
    for (final item in queue) {
      final packId = number(item, 'pack_id').toInt();
      final title = text(item, 'pack_title', fallback: 'حزمة');
      final color = text(item, 'pack_color', fallback: '#4338ca');
      final current = grouped[packId];
      grouped[packId] = current == null
          ? _TodayPackSummary(title: title, color: color, count: 1)
          : current.copyWith(count: current.count + 1);
    }

    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: 'توزيع اليوم حسب الحزمة',
            subtitle: 'يساعدك تعرف أين يتركز وقت المراجعة',
            icon: Icons.folder_copy_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          ...grouped.entries.map((entry) {
            final summary = entry.value;
            final color = Color(_parseHex(summary.color));
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.style_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _ShotDataPill(
                    label: 'كروت',
                    value: '${summary.count}',
                    color: color,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TodayReviewCard extends ConsumerWidget {
  const _TodayReviewCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(
      _parseHex(text(item, 'item_color', fallback: '#4338ca')),
    );
    final mode = _itemType(item);
    final itemId = _flashcardItemId(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(itemId),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          final ok = await showMoeenConfirmDialog(
            context: context,
            title: 'تأجيل الكرت',
            message:
                'هل أنت متأكد من رغبتك في إزالة هذا الكرت من جدول اليوم وتأجيله؟',
            confirmLabel: 'نعم، أجل الكرت',
            cancelLabel: 'إلغاء',
            color: AppColors.rose,
          );
          return ok;
        },
        onDismissed: (direction) async {
          if (itemId > 0) {
            await ref
                .read(flashcardLocalStoreProvider)
                .markSmartReviewItemCompletedToday(
                  itemId,
                  reviewKey: item['review_key']?.toString(),
                );
            await FloatingReview.completed(
              itemId,
              reviewKey: item['review_key']?.toString(),
            );
            if (!context.mounted) return;
            unawaited(_scheduleNextSmartReviewNotification(ref));
            ref.invalidate(_flashcardDailyQueueProvider);
          }
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.rose.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'تأجيل الكرت اليوم',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_sweep_rounded, color: Colors.white),
            ],
          ),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_modeIcon(mode), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ShotTinyPill(_typeLabel(mode)),
                            const SizedBox(width: 6),
                            _ShotTinyPill(
                              _flashcardPriorityLabel(text(item, 'priority')),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.slate500,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  text(
                                    item,
                                    'scheduled_time_label',
                                    fallback: text(
                                      item,
                                      'scheduled_time',
                                      fallback: '--:--',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text(item, 'front_content', fallback: 'كرت مراجعة'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          text(item, 'pack_title', fallback: 'حزمة مراجعة'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashcardsTodaySection extends StatelessWidget {
  const _FlashcardsTodaySection({
    required this.queue,
    required this.availableQueue,
    required this.packs,
    required this.onCreatePack,
    required this.onOpenToday,
  });

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> availableQueue;
  final List<Map<String, dynamic>> packs;
  final VoidCallback onCreatePack;
  final VoidCallback onOpenToday;

  @override
  Widget build(BuildContext context) {
    final visibleQueue = queue.take(4).toList();
    final availableCount = availableQueue.length;
    final upcomingCount = (queue.length - availableCount).clamp(
      0,
      queue.length,
    );
    final grouped = <String, int>{};
    for (final item in queue) {
      final title = text(item, 'pack_title', fallback: 'حزمة');
      grouped[title] = (grouped[title] ?? 0) + 1;
    }

    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: 'مراجعة اليوم',
            subtitle: queue.isEmpty
                ? 'لا توجد كروت مجدولة الآن'
                : '$availableCount متاح الآن، و$upcomingCount قادم اليوم',
            icon: Icons.today_rounded,
            color: AppColors.royalBlue,
            trailing: TextButton.icon(
              onPressed: onOpenToday,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text(
                'عرض الكل',
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
          const SizedBox(height: 14),
          if (visibleQueue.isEmpty)
            _ShotEmptyBlock(
              icon: Icons.auto_awesome_rounded,
              title: packs.isEmpty ? 'ابدأ أول حزمة' : 'اليوم هادئ',
              message: packs.isEmpty
                  ? 'أنشئ حزمة صغيرة ثم أضف كروتًا قصيرة لتظهر هنا.'
                  : 'لا توجد كروت مستحقة الآن. يمكنك بدء مراجعة من أي حزمة.',
              actionLabel: packs.isEmpty ? 'إنشاء حزمة' : null,
              onAction: packs.isEmpty ? onCreatePack : null,
            )
          else ...[
            ...visibleQueue.map(_TodayQueueTile.new),
            if (queue.length > visibleQueue.length) ...[
              const SizedBox(height: 10),
              _ShotSoftNote(
                text:
                    'يوجد ${queue.length - visibleQueue.length} كرت آخر ضمن جدول اليوم.',
              ),
            ],
          ],
          if (grouped.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: grouped.entries.take(4).map((entry) {
                return _ShotDataPill(
                  label: entry.key,
                  value: '${entry.value}',
                  color: AppColors.midnight,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayPackSummary {
  const _TodayPackSummary({
    required this.title,
    required this.color,
    required this.count,
  });

  final String title;
  final String color;
  final int count;

  _TodayPackSummary copyWith({int? count}) {
    return _TodayPackSummary(
      title: title,
      color: color,
      count: count ?? this.count,
    );
  }
}
