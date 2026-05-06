part of 'delegate_screens.dart';

class DelegateMessagesScreen extends ConsumerWidget {
  const DelegateMessagesScreen({super.key});
  static const route = DelegateRoutes.messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListScreen(
      title: 'رسائل الطلاب',
      index: 16,
      state: ref.watch(_delegateMessagesProvider),
      onRetry: () => ref.invalidate(_delegateMessagesProvider),
      extractor: (data) => asList(data['conversations'] ?? data['data']),
      eligibleLoader: () =>
          ref.read(delegateRepositoryProvider).eligibleStudents(),
      openPath: (id) => '/delegate/messages/$id',
      startMessage: ({required int recipientId, required String content}) => ref
          .read(delegateRepositoryProvider)
          .sendStudentMessage(studentId: recipientId, content: content),
    );
  }
}

class DelegateConversationScreen extends ConsumerStatefulWidget {
  const DelegateConversationScreen({super.key, required this.conversationId});
  final int conversationId;

  @override
  ConsumerState<DelegateConversationScreen> createState() =>
      _DelegateConversationScreenState();
}

class _DelegateConversationScreenState
    extends ConsumerState<DelegateConversationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(delegateRepositoryProvider)
        .conversation(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return _ConversationView(
      title: 'محادثة طالب',
      subtitle: 'طالب',
      index: 16,
      future: _future,
      reload: () => setState(
        () => _future = ref
            .read(delegateRepositoryProvider)
            .conversation(widget.conversationId),
      ),
      send: (body) => ref
          .read(delegateRepositoryProvider)
          .sendStudentMessage(
            conversationId: widget.conversationId,
            content: body,
          ),
    );
  }
}

class DelegateDoctorChatsScreen extends ConsumerWidget {
  const DelegateDoctorChatsScreen({super.key});
  static const route = DelegateRoutes.doctorChats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListScreen(
      title: 'محادثات الدكاترة',
      index: 17,
      state: ref.watch(_delegateDoctorChatsProvider),
      onRetry: () => ref.invalidate(_delegateDoctorChatsProvider),
      extractor: (data) => asList(data['conversations'] ?? data['data']),
      eligibleLoader: () =>
          ref.read(delegateRepositoryProvider).eligibleDoctors(),
      openPath: (id) => '/delegate/doctor-chats/$id',
      startMessage: ({required int recipientId, required String content}) => ref
          .read(delegateRepositoryProvider)
          .sendDoctorMessage(doctorId: recipientId, content: content),
    );
  }
}

class DelegateDoctorConversationScreen extends ConsumerStatefulWidget {
  const DelegateDoctorConversationScreen({
    super.key,
    required this.conversationId,
  });
  final int conversationId;

  @override
  ConsumerState<DelegateDoctorConversationScreen> createState() =>
      _DelegateDoctorConversationScreenState();
}

class _DelegateDoctorConversationScreenState
    extends ConsumerState<DelegateDoctorConversationScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(delegateRepositoryProvider)
        .doctorChat(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return _ConversationView(
      title: 'محادثة دكتور',
      subtitle: 'دكتور',
      index: 17,
      future: _future,
      reload: () => setState(
        () => _future = ref
            .read(delegateRepositoryProvider)
            .doctorChat(widget.conversationId),
      ),
      send: (body) => ref
          .read(delegateRepositoryProvider)
          .sendDoctorMessage(
            conversationId: widget.conversationId,
            content: body,
          ),
    );
  }
}

class DelegateInquiriesScreen extends ConsumerStatefulWidget {
  const DelegateInquiriesScreen({super.key});
  static const route = DelegateRoutes.inquiries;

  @override
  ConsumerState<DelegateInquiriesScreen> createState() =>
      _DelegateInquiriesScreenState();
}

