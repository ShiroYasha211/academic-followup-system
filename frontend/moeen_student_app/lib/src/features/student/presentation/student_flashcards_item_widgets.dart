// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _FlashcardItemTile extends StatelessWidget {
  const _FlashcardItemTile(this.item, {this.onDelete});

  final Map<String, dynamic> item;
  final VoidCallback? onDelete;

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

  Widget _buildStatusBadge(String response) {
    final (label, badgeColor) = switch (response) {
      'easy' => ('سهل', AppColors.success),
      'medium' => ('متوسط', AppColors.goldDeep),
      'hard' => ('صعب', AppColors.rose),
      _ => ('لم يُراجع', AppColors.royalBlue),
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
    final packColor = Color(
      _parseHex(text(item, 'item_color', fallback: '#4338ca')),
    );
    final type = text(
      item,
      'item_type',
      fallback: text(item, 'resolved_item_type'),
    );
    final priority = text(item, 'priority', fallback: 'normal');
    final lastResponse = text(item, 'last_response');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
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
                      text(item, 'front_content', fallback: 'عنصر'),
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
                        _buildPriorityBadge(priority),
                        _buildStatusBadge(lastResponse),
                        _ShotTinyPill(_flashModeLabel(type)),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.rose,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.rose,
                    backgroundColor: AppColors.rose.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSessionHeader extends StatelessWidget {
  const _ReviewSessionHeader({
    required this.color,
    required this.packTitle,
    required this.current,
    required this.total,
    required this.type,
  });

  final Color color;
  final String packTitle;
  final int current;
  final int total;
  final String type;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.auto_stories_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(type)} · $current من $total',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _ShotTypeChip(type: type),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
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

class _ReviewHelperText extends StatelessWidget {
  const _ReviewHelperText({
    required this.item,
    required this.color,
    required this.showBack,
  });

  final Map<String, dynamic> item;
  final Color color;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final type = _itemType(item);
    final hasBack = text(item, 'back_content').isNotEmpty;
    final message = switch (type) {
      'mcq' => 'اختر الإجابة وسيتم تسجيلها مباشرة.',
      'one_line' => 'اقرأ البطاقة ثم اضغط تمت عند الانتهاء.',
      _ when hasBack && !showBack =>
        'اضغط على البطاقة لعرض الإجابة ثم قيّم تذكرك.',
      _ => 'قيّم تذكرك للكرت حتى نحدد موعد المراجعة القادمة.',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({
    required this.item,
    required this.recording,
    required this.onSkip,
    required this.onHard,
    required this.onMedium,
    required this.onEasy,
  });

  final Map<String, dynamic> item;
  final bool recording;
  final VoidCallback onSkip;
  final VoidCallback onHard;
  final VoidCallback onMedium;
  final VoidCallback onEasy;

  @override
  Widget build(BuildContext context) {
    final type = _itemType(item);
    final isMcq = type == 'mcq';
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: isMcq
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    'سيتم تسجيل اختيارك بمجرد الضغط على الإجابة.',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: recording ? null : onSkip,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('تخطي'),
                ),
              ],
            )
          : Row(
              children: [
                _SmallSkipButton(onPressed: recording ? null : onSkip),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReviewButton(
                    label: 'سهل',
                    color: AppColors.success,
                    icon: Icons.sentiment_very_satisfied_rounded,
                    subtitle: 'تقليل الظهور',
                    onTap: recording ? null : onEasy,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReviewButton(
                    label: 'متوسط',
                    color: AppColors.goldDeep,
                    icon: Icons.sentiment_neutral_rounded,
                    subtitle: 'عادي',
                    onTap: recording ? null : onMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReviewButton(
                    label: 'صعب',
                    color: AppColors.rose,
                    icon: Icons.sentiment_very_dissatisfied_rounded,
                    subtitle: 'زيادة الظهور',
                    onTap: recording ? null : onHard,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SmallSkipButton extends StatelessWidget {
  const _SmallSkipButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 52,
          height: 58,
          child: Icon(Icons.skip_next_rounded, color: AppColors.slate500),
        ),
      ),
    );
  }
}

class _ReviewButton extends StatefulWidget {
  const _ReviewButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  State<_ReviewButton> createState() => _ReviewButtonState();
}

class _ReviewButtonState extends State<_ReviewButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _scale = 0.9),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              widget.onTap!();
            },
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 22),
              const SizedBox(height: 4),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color.withValues(alpha: 0.75),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
