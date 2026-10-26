part of 'student_content_screens.dart';

class _FlashcardPermissionPanel extends ConsumerStatefulWidget {
  const _FlashcardPermissionPanel();

  @override
  ConsumerState<_FlashcardPermissionPanel> createState() =>
      _FlashcardPermissionPanelState();
}

class _FlashcardPermissionPanelState
    extends ConsumerState<_FlashcardPermissionPanel>
    with WidgetsBindingObserver {
  FloatingReviewStatus? _status;
  String? _error;
  bool _busy = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revision++;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!FloatingReview.supportedPlatform) return;
    final revision = ++_revision;
    try {
      final status = await FloatingReview.status();
      if (!mounted || revision != _revision) return;
      setState(() {
        _status = status;
        _error = status.supported
            ? null
            : 'تعذر التحقق من الأذونات في هذه النسخة.';
      });
    } on PlatformException {
      if (mounted && revision == _revision) {
        setState(() {
          _status = null;
          _error = 'تعذر قراءة حالة الأذونات.';
        });
      }
    }
  }

  Future<void> _open(bool overlay) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (overlay) {
        await FloatingReview.requestPermission();
      } else {
        await FloatingReview.openNotificationSettings();
      }
      await _refresh();
    } on PlatformException {
      if (mounted) setState(() => _error = 'تعذر فتح إعدادات الإذن.');
    } on MissingPluginException {
      if (mounted)
        setState(() => _error = 'أغلق التطبيق وشغّل النسخة المحدثة بالكامل.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _permission({
    required String title,
    required IconData icon,
    required bool? allowed,
    required bool overlay,
  }) {
    final color = allowed == true
        ? AppColors.success
        : allowed == false
        ? AppColors.rose
        : AppColors.slate500;
    final label = allowed == true
        ? 'مسموح'
        : allowed == false
        ? 'غير مسموح'
        : _error == null
        ? 'جارٍ التحقق'
        : 'تعذر التحقق';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(label, style: TextStyle(color: color)),
      onTap: _busy ? null : () => _open(overlay),
      trailing: IconButton(
        tooltip: 'إعدادات $title',
        onPressed: _busy ? null : () => _open(overlay),
        icon: const Icon(Icons.settings_outlined),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FloatingReview.supportedPlatform) return const SizedBox.shrink();
    final status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'أذونات الإشعارات والفقاعة',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث الأذونات',
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        _permission(
          title: 'الإشعارات',
          icon: Icons.notifications_active_outlined,
          allowed: status?.notificationsAllowed,
          overlay: false,
        ),
        const Divider(height: 1),
        _permission(
          title: 'الظهور فوق التطبيقات',
          icon: Icons.picture_in_picture_alt_rounded,
          allowed: status?.supported == true ? status?.permission : null,
          overlay: true,
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.rose)),
      ],
    );
  }
}
