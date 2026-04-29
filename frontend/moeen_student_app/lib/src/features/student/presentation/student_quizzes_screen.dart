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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                  _QuizList(items: doctorQuizzes, emptyMessage: 'لا توجد كويزات متاحة حالياً.'),
                  _QuizList(items: competitions, emptyMessage: 'لا توجد مسابقات نشطة.'),
                  _AttemptList(items: attempts),
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
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'أنجزت $completed من أصل $total اختبار متاح',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
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
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
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
    if (items.isEmpty) return EmptyState(message: emptyMessage);
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: items.length,
      itemBuilder: (context, index) => _EntryAnimation(
        index: index,
        child: _QuizTile(asMap(items[index])),
      ),
    );
  }
}

class _AttemptList extends StatelessWidget {
  const _AttemptList({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyState(message: 'لم تقم بأي محاولات بعد.');
    return ListView.builder(
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
  const StudentQuizTakeScreen({super.key, required this.quizId, this.accessCode});
  final int quizId;
  final String? accessCode;

  @override
  ConsumerState<StudentQuizTakeScreen> createState() => _StudentQuizTakeScreenState();
}

class _StudentQuizTakeScreenState extends ConsumerState<StudentQuizTakeScreen> {
  final Map<String, dynamic> _answers = {};
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = (quizId: widget.quizId, accessCode: widget.accessCode);
    final state = ref.watch(_quizTakeProvider(params));

    return StudentShell(
      currentIndex: 7,
      title: 'حل الكويز',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_quizTakeProvider(params)),
        builder: (data) {
          final quiz = asMap(data['quiz']);
          final attempt = asMap(data['attempt']);
          final questions = asList(data['questions']);
          final totalQuestions = questions.length;
          final progress = totalQuestions > 0 ? (_currentIndex + 1) / totalQuestions : 0.0;

          return Column(
            children: [
              // Progress Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text(quiz, 'title'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('السؤال ${_currentIndex + 1} من $totalQuestions', style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        _TimerWidget(durationMinutes: number(quiz, 'duration_minutes').toInt()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.slate100,
                        valueColor: const AlwaysStoppedAnimation(AppColors.royalBlue),
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
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    if (_currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Text('السابق', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    if (_currentIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          if (_currentIndex < totalQuestions - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            _confirmSubmit(number(attempt, 'id').toInt());
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _currentIndex == totalQuestions - 1 ? AppColors.success : AppColors.royalBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _currentIndex == totalQuestions - 1 ? 'إرسال الإجابات' : 'التالي',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSubmit(int attemptId) async {
    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد الإرسال',
      message: 'هل أنت متأكد من رغبتك في إرسال الإجابات؟ لا يمكنك التراجع بعد الإرسال.',
      confirmLabel: 'نعم، إرسال الآن',
      color: AppColors.success,
    );
    if (confirmed) _submit(attemptId);
  }

  Future<void> _submit(int attemptId) async {
    if (attemptId <= 0) return;
    setState(() => _submitting = true);
    try {
      final response = await ref.read(studentContentRepositoryProvider).submitQuiz(attemptId, _answers);
      final id = number(response, 'attempt_id', fallback: attemptId).toInt();
      if (mounted) {
        context.go(StudentQuizzesScreen.resultPath(id));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _TimerWidget extends StatefulWidget {
  const _TimerWidget({required this.durationMinutes});
  final int durationMinutes;

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  late int _secondsLeft;
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => _secondsLeft - i - 1).take(_secondsLeft);
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft <= 0) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: _timerStream,
      initialData: _secondsLeft,
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 0;
        final mins = remaining ~/ 60;
        final secs = remaining % 60;
        final isLow = remaining < 60;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isLow ? AppColors.danger : AppColors.royalBlue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: isLow ? AppColors.danger : AppColors.royalBlue),
              const SizedBox(width: 6),
              Text(
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style: TextStyle(color: isLow ? AppColors.danger : AppColors.royalBlue, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      },
    );
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
          final score = number(attempt, 'score').toDouble();
          final isSuccess = score >= 50;
          final color = isSuccess ? AppColors.success : AppColors.danger;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Result Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15))],
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
                              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: color),
                            ),
                            Text(
                              isSuccess ? 'عمل رائع!' : 'تحتاج للمذاكرة',
                              style: TextStyle(color: color.withValues(alpha: 0.6), fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      text(quiz, 'title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.midnight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تم تقديم المحاولة في ${dateOnly(text(attempt, 'submitted_at'))}',
                      style: const TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats Row
              Row(
                children: [
                  _ResultStatTile(
                    label: 'الإجابات الصحيحة',
                    value: text(attempt, 'correct_answers_count', fallback: '-'),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 16),
                  _ResultStatTile(
                    label: 'الإجابات الخاطئة',
                    value: text(attempt, 'wrong_answers_count', fallback: '-'),
                    icon: Icons.cancel_rounded,
                    color: AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go(StudentQuizzesScreen.route),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midnight,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('العودة للقائمة الرئيسية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultStatTile extends StatelessWidget {
  const _ResultStatTile({required this.label, required this.value, required this.icon, required this.color});
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.midnight),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
