// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _PackDetailsHero extends StatelessWidget {
  const _PackDetailsHero({
    required this.pack,
    required this.itemsCount,
    required this.childPacksCount,
  });

  final Map<String, dynamic> pack;
  final int itemsCount;
  final int childPacksCount;

  @override
  Widget build(BuildContext context) {
    final packColor = Color(
      _parseHex(text(pack, 'color', fallback: '#4338ca')),
    );
    final title = text(pack, 'title', fallback: 'حزمة مراجعة');
    final description = text(pack, 'description');
    final displayMode = text(pack, 'display_mode', fallback: 'one_line');

    final modeLabel = switch (displayMode) {
      'one_line' => 'One Line Shot',
      'flash_card' => 'بطاقة أمام/خلف',
      'qa' => 'سؤال وجواب',
      'mcq' => 'اختيار من متعدد',
      _ => 'مراجعة ذكية',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            packColor,
            packColor
                .withRed((packColor.red - 30).clamp(0, 255))
                .withGreen((packColor.green - 30).clamp(0, 255)),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: packColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.copy_rounded, '$itemsCount عناصر'),
                Container(
                  width: 1,
                  height: 18,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildStatItem(
                  Icons.account_tree_rounded,
                  '$childPacksCount حزم فرعية',
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildStatItem(Icons.layers_rounded, modeLabel),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroChip(
                Icons.calendar_month_rounded,
                _scheduleModeLabel(
                  text(
                    pack,
                    'schedule_mode',
                    fallback: _scheduleModeFromRepeatCycle(
                      text(pack, 'repeat_cycle'),
                    ),
                  ),
                ),
              ),
              _buildHeroChip(
                Icons.style_rounded,
                '${number(pack, 'daily_card_limit', fallback: number(pack, 'daily_notification_count', fallback: 5)).toInt()} كروت يوميًا',
              ),
              _buildHeroChip(
                Icons.speed_rounded,
                _packPriorityLabel(
                  text(pack, 'pack_priority', fallback: 'medium'),
                ),
              ),
              _buildHeroChip(
                Icons.timer_rounded,
                'كل ${number(pack, 'smart_review_frequency_minutes', fallback: 30).toInt()} دقيقة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ChildPackCompactCard extends StatelessWidget {
  const _ChildPackCompactCard(this.pack);

  final Map<String, dynamic> pack;

  @override
  Widget build(BuildContext context) {
    final color = Color(_parseHex(text(pack, 'color', fallback: '#4338ca')));
    final count = text(pack, 'items_count', fallback: '0');
    final id = number(pack, 'id').toInt();

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push(StudentFlashcardsScreen.detailsPath(id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bolt_rounded, color: color, size: 16),
                    ),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: color.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text(pack, 'title', fallback: 'حزمة فرعية'),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.style_rounded,
                          color: color.withValues(alpha: 0.7),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count بطاقات',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

