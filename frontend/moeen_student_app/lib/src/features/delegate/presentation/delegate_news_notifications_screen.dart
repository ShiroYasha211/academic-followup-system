part of 'delegate_screens.dart';

class DelegateNewsScreen extends ConsumerWidget {
  const DelegateNewsScreen({super.key});
  static const route = DelegateRoutes.news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateNewsProvider);

    return DelegateShell(
      currentIndex: 1,
      title: 'أخبار الدفعة',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateNewsProvider),
        builder: (data) {
          final items = asList(
            asMap(data['data']).isNotEmpty ? data['data'] : data,
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_delegateNewsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: _NewsHero(total: items.length.toString()),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                  sliver: items.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: _EmptyState(
                              'لا توجد أخبار أو تعميمات حالياً.',
                            ),
                          ),
                        )
                      : SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) =>
                              _NewsCard(item: items[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DelegateNotificationsScreen extends ConsumerWidget {
  const DelegateNotificationsScreen({super.key});
  static const route = DelegateRoutes.notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateNotificationsProvider);
    return DelegateShell(
      currentIndex: 2,
      title: 'التنبيهات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateNotificationsProvider),
        builder: (data) {
          final items = asList(data['notifications']).map(asMap).toList();
          final unread = items
              .where((item) => text(item, 'read_at').isEmpty)
              .length;

          if (items.isEmpty) {
            return const _EmptyState('لا توجد تنبيهات حالياً.');
          }

          final grouped = _groupNotifications(items);

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_delegateNotificationsProvider),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  sliver: SliverToBoxAdapter(
                    child: _NotificationsHeader(
                      unreadCount: unread,
                      onMarkAllRead: () => _markAllRead(context, ref),
                    ),
                  ),
                ),
                ...grouped.entries.expand((entry) {
                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList.builder(
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          final item = entry.value[index];
                          return _NotificationCard(
                            item: item,
                            onRead: () => _markRead(
                              context,
                              ref,
                              number(item, 'id').toInt(),
                            ),
                          );
                        },
                      ),
                    ),
                  ];
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications(
    List<Map<String, dynamic>> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Map<String, dynamic>>>{};

    for (final item in items) {
      final dateStr = text(item, 'created_at');
      final date = DateTime.tryParse(dateStr) ?? now;
      final itemDate = DateTime(date.year, date.month, date.day);

      String key;
      if (itemDate == today) {
        key = 'اليوم';
      } else if (itemDate == yesterday) {
        key = 'أمس';
      } else {
        key = 'سابقاً';
      }

      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref, int id) async {
    if (id <= 0) return;
    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).markNotificationRead(id),
      after: () => ref.invalidate(_delegateNotificationsProvider),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    await _run(
      context,
      () => ref.read(delegateRepositoryProvider).markAllNotificationsRead(),
      after: () => ref.invalidate(_delegateNotificationsProvider),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlue, AppColors.royalBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount > 0
                      ? '$unreadCount تنبيه جديد'
                      : 'لا توجد تنبيهات جديدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'ابقَ على اطلاع بكل جديد في معاً.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            IconButton.filledTonal(
              onPressed: onMarkAllRead,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'تحديد الكل كمقروء',
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onRead});

  final Map<String, dynamic> item;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final type = text(item, 'type', fallback: 'notification');
    final unread = text(item, 'read_at').isEmpty;
    final color = _notificationColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (unread ? color : AppColors.slate200).withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: unread ? color.withValues(alpha: 0.15) : AppColors.slate100,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: unread ? onRead : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: unread ? color : AppColors.slate200),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _notificationIcon(type),
                              color: color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text(item, 'title', fallback: 'تنبيه'),
                                  style: TextStyle(
                                    fontWeight: unread
                                        ? FontWeight.w900
                                        : FontWeight.w800,
                                    fontSize: 15,
                                    color: unread
                                        ? AppColors.slate900
                                        : AppColors.slate700,
                                  ),
                                ),
                                Text(
                                  '${_notificationTypeLabel(type)} • ${timeAgo(text(item, 'created_at'))}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        text(item, 'message', fallback: text(item, 'body')),
                        style: TextStyle(
                          height: 1.6,
                          fontSize: 14,
                          color: unread
                              ? AppColors.slate800
                              : AppColors.slate600,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: onRead,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: color,
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'فهمت',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _notificationColor(String type) => switch (type) {
    'exam' => AppColors.danger,
    'assignment' => AppColors.orange,
    'poll' => AppColors.violet,
    'attendance' => AppColors.warning,
    'attendance_edit_request' => AppColors.warning,
    'announcement' => AppColors.royalBlue,
    _ => AppColors.royalBlue,
  };

  IconData _notificationIcon(String type) => switch (type) {
    'exam' => Icons.event_note_rounded,
    'assignment' => Icons.assignment_rounded,
    'poll' => Icons.poll_rounded,
    'attendance' => Icons.person_off_rounded,
    'attendance_edit_request' => Icons.edit_calendar_rounded,
    _ => Icons.notifications_rounded,
  };

  String _notificationTypeLabel(String type) => switch (type) {
    'exam' => 'اختبار جديد',
    'assignment' => 'تكليف دراسي',
    'poll' => 'استطلاع رأي',
    'attendance' => 'غياب / حضور',
    'attendance_edit_request' => 'طلب تعديل حضور',
    'announcement' => 'تعميم رسمي',
    _ => 'تنبيه نظام',
  };
}

class _NewsHero extends StatelessWidget {
  const _NewsHero({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.goldDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(
              Icons.campaign_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'المركز الإخباري للدفعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'لديك $total تحديثات جديدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'استعرض التعميمات والاستبيانات الرسمية من الكلية.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
