part of 'student_content_screens.dart';

class StudentStarsScreen extends ConsumerStatefulWidget {
  const StudentStarsScreen({super.key});

  static const route = '/student/stars';

  @override
  ConsumerState<StudentStarsScreen> createState() => _StudentStarsScreenState();
}

class _StudentStarsScreenState extends ConsumerState<StudentStarsScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _message = TextEditingController();
  List<dynamic> _users = [];
  Map<String, dynamic>? _selectedUser;
  bool _searching = false;
  bool _gifting = false;

  @override
  void dispose() {
    _search.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_starsProvider);
    return StudentShell(
      currentIndex: 8,
      title: 'نجومي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_starsProvider),
        builder: (data) {
          final balance = asMap(data['balance']);
          final transactions = asList(data['transactions']);
          final honor = asList(data['honor_board']);

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _StarBalanceCard(balance: balance)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: AppColors.slate50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: TabBar(
                        isScrollable: false,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.slate600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.royalBlue,
                        ),
                        tabs: const [
                          Tab(text: 'الإهداء'),
                          Tab(text: 'لوحة الشرف'),
                          Tab(text: 'السجل'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  // Tab 1: Gifting
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _GiftingSection(
                        search: _search,
                        amount: _amount,
                        message: _message,
                        users: _users,
                        selectedUser: _selectedUser,
                        searching: _searching,
                        gifting: _gifting,
                        onSearch: _searchUsers,
                        onSelect: (user) =>
                            setState(() => _selectedUser = user),
                        onGift: _gift,
                      ),
                    ],
                  ),
                  // Tab 2: Honor Board
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (honor.isEmpty)
                        const EmptyState(
                          message: 'لا توجد بيانات في لوحة الشرف.',
                        )
                      else
                        ...honor.indexed.map(
                          (entry) => _EntryAnimation(
                            index: entry.$1,
                            child: _HonorTile(
                              rank: entry.$1 + 1,
                              item: asMap(entry.$2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Tab 3: History
                  ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      if (transactions.isEmpty)
                        const EmptyState(message: 'لا توجد حركات نجوم.')
                      else
                        ...transactions.map(
                          (item) => _StarTransactionTile(asMap(item)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _searchUsers() async {
    if (_search.text.trim().length < 2) return;
    setState(() => _searching = true);
    try {
      final users = await ref
          .read(studentContentRepositoryProvider)
          .searchStarUsers(_search.text.trim());
      setState(() => _users = users);
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
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _gift() async {
    final selected = _selectedUser;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر الطالب أولاً.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _gifting = true);
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .giftStars(
            recipientId: number(selected, 'id').toInt(),
            amount: int.tryParse(_amount.text.trim()) ?? 1,
            message: _message.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        ref.invalidate(_starsProvider);
      }
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
      if (mounted) setState(() => _gifting = false);
    }
  }
}

class _StarBalanceCard extends StatelessWidget {
  const _StarBalanceCard({required this.balance});
  final Map<String, dynamic> balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.stars_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'رصيد النجوم الحالي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                text(balance, 'current', fallback: '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'إجمالي المكتسب: ${text(balance, 'total_earned', fallback: '0')} نجمة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GiftingSection extends StatelessWidget {
  const _GiftingSection({
    required this.search,
    required this.amount,
    required this.message,
    required this.users,
    required this.selectedUser,
    required this.searching,
    required this.gifting,
    required this.onSearch,
    required this.onSelect,
    required this.onGift,
  });

  final TextEditingController search;
  final TextEditingController amount;
  final TextEditingController message;
  final List<dynamic> users;
  final Map<String, dynamic>? selectedUser;
  final bool searching;
  final bool gifting;
  final VoidCallback onSearch;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ابحث عن زميل لإهدائه نجوم',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          decoration: InputDecoration(
            hintText: 'الاسم أو رقم القيد...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: onSearch,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
          ),
          onSubmitted: (_) => onSearch(),
        ),
        if (users.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...users.map((user) {
            final map = asMap(user);
            final selected = text(selectedUser ?? {}, 'id') == text(map, 'id');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.royalBlue.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.royalBlue : AppColors.slate100,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                onTap: () => onSelect(map),
                leading: CircleAvatar(
                  backgroundColor:
                      (selected ? AppColors.royalBlue : AppColors.slate200)
                          .withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: selected ? AppColors.royalBlue : AppColors.slate400,
                  ),
                ),
                title: Text(
                  text(map, 'name'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('رقم القيد: ${text(map, 'student_number')}'),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.royalBlue,
                      )
                    : null,
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد النجوم',
                  prefixIcon: Icon(Icons.stars_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: message,
                decoration: const InputDecoration(
                  labelText: 'رسالة إهداء (اختياري)',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: gifting ? null : onGift,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFBE123C),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: gifting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.card_giftcard_rounded),
          label: const Text(
            'إهداء النجوم الآن',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _HonorTile extends StatelessWidget {
  const _HonorTile({required this.rank, required this.item});
  final int rank;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final color = rank == 1
        ? const Color(0xFFF59E0B)
        : (rank == 2
              ? const Color(0xFF94A3B8)
              : (rank == 3 ? const Color(0xFFB45309) : AppColors.slate400));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop3 ? color.withValues(alpha: 0.3) : AppColors.slate100,
          width: isTop3 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isTop3
                ? Icon(Icons.emoji_events_rounded, color: color, size: 20)
                : Text(
                    '$rank',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
          ),
          const SizedBox(width: 14),
          _UserAvatar(name: text(item, 'name'), size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(item, 'name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
                Text(
                  '${text(item, 'stars_count')} نجمة',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (rank == 1)
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFF59E0B),
            ),
        ],
      ),
    );
  }
}

class _StarTransactionTile extends StatelessWidget {
  const _StarTransactionTile(this.item);
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final type = text(item, 'type');
    final isCredit = type == 'earned' || type == 'received';
    final color = isCredit ? AppColors.success : const Color(0xFFBE123C);
    final icon = isCredit
        ? Icons.add_circle_outline_rounded
        : Icons.remove_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(item, 'description'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
          Text(
            '${isCredit ? '+' : '-'}${text(item, 'amount')}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
