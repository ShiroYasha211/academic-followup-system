part of 'student_content_screens.dart';

class StudentLibraryNavigationScreen extends ConsumerWidget {
  const StudentLibraryNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudentShell(
      currentIndex: 12,
      title: 'المكتبة المشتركة',
      child: _StudentLibraryBrowser(type: 'shared', ref: ref),
    );
  }
}

class StudentResourcesNavigationScreen extends ConsumerWidget {
  const StudentResourcesNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StudentShell(
      currentIndex: 11,
      title: 'مصادر المقرر',
      child: _StudentLibraryBrowser(type: 'course', ref: ref),
    );
  }
}

class _StudentLibraryBrowser extends StatelessWidget {
  const _StudentLibraryBrowser({required this.type, required this.ref});

  final String type;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(studentContentRepositoryProvider);
    final shared = type == 'shared';
    return LibraryBrowser(
      title: shared ? 'المكتبة المشتركة' : 'مصادر المقرر',
      subtitle: shared
          ? 'تصفح المواد والأقسام والملفات التعليمية المشتركة'
          : 'انتقل من المستوى إلى المادة ثم اختر القسم المطلوب',
      accentColor: shared ? AppColors.royalBlue : const Color(0xFF0F766E),
      gradient: shared
          ? const LinearGradient(
              colors: [
                AppColors.midnight,
                AppColors.royalBlueDark,
                AppColors.royalBlue,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            )
          : const LinearGradient(
              colors: [
                Color(0xFF134E4A),
                Color(0xFF0F766E),
                Color(0xFF14B8A6),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
      heroIcon: shared
          ? Icons.library_books_rounded
          : Icons.folder_special_rounded,
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
    StudentContentRepository repository,
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
      url = absoluteUrl(path.startsWith('storage/') ? path : 'storage/$path');
    }
    final saved = await DownloadService.downloadUrlToMoeenFolder(
      url: url,
      fileName: fileName,
      section: type == 'shared' ? 'SharedLibrary' : 'CourseResources',
    );
    if (context.mounted && saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم حفظ $fileName بنجاح',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'فتح الملف',
            textColor: AppColors.gold,
            onPressed: () async {
              try {
                await OpenFilex.open(saved);
              } catch (_) {}
            },
          ),
        ),
      );
    }
  }
}
