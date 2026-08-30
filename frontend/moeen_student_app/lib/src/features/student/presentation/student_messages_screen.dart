part of 'student_content_screens.dart';

class StudentMessagesScreen extends ConsumerWidget {
  const StudentMessagesScreen({super.key});

  static const route = '/student/messages';
  static String conversationPath(int id) => '/student/messages/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_messagesProvider);
    return StudentShell(
      currentIndex: 16,
      title: 'الرسائل',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startConversation(context, ref),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_rounded),
        label: const Text(
          'مراسلة المندوب',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_messagesProvider),
        loading: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: 8,
          itemBuilder: (_, __) => const _MessageSkeleton(),
        ),
        builder: (data) {
          final delegate = asMap(data['delegate']);
          final conversations = asList(
            data['conversations'],
          ).map(asMap).toList();
          final unreadCount = number(data, 'unread_count').toInt();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_messagesProvider);
              ref.invalidate(studentUnreadMessagesCountProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _DelegateHeader(delegate: delegate),
                        const SizedBox(height: 12),
                        _UnreadMessagesHeader(unreadCount: unreadCount),
                      ],
                    ),
                  ),
                ),
                if (conversations.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: delegate.isEmpty
                          ? 'لا يمكن بدء محادثة لأن دفعتك لا تحتوي على مندوب.'
                          : 'لا توجد محادثات بعد. ابدأ محادثة مع المندوب.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return _EntryAnimation(
                          index: index,
                          child: _ConversationCard(
                            conversation: conversations[index],
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

  Future<void> _startConversation(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref
          .read(studentContentRepositoryProvider)
          .startConversation();
      final id = number(data, 'conversation_id').toInt();
      ref.invalidate(_messagesProvider);
      ref.invalidate(studentUnreadMessagesCountProvider);
      if (context.mounted && id > 0) {
        context.push(StudentMessagesScreen.conversationPath(id));
      }
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
}

class StudentConversationScreen extends ConsumerStatefulWidget {
  const StudentConversationScreen({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<StudentConversationScreen> createState() =>
      _StudentConversationScreenState();
}

class _StudentConversationScreenState
    extends ConsumerState<StudentConversationScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  bool _refreshedUnreadCount = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_conversationProvider(widget.conversationId));
    return state.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.royalBlue,
            ),
          ),
          title: const Text(
            'المحادثة',
            style: TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.royalBlue,
            ),
          ),
          title: const Text(
            'المحادثة',
            style: TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(_conversationProvider(widget.conversationId)),
        ),
      ),
      data: (data) {
        final conversation = asMap(data['conversation']);
        final delegate = asMap(conversation['delegate']);
        final messages = asList(data['messages']).map(asMap).toList();
        final name = text(delegate, 'name', fallback: 'المندوب');

        if (!_refreshedUnreadCount) {
          _refreshedUnreadCount = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.invalidate(_messagesProvider);
            ref.invalidate(studentUnreadMessagesCountProvider);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            leadingWidth: 54,
            leading: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.royalBlue,
              ),
            ),
            title: Row(
              children: [
                _UserAvatar(name: name, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const Text(
                        'المندوب',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const EmptyState(
                          message: 'لا توجد رسائل في هذه المحادثة.',
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final item = messages[messages.length - 1 - index];
                            final sender = asMap(item['sender']);
                            final isMine =
                                text(sender, 'role') == 'student' ||
                                text(item, 'type') == 'student_to_delegate';

                            // Date Divider logic
                            bool showDate = false;
                            String dateLabel = '';
                            if (index == messages.length - 1) {
                              showDate = true;
                              dateLabel = _formatChatDate(
                                text(item, 'created_at'),
                              );
                            } else {
                              final nextItem =
                                  messages[messages.length - 2 - index];
                              final currentDate = dateOnly(
                                text(item, 'created_at'),
                              );
                              final nextDate = dateOnly(
                                text(nextItem, 'created_at'),
                              );
                              if (currentDate != nextDate) {
                                showDate = true;
                                dateLabel = _formatChatDate(
                                  text(item, 'created_at'),
                                );
                              }
                            }

                            return Column(
                              children: [
                                if (showDate) _DateDivider(label: dateLabel),
                                _ChatBubble(message: item, isMine: isMine),
                              ],
                            );
                          },
                        ),
                ),
                _MessageComposer(
                  controller: _message,
                  sending: _sending,
                  onSend: _send,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatChatDate(String value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime.tryParse(value) ?? now;
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'اليوم';
    if (itemDate == yesterday) return 'أمس';
    return prettyDate(value);
  }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(studentContentRepositoryProvider)
          .sendMessage(conversationId: widget.conversationId, body: body);
      _message.clear();
      ref.invalidate(_conversationProvider(widget.conversationId));
      ref.invalidate(_messagesProvider);
      ref.invalidate(studentUnreadMessagesCountProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _UnreadMessagesHeader extends StatelessWidget {
  const _UnreadMessagesHeader({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasUnread
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUnread
              ? AppColors.danger.withValues(alpha: 0.18)
              : AppColors.slate100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasUnread
                ? Icons.mark_chat_unread_rounded
                : Icons.mark_chat_read_rounded,
            color: hasUnread ? AppColors.danger : AppColors.slate400,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasUnread
                  ? 'لديك $unreadCount رسالة غير مقروءة'
                  : 'كل الرسائل مقروءة',
              style: TextStyle(
                color: hasUnread ? AppColors.danger : AppColors.slate500,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegateHeader extends StatelessWidget {
  const _DelegateHeader({required this.delegate});
  final Map<String, dynamic> delegate;

  @override
  Widget build(BuildContext context) {
    if (delegate.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
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
                  'مندوب الدفعة: ${text(delegate, 'name')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'تواصل معه للاستفسار أو طلب المساعدة.',
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
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation});
  final Map<String, dynamic> conversation;

  @override
  Widget build(BuildContext context) {
    final delegate = asMap(conversation['delegate']);
    final last = asMap(conversation['last_message']);
    final unread = number(conversation, 'unread_count').toInt();
    final name = text(delegate, 'name', fallback: 'المندوب');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (unread > 0 ? AppColors.royalBlue : AppColors.slate200)
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: unread > 0
              ? AppColors.royalBlue.withValues(alpha: 0.12)
              : AppColors.slate100,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(
          StudentMessagesScreen.conversationPath(
            number(conversation, 'id').toInt(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(name: name, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: unread > 0
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.slate900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        Text(
                          timeAgo(text(last, 'created_at')),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text(last, 'body', fallback: 'افتح المحادثة للتواصل.'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0
                            ? AppColors.slate800
                            : AppColors.slate500,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.slate300,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(1).join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalBlue.withValues(alpha: 0.1),
            AppColors.royalBlue.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.royalBlue.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.royalBlue,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.35,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});
  final Map<String, dynamic> message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(
                  colors: [AppColors.royalBlue, AppColors.royalBlueDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          color: isMine ? null : AppColors.slate100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: isMine
              ? null
              : Border.all(
                  color: AppColors.slate200.withValues(alpha: 0.5),
                  width: 1.2,
                ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text(message, 'body', fallback: text(message, 'content')),
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.midnight,
                fontWeight: isMine ? FontWeight.w600 : FontWeight.w700,
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeOnly(text(message, 'created_at')),
              style: TextStyle(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.slate400,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.slate200.withValues(alpha: 0.8),
                ),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(color: AppColors.slate400, fontFamily: 'Cairo'),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.royalBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
