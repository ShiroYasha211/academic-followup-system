part of 'staff_screens.dart';

class DoctorLibraryScreen extends ConsumerStatefulWidget {
  const DoctorLibraryScreen({super.key});

  static const route = '/doctor/library';

  @override
  ConsumerState<DoctorLibraryScreen> createState() =>
      _DoctorLibraryScreenState();
}

class _DoctorLibraryScreenState extends ConsumerState<DoctorLibraryScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final TabController _tabs;
  int? _subjectId;
  String _fileType = 'all';
  bool _myUploads = false;
  bool _isGrid = false;
  bool _busy = false;

  static const _categories = [
    ('all', 'الكل'),
    ('lectures', 'المحاضرات'),
    ('exams', 'النماذج'),
    ('summaries', 'ملخصات'),
    ('quizzes', 'كويزات'),
    ('other', 'أخرى'),
  ];

  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _search.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/library',
          query: {
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            if (_subjectId != null) 'subject_id': _subjectId,
            if (_fileType != 'all') 'file_type': _fileType,
            if (_myUploads) 'my_uploads': true,
            'grouped': true,
          },
        );
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'المكتبة المشتركة',
      currentRoute: DoctorLibraryScreen.route,
      child: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
              final payload = _docMap(_docData(snapshot.data ?? const {}));
              final filters = _docMap(payload['filters']);
              final subjects = _docList(filters['subjects']);
              final uploadSubjects = _docList(filters['upload_subjects']);
              final groups = _docList(payload['groups']);

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        children: [
                          _DocHero(
                            title: 'المكتبة المشتركة',
                            subtitle:
                                'ملفات وموارد تعليمية مشتركة مع إمكانية الرفع والتحميل.',
                            icon: Icons.local_library_rounded,
                            trailing: IconButton.filledTonal(
                              onPressed: () => _showUpload(uploadSubjects),
                              icon: const Icon(Icons.cloud_upload_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LibraryToolbar(
                            search: _search,
                            isGrid: _isGrid,
                            onSearch: _reload,
                            onFilter: () => _showLibraryFilters(subjects),
                            onUpload: () => _showUpload(uploadSubjects),
                            onToggleView: () =>
                                setState(() => _isGrid = !_isGrid),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DoctorSliverHeader(
                      height: 74,
                      child: Container(
                        color: AppColors.cream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.slate200.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabs,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.slate600,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: AppColors.royalBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tabs: _categories
                                .map((e) => Tab(text: e.$2))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabs,
                  children: _categories.map((cat) {
                    final visibleGroups = groups
                        .map((group) {
                          final resources = _docList(group['resources']);
                          final items = cat.$1 == 'all'
                              ? resources
                              : resources
                                    .where(
                                      (item) =>
                                          _docText(item['category']) == cat.$1,
                                    )
                                    .toList();
                          return {...group, 'resources': items};
                        })
                        .where(
                          (group) => _docList(group['resources']).isNotEmpty,
                        )
                        .toList();
                    if (visibleGroups.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: _DocEmpty('لا توجد ملفات في هذا التصنيف.'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemCount: visibleGroups.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) => _LibrarySubjectGroupCard(
                        group: visibleGroups[index],
                        compact: _isGrid,
                        onResourceTap: _showResourceDetails,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showLibraryFilters(List<_Json> subjects) async {
    int? subject = _subjectId;
    var type = _fileType;
    var mine = _myUploads;
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'فلاتر المكتبة',
      icon: Icons.tune_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              initialValue: subject,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'المادة'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل المواد'),
                ),
                ...subjects.map(
                  (item) => DropdownMenuItem<int?>(
                    value: _docInt(item['id']),
                    child: Text(_docText(item['name'])),
                  ),
                ),
              ],
              onChanged: (value) => setLocal(() => subject = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'نوع الملف'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الكل')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'docx', child: Text('Word')),
                DropdownMenuItem(value: 'pptx', child: Text('PowerPoint')),
                DropdownMenuItem(value: 'xlsx', child: Text('Excel')),
              ],
              onChanged: (value) => setLocal(() => type = value ?? 'all'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ملفاتي فقط'),
              value: mine,
              onChanged: (value) => setLocal(() => mine = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تطبيق الفلاتر'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        _subjectId = subject;
        _fileType = type;
        _myUploads = mine;
        _future = _fetch();
      });
    }
  }

  Future<void> _showUpload(List<_Json> subjects) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final semester = TextEditingController();
    final lecturer = TextEditingController();
    final description = TextEditingController();
    int? subjectId = subjects.isEmpty ? null : _docInt(subjects.first['id']);
    var category = 'lectures';
    var subCategory = 'theoretical';
    var visibility = 'batch';
    PlatformFile? file;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'رفع ملف للمكتبة',
      icon: Icons.cloud_upload_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: subjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المادة'),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem(
                        value: _docInt(item['id']),
                        child: Text(_docText(item['name'])),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setLocal(() => subjectId = value),
                validator: (value) => value == null ? 'اختر المادة.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان الملف'),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب عنوان الملف.' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'التصنيف'),
                      items: const [
                        DropdownMenuItem(
                          value: 'lectures',
                          child: Text('محاضرات'),
                        ),
                        DropdownMenuItem(
                          value: 'summaries',
                          child: Text('ملخصات'),
                        ),
                        DropdownMenuItem(
                          value: 'quizzes',
                          child: Text('كويزات'),
                        ),
                        DropdownMenuItem(value: 'exams', child: Text('نماذج')),
                        DropdownMenuItem(value: 'other', child: Text('أخرى')),
                      ],
                      onChanged: (value) =>
                          setLocal(() => category = value ?? 'lectures'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: subCategory,
                      decoration: const InputDecoration(
                        labelText: 'النوع الفرعي',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'theoretical',
                          child: Text('نظري'),
                        ),
                        DropdownMenuItem(
                          value: 'practical',
                          child: Text('عملي'),
                        ),
                        DropdownMenuItem(
                          value: 'seminar',
                          child: Text('سمنار'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('أخرى')),
                      ],
                      onChanged: (value) =>
                          setLocal(() => subCategory = value ?? 'theoretical'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: semester,
                decoration: const InputDecoration(labelText: 'معلومات الترم'),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب معلومات الترم.' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lecturer,
                decoration: const InputDecoration(labelText: 'اسم المحاضر'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: visibility,
                decoration: const InputDecoration(labelText: 'الظهور'),
                items: const [
                  DropdownMenuItem(value: 'batch', child: Text('الدفعة')),
                  DropdownMenuItem(value: 'college', child: Text('الكلية')),
                  DropdownMenuItem(value: 'everyone', child: Text('الجميع')),
                ],
                onChanged: (value) =>
                    setLocal(() => visibility = value ?? 'batch'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.isNotEmpty) {
                    setLocal(() => file = result.files.first);
                  }
                },
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(file?.name ?? 'اختيار الملف'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  if (file?.path == null) {
                    _docSnack(
                      ctx,
                      'اختر الملف أولًا.',
                      color: AppColors.warning,
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('رفع الملف'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || subjectId == null || file?.path == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(staffRepositoryProvider).upload('/doctor/library/upload', {
        'subject_id': subjectId,
        'title': title.text.trim(),
        'category': category,
        'sub_category': subCategory,
        'semester_info': semester.text.trim(),
        'visibility': visibility,
        'description': description.text.trim(),
        'lecturer_name': lecturer.text.trim(),
        'file': await MultipartFile.fromFile(file!.path!, filename: file!.name),
      });
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم رفع الملف بنجاح.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResourceDetails(_Json item) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الملف',
      icon: _docFileIcon(_docText(item['file_type'])),
      color: AppColors.royalBlue,
      child: _ResourceDetailsPanel(
        item: item,
        onDownload: () => _downloadResource(item),
        onOpen: () => _openResource(item),
      ),
    );
  }

  Future<void> _downloadResource(_Json item) async {
    final id = _docInt(item['id']);
    if (id <= 0) return;
    setState(() => _busy = true);
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get('/doctor/library/$id/download');
      final url = _docText(_docMap(_docData(response))['download_url']);
      if (url.isEmpty) throw const ApiException('رابط التحميل غير متاح.');
      final fileName = _docFileName(item);
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: fileName,
        section: 'SharedLibrary',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل الملف',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openResource(_Json item) async {
    final path = await DownloadService.openMoeenFile(
      fileName: _docFileName(item),
      section: 'SharedLibrary',
    );
    if (!mounted || path != null) return;
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'الملف غير محمل',
      message: 'هذا الملف غير موجود على الجهاز. هل تريد تحميله الآن؟',
      confirmLabel: 'تحميل الآن',
      icon: Icons.download_rounded,
      color: AppColors.royalBlue,
    );
    if (ok) await _downloadResource(item);
  }
}

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
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
  final VoidCallback onUpload;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            decoration: const InputDecoration(
              hintText: 'ابحث عن ملف أو مادة...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onToggleView,
          icon: Icon(
            isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
          ),
        ),
        IconButton.filledTonal(
          onPressed: onFilter,
          icon: const Icon(Icons.tune_rounded),
        ),
        IconButton.filled(
          onPressed: onUpload,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _LibrarySubjectGroupCard extends StatelessWidget {
  const _LibrarySubjectGroupCard({
    required this.group,
    required this.compact,
    required this.onResourceTap,
  });

  final _Json group;
  final bool compact;
  final ValueChanged<_Json> onResourceTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(group['subject']);
    final resources = _docList(group['resources']);
    final shownResources = compact ? resources.take(4).toList() : resources;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(subject['name'], 'مادة دراسية'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_docText(subject['major'], '-')} - ${_docText(subject['level'], '-')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                '${resources.length} ملف',
                AppColors.teal,
                icon: Icons.folder_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...shownResources.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LibraryResourceMiniTile(
                item: item,
                onTap: () => onResourceTap(item),
              ),
            ),
          ),
          if (compact && resources.length > shownResources.length)
            Text(
              '+ ${resources.length - shownResources.length} ملفات أخرى في هذه المادة',
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryResourceMiniTile extends StatelessWidget {
  const _LibraryResourceMiniTile({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['file_type'], 'file');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            Icon(_docFileIcon(type), color: AppColors.royalBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docText(item['title'], 'ملف'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_docText(item['category'], '-')} - ${type.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LibraryListCard extends StatelessWidget {
  const _LibraryListCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(item['subject']);
    final type = _docText(item['file_type'], 'file');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_docFileIcon(type), color: AppColors.royalBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docText(item['title'], 'ملف'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${_docText(subject['name'], '-')} • ${type.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LibraryGridCard extends StatelessWidget {
  const _LibraryGridCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['file_type'], 'file');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_docFileIcon(type), color: AppColors.royalBlue, size: 38),
            const Spacer(),
            Text(
              _docText(item['title'], 'ملف'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            _DocPill(type.toUpperCase(), AppColors.royalBlue),
          ],
        ),
      ),
    );
  }
}

class _ResourceDetailsPanel extends StatelessWidget {
  const _ResourceDetailsPanel({
    required this.item,
    required this.onDownload,
    required this.onOpen,
  });

  final _Json item;
  final VoidCallback onDownload;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(item['subject']);
    final uploader = _docMap(item['uploader']);
    final type = _docText(item['file_type'], 'file');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _docText(item['title'], 'ملف'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DocPill(
              type.toUpperCase(),
              AppColors.royalBlue,
              icon: _docFileIcon(type),
            ),
            _DocPill(_docText(item['category'], '-'), AppColors.warning),
            _DocPill(
              '${_docInt(item['downloads_count'])} تحميل',
              AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoTile(label: 'المادة', value: _docText(subject['name'], '-')),
        _InfoTile(label: 'الترم', value: _docText(item['semester_info'], '-')),
        _InfoTile(
          label: 'المحاضر',
          value: _docText(item['lecturer_name'], '-'),
        ),
        _InfoTile(label: 'الناشر', value: _docText(uploader['name'], '-')),
        _InfoTile(label: 'الوصف', value: _docText(item['description'], '-')),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('فتح'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: const Text('تحميل'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DoctorSliverHeader extends SliverPersistentHeaderDelegate {
  const _DoctorSliverHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DoctorSliverHeader oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

