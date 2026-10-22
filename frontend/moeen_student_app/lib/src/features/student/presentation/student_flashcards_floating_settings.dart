part of 'student_content_screens.dart';

class _FloatingReviewSettings extends ConsumerStatefulWidget {
  const _FloatingReviewSettings();

  @override
  ConsumerState<_FloatingReviewSettings> createState() =>
      _FloatingReviewSettingsState();
}

class _FloatingReviewSettingsState
    extends ConsumerState<_FloatingReviewSettings>
    with WidgetsBindingObserver {
  FloatingReviewStatus? _status;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final session = ref.read(authControllerProvider).valueOrNull;
      if (session == null || session.isDelegate) return;
      await FloatingReview.configure(session);
      final status = await FloatingReview.status();
      if (mounted)
        setState(() {
          _status = status;
          _error = null;
        });
    } on PlatformException {
      if (mounted) setState(() => _error = 'تعذر قراءة حالة المراجعة العائمة.');
    } on MissingPluginException {
      if (mounted)
        setState(
          () => _error = 'يلزم إغلاق التطبيق وتشغيل النسخة المحدثة بالكامل.',
        );
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } on PlatformException {
      if (mounted)
        setState(
          () => _error =
              'تعذر تشغيل المراجعة. تحقق من الإذن ووجودك خارج الاختبار.',
        );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FloatingReview.supportedPlatform) return const SizedBox.shrink();
    final status = _status;
    if (status == null) {
      return ListTile(
        leading: const Icon(Icons.picture_in_picture_alt_rounded),
        title: const Text('عرض المراجعة'),
        subtitle: Text(_error ?? 'جارٍ التحقق من الحالة...'),
        trailing: IconButton(
          tooltip: 'تحديث الحالة',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      );
    }
    if (!status.supported) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ReviewDisplayMode>(
          value: status.mode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'عرض المراجعة',
            prefixIcon: Icon(Icons.picture_in_picture_alt_rounded),
          ),
          items: const [
            DropdownMenuItem(
              value: ReviewDisplayMode.inApp,
              child: Text('داخل معين'),
            ),
            DropdownMenuItem(
              value: ReviewDisplayMode.floating,
              child: Text('نافذة عائمة خارج معين'),
            ),
            DropdownMenuItem(
              value: ReviewDisplayMode.notificationOnly,
              child: Text('إشعار فقط'),
            ),
          ],
          onChanged: _busy
              ? null
              : (mode) {
                  if (mode != null)
                    unawaited(
                      _act(() async {
                        await FloatingReview.setMode(mode);
                        if (!mounted) return;
                        await _scheduleNextSmartReviewNotification(ref);
                      }),
                    );
                },
        ),
        if (status.mode == ReviewDisplayMode.floating) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                status.running
                    ? Icons.play_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: status.running ? AppColors.success : AppColors.slate500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.running
                      ? 'جلسة المراجعة نشطة'
                      : 'جلسة المراجعة متوقفة',
                ),
              ),
              IconButton(
                tooltip: 'تحديث الحالة',
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (!status.permission)
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _act(FloatingReview.requestPermission),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('السماح بالظهور فوق التطبيقات'),
            )
          else
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _act(() async {
                      if (status.running) {
                        await FloatingReview.endSession();
                      } else {
                        final allowed =
                            await PushNotificationService.requestReviewNotificationPermission();
                        if (!allowed)
                          throw PlatformException(
                            code: 'notifications_disabled',
                          );
                        if (!mounted) return;
                        await FloatingReview.start();
                      }
                      if (!mounted) return;
                      await _scheduleNextSmartReviewNotification(ref);
                    }),
              icon: Icon(
                status.running ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                status.running ? 'إيقاف الجلسة' : 'بدء جلسة المراجعة',
              ),
            ),
        ],
        if (status.pending > 0) ...[
          const SizedBox(height: 8),
          Text(
            'إجابات بانتظار المزامنة: ${status.pending}',
            style: const TextStyle(color: AppColors.slate700),
          ),
        ],
        if (_error != null || status.message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _error ?? status.message,
            style: TextStyle(
              color: _error != null ? AppColors.danger : AppColors.slate700,
            ),
          ),
        ],
      ],
    );
  }
}
