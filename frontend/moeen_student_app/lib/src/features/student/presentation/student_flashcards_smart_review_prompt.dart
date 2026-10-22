// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

Future<bool> showStudentFlashcardSmartReviewPrompt({
  required BuildContext context,
  required WidgetRef ref,
  bool force = false,
  bool availableOnly = true,
}) async {
  final store = ref.read(flashcardLocalStoreProvider);
  final canShow = force || await store.canShowSmartReview();
  if (!canShow || !context.mounted) return false;
  final lease = await FloatingReview.beginInApp(force: force);
  if (lease == null) return false;
  try {
    if (!context.mounted) return false;
    return await _showAcquiredSmartReviewPrompt(
      context: context,
      ref: ref,
      store: store,
      availableOnly: availableOnly,
    );
  } finally {
    await FloatingReview.endInApp(lease);
  }
}

Future<bool> _showAcquiredSmartReviewPrompt({
  required BuildContext context,
  required WidgetRef ref,
  required FlashcardLocalStore store,
  required bool availableOnly,
}) async {
  final native = await FloatingReview.status();
  for (final id in native.seenIds) {
    await store.markSmartReviewItemCompletedToday(id);
  }
  if (!context.mounted) return false;

  Map<String, dynamic>? data;
  try {
    data = await ref
        .read(studentContentRepositoryProvider)
        .flashcardDailyQueue();
    await store.cacheDailyQueue(data);
  } on ApiException catch (error) {
    if (!error.isOffline) return false;
    data = await store.loadDailyQueue();
  } catch (_) {
    data = await store.loadDailyQueue();
  }

  final state = await store.load();
  final queue = _todayPendingReviewItems(
    data ?? const {},
    state,
    availableOnly: availableOnly,
  );
  if (queue.isEmpty || !context.mounted) return false;

  await store.markSmartReviewShown();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: size.height * 0.88,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.midnight.withValues(alpha: 0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: _SmartReviewPromptSheet(item: queue.first),
              ),
            ),
          ),
        ),
      );
    },
  );
  return true;
}

class _SmartReviewPromptSheet extends ConsumerStatefulWidget {
  const _SmartReviewPromptSheet({required this.item});

  final Map<String, dynamic> item;

  @override
  ConsumerState<_SmartReviewPromptSheet> createState() =>
      _SmartReviewPromptSheetState();
}

class _SmartReviewPromptSheetState
    extends ConsumerState<_SmartReviewPromptSheet> {
  bool _showBack = false;
  bool _recording = false;
  final _eventId = FloatingReview.eventId();

  @override
  Widget build(BuildContext context) {
    final color = Color(
      _parseHex(
        text(
          widget.item,
          'item_color',
          fallback: text(widget.item, 'pack_color', fallback: '#4338ca'),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewSessionHeader(
          color: color,
          packTitle: text(widget.item, 'pack_title', fallback: 'One Line'),
          current: 1,
          total: 1,
          type: _itemType(widget.item),
        ),
        const SizedBox(height: 16),
        _ShotReviewCard(
          item: widget.item,
          color: color,
          showBack: _showBack,
          onToggleBack: () => setState(() => _showBack = !_showBack),
          onAnswer: _record,
          recording: _recording,
        ),
        const SizedBox(height: 14),
        _ReviewHelperText(item: widget.item, color: color, showBack: _showBack),
        const SizedBox(height: 14),
        _ReviewBottomBar(
          item: widget.item,
          recording: _recording,
          onSkip: _snooze,
          onHard: () => _record('hard'),
          onMedium: () => _record('medium'),
          onEasy: () => _record('easy'),
        ),
      ],
    );
  }

  Future<void> _record(String level) async {
    if (_recording) return;
    final itemId = _flashcardItemId(widget.item);
    if (itemId <= 0) return;
    setState(() => _recording = true);
    try {
      final isOnline = await ref.read(connectivityServiceProvider).isOnline();
      if (!isOnline) {
        await ref
            .read(flashcardLocalStoreProvider)
            .addPendingProgress(
              itemId: itemId,
              responseLevel: level,
              clientEventId: _eventId,
            );
      } else {
        await ref
            .read(studentContentRepositoryProvider)
            .recordFlashcardProgress(
              itemId: itemId,
              responseLevel: level,
              clientEventId: _eventId,
            );
        await ref
            .read(flashcardLocalStoreProvider)
            .markSmartReviewItemCompletedToday(itemId);
      }
    } on ApiException catch (error) {
      if (!error.isOffline) {
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر تسجيل المراجعة',
          message: error.message,
          icon: Icons.error_outline_rounded,
          color: AppColors.rose,
        );
        if (mounted) setState(() => _recording = false);
        return;
      }
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(
            itemId: itemId,
            responseLevel: level,
            clientEventId: _eventId,
          );
    } catch (_) {
      await ref
          .read(flashcardLocalStoreProvider)
          .addPendingProgress(
            itemId: itemId,
            responseLevel: level,
            clientEventId: _eventId,
          );
    }
    await FloatingReview.completed(itemId);
    if (!mounted) return;
    await ref.read(flashcardLocalStoreProvider).snoozeSmartReview();
    await _scheduleNextSmartReviewNotification(ref);
    ref.invalidate(_flashcardDailyQueueProvider);
    ref.invalidate(_flashcardsProvider);
    Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await FloatingReview.snooze();
    await ref.read(flashcardLocalStoreProvider).snoozeSmartReview();
    await _scheduleNextSmartReviewNotification(ref);
    if (mounted) Navigator.of(context).pop();
  }
}
