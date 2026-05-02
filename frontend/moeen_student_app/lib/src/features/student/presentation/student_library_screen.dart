part of 'student_content_screens.dart';

class StudentLibraryScreen extends ConsumerStatefulWidget {
  const StudentLibraryScreen({super.key});

  static const route = '/student/library';

  @override
  ConsumerState<StudentLibraryScreen> createState() =>
      _StudentLibraryScreenState();
}

class _StudentLibraryScreenState extends ConsumerState<StudentLibraryScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late TabController _tabController;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'الكل'},
    {'value': 'lectures', 'label': 'المحاضرات'},
    {'value': 'exams', 'label': 'النماذج'},
    {'value': 'summaries', 'label': 'ملخصات'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  int? _subjectId;
  String _fileType = 'all';
  bool _myUploads = false;
  bool _busy = false;
  bool _isGrid = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  LibraryQuery get _query => (
    search: _search.text,
    subjectId: _subjectId,
    category: 'all',
    fileType: _fileType,
    myUploads: _myUploads,
    page: 1,
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
    final state = ref.watch(_libraryProvider(query));

    return StudentShell(
      currentIndex: 12,
      title: 'المكتبة المشتركة',
      child: Stack(
        children: [
          _AsyncBody(
            state: state,
            onRetry: () => ref.invalidate(_libraryProvider(query)),
            builder: (data) => _buildLayout(context, data),
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context, dynamic data) {
    final filters = data != null ? asMap(data['filters']) : <String, dynamic>{};
    final subjects = asList(filters['subjects']).map(asMap).toList();
    final canUpload = boolValue(filters, 'can_upload');
    final page = data != null ? asMap(data['resources']) : {};
    final resources = asList(page['data']).map(asMap).toList();

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CompactHeader(
                  title: 'المكتبة المشتركة',
                  subtitle: 'مراجع ومنشورات أضافها زملائك في الدفعة',
                  icon: Icons.library_books_rounded,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 16),
                _LibraryActionRow(
                  search: _search,
                  isGrid: _isGrid,
                  onSearch: () => setState(() {}),
                  onFilter: () => _showAdvancedFilters(context, subjects),
                  onUpload: canUpload
                      ? () => _showUpload(context, subjects)
                      : null,
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
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.2),
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
              : resources
                    .where((r) => text(r, 'category') == catValue)
                    .toList();

          if (filtered.isEmpty) {
            return const EmptyState(
              message: 'لا توجد ملفات في هذا التصنيف حالياً.',
              icon: Icons.folder_open_rounded,
            );
          }

          if (_isGrid) {
            return GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _CourseResourceGridCard(
                item: filtered[i],
                onDownload: () => _download(context, filtered[i]),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _CourseResourceCard(
              item: filtered[i],
              onDownload: () => _download(context, filtered[i]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final id = number(item, 'id').toInt();
    if (id <= 0) return;

    setState(() => _busy = true);
    try {
      final url = await ref
          .read(studentContentRepositoryProvider)
          .libraryDownloadUrl(id);
      if (!context.mounted) return;

      final savedPath = await DownloadService.downloadUrl(
        url: url,
        fileName: _safeFileName(item),
      );

      if (context.mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف في: $savedPath'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      ref.invalidate(_libraryProvider(_query));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showUpload(
    BuildContext context,
    List<Map<String, dynamic>> subjects,
  ) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final description = TextEditingController();
    final semester = TextEditingController();
    final lecturer = TextEditingController();
    int? subjectId = subjects.isEmpty
        ? null
        : number(subjects.first, 'id').toInt();
    String category = 'lectures';
    String visibility = 'batch';
    PlatformFile? selectedFile;
    String? fileError;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'رفع ملف للمكتبة',
      icon: Icons.cloud_upload_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب عنوان الملف.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'عنوان الملف',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: subjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المادة'),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem(
                        value: number(item, 'id').toInt(),
                        child: Text(
                          text(item, 'name'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setLocal(() => subjectId = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: _uploadCategoryOptions.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setLocal(() => category = value ?? 'lectures'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: visibility,
                      decoration: const InputDecoration(labelText: 'الظهور'),
                      items: const [
                        DropdownMenuItem(value: 'batch', child: Text('دفعتي')),
                        DropdownMenuItem(
                          value: 'college',
                          child: Text('التخصص'),
                        ),
                        DropdownMenuItem(
                          value: 'everyone',
                          child: Text('الجميع'),
                        ),
                      ],
                      onChanged: (value) =>
                          setLocal(() => visibility = value ?? 'batch'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: semester,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اكتب معلومات الترم.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'معلومات الترم',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lecturer,
                decoration: const InputDecoration(
                  labelText: 'اسم المحاضر اختياري',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف مختصر اختياري',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    withData: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setLocal(() {
                      selectedFile = result.files.first;
                      fileError = null;
                    });
                  }
                },
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(selectedFile?.name ?? 'اختيار الملف'),
              ),
              if (fileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  fileError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  if (subjectId == null) {
                    setLocal(() => fileError = 'اختر المادة أولاً.');
                    return;
                  }
                  if (selectedFile?.path == null) {
                    setLocal(() => fileError = 'اختر الملف قبل الرفع.');
                    return;
                  }
                  Navigator.pop(sheetContext, true);
                },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('رفع الملف'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;
    final file = selectedFile;
    if (subjectId == null ||
        title.text.trim().isEmpty ||
        semester.text.trim().isEmpty ||
        file?.path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أكمل العنوان والمادة والترم واختر الملف أولاً.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final message = await ref
          .read(studentContentRepositoryProvider)
          .uploadLibraryResource(
            subjectId: subjectId!,
            title: title.text.trim(),
            category: category,
            semesterInfo: semester.text.trim(),
            visibility: visibility,
            filePath: file!.path!,
            fileName: file.name,
            description: description.text,
            lecturerName: lecturer.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
      }
      ref.invalidate(_libraryProvider(_query));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showAdvancedFilters(
    BuildContext context,
    List<Map<String, dynamic>> subjects,
  ) async {
    int? subject = _subjectId;
    String type = _fileType;
    bool mine = _myUploads;

    final result = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'خيارات التصفية',
      icon: Icons.tune_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              value: subject,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'المادة'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل المواد'),
                ),
                ...subjects.map(
                  (item) => DropdownMenuItem<int?>(
                    value: number(item, 'id').toInt(),
                    child: Text(text(item, 'name')),
                  ),
                ),
              ],
              onChanged: (val) => setLocal(() => subject = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'نوع الملف'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الكل')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'docx', child: Text('Word')),
                DropdownMenuItem(value: 'pptx', child: Text('PowerPoint')),
              ],
              onChanged: (val) => setLocal(() => type = val ?? 'all'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('ملفاتي فقط'),
              value: mine,
              onChanged: (val) => setLocal(() => mine = val),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
              ),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _subjectId = subject;
        _fileType = type;
        _myUploads = mine;
      });
    }
  }
}

class _LibraryActionRow extends StatelessWidget {
  const _LibraryActionRow({
    required this.search,
    required this.isGrid,
    required this.onSearch,
    required this.onFilter,
    required this.onUpload,
    required this.onToggleView,
  });
  final TextEditingController search;
  final bool isGrid;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback? onUpload;
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
        if (onUpload != null) ...[
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.add_rounded,
            onTap: onUpload!,
            color: AppColors.royalBlue,
            iconColor: Colors.white,
          ),
        ],
      ],
    );
  }
}
