part of 'student_content_screens.dart';

class StudentStarsScreen extends ConsumerStatefulWidget {
  const StudentStarsScreen({super.key});

  static const route = '/student/stars';

  @override
  ConsumerState<StudentStarsScreen> createState() => _StudentStarsScreenState();
}

class _StudentStarsScreenState extends ConsumerState<StudentStarsScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _amount = TextEditingController(text: '1');
  final _message = TextEditingController();
  List<dynamic> _users = [];
  Map<String, dynamic>? _selectedUser;
  bool _searching = false;
  bool _gifting = false;
  bool _refreshing = false;

  // متغيرات الترقيم والـ Debouncing
  List<dynamic> _transactions = [];
  int _currentPage = 1;
  bool _loadingMore = false;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.addListener(_onSearchChanged);
    
    // شحن البيانات الأولية إذا تم تحميلها مسبقاً في الـ Cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(_starsProvider);
      if (state.hasValue && state.value != null) {
        final items = asList(state.value!['transactions']).toList();
        setState(() {
          _transactions = items;
          _currentPage = 1;
          _hasMore = items.length >= 15;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _search.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _searchUsers();
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    _refreshing = true;
    try {
      ref.invalidate(_starsProvider);
      final data = await ref.read(_starsProvider.future);
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          _transactions = asList(data['transactions']).toList();
        });
      }
    } on ApiException catch (error) {
      if (mounted && !error.isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await ref
          .read(studentContentRepositoryProvider)
          .stars(page: nextPage);
      final items = asList(response['transactions']).toList();
      if (mounted) {
        setState(() {
          if (items.isEmpty) {
            _hasMore = false;
          } else {
            _transactions.addAll(items);
            _currentPage = nextPage;
            if (items.length < 15) {
              _hasMore = false;
            }
          }
        });
      }
    } catch (_) {
      // تجاهل الخطأ بصمت لتجنب إزعاج المستخدم أثناء الـ Infinite Scroll
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  String _getDateHeader(String rawDate) {
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    if (parsed == null) return 'غير محدد';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(parsed.year, parsed.month, parsed.day);

    if (itemDate == today) {
      return 'اليوم';
    } else if (itemDate == yesterday) {
      return 'أمس';
    } else {
      return dateOnly(rawDate);
    }
  }

  List<dynamic> _getGroupedTransactions() {
    final List<dynamic> grouped = [];
    String lastHeader = '';

    for (var i = 0; i < _transactions.length; i++) {
      final item = asMap(_transactions[i]);
      final createdAtRaw = text(item, 'created_at');
      final dateStr = _getDateHeader(createdAtRaw);

      if (dateStr != lastHeader) {
        grouped.add(dateStr);
        lastHeader = dateStr;
      }
      grouped.add(item);
    }
    return grouped;
  }

  Widget _buildHonorPodium(List<dynamic> honor) {
    if (honor.length < 3) return const SizedBox.shrink();

    final first = asMap(honor[0]);
    final second = asMap(honor[1]);
    final third = asMap(honor[2]);

    Widget buildPodiumColumn({
      required Map<String, dynamic> student,
      required int rank,
      required double baseHeight,
      required List<Color> baseGradient,
      required double avatarSize,
      required Color borderColor,
      required String crownEmoji,
    }) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: avatarSize / 2 + 3,
                    backgroundColor: borderColor,
                    child: _UserAvatar(
                      name: text(student, 'name'),
                      size: avatarSize,
                    ),
                  ),
                ),
                if (crownEmoji.isNotEmpty)
                  Positioned(
                    top: -22,
                    child: Text(
                      crownEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                text(student, 'name'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.midnight,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    text(student, 'stars_balance'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: baseHeight,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: baseGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseGradient.last.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$rank',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 290,
      margin: const EdgeInsets.only(bottom: 24, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          buildPodiumColumn(
            student: second,
            rank: 2,
            baseHeight: 95,
            baseGradient: [const Color(0xFFCBD5E1), const Color(0xFF64748B)],
            avatarSize: 52,
            borderColor: const Color(0xFF94A3B8),
            crownEmoji: '',
          ),
          buildPodiumColumn(
            student: first,
            rank: 1,
            baseHeight: 125,
            baseGradient: [const Color(0xFFFBBF24), const Color(0xFFD97706)],
            avatarSize: 64,
            borderColor: const Color(0xFFF59E0B),
            crownEmoji: '👑',
          ),
          buildPodiumColumn(
            student: third,
            rank: 3,
            baseHeight: 75,
            baseGradient: [const Color(0xFFD97706).withValues(alpha: 0.7), const Color(0xFF78350F)],
            avatarSize: 46,
            borderColor: const Color(0xFFB45309),
            crownEmoji: '',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_transactions.isEmpty) {
      return const EmptyState(message: 'لا توجد حركات نجوم.');
    }
    final grouped = _getGroupedTransactions();
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreTransactions();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        itemCount: grouped.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == grouped.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF59E0B),
                ),
              ),
            );
          }

          final current = grouped[index];
          if (current is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10, right: 4),
              child: Text(
                current,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          }

          return _StarTransactionTile(asMap(current));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع للتغيرات القادمة من الـ Provider لتحديث سجل الحركات الأولي
    ref.listen<AsyncValue<Map<String, dynamic>>>(_starsProvider,
        (previous, next) {
      next.whenData((data) {
        final items = asList(data['transactions']).toList();
        setState(() {
          _transactions = items;
          _currentPage = 1;
          _hasMore = items.length >= 15;
        });
      });
    });

    final state = ref.watch(_starsProvider);
    return StudentShell(
      currentIndex: 8,
      title: 'نجومي',
      child: _AsyncBody(
        state: state,
        onRetry: () {
          _refresh();
        },
        builder: (data) {
          final balance = asMap(data['balance']);
          final honor = asList(data['honor_board']);
          final giftLimit = asMap(data['gift_limit']);

          return DefaultTabController(
            length: 3,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(child: _StarBalanceCard(balance: balance)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      height: 70,
                      child: Container(
                        color: AppColors.slate50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: TabBar(
                            isScrollable: false,
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF475569),
                            labelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.royalBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.royalBlue.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🎁'),
                                    SizedBox(width: 4),
                                    Text('الإهداء'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🏆'),
                                    SizedBox(width: 4),
                                    Text('لوحة الشرف'),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('📜'),
                                    SizedBox(width: 4),
                                    Text('السجل'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    // Tab 1: Gifting
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      children: [
                        _GiftingSection(
                          search: _search,
                          amount: _amount,
                          message: _message,
                          users: _users,
                          selectedUser: _selectedUser,
                          balance: number(balance, 'current').toInt(),
                          giftLimit: giftLimit,
                          searching: _searching,
                          gifting: _gifting,
                          onSearch: _searchUsers,
                          onSelect: (user) =>
                              setState(() => _selectedUser = user),
                          onGift: () => _gift(giftLimit, balance),
                        ),
                      ],
                    ),
                    // Tab 2: Honor Board
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      children: [
                        if (honor.isEmpty)
                          const EmptyState(
                            message: 'لا توجد بيانات في لوحة الشرف.',
                          )
                        else ...[
                          if (honor.length >= 3)
                            _buildHonorPodium(honor),
                          ...honor.indexed.map(
                            (entry) {
                              final index = entry.$1;
                              if (honor.length >= 3 && index < 3) {
                                return const SizedBox.shrink();
                              }
                              return _EntryAnimation(
                                index: index,
                                child: _HonorTile(
                                  rank: index + 1,
                                  item: asMap(entry.$2),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    // Tab 3: History
                    _buildHistoryTab(),
                  ],
                ),
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

  Future<void> _gift(
    Map<String, dynamic> giftLimit,
    Map<String, dynamic> balance,
  ) async {
    final selected = _selectedUser;
    if (selected == null) {
      await showMoeenInfoDialog(
        context: context,
        title: 'اختر الطالب',
        message: 'اختر الطالب الذي تريد إهداء النجوم له أولاً.',
        icon: Icons.person_search_rounded,
        color: AppColors.warning,
      );
      return;
    }

    final amount = int.tryParse(_amount.text.trim());
    final currentBalance = number(balance, 'current').toInt();
    final remaining = giftLimit.isEmpty
        ? currentBalance
        : number(giftLimit, 'remaining').toInt();
    if (giftLimit.isNotEmpty && giftLimit['enabled'] != true) {
      await showMoeenInfoDialog(
        context: context,
        title: 'التحويل متوقف',
        message: 'أوقفت إدارة النظام تحويل النجوم بين الطلاب مؤقتًا.',
        icon: Icons.block_rounded,
        color: AppColors.warning,
      );
      return;
    }
    if (amount == null || amount < 1) {
      await showMoeenInfoDialog(
        context: context,
        title: 'عدد غير صحيح',
        message: 'أدخل عددًا صحيحًا من النجوم لا يقل عن نجمة واحدة.',
        icon: Icons.error_outline_rounded,
        color: AppColors.danger,
      );
      return;
    }
    if (amount > currentBalance || amount > remaining) {
      await showMoeenInfoDialog(
        context: context,
        title: 'تعذر إتمام الإهداء',
        message:
            'الحد الأقصى المتاح لك الآن هو ${math.min(currentBalance, remaining)} نجمة.',
        icon: Icons.info_outline_rounded,
        color: AppColors.warning,
      );
      return;
    }

    final confirmed = await showMoeenConfirmDialog(
      context: context,
      title: 'تأكيد إهداء النجوم',
      message:
          'سيتم إهداء $amount نجمة إلى ${text(selected, 'name')}.\n'
          'سيتبقى من حد التحويل ${remaining - amount} نجمة.',
      confirmLabel: 'تأكيد الإهداء',
      icon: Icons.card_giftcard_rounded,
      color: const Color(0xFFF59E0B),
    );
    if (!confirmed || !mounted) return;

    setState(() => _gifting = true);
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .giftStars(
            recipientId: number(selected, 'id').toInt(),
            amount: amount,
            message: _message.text.trim(),
          );
      if (mounted) {
        await _refresh();
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تم الإهداء',
          message: message,
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
        if (!mounted) return;
        _amount.text = '1';
        _message.clear();
        setState(() {
          _selectedUser = null;
          _users = [];
          _search.clear();
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        await showMoeenInfoDialog(
          context: context,
          title: 'تعذر إهداء النجوم',
          message: error.message,
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
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
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFBF953F),
            Color(0xFFFCF6BA),
            Color(0xFFB38728),
            Color(0xFFFBF5B7),
            Color(0xFFAA771C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAA771C).withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Icon(
              Icons.stars_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            left: -35,
            bottom: -35,
            child: Icon(
              Icons.star_outline_rounded,
              size: 100,
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
                      color: Colors.black.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'رصيد النجوم الحالي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                text(balance, 'current', fallback: '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  'إجمالي النجوم المكتسبة: ${text(balance, 'total_earned', fallback: '0')} نجمة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Cairo',
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
    required this.balance,
    required this.giftLimit,
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
  final int balance;
  final Map<String, dynamic> giftLimit;
  final bool searching;
  final bool gifting;
  final VoidCallback onSearch;
  final ValueChanged<Map<String, dynamic>?> onSelect;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    final hasLimitData = giftLimit.isNotEmpty;
    final enabled = !hasLimitData || giftLimit['enabled'] == true;
    final remaining = hasLimitData
        ? number(giftLimit, 'remaining').toInt()
        : balance;
    final canGift = enabled && remaining > 0 && balance > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StarGiftLimitCard(limit: giftLimit),
        const SizedBox(height: 20),
        if (selectedUser != null) ...[
          const Text(
            'الطالب المستهدف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.royalBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: AppColors.royalBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(selectedUser!, 'name'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'رقم القيد: ${text(selectedUser!, 'student_number')}',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onSelect(null),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
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
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: canGift,
                decoration: InputDecoration(
                  labelText: 'عدد النجوم',
                  helperText: canGift
                      ? 'المتاح: ${math.min(balance, remaining)}'
                      : null,
                  prefixIcon: const Icon(Icons.stars_rounded),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: message,
                enabled: canGift,
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
          onPressed: gifting || !canGift ? null : onGift,
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

class _StarGiftLimitCard extends StatelessWidget {
  const _StarGiftLimitCard({required this.limit});

  final Map<String, dynamic> limit;

  @override
  Widget build(BuildContext context) {
    if (limit.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc), // slate-50
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xff64748b)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'سيتم التحقق من حد التحويل عند تنفيذ الإهداء.',
                style: TextStyle(
                  color: Color(0xff334155),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final enabled = limit['enabled'] == true;
    final maximum = number(limit, 'maximum').toInt();
    final used = number(limit, 'used').toInt();
    final remaining = number(limit, 'remaining').toInt();
    final progress = maximum > 0
        ? (used / maximum).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final periodLabel = text(limit, 'period_label', fallback: 'الفترة الحالية');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFFFFDF5) : const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled ? const Color(0xFFFDE68A) : const Color(0xffcbd5e1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:
                      (enabled ? const Color(0xFFF59E0B) : const Color(0xff64748b))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enabled ? Icons.swap_horizontal_circle_rounded : Icons.block_rounded,
                  color: enabled ? const Color(0xFFD97706) : const Color(0xff64748b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'حد تحويل النجوم بين الطلاب' : 'التحويل متوقف حاليًا',
                      style: const TextStyle(
                        color: Color(0xff1e293b),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                        fontSize: 15,
                      ),
                    ),
                    if (enabled)
                      Text(
                        'يتجدد خلال $periodLabel',
                        style: const TextStyle(
                          color: Color(0xff64748b),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StarLimitMetric(value: '$maximum', label: 'الحد المسموح'),
                ),
                Expanded(
                  child: _StarLimitMetric(value: '$used', label: 'المستخدم حالياً'),
                ),
                Expanded(
                  child: _StarLimitMetric(
                    value: '$remaining',
                    label: 'المتبقي المتاح',
                    highlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFFEF3C7),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              remaining > 0
                  ? 'موعد التجديد: ${_formatStarReset(limit['resets_at'])}'
                  : 'لقد استهلكت كامل الحد المتاح للفترة الحالية. سيتجدد في ${_formatStarReset(limit['resets_at'])}.',
              style: TextStyle(
                color: remaining > 0 ? const Color(0xff475569) : AppColors.danger,
                fontSize: 11,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'أوقفت إدارة النظام تحويل النجوم بين الطلاب مؤقتًا لأسباب تنظيمية.',
              style: TextStyle(
                color: Color(0xff475569),
                fontSize: 12,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarLimitMetric extends StatelessWidget {
  const _StarLimitMetric({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlighted ? const Color(0xFFD97706) : AppColors.midnight,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate500,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _formatStarReset(Object? raw) {
  final parsed = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
  if (parsed == null) return 'غير محدد';

  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour < 12 ? 'ص' : 'م';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');

  return '$day/$month/${parsed.year}، $hour:$minute $period';
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
              : (rank == 3 ? const Color(0xFFB45309) : const Color(0xff94a3b8)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop3 ? color.withValues(alpha: 0.3) : const Color(0xfff1f5f9),
          width: isTop3 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isTop3 ? color.withValues(alpha: 0.1) : const Color(0xfff1f5f9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isTop3
                ? Icon(Icons.emoji_events_rounded, color: color, size: 18)
                : Text(
                    '$rank',
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          _UserAvatar(name: text(item, 'name'), size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(item, 'name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                  ),
                ),
                Text(
                  'رقم القيد: ${text(item, 'student_number')}',
                  style: const TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 11,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xfffef3c7), // amber-100
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xffd97706), size: 14),
                const SizedBox(width: 4),
                Text(
                  text(item, 'stars_balance'),
                  style: const TextStyle(
                    color: Color(0xffd97706),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    fontSize: 12,
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

class _StarTransactionTile extends StatelessWidget {
  const _StarTransactionTile(this.item);
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final amountVal = number(item, 'amount').toInt();
    final isCredit = amountVal > 0;
    final color = isCredit ? const Color(0xff10b981) : const Color(0xffe11d48); // Emerald and Rose
    final icon = isCredit
        ? Icons.arrow_downward_rounded // Money coming in
        : Icons.arrow_upward_rounded; // Money going out

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xfff1f5f9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
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
                    fontFamily: 'Cairo',
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeOnly(text(item, 'created_at')),
                  style: const TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 11,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${isCredit ? '+' : '-'}${amountVal.abs()}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
