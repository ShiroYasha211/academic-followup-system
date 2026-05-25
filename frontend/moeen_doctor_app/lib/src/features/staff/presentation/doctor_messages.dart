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
        icon: const Icon(Icons.chat_rounded),
        label: const Text('محادثة'),
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
                _DocHero(
                  title: 'محادثات المندوبين',
                  subtitle:
                      'متابعة الرسائل مع مندوبي موادك والرد عليهم مباشرة.',
                  icon: Icons.chat_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () async {
                      await context.push(DoctorStartConversationScreen.route);
                      _reload();
                    },
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'المحادثات',
                      value: conversations.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.forum_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unread.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_chat_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (conversations.isEmpty)
                  const _DocEmpty('لا توجد محادثات بعد.')
                else
                  ...conversations.map(
                    (conversation) => _ConversationCard(
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

  // ignore: unused_element
  Future<void> _startConversation() async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'بدء محادثة',
      icon: Icons.add_comment_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _StartConversationPanel(
        onStarted: (conversationId) async {
          Navigator.pop(context);
          _reload();
          await _openConversation(conversationId);
        },
      ),
    );
  }

  Future<void> _openConversation(int conversationId) async {
    await context.push(DoctorConversationScreen.path(conversationId));
    _reload();
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
          _DocHero(
            title: 'بدء محادثة',
            subtitle: 'اختر مندوبًا من نطاق موادك وافتح محادثة مباشرة.',
            icon: Icons.add_comment_rounded,
          ),
          const SizedBox(height: 14),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: _ConversationPanel(
            conversationId: conversationId,
            fillAvailable: true,
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.onTap});

  final _Json conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delegate = _docMap(conversation['delegate']);
    final unread = _docInt(conversation['unread_count']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.royalBlue.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.royalBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docText(delegate['name'], 'مندوب'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docText(
                      conversation['last_message'],
                      'لا توجد رسائل بعد.',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docDate(conversation['last_message_at']),
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0) _DocPill(unread.toString(), AppColors.danger),
          ],
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
      children: [
        TextField(
          controller: _search,
          onSubmitted: (_) => _reload(),
          decoration: InputDecoration(
            hintText: 'ابحث عن مندوب...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
            final delegates = _docList(_docData(snapshot.data ?? const {}));
            if (delegates.isEmpty) {
              return const _DocEmpty('لا يوجد مندوبون ضمن نطاق موادك.');
            }
            return Column(
              children: delegates.map((delegate) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_rounded),
                    ),
                    title: Text(_docText(delegate['name'])),
                    subtitle: Text(
                      '${_docText(delegate['student_number'], '-')} • ${_delegateRoleLabel(_docText(delegate['role']))}',
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _start(delegate),
                  ),
                );
              }).toList(),
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
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/messages/${widget.conversationId}');
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
        final conversation = _docMap(data['conversation']);
        final delegate = _docMap(conversation['delegate']);
        final messages = _docList(data['messages']);
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_rounded)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _docText(delegate['name'], 'مندوب'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: messages.isEmpty
                  ? const _DocEmpty('لا توجد رسائل بعد.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = _docBool(message['is_mine']);
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.royalBlue
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(message['body']),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : AppColors.midnight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _docDate(message['created_at']),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white.withValues(alpha: 0.72)
                                        : AppColors.slate500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
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

String _delegateRoleLabel(String role) {
  switch (role) {
    case 'practical_delegate':
      return 'مندوب عملي';
    case 'delegate':
      return 'مندوب';
    default:
      return role;
  }
}

