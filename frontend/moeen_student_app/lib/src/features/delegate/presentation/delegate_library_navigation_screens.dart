part of 'delegate_screens.dart';

class DelegateLibraryNavigationScreen extends ConsumerWidget {
  const DelegateLibraryNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DelegateShell(
      currentIndex: 9,
      title: 'المكتبة المشتركة',
      child: _DelegateLibraryBrowser(type: 'shared', ref: ref),
    );
  }
}

class DelegateResourcesNavigationScreen extends ConsumerWidget {
  const DelegateResourcesNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DelegateShell(
      currentIndex: 8,
      title: 'مصادر المقرر',
      child: _DelegateLibraryBrowser(type: 'course', ref: ref),
    );
  }
}

class _DelegateLibraryBrowser extends StatelessWidget {
  const _DelegateLibraryBrowser({required this.type, required this.ref});

  final String type;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(delegateRepositoryProvider);
    final shared = type == 'shared';
    return LibraryBrowser(
      title: shared ? 'المكتبة المشتركة' : 'مصادر المقرر',
      subtitle: shared
          ? 'محتوى منظم حسب المستوى والفصل والمادة'
          : 'أدر ملفات دفعتك ضمن الأقسام الممنوحة لك',
      accentColor: shared ? AppColors.royalBlue : const Color(0xFF0F766E),
      load: (node, search, page) => repository.libraryNavigation(
        type: type,
        node: node,
        search: search,
        page: page,
      ),
      onDownload: (resource) => _download(context, repository, resource),
      onCreateNode: (spaceId, parentId, title) => repository.createLibraryNode(
        spaceId: spaceId,
        parentId: parentId,
        title: title,
      ),
      onUpdateNode: repository.updateLibraryNode,
      onDeleteNode: repository.deleteLibraryNode,
      onReorder: repository.reorderLibraryNodes,
      onUpload: (nodeId, title, description, visibility, file) {
        return repository.uploadLibraryNodeResource(
          nodeId: nodeId,
          title: title,
          description: description,
          visibility: visibility,
          filePath: file.path!,
          fileName: file.name,
        );
      },
    );
  }

  Future<void> _download(
    BuildContext context,
    DelegateRepository repository,
    Map<String, dynamic> resource,
  ) async {
    final id = int.tryParse(resource['id']?.toString() ?? '') ?? 0;
    final title = resource['title']?.toString() ?? 'resource';
    final extension = resource['file_type']?.toString() ?? 'file';
    final fileName = title.toLowerCase().endsWith('.$extension')
        ? title
        : '$title.$extension';
    String url;
    if (type == 'shared') {
      if (id <= 0) return;
      url = await repository.libraryDownloadUrl(id);
    } else {
      final path = resource['file_path']?.toString() ?? '';
      if (path.isEmpty) throw const ApiException('مسار الملف غير متاح.');
      url = absoluteUrl(path.startsWith('/storage/') ? path : '/storage/$path');
    }
    final saved = await DownloadService.downloadUrlToMoeenFolder(
      url: url,
      fileName: fileName,
      section: type == 'shared' ? 'SharedLibrary' : 'CourseResources',
    );
    if (context.mounted && saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحميل الملف بنجاح.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
