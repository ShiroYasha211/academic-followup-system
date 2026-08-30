part of 'student_content_screens.dart';

class StudentNotificationsScreen extends ConsumerWidget {
  const StudentNotificationsScreen({super.key});

  static const route = '/student/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_notificationsProvider(1));
    return StudentShell(
      currentIndex: 9,
      title: 'التنبيهات',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_notificationsProvider(1)),
        loading: ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: 6,
          itemBuilder: (_, __) => const _NotificationSkeleton(),
        ),
        builder: (data) {
          final page = asMap(data['notifications']);
          final items = asList(page['data']).map(asMap).toList();
          final unread = items
              .where((item) => text(item, 'read_at').isEmpty)
              .length;

          if (items.isEmpty) {
            return const EmptyState(message: 'لا توجد تنبيهات حالياً.');
          }

          final grouped = _groupNotifications(items);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_notificationsProvider(1)),
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
                          style: TextStyle(
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
                          return _EntryAnimation(
                            index: index,
                            child: _NotificationCard(
                              item: item,
                              onRead: () => _markRead(context, ref, item),
                              onVote: (optionId) => _vote(
                                context,
                                ref,
                                notificationId: number(item, 'id').toInt(),
                                optionId: optionId,
                              ),
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

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final id = number(item, 'id').toInt();
    if (id <= 0) return;
    final route = _routeForNotification(item);
    try {
      if (text(item, 'read_at').isEmpty) {
        await ref
            .read(studentContentRepositoryProvider)
            .markNotificationRead(id);
        ref.invalidate(_notificationsProvider(1));
        ref.invalidate(studentUnreadNotificationsCountProvider);
        ref.invalidate(studentUnreadScreenCountsProvider);
      }
      if (!context.mounted) return;
      if (route != null) {
        context.go(route);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد الإشعار كمقروء.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    await _runSnack(
      context,
      () =>
          ref.read(studentContentRepositoryProvider).markAllNotificationsRead(),
      onDone: () {
        ref.invalidate(_notificationsProvider(1));
        ref.invalidate(studentUnreadNotificationsCountProvider);
      },
    );
  }

  Future<void> _vote(
    BuildContext context,
    WidgetRef ref, {
    required int notificationId,
    required int optionId,
  }) async {
    await _runSnack(
      context,
      () => ref
          .read(studentContentRepositoryProvider)
          .voteNotification(notificationId: notificationId, optionId: optionId),
      onDone: () {
        ref.invalidate(_notificationsProvider(1));
        ref.invalidate(studentUnreadNotificationsCountProvider);
      },
    );
  }
}

String? _routeForNotification(Map<String, dynamic> item) {
  final data = asMap(item['data']);
  final target =
      (text(data, 'target_screen').isNotEmpty
              ? text(data, 'target_screen')
              : text(data, 'screen'))
          .trim();
  final type = text(item, 'type');
  final key = target.isNotEmpty ? target : type;

  final scheduleItemId = text(data, 'schedule_item_id').isNotEmpty
      ? text(data, 'schedule_item_id')
      : (text(data, 'study_item_id').isNotEmpty
            ? text(data, 'study_item_id')
            : text(data, 'item_id'));

  if ((key == 'study_session' || key == 'study_reminder') &&
      scheduleItemId.isNotEmpty) {
    return '/student/study-center/$scheduleItemId/session';
  }

  final inquiryId = text(data, 'inquiry_id');
  if (key == 'inquiry' && inquiryId.isNotEmpty) {
    return '/student/inquiries/$inquiryId';
  }

  final assignmentId = text(data, 'assignment_id');
  if (key == 'assignment' && assignmentId.isNotEmpty) {
    return '/student/assignments/$assignmentId';
  }

  final conversationId = text(data, 'conversation_id').isNotEmpty
      ? text(data, 'conversation_id')
      : text(data, 'doctor_conversation_id');
  if (key == 'message' && conversationId.isNotEmpty) {
    return '/student/messages/$conversationId';
  }

  final packId = text(data, 'pack_id');
  if ((key == 'flashcard_assignment' ||
          key == 'flashcard_review' ||
          key == 'flashcards') &&
      packId.isNotEmpty) {
    return '/student/flashcards/$packId';
  }

  final subjectId = text(data, 'subject_id');
  if (subjectId.isNotEmpty) {
    if (key == 'attendance' ||
        key == 'attendance_confirmation' ||
        key == 'absence_warning' ||
        key == 'lecture_report' ||
        key == 'excuse') {
      return '/student/subjects/$subjectId?tab=attendance';
    }
  }

  return switch (key) {
    'study_center' ||
    'study' ||
    'study_reminder' => StudentStudyCenterScreen.route,
    'quizzes' || 'quiz' => StudentQuizzesScreen.route,
    'assignments' || 'assignment' => StudentAssignmentsScreen.route,
    'schedule' || 'schedules' => StudentScheduleScreen.route,
    'reminders' || 'reminder' => StudentRemindersScreen.route,
    'resources' || 'resource' => StudentResourcesScreen.route,
    'library' => StudentLibraryScreen.route,
    'authorized_grades' ||
    'grade_delegation' => StudentAuthorizedGradesScreen.route,
    'stars' || 'star' || 'tree_farm' => StudentStarsScreen.route,
    'inquiries' ||
    'inquiry' ||
    'doctor_inquiry' => StudentInquiriesScreen.route,
    'messages' || 'message' => StudentMessagesScreen.route,
    'news' ||
    'news_hub' ||
    'announcement' ||
    'alert' ||
    'absence_warning' => StudentNewsScreen.route,
    'rare_case' || 'rare_cases' => StudentClinicalRareCasesScreen.route,
    'clinical_assignment' => StudentClinicalAssignmentsScreen.route,
    'clinical' => StudentClinicalScreen.route,
    'one_line_shot' ||
    'one_line_shot_quick_review' ||
    'flashcards' ||
    'flashcard_review' ||
    'flashcard_assignment' => '/student/flashcards/quick-review',
    'notifications' => StudentNotificationsScreen.route,
    _ => null,
  };
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
        gradient: LinearGradient(
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
  const _NotificationCard({
    required this.item,
    required this.onRead,
    required this.onVote,
  });

  final Map<String, dynamic> item;
  final VoidCallback onRead;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final type = text(item, 'type', fallback: 'notification');
    final unread = text(item, 'read_at').isEmpty;
    final color = _notificationColor(type);
    final poll = asMap(item['poll_data']);
    final options = asList(poll['options']).map(asMap).toList();
    final hasVoted = boolValue(poll, 'has_voted');
    final votedId = number(poll, 'voted_option_id').toInt();
    final canOpen = _routeForNotification(item) != null;

    final data = asMap(item['data']);
    Widget? detailsWidget;
    String? ctaLabel;

    if (type == 'assignment') {
      final subjectName = text(data, 'subject_name');
      final dueDate = text(data, 'due_date');
      ctaLabel = 'عرض تفاصيل التكليف 📝';

      detailsWidget = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjectName.isNotEmpty)
              _NotificationInfoRow(
                label: 'المادة',
                value: subjectName,
                icon: Icons.book_rounded,
              ),
            if (dueDate.isNotEmpty)
              _NotificationInfoRow(
                label: 'تاريخ التسليم',
                value: dateOnly(dueDate),
                icon: Icons.event_rounded,
              ),
          ],
        ),
      );
    } else if (type == 'attendance' ||
        type == 'attendance_confirmation' ||
        type == 'absence_warning' ||
        type == 'lecture_report') {
      final subjectName = text(data, 'subject_name');
      final date = text(data, 'date');
      final count = text(data, 'absence_count');
      ctaLabel = type == 'lecture_report'
          ? 'سجل المحاضرات 🗓️'
          : type == 'attendance_confirmation'
          ? 'تفاصيل الحضور'
          : 'تفاصيل الغياب 🥀';

      detailsWidget = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjectName.isNotEmpty)
              _NotificationInfoRow(
                label: 'المادة',
                value: subjectName,
                icon: Icons.school_rounded,
              ),
            if (date.isNotEmpty)
              _NotificationInfoRow(
                label: 'التاريخ',
                value: dateOnly(date),
                icon: Icons.calendar_today_rounded,
              ),
            if (count.isNotEmpty)
              _NotificationInfoRow(
                label: 'عدد مرات الغياب',
                value: count,
                icon: Icons.warning_rounded,
              ),
          ],
        ),
      );
    } else if (type == 'tree_farm') {
      final coins = text(data, 'coins_amount');
      final stars = text(data, 'stars_amount');
      final status = text(data, 'status');
      ctaLabel = 'عرض رصيد النجوم ⭐';

      String statusText = status == 'approved'
          ? 'مقبول 🎉'
          : (status == 'rejected' ? 'مرفوض ❌' : 'قيد الانتظار ⏳');
      Color statusColor = status == 'approved'
          ? AppColors.success
          : (status == 'rejected' ? AppColors.danger : AppColors.warning);

      detailsWidget = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coins.isNotEmpty && stars.isNotEmpty)
              _NotificationInfoRow(
                label: 'التحويل',
                value: '$coins عملة 🪙 ➔ $stars نجوم ⭐',
                icon: Icons.swap_horiz_rounded,
              ),
            _NotificationInfoRow(
              label: 'حالة الطلب',
              value: statusText,
              valueColor: statusColor,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
        ),
      );
    } else if (type == 'message') {
      ctaLabel = 'فتح المحادثة 💬';
    } else if (type == 'flashcard_assignment') {
      ctaLabel = 'ابدأ المراجعة الآن ⚡';
    } else if (type == 'inquiry' || type == 'announcement') {
      ctaLabel = 'تفاصيل الاستفسار 👨‍⚕️';
    } else if (type == 'study_reminder') {
      ctaLabel = 'بدء الجلسة ⏱️';
    } else if (canOpen) {
      ctaLabel = 'عرض التفاصيل 🔍';
    }

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
        onTap: unread || canOpen ? onRead : null,
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
                                  style: TextStyle(
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
                      if (detailsWidget != null) detailsWidget,
                      if (options.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _PollWidget(
                          options: options,
                          hasVoted: hasVoted,
                          votedId: votedId,
                          color: color,
                          onVote: onVote,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (canOpen && ctaLabel != null)
                            TextButton.icon(
                              onPressed: onRead,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: color,
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if (unread)
                            TextButton.icon(
                              onPressed: onRead,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: AppColors.slate600,
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'فهمت',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
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
}

class _PollWidget extends StatelessWidget {
  const _PollWidget({
    required this.options,
    required this.hasVoted,
    required this.votedId,
    required this.color,
    required this.onVote,
  });

  final List<Map<String, dynamic>> options;
  final bool hasVoted;
  final int votedId;
  final Color color;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final totalVotes = options.fold<int>(
      0,
      (sum, item) => sum + number(item, 'votes_count').toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.poll_rounded, size: 16, color: AppColors.slate500),
            const SizedBox(width: 8),
            Text(
              'استطلاع رأي',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.slate700,
              ),
            ),
            const Spacer(),
            Text(
              '$totalVotes صوت',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          final id = number(option, 'id').toInt();
          final selected = id == votedId;
          final votes = number(option, 'votes_count').toInt();
          final percent = totalVotes == 0 ? 0.0 : (votes / totalVotes);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: hasVoted ? null : () => onVote(id),
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : AppColors.slate200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                  ),
                  if (hasVoted)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 44,
                      width: MediaQuery.of(context).size.width * percent,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: selected ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: color,
                            size: 18,
                          )
                        else if (!hasVoted)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.slate400),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text(option, 'text'),
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              fontSize: 13,
                              color: selected
                                  ? AppColors.slate900
                                  : AppColors.slate700,
                            ),
                          ),
                        ),
                        if (hasVoted)
                          Text(
                            '${(percent * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _NotificationInfoRow extends StatelessWidget {
  const _NotificationInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: valueColor ?? AppColors.slate900,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
