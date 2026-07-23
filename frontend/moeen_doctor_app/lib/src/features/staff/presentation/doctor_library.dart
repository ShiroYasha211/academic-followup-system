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
                          _LibraryHeaderV3(
                            onUpload: () => _showUpload(uploadSubjects),
                          ),
                          const SizedBox(height: 14),
                          _LibraryToolbarV3(
                            search: _search,
                            isGrid: _isGrid,
                            subjectId: _subjectId,
                            fileType: _fileType,
                            myUploads: _myUploads,
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
                        color: const Color(0xFFF8FAFE),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(4),
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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.royalBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            tabs: _categories
                                .map(
                                  (e) => Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        e.$2,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
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
                        child: _DocEmpty('لا توجد ملفات في هذا التصنيف حاليا.'),
                      );
                    }

                    if (_isGrid) {
                      final flattenedFiles = visibleGroups.expand((group) {
                        final resList = _docList(group['resources']);
                        final subjectMap = _docMap(group['subject']);
                        final subjectName = _docText(
                          subjectMap['name'],
                          'مادة',
                        );
                        return resList.map(
                          (res) => {
                            ..._docMap(res),
                            'subject_name': subjectName,
                          },
                        );
                      }).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: flattenedFiles.length,
                        itemBuilder: (context, index) {
                          final fileItem = flattenedFiles[index];
                          return _LibraryGridCardV3(
                            item: fileItem,
                            onTap: () => _showResourceDetails(fileItem),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemCount: visibleGroups.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _LibrarySubjectGroupCardV3(
                            group: visibleGroups[index],
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
                color: Colors.black.withValues(alpha: 0.12),
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
      title: 'تصفية ملفات المكتبة',
      icon: Icons.tune_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int?>(
              initialValue: subject,
              isExpanded: true,
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
              decoration: InputDecoration(
                labelText: 'تصفية حسب المادة',
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل المواد الدراسية'),
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
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: type,
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
              decoration: InputDecoration(
                labelText: 'نوع مستند الملف',
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('كل الامتدادات')),
                DropdownMenuItem(value: 'pdf', child: Text('ملفات PDF')),
                DropdownMenuItem(value: 'word', child: Text('مستندات Word')),
                DropdownMenuItem(
                  value: 'powerpoint',
                  child: Text('عروض PowerPoint'),
                ),
                DropdownMenuItem(value: 'excel', child: Text('جداول Excel')),
              ],
              onChanged: (value) => setLocal(() => type = value ?? 'all'),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text(
                  'عرض ملفاتي المرفوعة فقط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.midnight,
                  ),
                ),
                value: mine,
                activeThumbColor: AppColors.royalBlue,
                onChanged: (value) => setLocal(() => mine = value),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'تطبيق خيارات الفلترة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
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
      title: 'رفع مستند للمكتبة',
      icon: Icons.cloud_upload_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'البيانات الأكاديمية للملف',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: subjectId,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'المادة الدراسية',
                      ),
                      items: subjects
                          .map(
                            (item) => DropdownMenuItem(
                              value: _docInt(item['id']),
                              child: Text(_docText(item['name'])),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setLocal(() => subjectId = value),
                      validator: (value) =>
                          value == null ? 'اختر المادة الدراسية.' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'التصنيف الرئيسي',
                            ),
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
                              DropdownMenuItem(
                                value: 'exams',
                                child: Text('نماذج'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('أخرى'),
                              ),
                            ],
                            onChanged: (value) =>
                                setLocal(() => category = value ?? 'lectures'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: subCategory,
                            style: const TextStyle(
                              color: AppColors.midnight,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
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
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('أخرى'),
                              ),
                            ],
                            onChanged: (value) => setLocal(
                              () => subCategory = value ?? 'theoretical',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'محتوى وتفاصيل المستند',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'عنوان الملف',
                      ),
                      validator: (value) => _docText(value).isEmpty
                          ? 'اكتب عنوان الملف بشكل صحيح.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: semester,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'الفصل الدراسي / الترم',
                            ),
                            validator: (value) => _docText(value).isEmpty
                                ? 'اكتب معلومات الترم.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lecturer,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'المحاضر / الدكتور',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: visibility,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'صلاحيات ظهور الملف',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'batch',
                          child: Text('الدفعة الدراسية'),
                        ),
                        DropdownMenuItem(
                          value: 'college',
                          child: Text('الكلية بالكامل'),
                        ),
                        DropdownMenuItem(
                          value: 'everyone',
                          child: Text('الجميع (عام)'),
                        ),
                      ],
                      onChanged: (value) =>
                          setLocal(() => visibility = value ?? 'batch'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'وصف إضافي للملف',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.isNotEmpty) {
                    setLocal(() => file = result.files.first);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: file != null
                        ? AppColors.success.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: file != null
                          ? AppColors.success
                          : AppColors.slate200,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        file != null
                            ? Icons.check_circle_rounded
                            : Icons.attach_file_rounded,
                        color: file != null
                            ? AppColors.success
                            : AppColors.slate500,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file?.name ?? 'اضغط لاختيار مستند من جهازك',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: file != null
                                ? AppColors.success
                                : AppColors.slate700,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  if (file?.path == null) {
                    _docSnack(
                      ctx,
                      'الرجاء اختيار مستند أولا.',
                      color: AppColors.warning,
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: const Text(
                  'رفع وبث الملف للمكتبة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
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
      _docSnack(
        context,
        'تم رفع المستند وبثه للمكتبة بنجاح.',
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showResourceDetails(_Json item) async {
    final type = _docText(item['file_type']);
    final colorsAndIcon = _getFileColorsAndIcon(type);
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل ملف المكتبة',
      icon: colorsAndIcon.$3,
      color: colorsAndIcon.$1,
      child: _ResourceDetailsPanelV3(
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
      if (url.isEmpty) {
        throw const ApiException('رابط تحميل المستند غير متاح حاليا.');
      }
      final fileName = _docFileName(item);
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: fileName,
        section: 'SharedLibrary',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل المستند',
        message: 'تم حفظ الملف بنجاح في المسار:\n${result.path}',
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
      title: 'المستند غير محمل',
      message:
          'هذا الملف غير موجود على جهازك حاليا، هل تريد تحميله وفتحه الآن؟',
      confirmLabel: 'نعم، تحميل الآن',
      icon: Icons.download_rounded,
      color: AppColors.royalBlue,
    );
    if (ok) await _downloadResource(item);
  }
}

class _LibraryHeaderV3 extends StatelessWidget {
  const _LibraryHeaderV3({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            end: -24,
            top: -24,
            child: Icon(
              Icons.local_library_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المكتبة التعليمية المشتركة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مستودع الموارد والملفات المشتركة لجميع الكليات والمواد.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onUpload,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 22,
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

class _LibraryToolbarV3 extends StatelessWidget {
  const _LibraryToolbarV3({
    required this.search,
    required this.isGrid,
    required this.subjectId,
    required this.fileType,
    required this.myUploads,
    required this.onSearch,
    required this.onFilter,
    required this.onUpload,
    required this.onToggleView,
  });

  final TextEditingController search;
  final bool isGrid;
  final int? subjectId;
  final String fileType;
  final bool myUploads;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onUpload;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters =
        subjectId != null || fileType != 'all' || myUploads;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن ملف أو مادة دراسية...',
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
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onToggleView,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.slate100,
            foregroundColor: AppColors.royalBlue,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(
            isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            size: 20,
          ),
          tooltip: isGrid ? 'عرض القائمة' : 'عرض الشبكة',
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: onFilter,
          style: IconButton.styleFrom(
            backgroundColor: hasActiveFilters
                ? AppColors.royalBlue.withValues(alpha: 0.12)
                : AppColors.slate100,
            foregroundColor: hasActiveFilters
                ? AppColors.royalBlue
                : AppColors.slate600,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: hasActiveFilters
                  ? const BorderSide(color: AppColors.royalBlue, width: 1.2)
                  : BorderSide.none,
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'فلاتر إضافية',
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          onPressed: onUpload,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.royalBlue,
            foregroundColor: Colors.white,
            fixedSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          tooltip: 'رفع ملف جديد',
        ),
      ],
    );
  }
}

class _LibrarySubjectGroupCardV3 extends StatelessWidget {
  const _LibrarySubjectGroupCardV3({
    required this.group,
    required this.onResourceTap,
  });

  final _Json group;
  final ValueChanged<_Json> onResourceTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(group['subject']);
    final resources = _docList(group['resources']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalBlue.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.folder_copy_rounded,
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
                      _docText(subject['name'], 'مادة دراسية'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_docText(subject['major'], 'تخصص عام')} • ${_docText(subject['level'], 'المستوى')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DocPill(
                '${resources.length} ملفات',
                AppColors.royalBlue,
                icon: Icons.folder_zip_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...resources.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LibraryResourceMiniTileV3(
                item: item,
                onTap: () => onResourceTap(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryResourceMiniTileV3 extends StatelessWidget {
  const _LibraryResourceMiniTileV3({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['file_type'], 'file');
    final colorsAndIcon = _getFileColorsAndIcon(type);

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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorsAndIcon.$2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(colorsAndIcon.$3, color: colorsAndIcon.$1, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docText(item['title'], 'ملف بدون عنوان'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_docText(item['category'], 'موارد')} • ${type.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.slate400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryGridCardV3 extends StatelessWidget {
  const _LibraryGridCardV3({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['file_type'], 'file');
    final colorsAndIcon = _getFileColorsAndIcon(type);
    final subjectName = _docText(item['subject_name'], '-');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorsAndIcon.$2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      colorsAndIcon.$3,
                      color: colorsAndIcon.$1,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.download_rounded,
                          size: 10,
                          color: AppColors.slate500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${_docInt(item['downloads_count'])}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _docText(item['title'], 'ملف'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.royalBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _docText(item['category'], 'أخرى'),
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorsAndIcon.$1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceDetailsPanelV3 extends StatelessWidget {
  const _ResourceDetailsPanelV3({
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
    final colorsAndIcon = _getFileColorsAndIcon(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _docText(item['title'], 'ملف'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DocPill(
              type.toUpperCase(),
              colorsAndIcon.$1,
              icon: colorsAndIcon.$3,
            ),
            _DocPill(
              _docText(item['category'], 'ملف مشترك'),
              AppColors.warning,
              icon: Icons.category_rounded,
            ),
            _DocPill(
              '${_docInt(item['downloads_count'])} تحميلاً',
              AppColors.success,
              icon: Icons.download_done_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoTileV3(
                label: 'المادة الدراسية',
                value: _docText(subject['name'], '-'),
              ),
              _InfoTileV3(
                label: 'الفصل / الترم',
                value: _docText(item['semester_info'], '-'),
              ),
              _InfoTileV3(
                label: 'المحاضر العلمي',
                value: _docText(item['lecturer_name'], '-'),
              ),
              _InfoTileV3(
                label: 'الناشر / الدكتور',
                value: _docText(uploader['name'], '-'),
              ),
              _InfoTileV3(
                label: 'وصف المستند',
                value: _docText(item['description'], '-'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppColors.slate300),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'فتح المستند',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onDownload,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'تحميل الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTileV3 extends StatelessWidget {
  const _InfoTileV3({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
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

(Color, Color, IconData) _getFileColorsAndIcon(String type) {
  final ext = type.toLowerCase();
  if (ext == 'pdf') {
    return (
      AppColors.danger,
      AppColors.danger.withValues(alpha: 0.08),
      Icons.picture_as_pdf_rounded,
    );
  } else if (ext == 'docx' || ext == 'doc') {
    return (
      AppColors.royalBlue,
      AppColors.royalBlue.withValues(alpha: 0.08),
      Icons.description_rounded,
    );
  } else if (ext == 'pptx' || ext == 'ppt') {
    return (
      AppColors.orange,
      AppColors.orange.withValues(alpha: 0.08),
      Icons.slideshow_rounded,
    );
  } else if (ext == 'xlsx' || ext == 'xls') {
    return (
      AppColors.success,
      AppColors.success.withValues(alpha: 0.08),
      Icons.table_view_rounded,
    );
  }
  return (
    AppColors.slate500,
    AppColors.slate100,
    Icons.insert_drive_file_rounded,
  );
}
