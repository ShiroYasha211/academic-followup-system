// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _ShotSectionHeader extends StatelessWidget {
  const _ShotSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _ShotPanel extends StatelessWidget {
  const _ShotPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ShotMetricCard extends StatelessWidget {
  const _ShotMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -4,
            bottom: -4,
            child: Icon(icon, size: 48, color: color.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShotActionCard extends StatelessWidget {
  const _ShotActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotDataPill extends StatelessWidget {
  const _ShotDataPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label  $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ShotTinyPill extends StatelessWidget {
  const _ShotTinyPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.slate600,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ShotSoftNote extends StatelessWidget {
  const _ShotSoftNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ShotEmptyBlock extends StatelessWidget {
  const _ShotEmptyBlock({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.royalBlue, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _FlashcardsTodaySkeleton extends StatelessWidget {
  const _FlashcardsTodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return _ShotPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShotSectionHeader(
            title: 'مراجعة اليوم',
            subtitle: 'جاري تجهيز جدول المراجعة',
            icon: Icons.today_rounded,
            color: AppColors.royalBlue,
          ),
          const SizedBox(height: 14),
          ...List.generate(
            3,
            (_) => Container(
              height: 58,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardsOfflineSummary extends StatelessWidget {
  const _FlashcardsOfflineSummary({
    required this.packsCount,
    required this.onCreatePack,
  });

  final int packsCount;
  final VoidCallback onCreatePack;

  @override
  Widget build(BuildContext context) {
    return _ShotPanel(
      child: _ShotEmptyBlock(
        icon: Icons.cloud_off_rounded,
        title: 'وضع بدون اتصال',
        message: packsCount > 0
            ? 'تظهر الحزم المحفوظة ويمكنك مراجعتها. ستتم المزامنة عند رجوع الإنترنت.'
            : 'لا توجد حزم محفوظة بعد. افتح الميزة مرة واحدة أونلاين لحفظها.',
        actionLabel: packsCount == 0 ? 'إنشاء حزمة' : null,
        onAction: packsCount == 0 ? onCreatePack : null,
      ),
    );
  }
}

class _FlashcardsQueueWarning extends StatelessWidget {
  const _FlashcardsQueueWarning({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ShotPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.goldDeep.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.goldDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعذر تجهيز كروت اليوم',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
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
      ('قراءة', Icons.article_rounded, 'عرض الكروت كقائمة قراءة مبسطة'),
      (
        'اقلب الكرت',
        Icons.flip_rounded,
        'اقلب الكرت لرؤية الوجه الآخر للإجابة',
      ),
      (
        'سؤال وجواب',
        Icons.question_answer_rounded,
        'مراجعة تفاعلية بسؤال وجواب مباشر',
      ),
      (
        'اختيارات',
        Icons.checklist_rounded,
        'اختبر معلوماتك بالأسئلة متعددة الخيارات',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'أوضاع المراجعة والتعلم المتاحة',
            style: TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mode = modes[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mode.$2,
                        size: 20,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mode.$1,
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mode.$3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
    final isActive = boolValue(pack, 'is_active');
    final accuracy = number(pack, 'accuracy', fallback: 0).toDouble();
    final progress = (accuracy / 100).clamp(0.0, 1.0);

    return Opacity(
      opacity: isActive ? 1.0 : 0.65,
      child: Material(
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
                  child: Icon(
                    isActive
                        ? Icons.style_rounded
                        : Icons.pause_circle_filled_rounded,
                    color: isActive ? color : AppColors.slate400,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
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
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.midnight
                                    : AppColors.slate600,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: const Text(
                                'متوقفة',
                                style: TextStyle(
                                  color: AppColors.slate500,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count كرت • ${_typeLabel(text(pack, 'display_mode', fallback: 'one_line'))}',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: AppColors.slate100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isActive ? color : AppColors.slate400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${accuracy.toInt()}%',
                            style: TextStyle(
                              color: isActive ? color : AppColors.slate500,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'مراجعة',
                  onPressed: isActive
                      ? () =>
                            context.push(StudentFlashcardsScreen.reviewPath(id))
                      : null,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  color: isActive ? color : AppColors.slate300,
                ),
                _FlashcardPackMenu(pack: pack),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