class _DelegateInquiriesScreenState
    extends ConsumerState<DelegateInquiriesScreen> {
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final canUpdate = session?.hasPermission('students', 'update') ?? false;
    final state = ref.watch(_delegateInquiriesProvider(_status));
    return DelegateShell(
      currentIndex: 18,
      title: 'استفسارات الدكتور',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateInquiriesProvider(_status)),
        builder: (data) {
          final stats = asMap(data['stats']);
          final inquiries = asList(data['inquiries']).map(asMap).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_delegateInquiriesProvider(_status)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _InquiryStatsHeader(stats: stats)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _InquiryFilterChips(
                      selected: _status,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ),
                if (inquiries.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState('لا توجد استفسارات في هذا التصنيف.'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount: inquiries.length,
                      itemBuilder: (context, index) {
                        return _InquiryCard(
                          item: inquiries[index],
                          onTap: () => _showInquiryDetails(
                            context,
                            ref,
                            inquiries[index],
                            canUpdate: canUpdate,
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showInquiryDetails(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item, {
    required bool canUpdate,
  }) async {
    final inquiryId = number(item, 'id').toInt();
    final status = text(item, 'status');
    final subject = asMap(item['subject']);
    final student = asMap(item['student']);
    final color = _hexColor(text(item, 'status_color'), AppColors.royalBlue);

    await showMoeenBottomSheet(
      context: context,
      title: 'تفاصيل الاستفسار',
      icon: Icons.contact_support_rounded,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(label: 'الطالب', value: text(student, 'name')),
          _DetailRow(label: 'المادة', value: text(subject, 'name')),
          _DetailRow(label: 'الحالة', value: text(item, 'status_label')),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          const Text(
            'نص الاستفسار:',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Text(
              text(item, 'question', fallback: text(item, 'title')),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: AppColors.midnight,
              ),
            ),
          ),
          if (text(item, 'answer').isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'الرد الحالي:',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.1)),
              ),
              child: Text(
                text(item, 'answer'),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnight,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (canUpdate) {
                        Navigator.pop(context);
                        _replyInquirySheet(context, ref, item);
                      } else {
                        _showNoPermissionSnackBar(context);
                      }
                    },
                    icon: Opacity(
                      opacity: canUpdate ? 1.0 : 0.5,
                      child: const Icon(Icons.reply_rounded),
                    ),
                    label: const Text('رد الآن'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (canUpdate) {
                        Navigator.pop(context);
                        _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .forwardInquiry(inquiryId),
                          after: () => ref.invalidate(
                            _delegateInquiriesProvider(_status),
                          ),
                        );
                      } else {
                        _showNoPermissionSnackBar(context);
                      }
                    },
                    icon: Opacity(
                      opacity: canUpdate ? 1.0 : 0.5,
                      child: const Icon(Icons.forward_rounded),
                    ),
                    label: const Text('تحويل للدكتور'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status != 'closed' && status != 'forwarded')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  if (canUpdate) {
                    Navigator.pop(context);
                    _run(
                      context,
                      () => ref
                          .read(delegateRepositoryProvider)
                          .updateInquiryStatus(id: inquiryId, status: 'closed'),
                      after: () => ref.invalidate(
                        _delegateInquiriesProvider(_status),
                      ),
                    );
                  } else {
                    _showNoPermissionSnackBar(context);
                  }
                },
                icon: Opacity(
                  opacity: canUpdate ? 1.0 : 0.5,
                  child: const Icon(Icons.close_rounded),
                ),
                label: const Text('إغلاق الاستفسار'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InquiryStatsHeader extends StatelessWidget {
  const _InquiryStatsHeader({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlue, AppColors.royalBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة الاستفسارات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'راجع استفسارات الطلاب وقم بالرد عليها أو تحويلها.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _InquiryStatBox(
                label: 'معلقة',
                value: text(stats, 'pending', fallback: '0'),
                color: AppColors.gold,
              ),
              const SizedBox(width: 12),
              _InquiryStatBox(
                label: 'محولة',
                value: text(stats, 'forwarded', fallback: '0'),
                color: Colors.white,
                isWhite: true,
              ),
              const SizedBox(width: 12),
              _InquiryStatBox(
                label: 'تم الرد',
                value: text(stats, 'answered', fallback: '0'),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InquiryStatBox extends StatelessWidget {
  const _InquiryStatBox({
    required this.label,
    required this.value,
    required this.color,
    this.isWhite = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWhite ? Colors.white : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isWhite ? AppColors.royalBlue : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isWhite
                    ? AppColors.royalBlue.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryFilterChips extends StatelessWidget {
  const _InquiryFilterChips({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'الكل'),
      ('pending', 'قيد الانتظار'),
      ('forwarded', 'محولة للدكتور'),
      ('answered', 'تم الرد'),
      ('closed', 'مغلقة'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: filters.map((item) {
          final active = selected == item.$1;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.royalBlue : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppColors.royalBlue : AppColors.slate200,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.slate600,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final student = asMap(item['student']);
    final color = _hexColor(text(item, 'status_color'), AppColors.royalBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.contact_support_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(student, 'name', fallback: 'طالب'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          timeAgo(text(item, 'created_at')),
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MiniBadge(label: text(item, 'status_label'), color: color),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                text(item, 'title', fallback: text(item, 'question')),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 14,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text(subject, 'name'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
