part of 'staff_screens.dart';

class DoctorNewsScreen extends ConsumerStatefulWidget {
  const DoctorNewsScreen({super.key});

  static const route = '/doctor/news';

  @override
  ConsumerState<DoctorNewsScreen> createState() => _DoctorNewsScreenState();
}

class _DoctorNewsScreenState extends ConsumerState<DoctorNewsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();
  String _activeFilter = 'all'; // all, unread, polls, announcements

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

          final allItems = _docList(_docData(snapshot.data ?? const {}));
          final unreadCount = allItems
              .where((item) => item['read_at'] == null)
              .length;

          // Local Filter Logic
          final filteredItems = allItems.where((item) {
            final type = _docText(item['type']);
            final isUnread = item['read_at'] == null;
            if (_activeFilter == 'unread') {
              return isUnread;
            } else if (_activeFilter == 'polls') {
              return type == 'poll';
            } else if (_activeFilter == 'announcements') {
              return type == 'announcement';
            }
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _NewsHeaderV3(unreadCount: unreadCount),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DocMetric(
                        label: 'إجمالي الأخبار',
                        value: allItems.length.toString(),
                        color: AppColors.royalBlue,
                        icon: Icons.newspaper_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocMetric(
                        label: 'غير مقروءة',
                        value: unreadCount.toString(),
                        color: unreadCount > 0
                            ? AppColors.warning
                            : AppColors.slate400,
                        icon: Icons.mark_email_unread_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Quick Filter Chips Bar
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(label: 'كل الأخبار', filterKey: 'all'),
                      _filterChip(
                        label: 'غير المقروءة',
                        filterKey: 'unread',
                        count: unreadCount,
                      ),
                      _filterChip(label: 'الاستبيانات فقط', filterKey: 'polls'),
                      _filterChip(
                        label: 'الإعلانات العامة',
                        filterKey: 'announcements',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filteredItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: _DocEmpty('لا توجد أخبار مطابقة للفلاتر حالياً.'),
                  )
                else
                  ...filteredItems.map(
                    (item) => _DoctorNewsCardV3(
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

  Widget _filterChip({
    required String label,
    required String filterKey,
    int count = 0,
  }) {
    final isSelected = _activeFilter == filterKey;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filterKey),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.royalBlue : AppColors.slate200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.midnight,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  fontFamily: 'Cairo',
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? AppColors.royalBlue : Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      child: _DoctorNewsDetailsPanelV3(batchId: batchId, onChanged: _reload),
    );
  }
}

class _NewsHeaderV3 extends StatelessWidget {
  const _NewsHeaderV3({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlueDark, AppColors.royalBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -22,
            top: -22,
            child: Icon(
              Icons.newspaper_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المركز الإخباري الموحد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount > 0
                    ? 'لديك عدد $unreadCount إشعارات إخبارية جديدة لم تقرأ بعد.'
                    : 'أنت مطلع على كافة الأخبار والاستبيانات الرسمية بالكلية.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorNewsCardV3 extends StatelessWidget {
  const _DoctorNewsCardV3({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['type'], 'announcement');
    final unread = item['read_at'] == null;
    final sender = _docMap(item['sender']);
    final typeColor = _notificationTypeColor(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? typeColor.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unread
              ? typeColor.withValues(alpha: 0.35)
              : AppColors.slate100,
          width: unread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: unread ? 0.03 : 0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _notificationTypeIcon(type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _docText(item['title'], 'خبر جديد'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DocPill(
                    _notificationTypeLabel(type),
                    typeColor,
                    icon: unread ? Icons.fiber_manual_record_rounded : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _docText(item['message']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _DocPill(
                    _docText(sender['name'], 'الناشر الرسمي'),
                    AppColors.slate500,
                    icon: Icons.person_outline_rounded,
                  ),
                  _DocPill(
                    _docDate(item['created_at']),
                    AppColors.royalBlue,
                    icon: Icons.schedule_rounded,
                  ),
                  if (_docText(item['attachment_name']).isNotEmpty)
                    const _DocPill(
                      'مستند مرفق',
                      AppColors.teal,
                      icon: Icons.attach_file_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorNewsDetailsPanelV3 extends ConsumerStatefulWidget {
  const _DoctorNewsDetailsPanelV3({
    required this.batchId,
    required this.onChanged,
  });

  final String batchId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DoctorNewsDetailsPanelV3> createState() =>
      _DoctorNewsDetailsPanelV3State();
}

class _DoctorNewsDetailsPanelV3State
    extends ConsumerState<_DoctorNewsDetailsPanelV3> {
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
        final typeColor = _notificationTypeColor(type);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DocPill(
                  _notificationTypeLabel(type),
                  typeColor,
                  icon: _notificationTypeIcon(type),
                ),
                const SizedBox(width: 8),
                _DocPill(
                  _docDate(item['created_at']),
                  AppColors.royalBlue,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _docText(item['title'], 'خبر جديد'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الناشر: ${_docText(sender['name'], 'الكلية')}',
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Text(
                _docText(item['message']),
                style: const TextStyle(
                  color: AppColors.midnight,
                  height: 1.5,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            if (_docText(item['attachment_url']).isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _downloadAttachment(item),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.royalBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _docText(
                            item['attachment_name'],
                            'مستند مرفق بالخبر',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.midnight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: AppColors.royalBlue,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (type == 'poll') ...[
              const SizedBox(height: 18),
              Text(
                hasVoted
                    ? 'تم تسجيل تصويتك بنجاح'
                    : 'الرجاء اختيار إجابة من الاستبيان:',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 10),
              ...options.map((option) {
                final isSelected = hasVoted; // Highlight voted state nicely
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.success.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.success
                          : AppColors.slate200,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    title: Text(
                      _docText(option['option_text'] ?? option['text']),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    trailing: hasVoted
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          )
                        : FilledButton(
                            onPressed: _voting
                                ? null
                                : () => _vote(_docInt(option['id'])),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.royalBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'تصويت',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                );
              }),
            ],
            if (related.length > 1) ...[
              const SizedBox(height: 18),
              const Text(
                'التحديثات والإشعارات المرتبطة بالخبر:',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 10),
              ...related.map(
                (notification) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Text(
                    _docText(notification['message']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: AppColors.slate700,
                    ),
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
        message: 'تم حفظ المرفق بنجاح في:\n${result.path}',
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
                _NotificationsHeaderV3(
                  unreadCount: unreadCount,
                  onMarkAllRead: _markAllRead,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DocMetric(
                        label: 'إجمالي الإشعارات',
                        value: notifications.length.toString(),
                        color: AppColors.royalBlue,
                        icon: Icons.notifications_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocMetric(
                        label: 'غير مقروءة',
                        value: unreadCount.toString(),
                        color: unreadCount > 0
                            ? AppColors.warning
                            : AppColors.slate400,
                        icon: Icons.mark_email_unread_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (notifications.isEmpty)
                  const _DocEmpty('لا توجد إشعارات واردة حالياً.')
                else
                  ...notifications.map(
                    (notification) => _DoctorNotificationCardV3(
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
        ref.invalidate(staffAttentionCountsProvider);
        _reload();
      } catch (_) {
        // Showing details is more important than failing because read tracking failed.
      }
    }
    if (!mounted) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الإشعار الوارد',
      icon: Icons.notifications_active_rounded,
      color: _notificationTypeColor(_docText(notification['type'])),
      child: _NotificationDetailsPanelV3(notification: notification),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/notifications/mark-all-read', const {});
      if (!mounted) return;
      ref.invalidate(staffAttentionCountsProvider);
      _reload();
      _docSnack(
        context,
        'تم تعليم جميع الإشعارات كمقروءة بنجاح.',
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _NotificationsHeaderV3 extends StatelessWidget {
  const _NotificationsHeaderV3({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlueDark, AppColors.royalBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -20,
            top: -20,
            child: Icon(
              Icons.notifications_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مركز الإشعارات والتنبيهات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unreadCount > 0
                          ? 'لديك عدد $unreadCount إشعارات غير مقروءة تتطلب المتابعة.'
                          : 'لا توجد إشعارات معلقة، حسابك محدّث بالكامل.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onMarkAllRead,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      'قراءة الكل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorNotificationCardV3 extends StatelessWidget {
  const _DoctorNotificationCardV3({
    required this.notification,
    required this.onTap,
  });

  final _Json notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    final unread = notification['read_at'] == null;
    final typeColor = _notificationTypeColor(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: unread ? typeColor.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: unread
              ? typeColor.withValues(alpha: 0.35)
              : AppColors.slate100,
          width: unread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: unread ? 0.03 : 0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _notificationTypeIcon(type),
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
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
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _DocPill(_notificationTypeLabel(type), typeColor),
                        _DocPill(
                          _docDate(notification['created_at']),
                          AppColors.royalBlue,
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailsPanelV3 extends StatelessWidget {
  const _NotificationDetailsPanelV3({required this.notification});

  final _Json notification;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    final typeColor = _notificationTypeColor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _DocPill(
              _notificationTypeLabel(type),
              typeColor,
              icon: _notificationTypeIcon(type),
            ),
            const SizedBox(width: 8),
            _DocPill(
              _docDate(notification['created_at']),
              AppColors.royalBlue,
              icon: Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _docText(notification['title'], 'إشعار جديد'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Text(
            _docText(notification['message']),
            style: const TextStyle(
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        if (_docText(notification['attachment_name']).isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.royalBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _docText(notification['attachment_name']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
