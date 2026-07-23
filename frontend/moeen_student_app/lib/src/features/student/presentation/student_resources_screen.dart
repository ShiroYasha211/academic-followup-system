part of 'student_content_screens.dart';

class StudentResourcesScreen extends ConsumerStatefulWidget {
  const StudentResourcesScreen({super.key});

  static const route = '/student/resources';

  @override
  ConsumerState<StudentResourcesScreen> createState() =>
      _StudentResourcesScreenState();
}

class _StudentResourcesScreenState extends ConsumerState<StudentResourcesScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late TabController _tabController;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'الكل'},
    {'value': 'lectures', 'label': 'المحاضرات'},
    {'value': 'summaries', 'label': 'الملخصات'},
    {'value': 'quizzes', 'label': 'كويزات'},
    {'value': 'exams', 'label': 'نماذج اختبارات'},
    {'value': 'references', 'label': 'مراجع'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  int? _subjectId;
  String _sort = 'newest';
  bool _scheduled = false;
  bool _isGrid = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _page = 1);
      }
    });
  }

  String get _selectedCategory => _categories[_tabController.index]['value']!;

  ResourceQuery get _query => (
    search: _search.text,
    subjectId: _subjectId,
    category: _selectedCategory,
    sort: _sort,
    scheduled: _scheduled,
    page: _page,
  );

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final state = ref.watch(_resourcesProvider(query));

    return StudentShell(
      currentIndex: 11,
      title: 'مصادر المقرر',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_resourcesProvider(query)),
        builder: (data) => _buildLayout(context, data),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, dynamic data) {
    final stats = asMap(data['stats']);
    final subjects = asList(data['subjects']).map(asMap).toList();
    final paginator = asMap(data['resources']);
    final resources = asList(paginator['data']).map(asMap).toList();

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CompactHeader(
                  title: 'المكتبة الرقمية',
                  subtitle:
                      '${text(stats, 'total_files', fallback: resources.length.toString())} ملف متاح للدراسة',
                  icon: Icons.auto_stories_rounded,
                  color: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 16),
                _ResourceActionRow(
                  search: _search,
                  isGrid: _isGrid,
                  onSearch: () => setState(() => _page = 1),
                  onFilter: () => _showAdvancedFilters(context, subjects),
                  onToggleView: () => setState(() => _isGrid = !_isGrid),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverAppBarDelegate(
            height: 74,
            child: Container(
              color: AppColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slate200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.slate600,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: _categories.map((c) => Tab(text: c['label'])).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((cat) {
          final catValue = cat['value'];
          final filtered = catValue == 'all'
              ? resources
              : resources.where((r) {
                  final c = text(r, 'category');
                  if (catValue == 'lectures' &&
                      (c == 'lectures' || c == 'lecture'))
                    return true;
                  if (catValue == 'summaries' &&
                      (c == 'summaries' || c == 'summary'))
                    return true;
                  return c == catValue;
                }).toList();
          final currentPage = number(paginator, 'current_page').toInt();
          final lastPage = number(paginator, 'last_page').toInt();
          final total = number(paginator, 'total').toInt();

          if (filtered.isEmpty) {
            return const EmptyState(
              message: 'لا توجد مصادر في هذا التصنيف.',
              icon: Icons.folder_open_rounded,
            );
          }

          if (_isGrid) {
            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(18),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _CourseResourceGridCard(
                      item: filtered[i],
                      onDownload: () => _downloadDirect(context, filtered[i]),
                      onOpen: () => _openDirect(context, filtered[i]),
                    ),
                  ),
                ),
                if (lastPage > 1)
                  _ResourcesPaginationBar(
                    currentPage: currentPage,
                    lastPage: lastPage,
                    total: total,
                    onPageChanged: (page) => setState(() => _page = page),
                  ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            itemCount: filtered.length + (lastPage > 1 ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              if (i == filtered.length) {
                return _ResourcesPaginationBar(
                  currentPage: currentPage,
                  lastPage: lastPage,
                  total: total,
                  onPageChanged: (page) => setState(() => _page = page),
                );
              }
              return _CourseResourceCard(
                item: filtered[i],
                onDownload: () => _downloadDirect(context, filtered[i]),
                onOpen: () => _openDirect(context, filtered[i]),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _downloadDirect(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final path = text(item, 'file_path');
    if (path.isEmpty) return;

    final url = absoluteUrl(
      path.startsWith('storage/') ? path : 'storage/$path',
    );
    await _downloadUrlToFile(
      context,
      url,
      text(item, 'title', fallback: 'resource'),
      section: 'CourseResources',
    );
  }

  Future<void> _openDirect(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final path = text(item, 'file_path');
    if (path.isEmpty) return;

    final url = absoluteUrl(
      path.startsWith('storage/') ? path : 'storage/$path',
    );
    final fileName = _downloadFileName(
      url,
      text(item, 'title', fallback: 'resource'),
    );
    String? opened;
    try {
      opened = await DownloadService.openMoeenFile(
        fileName: fileName,
        section: 'CourseResources',
      );
    } catch (_) {
      opened = null;
    }
    if (!context.mounted || opened != null) return;

    final downloadNow = await showMoeenConfirmDialog(
      context: context,
      title: 'الملف غير محمل',
      message: 'هذا الملف غير موجود في جهازك. هل تريد تحميله الآن؟',
      confirmLabel: 'تحميل الآن',
      icon: Icons.download_rounded,
      color: AppColors.royalBlue,
    );
    if (downloadNow && context.mounted) {
      await _downloadDirect(context, item);
    }
  }

  Future<void> _showAdvancedFilters(
    BuildContext context,
    List<Map<String, dynamic>> subjects,
  ) async {
    int? subject = _subjectId;
    String selectedSort = _sort;
    bool scheduled = _scheduled;

    final result = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تصفية المصادر',
      icon: Icons.tune_rounded,
      color: const Color(0xFF0D9488),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              value: subject,
              decoration: const InputDecoration(labelText: 'المادة الدراسية'),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل المواد')),
                ...subjects.map(
                  (s) => DropdownMenuItem(
                    value: number(s, 'id').toInt(),
                    child: Text(text(s, 'name')),
                  ),
                ),
              ],
              onChanged: (val) => setLocal(() => subject = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSort,
              decoration: const InputDecoration(labelText: 'ترتيب حسب'),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('الأحدث أولاً')),
                DropdownMenuItem(value: 'oldest', child: Text('الأقدم أولاً')),
                DropdownMenuItem(value: 'title', child: Text('العنوان (أ-ي)')),
              ],
              onChanged: (val) =>
                  setLocal(() => selectedSort = val ?? 'newest'),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: scheduled,
              contentPadding: EdgeInsets.zero,
              title: const Text('المصادر المجدولة فقط'),
              subtitle: const Text('عرض الملفات التي أضفتها إلى جدولك الدراسي'),
              activeColor: Color(0xFF0D9488),
              onChanged: (value) => setLocal(() => scheduled = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
              ),
              child: const Text('تطبيق الفلترة'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _subjectId = subject;
        _sort = selectedSort;
        _scheduled = scheduled;
        _page = 1;
      });
    }
  }
}

class _ResourcesPaginationBar extends StatelessWidget {
  const _ResourcesPaginationBar({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.onPageChanged,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'صفحة $currentPage من $lastPage - $total ملف',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.slate600,
              ),
            ),
            const Spacer(),
            IconButton.filledTonal(
              tooltip: 'السابق',
              onPressed: currentPage <= 1
                  ? null
                  : () => onPageChanged(currentPage - 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'التالي',
              onPressed: currentPage >= lastPage
                  ? null
                  : () => onPageChanged(currentPage + 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceActionRow extends StatelessWidget {
  const _ResourceActionRow({
    required this.search,
    required this.isGrid,
    required this.onSearch,
    required this.onFilter,
    required this.onToggleView,
  });
  final TextEditingController search;
  final bool isGrid;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.midnight.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: search,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: 'ابحث عن اسم الملف أو المادة...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _IconButton(
          icon: isGrid
              ? Icons.format_list_bulleted_rounded
              : Icons.grid_view_rounded,
          onTap: onToggleView,
        ),
        const SizedBox(width: 8),
        _IconButton(icon: Icons.tune_rounded, onTap: onFilter),
      ],
    );
  }
}
