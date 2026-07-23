// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardsAnalyticsScreen extends ConsumerWidget {
  const StudentFlashcardsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_flashcardAnalyticsProvider);
    final historyState = ref.watch(_flashcardHistoryProvider);

    return StudentShell(
      currentIndex: 15,
      title: 'نتائج One Line',
      child: _AsyncBody(
        state: state,
        onRetry: () {
          ref.invalidate(_flashcardAnalyticsProvider);
          ref.invalidate(_flashcardHistoryProvider);
        },
        builder: (data) {
          final summary = asMap(data['summary']);
          final distribution = asMap(data['response_distribution']);
          final bestPack = asMap(data['best_pack']);
          final focusPack = asMap(data['focus_pack']);
          final packs = asList(data['packs']).map(asMap).toList();

          final records = historyState.valueOrNull != null
              ? asList(historyState.valueOrNull!['records']).map(asMap).toList()
              : const <Map<String, dynamic>>[];

          final streak = _calculateStreak(records);
          final weeklyComparison = _calculateWeeklyComparison(records);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_flashcardAnalyticsProvider);
              ref.invalidate(_flashcardHistoryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                _AnalyticsHero(
                  summary: summary,
                  streak: streak,
                  weeklyComparison: weeklyComparison,
                ),
                const SizedBox(height: 16),
                _AnalyticsDistribution(distribution: distribution),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsPackCard(
                        title: 'أفضل حزمة أداءً',
                        pack: bestPack,
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnalyticsPackCard(
                        title: 'تحتاج تركيز مضاف',
                        pack: focusPack,
                        icon: Icons.flag_rounded,
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ShotSectionHeader(
                  title: 'أداء الحزم',
                  subtitle: packs.isEmpty
                      ? 'لا توجد بيانات كافية'
                      : 'مرتبة حسب عدد الكروت التي تمت مراجعتها',
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 12),
                if (packs.isEmpty)
                  _ShotPanel(
                    child: _ShotEmptyBlock(
                      icon: Icons.query_stats_rounded,
                      title: 'لا توجد نتائج بعد',
                      message: 'راجع بعض الكروت لتظهر التحليلات هنا.',
                    ),
                  )
                else
                  ...packs.map((pack) => _AnalyticsPackRow(pack: pack)),
              ],
            ),
          );
        },
      ),
    );
  }

  int _calculateStreak(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final dates = records
        .map((r) => text(r, 'last_shown_date'))
        .where((d) => d.isNotEmpty)
        .toSet();
    if (dates.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    final todayStr = _formatDateKey(checkDate);
    final yesterdayStr = _formatDateKey(
      checkDate.subtract(const Duration(days: 1)),
    );

    if (!dates.contains(todayStr) && !dates.contains(yesterdayStr)) {
      return 0;
    }

    if (!dates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = _formatDateKey(checkDate);
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _calculateWeeklyComparison(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 'لا توجد مراجعات مسجلة بعد';
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday % 7));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    int thisWeekCount = 0;
    int lastWeekCount = 0;

    for (final record in records) {
      final dateStr = text(record, 'last_shown_at');
      if (dateStr.isEmpty) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      if (date.isAfter(startOfThisWeek)) {
        thisWeekCount++;
      } else if (date.isAfter(startOfLastWeek)) {
        lastWeekCount++;
      }
    }

    if (lastWeekCount == 0) {
      return thisWeekCount > 0
          ? 'نشاط هذا الأسبوع مرتفع مقارنة بالأسبوع الماضي'
          : 'ابدأ المراجعة لتسجيل أداء الأسبوع';
    }

    final diff = ((thisWeekCount - lastWeekCount) / lastWeekCount * 100)
        .toInt();
    if (diff >= 0) {
      return 'المراجعات هذا الأسبوع أعلى بـ $diff% من الأسبوع الماضي';
    } else {
      return 'المراجعات هذا الأسبوع أقل بـ ${diff.abs()}% من الأسبوع الماضي';
    }
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.summary,
    required this.streak,
    required this.weeklyComparison,
  });

  final Map<String, dynamic> summary;
  final int streak;
  final String weeklyComparison;

  @override
  Widget build(BuildContext context) {
    final accuracy = number(summary, 'average_accuracy').toDouble();
    final reviewed = number(summary, 'reviewed_cards').toInt();
    final totalCards = number(summary, 'total_cards').toInt();
    final totalPacks = number(summary, 'total_packs').toInt();

    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليلات المراجعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'تفاصيل الاستذكار ومستوى دقة إجاباتك',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak يوم متتالي',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalCards > 0
                  ? (reviewed / totalCards).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أنجزت $reviewed من $totalCards كرت',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(totalCards > 0 ? (reviewed / totalCards * 100) : 0).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weeklyComparison,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShotStat(
                  label: 'الدقة العامة',
                  value: '${accuracy.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'مراجعة نشطة', value: '$reviewed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotStat(label: 'حزم مفعلة', value: '$totalPacks'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsDistribution extends StatelessWidget {
  const _AnalyticsDistribution({required this.distribution});

  final Map<String, dynamic> distribution;

  @override
  Widget build(BuildContext context) {
    final easy = number(distribution, 'easy').toInt();
    final medium = number(distribution, 'medium').toInt();
    final hard = number(distribution, 'hard').toInt();
    final total = easy + medium + hard;

    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: 'توزيع الإجابات',
            subtitle: total == 0
                ? 'لا توجد مراجعات بعد'
                : '${total.toInt()} إجابة مسجلة',
            icon: Icons.donut_large_rounded,
            color: AppColors.goldDeep,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DonutChart(easy: easy, medium: medium, hard: hard),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _DistributionBar(
                      label: 'سهل',
                      value: easy,
                      total: total,
                      color: AppColors.success,
                    ),
                    _DistributionBar(
                      label: 'متوسط',
                      value: medium,
                      total: total,
                      color: AppColors.goldDeep,
                    ),
                    _DistributionBar(
                      label: 'صعب',
                      value: hard,
                      total: total,
                      color: AppColors.rose,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({
    required this.easy,
    required this.medium,
    required this.hard,
  });

  final int easy;
  final int medium;
  final int hard;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.easy != widget.easy ||
        oldWidget.medium != widget.medium ||
        oldWidget.hard != widget.hard) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.easy + widget.medium + widget.hard;
    return SizedBox(
      width: 130,
      height: 130,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _DonutChartPainter(
              easy: widget.easy,
              medium: widget.medium,
              hard: widget.hard,
              progress: _animation.value,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'مراجعة',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.easy,
    required this.medium,
    required this.hard,
    required this.progress,
  });

  final int easy;
  final int medium;
  final int hard;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final total = easy + medium + hard;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = AppColors.slate100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    final colors = [AppColors.success, AppColors.goldDeep, AppColors.rose];
    final values = [easy, medium, hard];

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == 0) continue;

      final sweepAngle = (value / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final hasMultipleSegments = values.where((v) => v > 0).length > 1;
      final gap = hasMultipleSegments ? 0.08 : 0.0;

      canvas.drawArc(
        rect,
        startAngle + (gap / 2),
        (sweepAngle - gap).clamp(0.0, 2 * math.pi),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.easy != easy ||
        oldDelegate.medium != medium ||
        oldDelegate.hard != hard ||
        oldDelegate.progress != progress;
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPackCard extends StatelessWidget {
  const _AnalyticsPackCard({
    required this.title,
    required this.pack,
    required this.icon,
    required this.color,
  });

  final String title;
  final Map<String, dynamic> pack;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasData = pack.isNotEmpty;
    final packTitle = hasData
        ? text(pack, 'pack_title', fallback: 'حزمة')
        : 'لا توجد بيانات';
    final accuracy = hasData ? number(pack, 'accuracy').toDouble() : 0.0;
    final cardsCount = hasData ? number(pack, 'cards_count').toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${accuracy.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            packTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasData ? '$cardsCount بطاقة استذكار' : 'ابدأ الدراسة أولاً',
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPackRow extends StatelessWidget {
  const _AnalyticsPackRow({required this.pack});

  final Map<String, dynamic> pack;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      _parseHex(text(pack, 'pack_color', fallback: '#4338ca')),
    );
    final id = number(pack, 'pack_id').toInt();
    final accuracy = number(pack, 'accuracy').toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: id > 0
              ? () => context.push(StudentFlashcardsScreen.detailsPath(id))
              : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.style_rounded, color: color, size: 23),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(pack, 'pack_title', fallback: 'حزمة'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (accuracy / 100).clamp(0, 1),
                          minHeight: 7,
                          backgroundColor: AppColors.slate100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

