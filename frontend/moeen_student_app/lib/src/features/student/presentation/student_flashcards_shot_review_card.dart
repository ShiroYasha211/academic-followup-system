// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class _ShotReviewCard extends StatefulWidget {
  const _ShotReviewCard({
    super.key,
    required this.item,
    required this.color,
    required this.showBack,
    required this.onToggleBack,
    required this.onAnswer,
    required this.recording,
    this.onSkip,
  });

  final Map<String, dynamic> item;
  final Color color;
  final bool showBack;
  final VoidCallback onToggleBack;
  final ValueChanged<String> onAnswer;
  final bool recording;
  final VoidCallback? onSkip;

  @override
  State<_ShotReviewCard> createState() => _ShotReviewCardState();
}

class _ShotReviewCardState extends State<_ShotReviewCard>
    with SingleTickerProviderStateMixin {
  int? _selectedOption;
  bool? _selectedOptionCorrect;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  double _dragX = 0.0;
  double _dragY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 3.1415926535897932).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    if (widget.showBack) {
      _flipController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_itemType(widget.item) == 'mcq') return;
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_itemType(widget.item) == 'mcq') return;

    if (_dragX > 120) {
      widget.onAnswer('easy');
    } else if (_dragX < -120) {
      widget.onAnswer('hard');
    } else if (_dragY > 120) {
      if (widget.onSkip != null) widget.onSkip!();
    }

    setState(() {
      _dragX = 0.0;
      _dragY = 0.0;
      _isDragging = false;
    });
  }

  @override
  void didUpdateWidget(covariant _ShotReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_flashcardItemId(oldWidget.item) != _flashcardItemId(widget.item)) {
      _selectedOption = null;
      _selectedOptionCorrect = null;
      _flipController.reset();
      _dragX = 0.0;
      _dragY = 0.0;
      _isDragging = false;
    } else if (oldWidget.showBack != widget.showBack) {
      if (widget.showBack) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  Widget? _buildSwipeHint() {
    if (_dragX > 50) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'تقليل الظهور',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    } else if (_dragX < -50) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'زيادة الظهور',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    } else if (_dragY > 50) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.slate500.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'تخطي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Widget _buildCardContent(
    BuildContext context, {
    required bool showBackContent,
  }) {
    final type = _itemType(widget.item);
    final options = _flashcardOptions(widget.item);
    final back = text(widget.item, 'back_content');

    Color borderColor = AppColors.slate200;
    double borderWidth = 1.0;
    if (_isDragging) {
      if (_dragX > 30) {
        borderColor = AppColors.success.withValues(alpha: 0.8);
        borderWidth = 3.0;
      } else if (_dragX < -30) {
        borderColor = AppColors.rose.withValues(alpha: 0.8);
        borderWidth = 3.0;
      } else if (_dragY > 30) {
        borderColor = AppColors.slate500.withValues(alpha: 0.8);
        borderWidth = 3.0;
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: type == 'mcq' ? null : widget.onToggleBack,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ShotTypeChip(type: type),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      text(
                        widget.item,
                        'front_content',
                        fallback: 'كرت مراجعة',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    if (type == 'mcq') ...[
                      const SizedBox(height: 24),
                      ...options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final correct = _correctOptionIndex(widget.item);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ShotOptionTile(
                            label: entry.value,
                            selected: _selectedOption == index,
                            correct: _selectedOption == index
                                ? _selectedOptionCorrect
                                : null,
                            color: widget.color,
                            onTap: widget.recording || _selectedOption != null
                                ? null
                                : () {
                                    final isCorrect = index == correct;
                                    setState(() {
                                      _selectedOption = index;
                                      _selectedOptionCorrect = isCorrect;
                                    });
                                    Future<void>.delayed(
                                      const Duration(milliseconds: 450),
                                      () {
                                        if (!mounted) return;
                                        widget.onAnswer(
                                          isCorrect ? 'easy' : 'hard',
                                        );
                                      },
                                    );
                                  },
                          ),
                        );
                      }),
                    ] else if (back.isNotEmpty && showBackContent) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        back,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ] else if (back.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            color: widget.color,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'اضغط على الكرت لرؤية الإجابة',
                            style: TextStyle(
                              color: widget.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isDragging)
                Positioned.fill(
                  child: IgnorePointer(child: Center(child: _buildSwipeHint())),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _itemType(widget.item);

    if (type == 'mcq') {
      return _buildCardContent(context, showBackContent: false);
    }

    final angle = _flipAnimation.value;
    final isBack = angle > 3.1415926535897932 / 2;

    Widget cardChild = Transform.translate(
      offset: Offset(_dragX, _dragY * 0.4),
      child: Transform.rotate(
        angle: _dragX * 0.0005,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: Transform(
                transform: isBack
                    ? Matrix4.rotationY(3.1415926535897932)
                    : Matrix4.identity(),
                alignment: Alignment.center,
                child: _buildCardContent(context, showBackContent: isBack),
              ),
            );
          },
        ),
      ),
    );

    return GestureDetector(
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: cardChild,
    );
  }
}

class _ShotOptionTile extends StatelessWidget {
  const _ShotOptionTile({
    required this.label,
    required this.selected,
    required this.correct,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool? correct;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stateColor = correct == null
        ? color
        : correct!
        ? AppColors.success
        : AppColors.rose;
    final background = selected
        ? stateColor.withValues(alpha: 0.12)
        : AppColors.slate50;
    final icon = correct == null
        ? selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded
        : correct!
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? stateColor : AppColors.slate200,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? stateColor : AppColors.slate400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.midnight : AppColors.slate700,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotTypeChip extends StatelessWidget {
  const _ShotTypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _typeLabel(type),
        style: const TextStyle(
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FlashCardPreview extends StatelessWidget {
  const _FlashCardPreview({
    required this.content,
    this.backContent,
    required this.color,
    required this.onTap,
  });
  final String content;
  final String? backContent;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.85,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(38),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (backContent != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    backContent!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
