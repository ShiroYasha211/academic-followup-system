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
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('محادثة'),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: onRetry,
        builder: (data) {
          final items = extractor(data);
          return _ListScaffold(
            title: '$title (${items.length})',
            subtitle: 'دردشة منظمة وسريعة مع الأطراف المرتبطة بالدفعة.',
            icon: Icons.forum_rounded,
            colors: const [AppColors.violet, AppColors.royalBlue],
            children: [
              if (items.isEmpty) const _EmptyState('لا توجد محادثات حالية.'),
              for (final raw in items)
                InkWell(
                  onTap: () =>
                      context.push(openPath(number(raw, 'id').toInt())),
                  child: _DataCard(
                    title: text(
                      asMap(raw)['student'],
                      'name',
                      fallback: text(
                        asMap(raw)['doctor'],
                        'name',
                        fallback: 'محادثة',
                      ),
                    ),
                    subtitle: text(
                      asMap(raw)['last_message'],
                      'body',
                      fallback: text(
                        raw,
                        'last_message_at',
                        fallback: 'اضغط لعرض التفاصيل',
                      ),
                    ),
                    icon: Icons.chat_bubble_rounded,
                    color: AppColors.violet,
                  ),
                ),
            ],
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
    required this.future,
    required this.reload,
    required this.send,
  });

  final String title;
  final Future<Map<String, dynamic>> future;
  final VoidCallback reload;
  final Future<String> Function(String body) send;

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

  @override
  Widget build(BuildContext context) {
    return DelegateShell(
      currentIndex: 17,
      title: widget.title,
      child: FutureBuilder<Map<String, dynamic>>(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: widget.reload,
            );
          }
          final data = snapshot.data ?? {};
          final messages = asList(data['messages']);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    for (final raw in messages)
                      Align(
                        alignment:
                            text(asMap(raw)['sender'], 'role') == 'delegate'
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color:
                                text(asMap(raw)['sender'], 'role') == 'delegate'
                                ? AppColors.royalBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            text(raw, 'body', fallback: text(raw, 'content')),
                            style: TextStyle(
                              color:
                                  text(asMap(raw)['sender'], 'role') ==
                                      'delegate'
                                  ? Colors.white
                                  : AppColors.midnight,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.send(_message.text.trim());
      _message.clear();
      widget.reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in options.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: value == entry.key,
                label: Text(entry.value),
                onSelected: (_) => onChanged(entry.key),
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
