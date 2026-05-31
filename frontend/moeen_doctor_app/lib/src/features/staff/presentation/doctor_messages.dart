part of 'staff_screens.dart';

class DoctorMessagesScreen extends ConsumerStatefulWidget {
  const DoctorMessagesScreen({super.key});

  static const route = '/doctor/messages';

  @override
  ConsumerState<DoctorMessagesScreen> createState() =>
      _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends ConsumerState<DoctorMessagesScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/messages');
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'محادثات المندوبين',
      currentRoute: DoctorMessagesScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(DoctorStartConversationScreen.route);
          _reload();
        },
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text(
          'محادثة جديدة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final conversations = _docList(_docData(snapshot.data ?? const {}));
          final unread = conversations.fold<int>(
            0,
            (sum, item) => sum + _docInt(item['unread_count']),
          );
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _MessagesHeaderV3(unreadCount: unread),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DocMetric(
                        label: 'إجمالي المحادثات',
                        value: conversations.length.toString(),
                        color: AppColors.royalBlue,
                        icon: Icons.forum_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocMetric(
                        label: 'الرسائل غير المقروءة',
                        value: unread.toString(),
                        color: unread > 0
                            ? AppColors.danger
                            : AppColors.slate400,
                        icon: Icons.mark_chat_unread_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (conversations.isEmpty)
                  const _DocEmpty('لا توجد محادثات نشطة حالياً.')
                else
                  ...conversations.map(
                    (conversation) => _ConversationCardV3(
                      conversation: conversation,
                      onTap: () =>
                          _openConversation(_docInt(conversation['id'])),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openConversation(int conversationId) async {
    await context.push(DoctorConversationScreen.path(conversationId));
    _reload();
  }
}

class _MessagesHeaderV3 extends StatelessWidget {
  const _MessagesHeaderV3({required this.unreadCount});

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
            end: -20,
            top: -20,
            child: Icon(
              Icons.forum_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'صندوق الوارد والمراسلات',
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
                    ? 'لديك عدد $unreadCount رسائل جديدة لم يتم قراءتها بعد.'
                    : 'جميع المحادثات مع المندوبين محدثة ولا توجد رسائل معلقة.',
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

class DoctorStartConversationScreen extends StatelessWidget {
  const DoctorStartConversationScreen({super.key});

  static const route = '/doctor/messages/new';

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'بدء محادثة',
      currentRoute: DoctorMessagesScreen.route,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_comment_rounded,
                  color: AppColors.royalBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختيار مندوب مادة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ابحث عن مندوب المادة العلمي أو العملي لبدء التواصل معه.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StartConversationPanel(
            onStarted: (conversationId) async {
              if (context.mounted) {
                context.replace(DoctorConversationScreen.path(conversationId));
              }
            },
          ),
        ],
      ),
    );
  }
}

class DoctorConversationScreen extends StatelessWidget {
  const DoctorConversationScreen({super.key, required this.conversationId});

  static const route = '/doctor/messages/:conversationId';

  final int conversationId;

  static String path(int conversationId) => '/doctor/messages/$conversationId';

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'المحادثة',
      currentRoute: DoctorMessagesScreen.route,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _ConversationPanel(
            conversationId: conversationId,
            fillAvailable: true,
          ),
        ),
      ),
    );
  }
}

class _ConversationCardV3 extends StatelessWidget {
  const _ConversationCardV3({required this.conversation, required this.onTap});

  final _Json conversation;
  final VoidCallback onTap;

