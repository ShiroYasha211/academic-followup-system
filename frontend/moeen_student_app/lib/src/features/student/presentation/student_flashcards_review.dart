// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardReviewScreen extends ConsumerStatefulWidget {
  const StudentFlashcardReviewScreen({super.key, required this.packId});

  final int packId;

  @override
  ConsumerState<StudentFlashcardReviewScreen> createState() =>
      _StudentFlashcardReviewScreenState();
}

class _StudentFlashcardReviewScreenState
    extends ConsumerState<StudentFlashcardReviewScreen> {
  int _index = 0;
  bool _showBack = false;
  bool _recording = false;
  int _easyCount = 0;
  int _mediumCount = 0;
  int _hardCount = 0;
  int _skippedCount = 0;
  int _mcqCorrectCount = 0;
  int _mcqWrongCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_syncPendingProgress);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardReviewProvider(widget.packId));
    return StudentShell(
      currentIndex: 15,
      title: 'مراجعة One Line',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardReviewProvider(widget.packId)),
        builder: (data) {
          final items = asList(data['items']).map(asMap).toList();
          if (items.isEmpty) {
            return const Center(
              child: EmptyState(message: 'لا توجد عناصر للمراجعة اليوم.'),
            );
          }
          final item = items[_index.clamp(0, items.length - 1)];
          final color = Color(
            _parseHex(
              text(
                item,
                'item_color',
                fallback: text(
                  asMap(item['pack']),
                  'color',
                  fallback: '#4338ca',
                ),
              ),
            ),
          );

          final type = _itemType(item);
          final pack = asMap(item['pack']);
          final packTitle = text(pack, 'title', fallback: 'حزمة مراجعة');

          return Container(
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
                  _ReviewSessionHeader(
                    color: color,
                    packTitle: packTitle,
                    current: _index + 1,
                    total: items.length,
                    type: type,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      children: [
                        _ShotReviewCard(
                          item: item,
                          color: color,
                          showBack: _showBack,
                          onToggleBack: () =>
                              setState(() => _showBack = !_showBack),
                          onAnswer: (level) =>
                              _record(item, level, items.length),
                          recording: _recording,
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
                    onSkip: () => _skip(items.length),
                    onHard: () => _record(item, 'hard', items.length),
                    onMedium: () => _record(item, 'medium', items.length),
                    onEasy: () => _record(item, 'easy', items.length),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _record(
    Map<String, dynamic> item,
    String level,
    int total,
  ) async {
    if (_recording) return;
    final itemId = _flashcardItemId(item);
    if (itemId <= 0) return;
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
      if (error.isOffline) {
        await ref
            .read(flashcardLocalStoreProvider)
            .addPendingProgress(itemId: itemId, responseLevel: level);
        savedOffline = true;
      } else {
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
    } catch (_) {
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(itemId: itemId, responseLevel: level);
      savedOffline = true;
    }
    if (!mounted) return;
    _registerAnswer(level, _itemType(item) == 'mcq');
    setState(() => _recording = false);
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
    _skippedCount++;
    await _advanceOrFinish(total);
  }

  void _registerAnswer(String level, bool isMcq) {
    switch (level) {
      case 'easy':
        _easyCount++;
        if (isMcq) _mcqCorrectCount++;
        break;
      case 'medium':
        _mediumCount++;
        break;
      default:
        _hardCount++;
        if (isMcq) _mcqWrongCount++;
        break;
    }
  }

  Future<void> _advanceOrFinish(int total) async {
    if (_index + 1 >= total) {
      await _showSessionSummary(total);
      if (mounted) context.pop();
    } else if (mounted) {
      setState(() {
        _index++;
        _showBack = false;
      });
    }
  }

  Future<void> _showSessionSummary(int total) async {
    final answered = total - _skippedCount;
    final mcqTotal = _mcqCorrectCount + _mcqWrongCount;
    final mcqLine = mcqTotal == 0
        ? ''
        : '\nاختيارات صحيحة: $_mcqCorrectCount، خاطئة: $_mcqWrongCount';
    await showMoeenInfoDialog(
      context: context,
      title: 'انتهت المراجعة',
      message:
          'تمت مراجعة $answered من أصل $total كرت.\nسهل: $_easyCount، متوسط: $_mediumCount، صعب: $_hardCount، تخطي: $_skippedCount$mcqLine',
      icon: Icons.celebration_rounded,
      color: AppColors.success,
    );
  }

  Future<void> _syncPendingProgress() async {
    await _syncFlashcardPendingProgress(ref);
  }
}

