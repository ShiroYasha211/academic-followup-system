part of 'student_content_screens.dart';

class StudentQuizzesScreen extends ConsumerWidget {
  const StudentQuizzesScreen({super.key});

  static const route = '/student/quizzes';
  static String takePath(int id) => '/student/quizzes/$id/take';
  static String resultPath(int id) => '/student/quizzes/results/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_quizzesProvider);
    return StudentShell(
      currentIndex: 7,
      title: 'الكويزات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_quizzesProvider),
        builder: (data) {
          final doctorQuizzes = asList(data['doctor_quizzes']);
          final competitions = asList(data['competitions']);
          final attempts = asList(data['my_attempts']);

          Future<void> onRefresh() => ref.refresh(_quizzesProvider.future);

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _QuizPageHeader(
                    total: doctorQuizzes.length + competitions.length,
                    completed: attempts.length,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: AppColors.slate50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: TabBar(
                        isScrollable: false,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.slate600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.royalBlue,
                        ),
                        tabs: const [
                          Tab(text: 'المتاحة'),
                          Tab(text: 'المسابقات'),
                          Tab(text: 'محاولاتي'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: _QuizList(
                      items: doctorQuizzes,
                      emptyMessage: 'لا توجد كويزات متاحة حالياً.',
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: _QuizList(
                      items: competitions,
                      emptyMessage: 'لا توجد مسابقات نشطة.',
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: onRefresh,
                    child: _AttemptList(items: attempts),
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

class _QuizPageHeader extends StatelessWidget {
  const _QuizPageHeader({required this.total, required this.completed});
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز الاختبارات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أنجزت $completed من أصل $total اختبار متاح',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizList extends StatelessWidget {
  const _QuizList({required this.items, required this.emptyMessage});
  final List<dynamic> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          EmptyState(message: emptyMessage),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _EntryAnimation(index: index, child: _QuizTile(asMap(items[index]))),
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          EmptyState(message: 'لم تقم بأي محاولات بعد.'),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: items.length,
      itemBuilder: (context, index) => _EntryAnimation(
        index: index,
        child: _AttemptTile(asMap(items[index])),
      ),
    );
  }
}

class StudentQuizTakeScreen extends ConsumerStatefulWidget {
  const StudentQuizTakeScreen({
    super.key,
    required this.quizId,
    this.accessCode,
  });
  final int quizId;
  final String? accessCode;

  @override
  ConsumerState<StudentQuizTakeScreen> createState() =>
      _StudentQuizTakeScreenState();
}

class _StudentQuizTakeScreenState extends ConsumerState<StudentQuizTakeScreen>
    with WidgetsBindingObserver {
  static const _screenLockGracePeriod = Duration(seconds: 60);

  final Map<String, dynamic> _answers = {};
  final _pageController = PageController();
  Timer? _timer;
  Timer? _screenLockGraceTimer;
  Timer? _multiWindowGuardTimer;
  DateTime? _screenLockGraceDeadline;
  int? _attemptId;
  int? _secondsLeft;
  int? _questionSecondsLeft;
  int _currentIndex = 0;
  String _quizTimerMode = 'quiz';
  bool _allowQuestionBacktracking = true;
  bool _submitting = false;
  bool _initializedAttempt = false;
  bool _forcedExitSubmitStarted = false;
  late final StudentContentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(studentContentRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    _quizSecurityChannel.setMethodCallHandler(_handleQuizSecurityMethodCall);
    unawaited(_setQuizScreenSecurity(true));
    _multiWindowGuardTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_guardAgainstMultiWindow()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_guardAgainstMultiWindow());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _screenLockGraceTimer?.cancel();
    _multiWindowGuardTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _quizSecurityChannel.setMethodCallHandler(null);
    unawaited(_setQuizScreenSecurity(false));
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_submitting || _forcedExitSubmitStarted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_handleAppLeftForeground());
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final deadline = _screenLockGraceDeadline;
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        _screenLockGraceTimer?.cancel();
        _screenLockGraceDeadline = null;
        unawaited(_submitBecauseStudentLeft());
      } else {
        _screenLockGraceTimer?.cancel();
        _screenLockGraceDeadline = null;
        unawaited(_guardAgainstMultiWindow());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = (quizId: widget.quizId, accessCode: widget.accessCode);
    final state = ref.watch(_quizTakeProvider(params));

    return StudentShell(
      currentIndex: 7,
      title: 'حل الكويز',
      safeAreaBottom: false,
      onBackPressed: _confirmLeave,
      disableDrawer: true,
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_quizTakeProvider(params)),
        builder: (data) {
          final quiz = asMap(data['quiz']);
          final attempt = asMap(data['attempt']);
          final questions = asList(data['questions']);
          final totalQuestions = questions.length;
          _initializeAttempt(data, quiz, attempt, questions);
          final usesQuestionTimer = _usesQuestionTimer;
          final canGoToPreviousQuestion =
              _currentIndex > 0 &&
              !usesQuestionTimer &&
              _allowQuestionBacktracking;
          final progress = totalQuestions > 0
              ? (_currentIndex + 1) / totalQuestions
              : 0.0;

          return Column(
            children: [
              // Progress Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text(quiz, 'title'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'السؤال ${_currentIndex + 1} من $totalQuestions',
                                style: const TextStyle(
                                  color: AppColors.slate500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _QuizTimerPill(secondsLeft: _activeSecondsLeft),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.slate100,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Questions PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalQuestions,
                  onPageChanged: (idx) => setState(() {
                    _currentIndex = idx;
                    _resetQuestionTimer(asMap(questions[idx]));
                  }),
                  itemBuilder: (context, index) => _QuestionCard(
                    question: asMap(questions[index]),
                    index: index,
                    total: totalQuestions,
                    answers: _answers,
                    onOptionSelected: () {
                      // Optional: auto-advance or just visual feedback
                    },
                  ),
                ),
              ),
              // Navigation Bottom Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (canGoToPreviousQuestion)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'السابق',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        if (canGoToPreviousQuestion) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              if (_currentIndex < totalQuestions - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _confirmSubmit(number(attempt, 'id').toInt());
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _currentIndex == totalQuestions - 1
                                  ? AppColors.success
                                  : AppColors.royalBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _currentIndex == totalQuestions - 1
                                        ? 'إرسال الإجابات'
                                        : 'التالي',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int? get _activeSecondsLeft {
    if (_usesQuestionTimer &&
        _questionSecondsLeft != null &&
        _questionSecondsLeft! > 0) {
      return _questionSecondsLeft;
    }
    return _secondsLeft;
  }

  bool get _usesQuestionTimer => _quizTimerMode == 'per_question';

  void _initializeAttempt(
    Map<String, dynamic> data,
    Map<String, dynamic> quiz,
    Map<String, dynamic> attempt,
    List<dynamic> questions,
  ) {
    final attemptId = number(attempt, 'id').toInt();
    if (_initializedAttempt && _attemptId == attemptId) return;

    _initializedAttempt = true;
    _attemptId = attemptId;
    _quizTimerMode = text(quiz, 'timer_mode', fallback: 'quiz');
    _allowQuestionBacktracking = quiz.containsKey('allow_question_backtracking')
        ? boolValue(quiz, 'allow_question_backtracking')
        : true;
    _answers
      ..clear()
      ..addAll(
        asMap(data['existing_answers']).map((key, value) {
          return MapEntry(key.toString(), value);
        }),
      );

    final remaining = number(attempt, 'remaining_seconds').toInt();
    final durationSeconds = number(quiz, 'duration_minutes').toInt() * 60;
    _secondsLeft = _usesQuestionTimer
        ? null
        : (remaining > 0
              ? remaining
              : (durationSeconds > 0 ? durationSeconds : null));

    if (questions.isNotEmpty) _resetQuestionTimer(asMap(questions.first));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitting) return;
      var shouldSubmit = false;
      setState(() {
        if (!_usesQuestionTimer && _secondsLeft != null && _secondsLeft! > 0) {
          _secondsLeft = _secondsLeft! - 1;
          shouldSubmit = _secondsLeft == 0;
        }
        if (_usesQuestionTimer &&
            _questionSecondsLeft != null &&
            _questionSecondsLeft! > 0) {
          _questionSecondsLeft = _questionSecondsLeft! - 1;
          if (_questionSecondsLeft == 0) {
            if (_currentIndex < questions.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            } else {
              shouldSubmit = true;
            }
          }
        }
      });
      if (shouldSubmit) unawaited(_submit(_attemptId ?? 0, automatic: true));
    });
  }

  void _resetQuestionTimer(Map<String, dynamic> question) {
    if (!_usesQuestionTimer) {
      _questionSecondsLeft = null;
      return;
    }
    final seconds = number(question, 'time_limit_seconds').toInt();
    _questionSecondsLeft = seconds > 0 ? seconds : null;
  }

  Future<void> _handleAppLeftForeground() async {
    if (!mounted || _attemptId == null || _submitting) return;
    final screenLocked = await _isScreenLockedOrOff();
    if (!mounted || _submitting || _forcedExitSubmitStarted) return;

    if (screenLocked) {
      _startScreenLockGraceTimer();
      return;
    }

    await _submitBecauseStudentLeft();
  }

  void _startScreenLockGraceTimer() {
    _screenLockGraceTimer?.cancel();
    final deadline = DateTime.now().add(_screenLockGracePeriod);
    _screenLockGraceDeadline = deadline;
    _screenLockGraceTimer = Timer(_screenLockGracePeriod, () {
      if (!mounted || _submitting || _forcedExitSubmitStarted) return;
      if (_screenLockGraceDeadline == deadline) {
        _screenLockGraceDeadline = null;
        unawaited(_submitBecauseStudentLeft());
      }
    });
  }

  Future<void> _guardAgainstMultiWindow() async {
    if (!mounted || _attemptId == null || _submitting) return;
    if (await _isInQuizMultiWindowMode()) {
      if (!mounted || _submitting || _forcedExitSubmitStarted) return;
      await _submitBecauseStudentLeft();
    }
  }

  Future<dynamic> _handleQuizSecurityMethodCall(MethodCall call) async {
    if (call.method == 'onOverlayDetected' ||
        call.method == 'onWindowFocusLost') {
      await _submitBecauseSecurityOverlay();
    }
    return null;
  }

  Future<void> _submitBecauseSecurityOverlay() async {
    final attemptId = _attemptId;
    if (!mounted || attemptId == null || attemptId <= 0 || _submitting) return;
    _forcedExitSubmitStarted = true;
    _screenLockGraceTimer?.cancel();
    _multiWindowGuardTimer?.cancel();
    _multiWindowGuardTimer = null;
    final submitted = await _submit(attemptId, automatic: true);
    if (!submitted) {
      _forcedExitSubmitStarted = false;
      if (mounted) {
        _multiWindowGuardTimer ??= Timer.periodic(
          const Duration(seconds: 2),
          (_) => unawaited(_guardAgainstMultiWindow()),
        );
      }
    }
  }

  Future<void> _submitBecauseStudentLeft() async {
    final attemptId = _attemptId;
    if (!mounted || attemptId == null || attemptId <= 0 || _submitting) return;
    _forcedExitSubmitStarted = true;
    _screenLockGraceTimer?.cancel();
    _multiWindowGuardTimer?.cancel();
    _multiWindowGuardTimer = null;
    final submitted = await _submit(attemptId, automatic: true);
    if (!submitted) {
      _forcedExitSubmitStarted = false;
      if (mounted) {
        _multiWindowGuardTimer ??= Timer.periodic(
          const Duration(seconds: 2),
          (_) => unawaited(_guardAgainstMultiWindow()),
        );
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (_submitting) return true;
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تنبيه قبل الخروج',
      message:
          'إذا خرجت من صفحة الكويز سيتم تسليم إجاباتك الحالية وإنهاء المحاولة. هل تريد المتابعة؟',
      confirmLabel: 'تسليم وخروج',
      cancelLabel: 'البقاء',
      color: AppColors.danger,
    );
    if (!mounted) return true;
    if (confirmed) {
      await _submit(_attemptId ?? 0, automatic: true);
    }
    return true;
  }

  void _confirmSubmit(int attemptId) async {
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الإرسال',
      message:
          'هل أنت متأكد من رغبتك في إرسال الإجابات؟ لا يمكنك التراجع بعد الإرسال.',
      confirmLabel: 'نعم، إرسال الآن',
      color: AppColors.success,
    );
    if (!mounted) return;
    if (confirmed) unawaited(_submit(attemptId));
  }

  Future<bool> _submit(int attemptId, {bool automatic = false}) async {
    if (!mounted) return false;
    if (attemptId <= 0) return false;
    if (_submitting) return false;
    setState(() => _submitting = true);
    try {
      final response = await _repository.submitQuiz(attemptId, _answers);
      final id = number(response, 'attempt_id', fallback: attemptId).toInt();
      if (mounted) {
        if (automatic) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسليم إجاباتك الحالية وإنهاء الكويز.'),
            ),
          );
        }
        context.go(StudentQuizzesScreen.resultPath(id));
      }
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _QuizTimerPill extends StatelessWidget {
  const _QuizTimerPill({required this.secondsLeft});
  final int? secondsLeft;

  @override
  Widget build(BuildContext context) {
    final remaining = secondsLeft;
    if (remaining == null || remaining <= 0) return const SizedBox.shrink();
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    final isLow = remaining < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isLow ? AppColors.danger : AppColors.royalBlue).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isLow ? AppColors.danger : AppColors.royalBlue,
          ),
          const SizedBox(width: 6),
          Text(
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isLow ? AppColors.danger : AppColors.royalBlue,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

const _quizSecurityChannel = MethodChannel('moeen/security');

Future<void> _setQuizScreenSecurity(bool enabled) async {
  try {
    await _quizSecurityChannel.invokeMethod<void>('setSecureScreen', {
      'enabled': enabled,
    });
  } catch (_) {
    // Older platforms can safely ignore screenshot protection.
  }
}

Future<bool> _isScreenLockedOrOff() async {
  try {
    return await _quizSecurityChannel.invokeMethod<bool>(
          'isScreenLockedOrOff',
        ) ??
        false;
  } catch (_) {
    return false;
  }
}

Future<bool> _isInQuizMultiWindowMode() async {
  try {
    return await _quizSecurityChannel.invokeMethod<bool>(
          'isInMultiWindowMode',
        ) ??
        false;
  } catch (_) {
    return false;
  }
}

class StudentQuizResultScreen extends ConsumerWidget {
  const StudentQuizResultScreen({super.key, required this.attemptId});
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_quizResultProvider(attemptId));

    return StudentShell(
      currentIndex: 7,
      title: 'نتيجة الكويز',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_quizResultProvider(attemptId)),
        builder: (data) {
          final quiz = asMap(data['quiz']);
          final attempt = asMap(data['attempt']);
          final score = number(attempt, 'percentage').toDouble();
          final isSuccess = score >= 50;
          final color = isSuccess ? AppColors.success : AppColors.danger;
          final maxScore = number(attempt, 'max_score').toDouble();
          final duration = number(attempt, 'duration').toInt();
          final message = data['message']?.toString();
          final publicResults = asList(data['public_results']);

          if (message != null && message.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_off_rounded,
                      size: 64,
                      color: AppColors.slate300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go(StudentQuizzesScreen.route),
                      child: const Text('العودة'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Result Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 12,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(color),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${score.toInt()}%',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            Text(
                              '${number(attempt, 'score').toStringAsFixed(0)} / ${maxScore.toStringAsFixed(0)} درجة',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      text(quiz, 'title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم تقديم المحاولة في ${dateTime(text(attempt, 'submitted_at'))}',
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats Row
              Row(
                children: [
                  _ResultStatTile(
                    label: 'إجابات صحيحة',
                    value: text(
                      attempt,
                      'correct_answers_count',
                      fallback: '0',
                    ),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  _ResultStatTile(
                    label: 'إجابات خاطئة',
                    value: text(attempt, 'wrong_answers_count', fallback: '0'),
                    icon: Icons.cancel_rounded,
                    color: AppColors.danger,
                  ),
                  if (duration > 0) ...[
                    const SizedBox(width: 12),
                    _ResultStatTile(
                      label: 'دقيقة',
                      value: '$duration',
                      icon: Icons.timer_rounded,
                      color: AppColors.royalBlue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              if (publicResults.isNotEmpty) ...[
                _PublicQuizResultsList(results: publicResults),
                const SizedBox(height: 32),
              ],
              // Answers Review
              if (boolValue(quiz, 'show_correct_answers')) ...[
                const Text(
                  'مراجعة الإجابات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 16),
                _AnswersReviewList(
                  answers: asList(attempt['answers']),
                  showExplanations: boolValue(quiz, 'show_correction_notes'),
                ),
                const SizedBox(height: 32),
              ],
              FilledButton.icon(
                onPressed: () => context.go(StudentQuizzesScreen.route),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midnight,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'العودة للقائمة الرئيسية',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultStatTile extends StatelessWidget {
  const _ResultStatTile({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicQuizResultsList extends StatelessWidget {
  const _PublicQuizResultsList({required this.results});

  final List<dynamic> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.royalBlue),
              SizedBox(width: 8),
              Text(
                'نتائج الطلاب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'هذا الكويز مضبوط على عرض النتائج بشكل عام.',
            style: TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...results.map((item) {
            return _PublicQuizResultTile(result: asMap(item));
          }),
        ],
      ),
    );
  }
}

class _PublicQuizResultTile extends StatelessWidget {
  const _PublicQuizResultTile({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final student = asMap(result['student']);
    final isCurrentStudent = boolValue(result, 'is_current_student');
    final rank = number(result, 'rank').toInt();
    final score = number(result, 'score').toDouble();
    final maxScore = number(result, 'max_score').toDouble();
    final percentage = number(result, 'percentage').toDouble();
    final studentNumber = text(student, 'student_number');
    final color = isCurrentStudent ? AppColors.royalBlue : AppColors.slate400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentStudent
            ? AppColors.royalBlue.withValues(alpha: 0.06)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentStudent
              ? AppColors.royalBlue.withValues(alpha: 0.22)
              : AppColors.slate100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        text(student, 'name', fallback: 'طالب'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isCurrentStudent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'أنت',
                          style: TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (studentNumber.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    studentNumber,
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${score.toStringAsFixed(0)} / ${maxScore.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 11,
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

class _AnswersReviewList extends StatelessWidget {
  const _AnswersReviewList({
    required this.answers,
    required this.showExplanations,
  });
  final List<dynamic> answers;
  final bool showExplanations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: answers.asMap().entries.map((entry) {
        return _AnswerReviewTile(
          index: entry.key,
          answer: asMap(entry.value),
          showExplanations: showExplanations,
        );
      }).toList(),
    );
  }
}

class _AnswerReviewTile extends StatelessWidget {
  const _AnswerReviewTile({
    required this.index,
    required this.answer,
    required this.showExplanations,
  });
  final int index;
  final Map<String, dynamic> answer;
  final bool showExplanations;

  @override
  Widget build(BuildContext context) {
    final question = asMap(answer['question']);
    final options = asList(question['options']);
    final selectedOptionId = number(answer, 'selected_option_id').toInt();
    final isUnanswered =
        text(answer, 'answer_status') == 'unanswered' || selectedOptionId <= 0;
    final isCorrect = boolValue(answer, 'is_correct');
    final score = number(answer, 'score_awarded').toDouble();
    final maxScore = number(question, 'score').toDouble();
    final correctionNote = text(question, 'correction_note');
    final infoSource = text(question, 'info_source');

    final color = isCorrect
        ? AppColors.success
        : (isUnanswered ? AppColors.warning : AppColors.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_rounded : Icons.close_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'السؤال ${index + 1}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(0)} / ${maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Question Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text(question, 'question_text'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.midnight,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ...options.map((opt) {
            final option = asMap(opt);
            final optId = number(option, 'id').toInt();
            final isCorrectOpt = boolValue(option, 'is_correct');
            final isUserSelected = optId == selectedOptionId;

            Color? optColor;
            IconData? optIcon;

            if (isUserSelected) {
              optColor = isCorrectOpt ? AppColors.success : AppColors.danger;
              optIcon = isCorrectOpt
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded;
            } else if (isCorrectOpt) {
              optColor = AppColors.success.withValues(alpha: 0.5);
              optIcon = Icons.check_circle_outline_rounded;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: optColor?.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: optColor?.withValues(alpha: 0.2) ?? AppColors.slate50,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    optIcon ?? Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: optColor ?? AppColors.slate300,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text(option, 'option_text'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isUserSelected || isCorrectOpt
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: optColor ?? AppColors.slate700,
                        decoration: (isUserSelected && !isCorrectOpt)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // Correction Note
          if (showExplanations &&
              (correctionNote.isNotEmpty || infoSource.isNotEmpty))
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (correctionNote.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'الشرح:',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correctionNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (infoSource.isNotEmpty) ...[
                    if (correctionNote.isNotEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          size: 14,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'المصدر:',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      infoSource,
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF92400E).withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class StudentQuizPrepareScreen extends ConsumerStatefulWidget {
  const StudentQuizPrepareScreen({
    super.key,
    required this.quizId,
    this.quizData,
  });

  final int quizId;
  final Map<String, dynamic>? quizData;

  @override
  ConsumerState<StudentQuizPrepareScreen> createState() =>
      _StudentQuizPrepareScreenState();
}

class _StudentQuizPrepareScreenState
    extends ConsumerState<StudentQuizPrepareScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAcknowledged = false;
  bool _isLoading = false;
  late final StudentContentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(studentContentRepositoryProvider);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startQuiz(bool requiresCode) async {
    if (requiresCode && !_formKey.currentState!.validate()) {
      return;
    }
    if (!_isAcknowledged) return;

    setState(() => _isLoading = true);

    final accessCode = _codeController.text.trim();

    try {
      await _repository.takeQuiz(widget.quizId, accessCode: accessCode);

      if (mounted) {
        final codeParam = accessCode.isNotEmpty
            ? '?access_code=${Uri.encodeComponent(accessCode)}'
            : '';
        context.replace('/student/quizzes/${widget.quizId}/take$codeParam');
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesState = ref.watch(_quizzesProvider);
    Map<String, dynamic>? quiz = widget.quizData;

    if (quiz == null && quizzesState.hasValue) {
      final data = quizzesState.value;
      if (data != null) {
        final doctorQuizzes = asList(data['doctor_quizzes']);
        final competitions = asList(data['competitions']);

        final foundDoctorQuiz = doctorQuizzes.firstWhere(
          (q) => number(asMap(q), 'id').toInt() == widget.quizId,
          orElse: () => null,
        );
        if (foundDoctorQuiz != null) {
          quiz = asMap(foundDoctorQuiz);
        } else {
          final foundCompetition = competitions.firstWhere(
            (c) => number(asMap(c), 'id').toInt() == widget.quizId,
            orElse: () => null,
          );
          if (foundCompetition != null) {
            quiz = asMap(foundCompetition);
          }
        }
      }
    }

    if (quiz == null) {
      return StudentShell(
        currentIndex: 7,
        title: 'الاستعداد للاختبار',
        disableDrawer: true,
        child: Center(
          child: quizzesState.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تحميل بيانات الكويز',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(_quizzesProvider),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.midnight,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
        ),
      );
    }

    final title = text(quiz, 'title', fallback: 'كويز');
    final subjectName = text(quiz, 'subject_name', fallback: 'مقرر دراسي');
    final creatorName = text(quiz, 'creator_name', fallback: 'دكتور المقرر');
    final questionsCount = number(quiz, 'questions_count').toInt();
    final durationMin = number(quiz, 'duration_minutes').toInt();
    final requiresAccessCode = boolValue(quiz, 'requires_access_code');
    final timerMode = text(quiz, 'timer_mode', fallback: 'quiz');
    final timerModeLabel = timerMode == 'per_question'
        ? 'لكل سؤال'
        : 'للاختبار كاملاً';

    return StudentShell(
      currentIndex: 7,
      title: 'الاستعداد للاختبار',
      disableDrawer: true,
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Academic Header (Glassmorphic look with dark gradient)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF172B4D), Color(0xFF2D4B85)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF172B4D).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$subjectName • $creatorName',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bento Grid Stats
                Row(
                  children: [
                    _PrepStatCard(
                      icon: Icons.help_outline_rounded,
                      title: 'عدد الأسئلة',
                      value: '$questionsCount سؤال',
                      color: AppColors.royalBlue,
                    ),
                    const SizedBox(width: 12),
                    _PrepStatCard(
                      icon: Icons.timer_outlined,
                      title: 'الوقت المحدد',
                      value: durationMin > 0 ? '$durationMin دقيقة' : 'بلا وقت',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _PrepStatCard(
                      icon: Icons.speed_rounded,
                      title: 'نظام المؤقت',
                      value: timerModeLabel,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Security Warnings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تعليمات وتحذيرات أمنية هامة',
                            style: TextStyle(
                              color: AppColors.danger.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      const _WarningBullet(
                        text:
                            'الخروج من التطبيق: مغادرة شاشة الاختبار أو الخروج من التطبيق لأي سبب (مثل استقبال مكالمة، الرد على إشعار، أو فتح تطبيق آخر) يؤدي إلى سحب محاولتك وتسليم الاختبار تلقائياً فوراً دون أي مهلة انتظار.',
                      ),
                      const _WarningBullet(
                        text:
                            'الاستعداد والتشويش: يرجى إغلاق المكالمات والوسائط وتفعيل وضع "عدم الإزعاج" قبل البدء، والتواجد في مكان هادئ لتجنب أي تشويش قد يؤثر سلباً على أدائك أو يؤدي لإنهاء محاولتك.',
                      ),
                      const _WarningBullet(
                        text:
                            'تقسيم الشاشة: يمنع منعاً باتاً استخدام ميزة تقسيم الشاشة أو النوافذ المتعددة، وسيتم إلغاء وسحب محاولتك فوراً عند كشفها.',
                      ),
                      const _WarningBullet(
                        text:
                            'لقطات الشاشة: يمنع أخذ لقطات أو تسجيل الشاشة فيديو، وقد يعرض ذلك حسابك الجامعي للمساءلة.',
                      ),
                      const _WarningBullet(
                        text:
                            'العد التنازلي: بمجرد البدء، يسري الوقت ولا يمكن إيقافه مؤقتاً لأي سبب.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // How it works card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.midnight.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.royalBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'طريقة سير الاختبار والتعليمات',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.slate100, height: 1),
                      const SizedBox(height: 12),
                      const _InfoBullet(
                        icon: Icons.wifi_rounded,
                        text:
                            'تأكد من استقرار اتصال الإنترنت لديك بشكل كامل قبل البدء.',
                      ),
                      const _InfoBullet(
                        icon: Icons.play_arrow_rounded,
                        text:
                            'عند نقر "بدء الاختبار الآن"، سيتم تحميل الأسئلة ويسري العداد فوراً.',
                      ),
                      const _InfoBullet(
                        icon: Icons.check_circle_outline_rounded,
                        text:
                            'اختر الإجابة الصحيحة لكل سؤال، ثم استخدم أزرار التنقل للانتقال.',
                      ),
                      if (timerMode == 'per_question')
                        const _InfoBullet(
                          icon: Icons.hourglass_bottom_rounded,
                          text:
                              'بما أن الاختبار بنظام "لكل سؤال"، يرجى الإجابة قبل انتهاء مؤقت السؤال الفردي حيث سينتقل للأسئلة التالية تلقائياً.',
                        ),
                      const _InfoBullet(
                        icon: Icons.send_rounded,
                        text:
                            'عند الانتهاء من السؤال الأخير، يرجى نقر "إرسال الإجابات" لتأكيد تسليم درجتك.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Access Code (Only if required)
                if (requiresAccessCode) ...[
                  const Text(
                    'رمز دخول الكويز مطلوب',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال رمز الدخول للبدء';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'أدخل الرمز هنا',
                      hintStyle: const TextStyle(
                        letterSpacing: 0,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.slate200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Acknowledge Checkbox
                CheckboxListTile(
                  value: _isAcknowledged,
                  onChanged: (val) =>
                      setState(() => _isAcknowledged = val ?? false),
                  title: const Text(
                    'أقر بأنني قرأت كافة التعليمات والتحذيرات الأمنية الموضحة أعلاه، وأتحمل المسؤولية الكاملة في حال مخالفتها.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                      height: 1.5,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),

                // Start Button
                FilledButton(
                  onPressed: (_isAcknowledged && !_isLoading)
                      ? () => _startQuiz(requiresAccessCode)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: AppColors.slate300,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'بدء الاختبار الآن',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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

class _PrepStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _PrepStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.midnight,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBullet extends StatelessWidget {
  final String text;

  const _WarningBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.danger),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate700,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.royalBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate700,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
