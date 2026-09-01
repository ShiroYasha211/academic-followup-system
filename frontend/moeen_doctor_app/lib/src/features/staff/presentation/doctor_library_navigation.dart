part of 'staff_screens.dart';

class DoctorLibraryNavigationScreen extends ConsumerStatefulWidget {
  const DoctorLibraryNavigationScreen({super.key});

  @override
  ConsumerState<DoctorLibraryNavigationScreen> createState() =>
      _DoctorLibraryNavigationScreenState();
}

class _DoctorLibraryNavigationScreenState
    extends ConsumerState<DoctorLibraryNavigationScreen> {
  String _type = 'shared';

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'المكتبة التعليمية',
      currentRoute: DoctorLibraryScreen.route,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'shared',
                    icon: Icon(Icons.library_books_rounded),
                    label: Text('المكتبة المشتركة'),
                  ),
                  ButtonSegment(
                    value: 'course',
                    icon: Icon(Icons.menu_book_rounded),
                    label: Text('مصادر المقرر'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          Expanded(key: ValueKey(_type), child: _browser()),
        ],
      ),
    );
  }

  Widget _browser() {
    final repository = ref.read(staffRepositoryProvider);
    final shared = _type == 'shared';
    return LibraryBrowser(
      title: shared ? 'المكتبة المشتركة' : 'مصادر المقرر',
      subtitle: shared
          ? 'تصفح المحتوى المشترك وأدر الأقسام الممنوحة لك'
          : 'موادك وملفاتها مرتبة حسب الهيكل الأكاديمي',
      accentColor: shared ? AppColors.royalBlue : const Color(0xFF0F766E),
      load: (node, search, page) async {
        final response = await repository.get(
          '/doctor/library/navigation',
          query: {
            'type': _type,
            'node': node,
            'page': page,
            'per_page': 20,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
        );
        return _docMap(_docData(response));
      },
      onDownload: (resource) => _download(repository, resource),
      onCreateNode: (spaceId, parentId, title) async {
        final data = <String, dynamic>{
          'library_space_id': spaceId,
          'title': title,
          'node_type': 'folder',
          'icon': 'folder',
        };
        if (parentId != null) data['parent_id'] = parentId;
        await repository.post('/doctor/library/manage/nodes', data);
      },
      onUpdateNode: (nodeId, title) async {
        await repository.patch('/doctor/library/manage/nodes/$nodeId', {
          'title': title,
        });
      },
      onDeleteNode: (nodeId) async {
        await repository.delete('/doctor/library/manage/nodes/$nodeId');
      },
      onReorder: (spaceId, items) async {
        await repository.post('/doctor/library/manage/nodes/reorder', {
          'library_space_id': spaceId,
          'items': items,
        });
      },
      onUpload: (nodeId, title, description, visibility, file) async {
        await repository.upload('/doctor/library/manage/resources/upload', {
          'node_id': nodeId,
          'title': title,
          if (description.isNotEmpty) 'description': description,
          'visibility': visibility,
          'file': await MultipartFile.fromFile(file.path!, filename: file.name),
        });
      },
    );
  }

  Future<void> _download(
    StaffRepository repository,
    Map<String, dynamic> resource,
  ) async {
    final id = _docInt(resource['id']);
    final title = _docText(resource['title'], 'resource');
    final extension = _docText(resource['file_type'], 'file');
    final fileName = title.toLowerCase().endsWith('.$extension')
        ? title
        : '$title.$extension';
    String url;
    if (_type == 'shared') {
      if (id <= 0) return;
      final response = await repository.get('/doctor/library/$id/download');
      url = _docText(_docMap(_docData(response))['download_url']);
      if (url.isEmpty) throw const ApiException('تعذر تجهيز رابط تحميل الملف.');
    } else {
      final path = _docText(resource['file_path']);
      if (path.isEmpty) throw const ApiException('مسار الملف غير متاح.');
      final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      final cleanPath = path.replaceFirst(RegExp(r'^/?storage/'), '');
      url = '$base/storage/$cleanPath';
    }
    final result = await DownloadService.downloadUrlToMoeenFolder(
      url: url,
      fileName: fileName,
      section: _type == 'shared' ? 'SharedLibrary' : 'CourseResources',
    );
    if (mounted) {
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل الملف',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    }
  }
}
