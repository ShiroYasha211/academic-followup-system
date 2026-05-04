part of 'delegate_screens.dart';

class DelegateMessagesScreen extends ConsumerWidget {
  const DelegateMessagesScreen({super.key});
  static const route = DelegateRoutes.messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListScreen(
      title: 'رسائل الطلاب',
      index: 17,
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
      index: 18,
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
    final state = ref.watch(_delegateInquiriesProvider(_status));
    return DelegateShell(
      currentIndex: 19,
      title: 'استفسارات الدكتور',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateInquiriesProvider(_status)),
        builder: (data) {
          final items = asList(data['inquiries']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
            children: [
              const _HeroPanel(
                title: 'استفسارات الطلاب',
                subtitle: 'راجع الاستفسارات، أجب مباشرة أو حوّلها إلى الدكتور.',
                icon: Icons.contact_support_rounded,
                colors: [AppColors.violet, AppColors.royalBlue],
              ),
              const SizedBox(height: 14),
              _FilterChips(
                value: _status,
                options: const {
                  'all': 'الكل',
                  'pending': 'معلقة',
                  'forwarded': 'محولة',
                  'answered': 'مجاب',
                  'closed': 'مغلقة',
                },
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const _EmptyState('لا توجد استفسارات بهذه الحالة.'),
              for (final raw in items)
                _DataCard(
                  title: text(
                    raw,
                    'title',
                    fallback: text(raw, 'question', fallback: 'استفسار'),
                  ),
                  subtitle:
                      '${text(asMap(raw)['student'], 'name', fallback: 'طالب')} | ${text(raw, 'status', fallback: '-')}',
                  icon: Icons.question_answer_rounded,
                  color: AppColors.violet,
                  actions: [
                    if (text(raw, 'status') == 'pending')
                      IconButton(
                        onPressed: () =>
                            _replyInquirySheet(context, ref, asMap(raw)),
                        icon: const Icon(Icons.reply_rounded),
                      ),
                    if (text(raw, 'status') == 'pending')
                      IconButton(
                        onPressed: () => _run(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .forwardInquiry(number(raw, 'id').toInt()),
                          after: () => ref.invalidate(
                            _delegateInquiriesProvider(_status),
                          ),
                        ),
                        icon: const Icon(Icons.forward_rounded),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI
