part of 'staff_screens.dart';

class DoctorNewsScreen extends ConsumerStatefulWidget {
  const DoctorNewsScreen({super.key});

  static const route = '/doctor/news';

  @override
  ConsumerState<DoctorNewsScreen> createState() => _DoctorNewsScreenState();
}

class _DoctorNewsScreenState extends ConsumerState<DoctorNewsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/news', query: const {'per_page': 30});
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'المركز الإخباري',
      currentRoute: DoctorNewsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

          final items = _docList(_docData(snapshot.data ?? const {}));
          final unread = items.where((item) => item['read_at'] == null).length;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _DocHero(
                  title: 'المركز الإخباري',
                  subtitle:
                      'آخر الأخبار والتنبيهات الجماعية والاستبيانات المرتبطة بحسابك.',
                  icon: Icons.newspaper_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الأخبار',
                      value: items.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.newspaper_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unread.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_email_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const _DocEmpty('لا توجد أخبار حالياً.')
                else
                  ...items.map(
                    (item) => _DoctorNewsCard(
                      item: item,
                      onTap: () => _showNewsDetails(item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewsDetails(_Json item) async {
    final batchId = _docText(item['batch_id']);
    if (batchId.isEmpty) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الخبر',
      icon: Icons.article_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _DoctorNewsDetailsPanel(batchId: batchId, onChanged: _reload),
    );
  }
}

class _DoctorNewsCard extends StatelessWidget {
  const _DoctorNewsCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['type'], 'announcement');
    final unread = item['read_at'] == null;
    final sender = _docMap(item['sender']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration().copyWith(
          border: unread
              ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.28))
              : Border.all(color: AppColors.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _notificationTypeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _notificationTypeIcon(type),
                    color: _notificationTypeColor(type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _docText(item['title'], 'خبر جديد'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _DocPill(
                  _notificationTypeLabel(type),
                  _notificationTypeColor(type),
                  icon: unread ? Icons.fiber_manual_record_rounded : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _docText(item['message']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(sender['name'], 'النظام'),
                  AppColors.slate500,
                  icon: Icons.person_rounded,
                ),
                _DocPill(
                  _docDate(item['created_at']),
                  AppColors.slate500,
                  icon: Icons.schedule_rounded,
                ),
                if (_docText(item['attachment_name']).isNotEmpty)
                  const _DocPill(
                    'مرفق',
                    AppColors.royalBlue,
                    icon: Icons.attach_file_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorNewsDetailsPanel extends ConsumerStatefulWidget {
  const _DoctorNewsDetailsPanel({
    required this.batchId,
    required this.onChanged,
  });

  final String batchId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DoctorNewsDetailsPanel> createState() =>
      _DoctorNewsDetailsPanelState();
}

class _DoctorNewsDetailsPanelState
    extends ConsumerState<_DoctorNewsDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _voting = false;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/news/${widget.batchId}');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

        final data = _docMap(_docData(snapshot.data ?? const {}));
        final item = _docMap(data['item']);
        final related = _docList(data['related_notifications']);
        final options = _docList(data['poll_options']);
        final hasVoted = _docBool(data['has_voted']);
        final sender = _docMap(item['sender']);
        final type = _docText(item['type'], 'announcement');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DocPill(
                  _notificationTypeLabel(type),
                  _notificationTypeColor(type),
                ),
                const SizedBox(width: 8),
                _DocPill(_docDate(item['created_at']), AppColors.slate500),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _docText(item['title'], 'خبر جديد'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _docText(sender['name'], 'النظام'),
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _docText(item['message']),
              style: const TextStyle(
                color: AppColors.midnight,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_docText(item['attachment_url']).isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _downloadAttachment(item),
                icon: Icon(_docFileIcon(_docText(item['attachment_name']))),
                label: Text(_docText(item['attachment_name'], 'تحميل المرفق')),
              ),
            ],
            if (type == 'poll') ...[
              const SizedBox(height: 18),
              Text(
                hasVoted ? 'تم تسجيل تصويتك' : 'اختر إجابتك',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...options.map((option) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    title: Text(
                      _docText(option['option_text'] ?? option['text']),
                    ),
                    trailing: hasVoted
                        ? const Icon(Icons.check_circle_outline_rounded)
                        : FilledButton(
                            onPressed: _voting
                                ? null
                                : () => _vote(_docInt(option['id'])),
                            child: const Text('تصويت'),
                          ),
                  ),
                );
              }),
            ],
            if (related.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                'الإشعارات المرتبطة (${related.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...related.map(
                (notification) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: _cardDecoration(),
                  child: Text(
                    _docText(notification['message']),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _vote(int optionId) async {
    if (optionId <= 0) return;
    setState(() => _voting = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/news/${widget.batchId}/vote',
        {'option_id': optionId},
      );
      widget.onChanged();
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _downloadAttachment(_Json item) async {
    try {
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: _docText(item['attachment_url']),
        fileName: _docText(item['attachment_name'], 'news_attachment'),
        section: 'DoctorNews',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التحميل',
        message: 'تم حفظ المرفق في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorNotificationsScreen extends ConsumerStatefulWidget {
  const DoctorNotificationsScreen({super.key});

  static const route = '/doctor/notifications';

  @override
  ConsumerState<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState
    extends ConsumerState<DoctorNotificationsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/notifications');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'الإشعارات',
      currentRoute: DoctorNotificationsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

          final data = _docMap(_docData(snapshot.data ?? const {}));
          final notifications = _docList(data['notifications']);
          final unreadCount = _docInt(data['unread_count']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _DocHero(
                  title: 'الإشعارات',
                  subtitle: 'متابعة إشعارات النظام والتعليم عليها كمقروءة.',
                  icon: Icons.notifications_rounded,
                  trailing: unreadCount > 0
                      ? TextButton(
                          onPressed: _markAllRead,
                          child: const Text('قراءة الكل'),
                        )
                      : IconButton.filledTonal(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الإجمالي',
                      value: notifications.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.notifications_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unreadCount.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_email_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (notifications.isEmpty)
                  const _DocEmpty('لا توجد إشعارات حالياً.')
                else
                  ...notifications.map(
                    (notification) => _DoctorNotificationCard(
                      notification: notification,
                      onTap: () => _openNotification(notification),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotification(_Json notification) async {
    final id = _docInt(notification['id']);
    if (id > 0 && notification['read_at'] == null) {
      try {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/notifications/$id/read', const {});
        _reload();
      } catch (_) {
        // Showing details is more important than failing because read tracking failed.
      }
    }
    if (!mounted) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الإشعار',
      icon: Icons.notifications_active_rounded,
      color: _notificationTypeColor(_docText(notification['type'])),
      child: _NotificationDetailsPanel(notification: notification),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/notifications/mark-all-read', const {});
      if (!mounted) return;
      _reload();
      _docSnack(
        context,
        'تم تعليم جميع الإشعارات كمقروءة.',
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  const _DoctorNotificationCard({
    required this.notification,
    required this.onTap,
  });

  final _Json notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    final unread = notification['read_at'] == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration().copyWith(
          border: Border.all(
            color: unread
                ? _notificationTypeColor(type).withValues(alpha: 0.32)
                : AppColors.slate100,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _notificationTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _notificationTypeIcon(type),
                color: _notificationTypeColor(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _docText(notification['title'], 'إشعار جديد'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (unread)
                        const Icon(
                          Icons.fiber_manual_record_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _docText(notification['message']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DocPill(
                        _notificationTypeLabel(type),
                        _notificationTypeColor(type),
                      ),
                      _DocPill(
                        _docDate(notification['created_at']),
                        AppColors.slate500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDetailsPanel extends StatelessWidget {
  const _NotificationDetailsPanel({required this.notification});

  final _Json notification;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _DocPill(
              _notificationTypeLabel(type),
              _notificationTypeColor(type),
            ),
            const SizedBox(width: 8),
            _DocPill(_docDate(notification['created_at']), AppColors.slate500),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _docText(notification['title'], 'إشعار جديد'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          _docText(notification['message']),
          style: const TextStyle(
            height: 1.6,
            fontWeight: FontWeight.w700,
            color: AppColors.midnight,
          ),
        ),
        if (_docText(notification['attachment_name']).isNotEmpty) ...[
          const SizedBox(height: 16),
          _DocPill(
            _docText(notification['attachment_name']),
            AppColors.royalBlue,
            icon: Icons.attach_file_rounded,
          ),
        ],
      ],
    );
  }
}

