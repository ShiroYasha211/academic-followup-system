// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardQuickReviewScreen extends ConsumerStatefulWidget {
  const StudentFlashcardQuickReviewScreen({super.key});

  @override
  ConsumerState<StudentFlashcardQuickReviewScreen> createState() =>
      _StudentFlashcardQuickReviewScreenState();
}

class _StudentFlashcardQuickReviewScreenState
    extends ConsumerState<StudentFlashcardQuickReviewScreen> {
  int _index = 0;
  bool _showBack = false;
  bool _recording = false;
  int _reviewed = 0;
  int _skipped = 0;
  int _easyCount = 0;
  int _mediumCount = 0;
  int _hardCount = 0;
  Color? _flashColor;

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(_flashcardDailyQueueProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'مراجعة سريعة',
      child: _AsyncBody(
        state: queueState,
        onRetry: () => ref.invalidate(_flashcardDailyQueueProvider),
        builder: (data) {
          return FutureBuilder<FlashcardLocalState>(
            future: ref.read(flashcardLocalStoreProvider).load(),
            builder: (context, snapshot) {
              final queue = _todayPendingReviewItems(
                data,
                snapshot.data ?? const FlashcardLocalState(),
                availableOnly: true,
              );
              if (queue.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EmptyState(
                          message: 'لا توجد كروت جاهزة للمراجعة الآن.',
                          icon: Icons.task_alt_rounded,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              context.go(StudentFlashcardsScreen.route),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('العودة إلى One Line'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = queue[_index.clamp(0, queue.length - 1)];
              final color = Color(
                _parseHex(
                  text(
                    item,
                    'item_color',
                    fallback: text(item, 'pack_color', fallback: '#4338ca'),
                  ),
                ),
              );
              final type = _itemType(item);

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop) return;
                  await _confirmExit(queue.length);
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.14),
                            const Color(0xFFF8FAFC),
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            _QuickReviewTopBar(
                              reviewed: _reviewed,
                              skipped: _skipped,
                              remaining: queue.length - _index,
                              color: color,
                              progress: queue.isNotEmpty
                                  ? (_index / queue.length)
                                  : 0.0,
                              onClose: () => _confirmExit(queue.length),
                            ),
                            _ReviewSessionHeader(
                              color: color,
                              packTitle: text(
                                item,
                                'pack_title',
                                fallback: 'One Line',
                              ),
                              current: _index + 1,
                              total: queue.length,
                              type: type,
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  20,
                                  18,
                                ),
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          final isEntering =
                                              child.key ==
                                              ValueKey(_flashcardItemId(item));
                                          final offset = isEntering
                                              ? const Offset(1.0, 0.0)
                                              : const Offset(-1.0, 0.0);
                                          final slide =
                                              Tween<Offset>(
                                                begin: offset,
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOut,
                                                ),
                                              );
                                          return SlideTransition(
                                            position: slide,
                                            child: child,
                                          );
                                        },
                                    child: _ShotReviewCard(
                                      key: ValueKey(_flashcardItemId(item)),
                                      item: item,
                                      color: color,
                                      showBack: _showBack,
                                      onToggleBack: () => setState(
                                        () => _showBack = !_showBack,
                                      ),
                                      onAnswer: (level) =>
                                          _record(item, level, queue.length),
                                      recording: _recording,
                                      onSkip: () => _skip(queue.length),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _ReviewHelperText(
                                    item: item,
                                    color: color,
                                    showBack: _showBack,
                                  ),
                                ],
                              ),
                            ),
                            _ReviewBottomBar(
                              item: item,
                              recording: _recording,
                              onSkip: () => _skip(queue.length),
                              onHard: () => _record(item, 'hard', queue.length),
                              onMedium: () =>
                                  _record(item, 'medium', queue.length),
                              onEasy: () => _record(item, 'easy', queue.length),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_flashColor != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            color: _flashColor!.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmExit(int total) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'إنهاء الجلسة',
      message:
          'هل أنت متأكد من رغبتك في الخروج؟ سيتم اعتبار الكروت المتبقية كـ "تخطي".',
      confirmLabel: 'خروج وتخطي',
      cancelLabel: 'إلغاء',
      color: AppColors.rose,
    );
    if (ok == true && mounted) {
      final remaining = total - _index;
      setState(() {
        _skipped += remaining;
        _index = total - 1;
      });
      await _finishSession(total);
    }
  }

  Future<void> _record(
    Map<String, dynamic> item,
    String level,
    int total,
  ) async {
    if (_recording) return;
    final itemId = _flashcardItemId(item);
    if (itemId <= 0) return;

    final flashColor = switch (level) {
      'easy' => AppColors.success,
      'medium' => AppColors.goldDeep,
      'hard' => AppColors.rose,
      _ => null,
    };
    if (flashColor != null) {
      setState(() => _flashColor = flashColor);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _flashColor = null);
      });
    }

    setState(() => _recording = true);
    var savedOffline = false;
    try {
      final isOnline = await ref.read(connectivityServiceProvider).isOnline();
      if (!isOnline) {
        await ref
            .read(flashcardLocalStoreProvider)
            .addPendingProgress(itemId: itemId, responseLevel: level);
        savedOffline = true;
      } else {
        await ref
            .read(studentContentRepositoryProvider)
            .recordFlashcardProgress(itemId: itemId, responseLevel: level);
        await ref
            .read(flashcardLocalStoreProvider)
            .markSmartReviewItemCompletedToday(itemId);
      }
    } on ApiException catch (error) {
      if (!error.isOffline) {
        if (mounted) {
          await showMoeenInfoDialog(
            context: context,
            title: 'تعذر تسجيل المراجعة',
            message: error.message,
            icon: Icons.error_outline_rounded,
            color: AppColors.rose,
          );
        }
        if (mounted) setState(() => _recording = false);
        return;
      }
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(itemId: itemId, responseLevel: level);
      savedOffline = true;
    } catch (_) {
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(itemId: itemId, responseLevel: level);
      savedOffline = true;
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _reviewed++;
      if (level == 'easy') _easyCount++;
      if (level == 'medium') _mediumCount++;
      if (level == 'hard') _hardCount++;
    });
    if (savedOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المراجعة محليًا للمزامنة لاحقًا.'),
        ),
      );
    }
    await _advanceOrFinish(total);
  }

  Future<void> _skip(int total) async {
    if (_recording) return;
    setState(() => _skipped++);
    await _advanceOrFinish(total);
  }

  Future<void> _advanceOrFinish(int total) async {
    if (_index + 1 >= total) {
      await _finishSession(total);
      return;
    }
    if (!mounted) return;
    setState(() {
      _index++;
      _showBack = false;
    });
  }

  Future<void> _finishSession(int total) async {
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardsProvider);
    await _scheduleNextSmartReviewNotification(ref);

    await showMoeenBottomSheet<void>(
      context: context,
      title: 'اكتمال المراجعة',
      icon: Icons.emoji_events_rounded,
      color: AppColors.success,
      child: _ReviewFinishedSheet(
        reviewed: _reviewed,
        skipped: _skipped,
        easyCount: _easyCount,
        mediumCount: _mediumCount,
        hardCount: _hardCount,
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _index = 0;
            _reviewed = 0;
            _skipped = 0;
            _easyCount = 0;
            _mediumCount = 0;
            _hardCount = 0;
            _showBack = false;
          });
          ref.invalidate(_flashcardDailyQueueProvider);
        },
        onGoHome: () {
          Navigator.of(context).pop();
          context.go(StudentFlashcardsScreen.route);
        },
      ),
    );
    if (mounted) {
      if (_index >= total - 1) {
        context.go(StudentFlashcardsScreen.route);
      }
    }
  }
}

class _QuickReviewTopBar extends StatelessWidget {
  const _QuickReviewTopBar({
    required this.reviewed,
    required this.skipped,
    required this.remaining,
    required this.color,
    required this.progress,
    required this.onClose,
  });

  final int reviewed;
  final int skipped;
  final int remaining;
  final Color color;
  final double progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final barColor = Color.lerp(color, AppColors.success, progress) ?? color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.slate700,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickReviewMetric(
                        label: 'تمت',
                        value: '$reviewed',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickReviewMetric(
                        label: 'متبقي',
                        value: '$remaining',
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickReviewMetric(
                        label: 'تخطي',
                        value: '$skipped',
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReviewMetric extends StatelessWidget {
  const _QuickReviewMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

