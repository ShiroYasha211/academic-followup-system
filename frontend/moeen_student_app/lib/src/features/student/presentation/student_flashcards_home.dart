// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable

part of 'student_content_screens.dart';

class StudentFlashcardsScreen extends ConsumerStatefulWidget {
  const StudentFlashcardsScreen({super.key});

  static const route = '/student/flashcards';
  static const todayRoute = '/student/flashcards/today';
  static const packsRoute = '/student/flashcards/packs';
  static const upcomingRoute = '/student/flashcards/upcoming';
  static const historyRoute = '/student/flashcards/history';
  static const difficultyRoute = '/student/flashcards/difficulty';
  static const analyticsRoute = '/student/flashcards/analytics';
  static const quickReviewRoute = '/student/flashcards/quick-review';
  static String detailsPath(int id) => '/student/flashcards/$id';
  static String reviewPath(int id) => '/student/flashcards/$id/review';

  @override
  ConsumerState<StudentFlashcardsScreen> createState() =>
      _StudentFlashcardsScreenState();
}

class _StudentFlashcardsScreenState
    extends ConsumerState<StudentFlashcardsScreen> {
  StreamSubscription<bool>? _connectionSubscription;
  bool _syncingProgress = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncPendingProgress);
    Future.microtask(() => _scheduleNextSmartReviewNotification(ref));
    _connectionSubscription = ref
        .read(connectivityServiceProvider)
        .statusChanges()
        .listen((isOnline) {
          if (isOnline) {
            _syncPendingProgress();
            unawaited(_scheduleNextSmartReviewNotification(ref));
          }
        });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardsProvider);
    final queueState = ref.watch(_flashcardDailyQueueProvider);
    final oneLineState = ref.watch(_flashcardOneLineNotificationsProvider);
    ref.listen<AsyncValue<Map<String, dynamic>>>(
      _flashcardOneLineNotificationsProvider,
      (previous, next) {
        next.whenData((data) {
          unawaited(
            ref.read(oneLineNotificationSchedulerProvider).sync(data: data),
          );
        });
      },
    );
    return StudentShell(
      currentIndex: 15,
      title: 'One Line Shot',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePack(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('حزمة'),
        backgroundColor: AppColors.midnight,
        foregroundColor: Colors.white,
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () {
          ref.invalidate(_flashcardsProvider);
          ref.invalidate(_flashcardDailyQueueProvider);
          ref.invalidate(_flashcardOneLineNotificationsProvider);
        },
        builder: (data) {
          final stats = asMap(data['stats']);
          final packs = asList(data['packs']).map(asMap).toList();
          final queueList = queueState.valueOrNull != null
              ? asList(queueState.valueOrNull!['queue']).map(asMap).toList()
              : const <Map<String, dynamic>>[];
          final queueError = queueState.hasError ? queueState.error : null;
          final queueIsOffline =
              queueError is ApiException && queueError.isOffline;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_flashcardsProvider);
              ref.invalidate(_flashcardDailyQueueProvider);
              ref.invalidate(_flashcardOneLineNotificationsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              children: [
                queueState.when(
                  data: (queueData) {
                    return FutureBuilder<FlashcardLocalState>(
                      future: ref.read(flashcardLocalStoreProvider).load(),
                      builder: (context, snapshot) {
                        final localState =
                            snapshot.data ?? const FlashcardLocalState();
                        final availableQueue = _todayPendingReviewItems(
                          queueData,
                          localState,
                          availableOnly: true,
                        );
                        return _OneLineShotHero(
                          stats: stats,
                          queue: availableQueue,
                          pendingSync: localState.pendingProgress.length,
                          reviewedTodayCount: _todayReviewedItems(
                            queueData,
                          ).length,
                          onStart: () {
                            if (availableQueue.isNotEmpty) {
                              context.push(
                                StudentFlashcardsScreen.quickReviewRoute,
                              );
                            } else {
                              context.push(StudentFlashcardsScreen.packsRoute);
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => _OneLineShotHero(
                    stats: stats,
                    queue: const [],
                    pendingSync: 0,
                    reviewedTodayCount: 0,
                    loading: true,
                    onStart: () =>
                        context.push(StudentFlashcardsScreen.packsRoute),
                  ),
                  error: (_, _) => _OneLineShotHero(
                    stats: stats,
                    queue: const [],
                    pendingSync: 0,
                    reviewedTodayCount: 0,
                    offlineMode: queueIsOffline,
                    onStart: () =>
                        context.push(StudentFlashcardsScreen.packsRoute),
                  ),
                ),
                const SizedBox(height: 12),
                const _FlashcardPermissionPanel(),
                const SizedBox(height: 12),
                const _FlashcardSmartReviewSettingsCard(),
                const SizedBox(height: 16),
                oneLineState.when(
                  data: (data) => _OneLineShotNotificationPanel(
                    notificationData: data,
                    offline: data['_offline'] == true,
                  ),
                  loading: () => const _OneLineShotNotificationPanel(
                    notificationData: {},
                    loading: true,
                  ),
                  error: (error, _) => _FlashcardsQueueWarning(
                    message:
                        'تعذر تحميل جدول رسائل One Line: ${error is ApiException ? error.message : 'تعذر الاتصال بالخادم.'}',
                    onRetry: () =>
                        ref.invalidate(_flashcardOneLineNotificationsProvider),
                  ),
                ),
                const SizedBox(height: 16),
                queueState.when(
                  data: (queueData) {
                    return FutureBuilder<FlashcardLocalState>(
                      future: ref.read(flashcardLocalStoreProvider).load(),
                      builder: (context, snapshot) {
                        final localState =
                            snapshot.data ?? const FlashcardLocalState();
                        final allQueue = _todayPendingReviewItems(
                          queueData,
                          localState,
                        );
                        final availableQueue = _todayPendingReviewItems(
                          queueData,
                          localState,
                          availableOnly: true,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FlashcardsTodaySection(
                              queue: allQueue,
                              availableQueue: availableQueue,
                              packs: packs,
                              onCreatePack: () => _showCreatePack(context, ref),
                              onOpenToday: () => context.push(
                                StudentFlashcardsScreen.todayRoute,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FlashcardsInsightSection(
                              stats: stats,
                              packs: packs,
                              queue: allQueue,
                            ),
                            const SizedBox(height: 16),
                            _FlashcardsQuickActions(
                              onStart: () {
                                if (availableQueue.isNotEmpty) {
                                  context.push(
                                    StudentFlashcardsScreen.quickReviewRoute,
                                  );
                                } else {
                                  context.push(
                                    StudentFlashcardsScreen.packsRoute,
                                  );
                                }
                              },
                              onCreatePack: () => _showCreatePack(context, ref),
                              onOpenUpcoming: () => context.push(
                                StudentFlashcardsScreen.upcomingRoute,
                              ),
                              onOpenHistory: () => context.push(
                                StudentFlashcardsScreen.historyRoute,
                              ),
                              onOpenDifficulty: () => context.push(
                                StudentFlashcardsScreen.difficultyRoute,
                              ),
                              onOpenAnalytics: () => context.push(
                                StudentFlashcardsScreen.analyticsRoute,
                              ),
                              onOpenStore: () => context.push(
                                StudentFlashcardStoreScreen.route,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const _FlashcardsTodaySkeleton(),
                  error: (error, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error is ApiException && error.isOffline)
                        _FlashcardsOfflineSummary(
                          packsCount: packs.length,
                          onCreatePack: () => _showCreatePack(context, ref),
                        )
                      else
                        _FlashcardsQueueWarning(
                          message: error.toString(),
                          onRetry: () =>
                              ref.invalidate(_flashcardDailyQueueProvider),
                        ),
                      const SizedBox(height: 16),
                      _FlashcardsInsightSection(
                        stats: stats,
                        packs: packs,
                        queue: const [],
                      ),
                      const SizedBox(height: 16),
                      _FlashcardsQuickActions(
                        onStart: () =>
                            context.push(StudentFlashcardsScreen.packsRoute),
                        onCreatePack: () => _showCreatePack(context, ref),
                        onOpenUpcoming: () =>
                            context.push(StudentFlashcardsScreen.upcomingRoute),
                        onOpenHistory: () =>
                            context.push(StudentFlashcardsScreen.historyRoute),
                        onOpenDifficulty: () => context.push(
                          StudentFlashcardsScreen.difficultyRoute,
                        ),
                        onOpenAnalytics: () => context.push(
                          StudentFlashcardsScreen.analyticsRoute,
                        ),
                        onOpenStore: () =>
                            context.push(StudentFlashcardStoreScreen.route),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _ShotModeStrip(),
                const SizedBox(height: 20),
                _FlashcardPacksPreview(
                  packs: packs,
                  queue: queueList,
                  onOpenAll: () =>
                      context.push(StudentFlashcardsScreen.packsRoute),
                  onCreatePack: () => _showCreatePack(context, ref),
                ),
              ],
            ),
          );
        },
      ),
    );
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
    ref.invalidate(_flashcardsProvider);
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardOneLineNotificationsProvider);
  }

  Future<void> _showCreatePack(BuildContext context, WidgetRef ref) =>
      _showCreatePackSheet(context, ref);
}