  String _getInitials(String name) {
    if (name.isEmpty) return 'م';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final delegate = _docMap(conversation['delegate']);
    final unread = _docInt(conversation['unread_count']);
    final name = _docText(delegate['name'], 'مندوب المادة');
    final roleLabel = _delegateRoleLabelClean(_docText(delegate['role']));
    final initials = _getInitials(name);
    final lastMsg = _docText(
      conversation['last_message'],
      'لا توجد رسائل في المحادثة حالياً.',
    );
    final isUnread = unread > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.royalBlue.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnread
              ? AppColors.royalBlue.withValues(alpha: 0.22)
              : AppColors.slate100,
          width: isUnread ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUnread ? 0.03 : 0.015),
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
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isUnread
                          ? AppColors.royalBlue
                          : AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: isUnread ? Colors.white : AppColors.royalBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  if (isUnread)
                    PositionedDirectional(
                      end: -3,
                      top: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontWeight: isUnread
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        Text(
                          _docDate(conversation['last_message_at']),
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.royalBlue
                                : AppColors.slate400,
                            fontSize: 10,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread
                            ? AppColors.midnight
                            : AppColors.slate500,
                        fontSize: 12,
                        fontWeight: isUnread
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.royalBlue.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: AppColors.royalBlue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartConversationPanel extends ConsumerStatefulWidget {
  const _StartConversationPanel({required this.onStarted});

  final Future<void> Function(int conversationId) onStarted;

  @override
  ConsumerState<_StartConversationPanel> createState() =>
      _StartConversationPanelState();
}

class _StartConversationPanelState
    extends ConsumerState<_StartConversationPanel> {
  final _search = TextEditingController();
  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/messages/delegates',
          query: {
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
          },
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onSubmitted: (_) => _reload(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن مندوب بالاسم أو الرقم الأكاديمي...',
            hintStyle: const TextStyle(
              color: AppColors.slate400,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.slate400,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.slate100),
            ),
            suffixIcon: IconButton(
              onPressed: _reload,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
            final delegates = _docList(_docData(snapshot.data ?? const {}));
            if (delegates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: _DocEmpty('لا يوجد مندوبون مطابقون حالياً.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: delegates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final delegate = delegates[index];
                final roleText = _delegateRoleLabelClean(
                  _docText(delegate['role']),
                );
                final studentNum = _docText(delegate['student_number'], '-');

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.royalBlue,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      _docText(delegate['name']),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              studentNum,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            roleText,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.slate400,
                    ),
                    onTap: () => _start(delegate),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _start(_Json delegate) async {
    try {
      final response = await ref.read(staffRepositoryProvider).post(
        '/doctor/messages',
        {'delegate_id': _docInt(delegate['id'])},
      );
      final id = _docInt(_docMap(_docData(response))['conversation_id']);
      if (id > 0) await widget.onStarted(id);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _ConversationPanel extends ConsumerStatefulWidget {
  const _ConversationPanel({
    required this.conversationId,
    this.fillAvailable = false,
  });

  final int conversationId;
  final bool fillAvailable;

  @override
  ConsumerState<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<_ConversationPanel> {
  final _message = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Fetch and scroll to bottom once data is rendered
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: false),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/messages/${widget.conversationId}');
    ref.invalidate(staffAttentionCountsProvider);
    return response;
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // Helper to extract clean date string for grouping
  String _getMessageDateKey(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;

      if (difference == 0 && dateTime.day == now.day) {
        return 'اليوم';
      } else if (difference <= 1 &&
          dateTime.day == now.subtract(const Duration(days: 1)).day) {
        return 'أمس';
      } else {
        return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
      }
    } catch (_) {
      return 'أخرى';
    }
  }

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
        final conversation = _docMap(data['conversation']);
        final delegate = _docMap(conversation['delegate']);
        final messages = _docList(data['messages']);
        final name = _docText(delegate['name'], 'مندوب المادة');
        final roleLabel = _delegateRoleLabelClean(_docText(delegate['role']));

        // Pre-calculate scroll to bottom when messages load
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: false),
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.royalBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _reload,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.slate100,
                      foregroundColor: AppColors.royalBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: messages.isEmpty
                  ? const _DocEmpty(
                      'لا توجد رسائل في هذه المحادثة بعد. أرسل رسالة للبدء.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = _docBool(message['is_mine']);
                        final body = _docText(message['body']);
                        final createdAt = _docText(message['created_at']);
                        final formattedTime = _docDate(createdAt);

                        // Check if we need to show a date separator
                        bool showDateHeader = false;
                        String dateHeaderLabel = '';
                        if (index == 0) {
                          showDateHeader = true;
                          dateHeaderLabel = _getMessageDateKey(createdAt);
                        } else {
                          final prevMessage = messages[index - 1];
                          final prevCreatedAt = _docText(
                            prevMessage['created_at'],
                          );
                          final currentKey = _getMessageDateKey(createdAt);
                          final prevKey = _getMessageDateKey(prevCreatedAt);
                          if (currentKey != prevKey) {
                            showDateHeader = true;
                            dateHeaderLabel = currentKey;
                          }
                        }

                        // Check if consecutive message from same sender to group spacing
                        bool isConsecutive = false;
                        if (index > 0 && !showDateHeader) {
                          final prevMessage = messages[index - 1];
                          final prevMine = _docBool(prevMessage['is_mine']);
                          if (prevMine == mine) {
                            isConsecutive = true;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDateHeader) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: AppColors.slate100,
                                        endIndent: 12,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.slate100,
                                        ),
                                      ),
                                      child: Text(
                                        dateHeaderLabel,
                                        style: const TextStyle(
                                          color: AppColors.slate500,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: AppColors.slate100,
                                        indent: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(
                                  bottom: isConsecutive ? 4 : 10,
                                  top: isConsecutive ? 0 : 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.72,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? AppColors.royalBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topRight: const Radius.circular(18),
                                    topLeft: const Radius.circular(18),
                                    bottomRight: Radius.circular(mine ? 2 : 18),
                                    bottomLeft: Radius.circular(mine ? 18 : 2),
                                  ),
                                  border: mine
                                      ? null
                                      : Border.all(
                                          color: AppColors.slate100,
                                          width: 1.2,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: mine ? 0.04 : 0.015,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      body,
                                      style: TextStyle(
                                        color: mine
                                            ? Colors.white
                                            : AppColors.midnight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white.withValues(
                                                    alpha: 0.65,
                                                  )
                                                : AppColors.slate400,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (mine) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.done_all_rounded,
                                            size: 12,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة للمندوب...',
                        hintStyle: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sending ? null : _send,
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalBlue,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalBlue.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (widget.fillAvailable) return content;
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.76,
          child: content,
        );
      },
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    final body = _message.text.trim();
    setState(() => _sending = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/messages/${widget.conversationId}/send',
        {'body': body},
      );
      _message.clear();
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

String delegateRoleLabel(String role) {
  switch (role) {
    case 'practical_delegate':
      return 'مندوب عملي';
    case 'delegate':
      return 'مندوب نظري';
    default:
      return role;
  }
}

String _delegateRoleLabelClean(String role) {
  switch (role) {
    case 'practical_delegate':
      return 'مندوب عملي';
    case 'delegate':
      return 'مندوب أكاديمي';
    default:
      return role.isEmpty ? 'مندوب' : role;
  }
}
