part of 'delegate_screens.dart';

class DelegateSharedLibraryScreen extends ConsumerStatefulWidget {
  const DelegateSharedLibraryScreen({super.key});
  static const route = DelegateRoutes.libraryImport;

  @override
  ConsumerState<DelegateSharedLibraryScreen> createState() =>
      _DelegateSharedLibraryScreenState();
}

class _DelegateSharedLibraryScreenState
    extends ConsumerState<DelegateSharedLibraryScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late TabController _tabController;
  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'الكل'},
    {'value': 'lectures', 'label': 'محاضرات'},
    {'value': 'exams', 'label': 'نماذج'},
    {'value': 'summaries', 'label': 'ملخصات'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  int? _subjectId;
  bool _isGrid = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  ({String? query, String? category, int? subjectId}) get _query => (
    query: _search.text.trim(),
    category: 'all', // Fetch all categories once
    subjectId: _subjectId,
  );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final state = ref.watch(_delegateSharedLibraryProvider(query));
    final subjectsState = ref.watch(_delegateSubjectsProvider);

    return DelegateShell(
      currentIndex: 9,
      title: 'المكتبة المشتركة',
      child: Stack(
        children: [
          _AsyncBody<List<dynamic>>(
            state: state,
            onRetry: () =>
                ref.invalidate(_delegateSharedLibraryProvider(query)),
            builder: (items) {
              final subjects = asList(subjectsState.value).map(asMap).toList();
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const _HeroPanel(
                            title: 'المكتبة المشتركة',
                            subtitle:
                                'استكشف الموارد التعليمية من مختلف الدفعات واستوردها لمقرراتك.',
                            icon: Icons.library_add_rounded,
                            colors: [Color(0xFF0F172A), Color(0xFF334155)],
                          ),
                          const SizedBox(height: 16),
                          _LibraryActionRow(
                            controller: _search,
                            isGrid: _isGrid,
                            onSearch: () => setState(() {}),
                            onToggleView: () =>
                                setState(() => _isGrid = !_isGrid),
                            onFilter: () =>
                                _showFilterDialog(context, subjects),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      height: 68,
                      child: Container(
                        color: AppColors.ghostWhite,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                            tabs: _categories
                                .map((c) => Tab(text: c['label']))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) {
                    final catValue = cat['value']!;
                    // Local filtering by category
                    final tabItems = catValue == 'all'
                        ? items
                        : items
                              .where((i) => text(i, 'category') == catValue)
                              .toList();

                    if (tabItems.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: AppColors.slate300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد نتائج في هذا القسم',
                              style: TextStyle(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (_isGrid) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(18),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                        itemCount: tabItems.length,
                        itemBuilder: (ctx, i) => _SharedResourceGridCard(
                          resource: asMap(tabItems[i]),
                          canImport: true,
                          onImport: () => _showImportSheet(
                            context,
                            asMap(tabItems[i]),
                            subjects,
                          ),
                          onPreview: () => _preview(asMap(tabItems[i])),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      itemCount: tabItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _SharedResourceCard(
                        resource: asMap(tabItems[i]),
                        canImport: true,
                        onImport: () => _showImportSheet(
                          context,
                          asMap(tabItems[i]),
                          subjects,
                        ),
                        onPreview: () => _preview(asMap(tabItems[i])),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    List<Map<String, dynamic>> subjects,
  ) async {
    int? selected = _subjectId;
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تصفية حسب المادة',
      icon: Icons.filter_list_rounded,
      color: AppColors.primary,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              value: selected,
              decoration: const InputDecoration(labelText: 'اختر المادة'),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع المواد')),
                ...subjects.map(
                  (s) => DropdownMenuItem(
                    value: number(s, 'id').toInt(),
                    child: Text(text(s, 'name')),
                  ),
                ),
              ],
              onChanged: (v) => setLocal(() => selected = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تطبيق التصفية'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() => _subjectId = selected);
    }
  }

  Future<void> _showImportSheet(
    BuildContext context,
    Map<String, dynamic> resource,
    List<Map<String, dynamic>> subjects,
  ) async {
    int? targetSubjectId = subjects.isNotEmpty
        ? number(subjects.first, 'id').toInt()
        : null;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'استيراد المورد',
      icon: Icons.import_export_rounded,
      color: AppColors.primary,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أنت على وشك استيراد "${text(resource, 'title')}" إلى مقرراتك الدراسية.',
              style: const TextStyle(color: AppColors.slate600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: targetSubjectId,
              decoration: const InputDecoration(labelText: 'استيراد إلى مادة:'),
              items: subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: number(s, 'id').toInt(),
                      child: Text(text(s, 'name')),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setLocal(() => targetSubjectId = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تأكيد الاستيراد'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && targetSubjectId != null) {
      setState(() => _busy = true);
      try {
        final msg = await ref
            .read(delegateRepositoryProvider)
            .importResource(
              resourceId: number(resource, 'id').toInt(),
              subjectId: targetSubjectId!,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.success),
          );
        }
        ref.invalidate(_delegateResourcesProvider);
      } catch (e) {
        if (context.mounted) _showError(context, e);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _preview(Map<String, dynamic> resource) async {
    // Logic to download/view the file
    final id = number(resource, 'id').toInt();
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(studentContentRepositoryProvider)
          .libraryDownloadUrl(id);
      final savedPath = await DownloadService.downloadUrl(
        url: url,
        fileName:
            '${text(resource, 'title')}.${text(resource, 'file_type', fallback: 'pdf')}',
      );
      if (mounted && savedPath != null) {
        _toast(context, 'تم تحميل الملف بنجاح');
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _LibraryActionRow extends StatelessWidget {
  const _LibraryActionRow({
    required this.controller,
    required this.isGrid,
    required this.onSearch,
    required this.onToggleView,
    required this.onFilter,
  });

  final TextEditingController controller;
  final bool isGrid;
  final VoidCallback onSearch;
  final VoidCallback onToggleView;
  final VoidCallback onFilter;

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
              controller: controller,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: 'ابحث في المكتبة المشتركة...',
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

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.slate600),
      ),
    );
  }
}

class _SharedResourceCard extends StatelessWidget {
  const _SharedResourceCard({
    required this.resource,
    required this.onImport,
    required this.onPreview,
    this.canImport = true,
  });
  final Map<String, dynamic> resource;
  final VoidCallback onImport;
  final VoidCallback onPreview;
  final bool canImport;

  @override
  Widget build(BuildContext context) {
    final cat = text(resource, 'category');
    final color = _getSharedCategoryColor(cat);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getSharedCategoryIcon(cat), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(resource, 'title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  text(
                    asMap(resource['subject']),
                    'name',
                    fallback: 'مورد مكتبة',
                  ),
                  style: TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPreview,
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.slate500,
                ),
              ),
              IconButton(
                onPressed: onImport,
                icon: Opacity(
                  opacity: canImport ? 1.0 : 0.5,
                  child: const Icon(
                    Icons.library_add_rounded,
                    size: 20,
                    color: AppColors.primary,
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

class _SharedResourceGridCard extends StatelessWidget {
  const _SharedResourceGridCard({
    required this.resource,
    required this.onImport,
    required this.onPreview,
    this.canImport = true,
  });
  final Map<String, dynamic> resource;
  final VoidCallback onImport;
  final VoidCallback onPreview;
  final bool canImport;

  @override
  Widget build(BuildContext context) {
    final cat = text(resource, 'category');
    final color = _getSharedCategoryColor(cat);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_getSharedCategoryIcon(cat), color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text(resource, 'title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  text(asMap(resource['subject']), 'name', fallback: 'مادة'),
                  style: TextStyle(color: AppColors.slate500, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('عرض', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.slate600,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
              IconButton(
                onPressed: onImport,
                icon: Opacity(
                  opacity: canImport ? 1.0 : 0.5,
                  child: const Icon(
                    Icons.library_add_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _getSharedCategoryColor(String cat) {
  return switch (cat) {
    'lectures' => const Color(0xFF0D9488),
    'exams' => const Color(0xFFE11D48),
    'summaries' => const Color(0xFFD97706),
    'references' => const Color(0xFF2563EB),
    _ => const Color(0xFF64748B),
  };
}

IconData _getSharedCategoryIcon(String cat) {
  return switch (cat) {
    'lectures' => Icons.description_rounded,
    'exams' => Icons.assignment_rounded,
    'summaries' => Icons.auto_stories_rounded,
    'references' => Icons.menu_book_rounded,
    _ => Icons.insert_drive_file_rounded,
  };
}

class DelegateRemindersScreen extends ConsumerWidget {
  const DelegateRemindersScreen({super.key});
  static const route = DelegateRoutes.reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_delegateRemindersProvider('all'));

    const canCreate = true;
    const canUpdate = true;
    const canDelete = true;

    return DelegateShell(
      currentIndex: 10,
      title: 'التذكيرات',
      floatingActionButton: _AddReminderFAB(
        onPressed: () => _reminderSheet(context, ref),
        isEnabled: canCreate,
        onUnauthorized: () => _showNoPermissionSnackBar(context),
      ),
      child: _AsyncBody<Map<String, dynamic>>(
        state: state,
        onRetry: () => ref.invalidate(_delegateRemindersProvider('all')),
        builder: (data) {
          final reminders = asList(data['reminders']).map(asMap).toList();

          final now = DateTime.now();
          final today = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            return date != null &&
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          }).toList();

          final tomorrowDate = now.add(const Duration(days: 1));
          final tomorrow = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            return date != null &&
                date.year == tomorrowDate.year &&
                date.month == tomorrowDate.month &&
                date.day == tomorrowDate.day;
          }).toList();

          final upcoming = reminders.where((r) {
            final date = DateTime.tryParse(text(r, 'event_date'));
            final dayAfterTomorrow = now.add(const Duration(days: 2));
            return date != null &&
                date.isAfter(
                  dayAfterTomorrow.subtract(const Duration(seconds: 1)),
                );
          }).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_delegateRemindersProvider('all')),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _RemindersHero(count: reminders.length),
                const SizedBox(height: 24),
                if (reminders.isEmpty)
                  const _EmptyState('لا توجد تذكيرات حالياً. استمتع بوقتك! 🎉')
                else ...[
                  if (today.isNotEmpty) ...[
                    const _TimelineSection(
                      title: 'اليوم',
                      icon: Icons.today_rounded,
                      color: AppColors.rose,
                    ),
                    ...today.map((r) => _DelegateReminderCard(item: r)),
                    const SizedBox(height: 16),
                  ],
                  if (tomorrow.isNotEmpty) ...[
                    const _TimelineSection(
                      title: 'غداً',
                      icon: Icons.event_available_rounded,
                      color: AppColors.orange,
                    ),
                    ...tomorrow.map(
                      (r) => _DelegateReminderCard(
                        item: r,
                        canUpdate: canUpdate,
                        canDelete: canDelete,
                        onUnauthorized: () =>
                            _showNoPermissionSnackBar(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    const _TimelineSection(
                      title: 'قريباً',
                      icon: Icons.upcoming_rounded,
                      color: AppColors.royalBlue,
                    ),
                    ...upcoming.map(
                      (r) => _DelegateReminderCard(
                        item: r,
                        canUpdate: canUpdate,
                        canDelete: canDelete,
                        onUnauthorized: () =>
                            _showNoPermissionSnackBar(context),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RemindersHero extends StatelessWidget {
  const _RemindersHero({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalBlue,
            AppColors.royalBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لديك $count تذكيرات مجدولة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'نظم مهام الدفعة وابقَ على اطلاع دائم بكل جديد.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold,
            size: 32,
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(color: color.withValues(alpha: 0.1), thickness: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DelegateReminderCard extends ConsumerWidget {
  const _DelegateReminderCard({
    required this.item,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> item;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = text(item, 'title', fallback: 'تذكير');
    final desc = text(item, 'description');
    final priority = text(item, 'priority', fallback: 'medium');
    final color = _getPriorityColor(priority);
    final icon = _getReminderIcon(title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.midnight,
                              ),
                            ),
                            if (desc.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  desc,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(text(item, 'event_date')),
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: canUpdate
                                ? () => _reminderSheet(context, ref, item: item)
                                : onUnauthorized,
                            icon: Opacity(
                              opacity: canUpdate ? 1.0 : 0.5,
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: AppColors.slate400,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: canDelete
                                ? () => _delete(
                                    context,
                                    () => ref
                                        .read(delegateRepositoryProvider)
                                        .deleteReminder(
                                          number(item, 'id').toInt(),
                                        ),
                                    () => ref.invalidate(
                                      _delegateRemindersProvider('all'),
                                    ),
                                  )
                                : onUnauthorized,
                            icon: Opacity(
                              opacity: canDelete ? 1.0 : 0.5,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) => switch (p) {
    'high' => AppColors.danger,
    'medium' => AppColors.orange,
    _ => AppColors.success,
  };

  IconData _getReminderIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('اختبار') || t.contains('امتحان'))
      return Icons.menu_book_rounded;
    if (t.contains('تكليف') || t.contains('واجب'))
      return Icons.assignment_rounded;
    if (t.contains('محاضرة') || t.contains('درس')) return Icons.school_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatTime(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AddReminderFAB extends StatelessWidget {
  const _AddReminderFAB({
    required this.onPressed,
    this.isEnabled = true,
    this.onUnauthorized,
  });
  final VoidCallback onPressed;
  final bool isEnabled;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(
                alpha: isEnabled ? 0.35 : 0.1,
              ),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: isEnabled ? onPressed : onUnauthorized,
          backgroundColor: AppColors.royalBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.add_alert_rounded,
            color: Colors.white,
            size: 24,
          ),
          label: const Text(
            'تذكير جديد',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class DelegateAnnouncementsScreen extends ConsumerStatefulWidget {
  const DelegateAnnouncementsScreen({super.key});
  static const route = DelegateRoutes.announcements;

  @override
  ConsumerState<DelegateAnnouncementsScreen> createState() =>
      _DelegateAnnouncementsScreenState();
}

class _DelegateAnnouncementsScreenState
    extends ConsumerState<DelegateAnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _search = TextEditingController();
  final List<Map<String, String>> _tabs = [
    {'value': 'all', 'label': 'الكل', 'icon': '📣'},
    {'value': 'urgent', 'label': 'عاجل', 'icon': '🔥'},
    {'value': 'academic', 'label': 'أكاديمي', 'icon': '🎓'},
    {'value': 'general', 'label': 'عام', 'icon': '📢'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  ({String? query, String? category}) get _query => (
    query: _search.text.trim(),
    category: _tabs[_tabController.index]['value'],
  );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    const canCreate = true;
    const canUpdate = true;
    const canDelete = true;

    return DelegateShell(
      currentIndex: 11,
      title: 'إعلانات الدفعة',
      floatingActionButton: _AddAnnouncementFAB(
        onPressed: () => _newsSheet(context, ref),
        isEnabled: canCreate,
        onUnauthorized: () => _showNoPermissionSnackBar(context),
      ),
      child: _AsyncBody<Map<String, dynamic>>(
        state: ref.watch(_delegateAnnouncementsProvider(query)),
        onRetry: () => ref.invalidate(_delegateAnnouncementsProvider(query)),
        builder: (data) {
          final stats = asMap(data['stats']);
          final meta = asMap(data['announcements']);
          final list = asList(meta['data']).map(asMap).toList();

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _AnnouncementsHero(stats: stats),
                        const SizedBox(height: 20),
                        _AnnouncementsSearchRow(
                          controller: _search,
                          onChanged: (v) => setState(() {}),
                          onClear: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    child: Container(
                      color: AppColors.ghostWhite,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        indicatorColor: Colors.transparent,
                        dividerColor: Colors.transparent,
                        labelPadding: const EdgeInsets.only(right: 8),
                        tabs: _tabs.map((t) {
                          final isSelected =
                              _tabs[_tabController.index]['value'] ==
                              t['value'];
                          return Tab(
                            child: _CategoryChip(
                              label: t['label']!,
                              icon: t['icon']!,
                              isSelected: isSelected,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
              body: list.isEmpty
                  ? const _EmptyState('لا توجد إعلانات حالياً في هذا القسم.')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) => _AnnouncementFeedCard(
                        item: list[index],
                        canUpdate: canUpdate,
                        canDelete: canDelete,
                        onUnauthorized: () =>
                            _showNoPermissionSnackBar(context),
                        onEdit: () =>
                            _newsSheet(context, ref, item: list[index]),
                        onDelete: () => _delete(
                          context,
                          () => ref
                              .read(delegateRepositoryProvider)
                              .deleteAnnouncement(
                                number(list[index], 'id').toInt(),
                              ),
                          () => ref.invalidate(_delegateAnnouncementsProvider),
                        ),
                        onPin: () {
                          _togglePin(context, ref, list[index]);
                        },
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    try {
      await ref
          .read(delegateRepositoryProvider)
          .toggleAnnouncementPin(number(item, 'id').toInt());
      ref.invalidate(_delegateAnnouncementsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _AnnouncementsHero extends StatelessWidget {
  const _AnnouncementsHero({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.rose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لديك ${number(stats, 'total')} إعلانات',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'ابقَ دفعتك على اطلاع دائم بآخر المستجدات.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
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
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroStatItem(
                label: 'عاجل',
                value: number(stats, 'urgent').toString(),
                icon: Icons.local_fire_department_rounded,
              ),
              _HeroStatItem(
                label: 'مثبت',
                value: number(stats, 'pinned').toString(),
                icon: Icons.push_pin_rounded,
              ),
              _HeroStatItem(
                label: 'أكاديمي',
                value: number(stats, 'academic').toString(),
                icon: Icons.school_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementFeedCard extends StatelessWidget {
  const _AnnouncementFeedCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    final category = text(item, 'category');
    final isPinned = boolVal(item['is_pinned']);
    final hasAttachment = text(item, 'attachment_path').isNotEmpty;
    final color = _getNewsColor(category);

    return InkWell(
      onTap: () {
        final url = item['attachment_url'];
        if (url != null && url.isNotEmpty) {
          DownloadService.previewFile(url, item['title'] ?? 'المرفق');
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryLabel(category),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isPinned) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.push_pin_rounded,
                      color: AppColors.royalBlue,
                      size: 14,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatRelativeTime(text(item, 'created_at')),
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NewsActionMenu(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onPin: onPin,
                    isPinned: isPinned,
                    canUpdate: canUpdate,
                    canDelete: canDelete,
                    onUnauthorized: onUnauthorized,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text(item, 'title'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text(item, 'content'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate600,
                      height: 1.5,
                    ),
                  ),
                  if (hasAttachment) ...[
                    const SizedBox(height: 12),
                    _AttachmentPreview(
                      path: text(item, 'attachment_path'),
                      type: text(item, 'attachment_type'),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNewsColor(String cat) {
    switch (cat) {
      case 'urgent':
        return AppColors.rose;
      case 'academic':
        return AppColors.royalBlue;
      default:
        return AppColors.orange;
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'urgent':
        return 'عاجل جداً';
      case 'academic':
        return 'أكاديمي';
      case 'general':
        return 'عام';
      default:
        return 'إعلان';
    }
  }

  String _formatRelativeTime(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${date.day}/${date.month}';
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.path, required this.type});
  final String path;
  final String type;

  @override
  Widget build(BuildContext context) {
    final isImage = type == 'image';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(
            isImage ? Icons.image_rounded : Icons.description_rounded,
            color: AppColors.royalBlue,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'عرض المرفق',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.slate400,
          ),
        ],
      ),
    );
  }
}

class _NewsActionMenu extends StatelessWidget {
  const _NewsActionMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.isPinned,
    this.canUpdate = true,
    this.canDelete = true,
    this.onUnauthorized,
  });
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final bool isPinned;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.slate400,
        size: 20,
      ),
      onSelected: (v) {
        if (v == 'edit') {
          if (canUpdate) {
            onEdit();
          } else {
            onUnauthorized?.call();
          }
        }
        if (v == 'delete') {
          if (canDelete) {
            onDelete();
          } else {
            onUnauthorized?.call();
          }
        }
        if (v == 'pin') {
          if (canUpdate) {
            onPin();
          } else {
            onUnauthorized?.call();
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Opacity(
            opacity: canUpdate ? 1.0 : 0.5,
            child: Row(
              children: [
                Icon(
                  isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(isPinned ? 'إلغاء التثبيت' : 'تثبيت الإعلان'),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Opacity(
            opacity: canUpdate ? 1.0 : 0.5,
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 18),
                SizedBox(width: 12),
                Text('تعديل'),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Opacity(
            opacity: canDelete ? 1.0 : 0.5,
            child: const Row(
              children: [
                Icon(Icons.delete_rounded, size: 18, color: AppColors.rose),
                SizedBox(width: 12),
                Text('حذف', style: TextStyle(color: AppColors.rose)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsSearchRow extends StatelessWidget {
  const _AnnouncementsSearchRow({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ابحث في الإعلانات...',
          hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.slate400,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _AddAnnouncementFAB extends StatelessWidget {
  const _AddAnnouncementFAB({
    required this.onPressed,
    this.isEnabled = true,
    this.onUnauthorized,
  });
  final VoidCallback onPressed;
  final bool isEnabled;
  final VoidCallback? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: isEnabled ? 0.35 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: isEnabled ? onPressed : onUnauthorized,
          backgroundColor: AppColors.orange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.campaign_rounded,
            color: Colors.white,
            size: 26,
          ),
          label: const Text(
            'نشر إعلان',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
  });
  final String label;
  final String icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.orange : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColors.slate200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.slate700,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper functions for parsing
bool boolVal(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return fallback;
}
