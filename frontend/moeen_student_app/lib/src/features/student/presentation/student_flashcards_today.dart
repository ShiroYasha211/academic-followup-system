// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardsTodayScreen extends ConsumerStatefulWidget {
  const StudentFlashcardsTodayScreen({super.key});

  @override
  ConsumerState<StudentFlashcardsTodayScreen> createState() =>
      _StudentFlashcardsTodayScreenState();
}

class _StudentFlashcardsTodayScreenState
    extends ConsumerState<StudentFlashcardsTodayScreen> {
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _availabilityTimer;
  bool _syncingProgress = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncPendingProgress);
    _connectionSubscription = ref
        .read(connectivityServiceProvider)
        .statusChanges()
        .listen((isOnline) {
          if (isOnline) _syncPendingProgress();
        });
    _availabilityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _availabilityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(_flashcardDailyQueueProvider);
    final packsState = ref.watch(_flashcardsProvider);

    return StudentShell(
      currentIndex: 15,
      title: 'مراجعة اليوم',
      child: _AsyncBody(
        state: queueState,
        onRetry: () {
          ref.invalidate(_flashcardDailyQueueProvider);
          ref.invalidate(_flashcardsProvider);
        },
        builder: (queueData) {
          final packs = packsState.maybeWhen(
            data: (data) => asList(data['packs']).map(asMap).toList(),
            orElse: () => <Map<String, dynamic>>[],
          );

          return FutureBuilder<FlashcardLocalState>(
            future: ref.read(flashcardLocalStoreProvider).load(),
            builder: (context, snapshot) {
              final localState = snapshot.data ?? const FlashcardLocalState();
              final queue = _todayPendingReviewItems(queueData, localState);
              final availableQueue = _todayPendingReviewItems(
                queueData,
                localState,
                availableOnly: true,
              );
              final reviewedToday = _todayReviewedItems(queueData);
              final completedToday = queue.isEmpty && reviewedToday.isNotEmpty;
              final pendingSync = localState.pendingProgress.length;
              final fallbackPackId = packs.isNotEmpty
                  ? number(packs.first, 'id').toInt()
                  : 0;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(_flashcardDailyQueueProvider);
                  ref.invalidate(_flashcardsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                  children: [
                    _TodayReviewHero(
                      queue: queue,
                      availableQueue: availableQueue,
                      pendingSync: pendingSync,
                      reviewedTodayCount: reviewedToday.length,
                      onStart: () =>
                          _startTodayReview(availableQueue, fallbackPackId),
                    ),
                    const SizedBox(height: 16),
                    _TodayReviewStats(
                      queue: queue,
                      availableQueue: availableQueue,
                      pendingSync: pendingSync,
                    ),
                    const SizedBox(height: 16),
                    _TodayPackBreakdown(queue: queue),
                    const SizedBox(height: 16),
                    _TodayReviewStatusPanel(
                      pending: queue.length,
                      available: availableQueue.length,
                      reviewed: reviewedToday.length,
                      completedToday: completedToday,
                      autoRestart: localState.smartReviewAutoRestart,
                      onRestart: reviewedToday.isEmpty || queue.isNotEmpty
                          ? null
                          : () => _restartTodayReview(),
                      onToggleAutoRestart: (value) =>
                          _setAutoRestartReview(value),
                    ),
                    const SizedBox(height: 16),
                    _ShotSectionHeader(
                      title: 'كروت اليوم',
                      subtitle: queue.isEmpty
                          ? 'لا توجد كروت مستحقة الآن'
                          : 'مرتبة حسب وقت الظهور المقترح',
                      icon: Icons.view_agenda_rounded,
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(height: 12),
                    if (queue.isEmpty)
                      _ShotPanel(
                        child: _ShotEmptyBlock(
                          icon: Icons.task_alt_rounded,
                          title: 'لا توجد مراجعات الآن',
                          message: fallbackPackId > 0
                              ? 'يمكنك بدء مراجعة من إحدى حزمك أو العودة لاحقًا عند ظهور كروت مستحقة.'
                              : 'أنشئ حزمة وأضف كروتًا حتى يبدأ جدول المراجعة اليومي.',
                          actionLabel: fallbackPackId > 0
                              ? 'راجع أول حزمة'
                              : 'العودة للرئيسية',
                          onAction: fallbackPackId > 0
                              ? () => context.push(
                                  StudentFlashcardsScreen.reviewPath(
                                    fallbackPackId,
                                  ),
                                )
                              : () => context.go(StudentFlashcardsScreen.route),
                        ),
                      )
                    else
                      ...queue.map(
                        (item) => _TodayReviewCard(
                          item: item,
                          onTap: () {
                            final isAvailable = _boolValueFallback(
                              item,
                              'available_now',
                              true,
                            );
                            if (!isAvailable) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'هذا الكرت مجدول لاحقًا وسيظهر في وقته.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final packId = number(item, 'pack_id').toInt();
                            if (packId > 0) {
                              context.push(
                                StudentFlashcardsScreen.reviewPath(packId),
                              );
                            }
                          },
                        ),
                      ),
                    if (reviewedToday.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _ShotSectionHeader(
                        title: 'تمت مراجعتها اليوم',
                        subtitle: 'لن تظهر مرة أخرى إلا عند إعادة التفعيل',
                        icon: Icons.done_all_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      ...reviewedToday.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewedTodayCard(item: item),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _startTodayReview(List<Map<String, dynamic>> queue, int fallbackPackId) {
    if (queue.isEmpty && fallbackPackId <= 0) return;
    context.push(StudentFlashcardsScreen.quickReviewRoute);
  }

  Future<void> _restartTodayReview() async {
    try {
      final store = ref.read(flashcardLocalStoreProvider);
      final data = await ref
          .read(studentContentRepositoryProvider)
          .restartFlashcardDailyQueue();
      await store.cacheDailyQueue(data);
      await FloatingReview.updateQueue(store.accountKey, data);
    } on ApiException catch (error) {
      if (mounted)
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر إعادة المراجعة',
          message: error.message,
        );
      return;
    }
    if (!mounted) return;
    ref.invalidate(_flashcardDailyQueueProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إعادة تفعيل كروت اليوم.')),
    );
    setState(() {});
    unawaited(_scheduleNextSmartReviewNotification(ref));
  }

  Future<void> _setAutoRestartReview(bool value) async {
    final data = await ref
        .read(studentContentRepositoryProvider)
        .updateFlashcardSettings({'auto_restart_enabled': value});
    await ref.read(flashcardLocalStoreProvider).cacheSettings(data);
    await ref
        .read(flashcardLocalStoreProvider)
        .applyServerSmartReviewSettings(data, clearSnooze: true);
    if (!mounted) return;
    ref.invalidate(_flashcardSettingsProvider);
    ref.invalidate(_flashcardDailyQueueProvider);
    setState(() {});
  }

  Future<void> _syncPendingProgress() async {
    if (_syncingProgress) return;
    _syncingProgress = true;
    final synced = await _syncFlashcardPendingProgress(ref)
        .catchError((_) => 0)
        .whenComplete(() {
          _syncingProgress = false;
        });
    if (!mounted || synced == 0) return;
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardsProvider);
  }
}

class _TodayReviewStatusPanel extends StatelessWidget {
  const _TodayReviewStatusPanel({
    required this.pending,
    required this.available,
    required this.reviewed,
    required this.completedToday,
    required this.autoRestart,
    required this.onRestart,
    required this.onToggleAutoRestart,
  });

  final int pending;
  final int available;
  final int reviewed;
  final bool completedToday;
  final bool autoRestart;
  final VoidCallback? onRestart;
  final ValueChanged<bool> onToggleAutoRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShotPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ReviewStatusBadge(
                      label: 'متاح الآن',
                      value: '$available',
                      color: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReviewStatusBadge(
                      label: 'تمت مراجعتها',
                      value: '$reviewed',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (pending > available) ...[
                const SizedBox(height: 10),
                _ShotSoftNote(
                  text:
                      'هناك ${pending - available} كرت مجدول لاحقًا ضمن اليوم.',
                ),
              ],
              if (completedToday) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.12),
                        AppColors.success.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.success,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'إنجاز ممتاز اليوم! 🌟',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لقد أكملت مراجعة جميع الكروت المستحقة لليوم بنجاح. استمر في التدرب وحافظ على سلسلة تفوقك!',
                        style: TextStyle(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onRestart != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('إعادة تفعيل كروت اليوم'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.royalBlue,
                    side: const BorderSide(
                      color: AppColors.royalBlue,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Standalone Auto Restart Switch Panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.loop_rounded,
                color: AppColors.royalBlue,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تكرار المراجعة تلقائياً',
                      style: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'إعادة تفعيل الكروت تلقائياً عند انتهاء مراجعتها',
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: autoRestart,
                activeColor: AppColors.royalBlue,
                onChanged: onToggleAutoRestart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStatusBadge extends StatelessWidget {
  const _ReviewStatusBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewedTodayCard extends StatelessWidget {
  const _ReviewedTodayCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final response = text(item, 'last_response');
    final color = _responseColor(response);
    final nextDate = text(item, 'next_review_date');
    final nextTime = text(item, 'next_review_time');
    final nextLabel = nextDate.isEmpty
        ? 'حسب نسبة التكرار'
        : '$nextDate${nextTime.isNotEmpty ? ' · $nextTime' : ''}';
    return _ShotPanel(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.done_rounded, color: color),
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
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'النتيجة: ${text(item, 'last_response_label', fallback: _responseLabel(response))}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'الظهور القادم: $nextLabel',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            text(
              item,
              'reviewed_time_label',
              fallback: text(item, 'reviewed_time', fallback: '--:--'),
            ),
            style: const TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
