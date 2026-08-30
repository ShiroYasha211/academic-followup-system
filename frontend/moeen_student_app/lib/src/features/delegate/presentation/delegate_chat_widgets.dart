part of 'delegate_screens.dart';

class _ChatListScreen extends ConsumerWidget {
  const _ChatListScreen({
    required this.title,
    required this.index,
    required this.state,
    required this.onRetry,
    required this.extractor,
    required this.eligibleLoader,
    required this.openPath,
    required this.startMessage,
  });
  final String title;
  final int index;
  final AsyncValue<Map<String, dynamic>> state;
  final VoidCallback onRetry;
  final List<dynamic> Function(Map<String, dynamic>) extractor;
  final Future<List<dynamic>> Function() eligibleLoader;
  final String Function(int id) openPath;
  final Future<String> Function({
    required int recipientId,
    required String content,
  })
  startMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DelegateShell(
      currentIndex: index,
      title: title,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startChatSheet(context),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text(
          'محادثة جديدة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: onRetry,
        builder: (data) {
          final items = extractor(data).map(asMap).toList();
          final unreadCount = number(data, 'unread_count').toInt();

          return RefreshIndicator(
            onRefresh: () async => onRetry(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  sliver: SliverToBoxAdapter(
                    child: _UnreadMessagesHeader(unreadCount: unreadCount),
                  ),
                ),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState('لا توجد محادثات نشطة حالياً.'),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final raw = items[index];
                        final recipient =
                            (asMap(raw)['student'] as Map?)?.isNotEmpty == true
                            ? asMap(raw)['student']
                            : asMap(raw)['doctor'];
                        final name = text(
                          recipient,
                          'name',
                          fallback: 'محادثة',
                        );
                        final last = asMap(raw)['last_message'];
                        final unread = number(raw, 'unread_count').toInt();

                        final isDoctor =
                            (asMap(raw)['doctor'] as Map?)?.isNotEmpty == true;

                        return _ConversationCard(
                          name: name,
                          lastMessage: text(
                            last,
                            'body',
                            fallback: 'افتح المحادثة للتواصل.',
                          ),
                          time: text(last, 'created_at'),
                          unreadCount: unread,
                          isDoctor: isDoctor,
                          onTap: () =>
                              context.push(openPath(number(raw, 'id').toInt())),
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

  Future<void> _startChatSheet(BuildContext context) async {
    final recipients = await eligibleLoader();
    if (!context.mounted) return;
    var recipientId = recipients.isNotEmpty
        ? number(recipients.first, 'id').toInt()
        : 0;
    final message = TextEditingController();
    await _formSheet(
      context,
      title: 'بدء محادثة',
      fields: [
        DropdownButtonFormField<int>(
          value: recipientId == 0 ? null : recipientId,
          items: recipients
              .map(
                (recipient) => DropdownMenuItem(
                  value: number(recipient, 'id').toInt(),
                  child: Text(text(recipient, 'name')),
                ),
              )
              .toList(),
          onChanged: (value) => recipientId = value ?? 0,
          decoration: const InputDecoration(labelText: 'المستلم'),
        ),
        TextField(
          controller: message,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'الرسالة'),
        ),
      ],
      onSave: () =>
          startMessage(recipientId: recipientId, content: message.text.trim()),
      after: onRetry,
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.title,
    required this.subtitle,
    required this.future,
    required this.reload,
    required this.send,
    required this.index,
  });

  final String title;
  final String subtitle;
  final Future<Map<String, dynamic>> future;
  final VoidCallback reload;
  final Future<String> Function(String body) send;
  final int index;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _cachedData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedData = snapshot.data;
        }

        if (_cachedData == null &&
            snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
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
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError && _cachedData == null) {
          return Scaffold(
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
            ),
            body: _ErrorState(
              message: snapshot.error.toString(),
              onRetry: widget.reload,
            ),
          );
        }

        final data = _cachedData ?? {};
        final messages = asList(data['messages']).map(asMap).toList();
        final conversation = asMap(data['conversation']);
        final recipient =
            (asMap(conversation['student']) as Map?)?.isNotEmpty == true
            ? asMap(conversation['student'])
            : asMap(conversation['doctor']);
        final name = text(recipient, 'name', fallback: 'المحادثة');
        final isDoctor =
            (asMap(conversation['doctor']) as Map?)?.isNotEmpty == true;

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
                _UserAvatar(name: name, size: 38, isDoctor: isDoctor),
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
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
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
                      ? const _EmptyState('لا توجد رسائل في هذه المحادثة.')
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final item = messages[messages.length - 1 - index];
                            final sender = asMap(item['sender']);
                            final isMine = boolValue(
                              item,
                              'is_mine',
                              fallback:
                                  text(sender, 'role') == 'delegate' ||
                                  text(sender, 'role') == 'practical_delegate',
                            );

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
      await widget.send(body);
      _message.clear();
      widget.reload();
    } catch (error) {
      if (mounted) _showError(context, error);
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
    this.isDoctor = false,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (unreadCount > 0 ? AppColors.royalBlue : AppColors.slate200)
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: unreadCount > 0
              ? AppColors.royalBlue.withValues(alpha: 0.12)
              : AppColors.slate100,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(name: name, size: 54, isDoctor: isDoctor),
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
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w900
                                  : FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo(time),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? AppColors.slate800
                            : AppColors.slate500,
                        fontWeight: unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
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
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
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
  const _UserAvatar({
    required this.name,
    required this.size,
    this.isDoctor = false,
  });

  final String name;
  final double size;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(1).join().toUpperCase()
        : '?';

    final roleColor = isDoctor ? AppColors.royalBlue : AppColors.teal;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withValues(alpha: 0.1),
            roleColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: roleColor,
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
                ),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(color: AppColors.slate400),
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

// Kept for screens that may reuse the compact info-row visual.
// ignore: unused_element
class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _DataCard(
    title: label,
    subtitle: value,
    icon: icon,
    color: AppColors.royalBlue,
  );
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.disabled,
    required this.onSubscribe,
  });
  final SubscriptionPackage package;
  final bool disabled;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final price = package.priceDelegate > 0
        ? package.priceDelegate
        : package.displayPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            package.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            package.description,
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _PackageInfoItem(
                icon: Icons.calendar_month_rounded,
                label: '${package.durationDays} يوم',
              ),
              const SizedBox(width: 20),
              _PackageInfoItem(
                icon: Icons.payments_rounded,
                label: money(price),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled ? null : onSubscribe,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: AppColors.midnight,
              ),
              child: const Text(
                'اشتراك في هذه الباقة',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
