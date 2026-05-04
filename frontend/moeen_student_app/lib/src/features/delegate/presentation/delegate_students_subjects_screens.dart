part of 'delegate_screens.dart';

class DelegateStudentsScreen extends ConsumerStatefulWidget {
  const DelegateStudentsScreen({super.key});
  static const route = DelegateRoutes.students;

  @override
  ConsumerState<DelegateStudentsScreen> createState() =>
      _DelegateStudentsScreenState();
}

class _DelegateStudentsScreenState
    extends ConsumerState<DelegateStudentsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(delegateStudentsProvider);

    return DelegateShell(
      currentIndex: 3,
      title: 'إدارة الطلاب',
      floatingActionButton: _PremiumAddButton(
        onPressed: () => _studentSheet(context, ref),
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(delegateStudentsProvider),
        builder: (data) {
          final allItems = asList(data['data']);
          final total = number(data, 'total').toInt();

          final items = allItems.where((item) {
            final q = _searchQuery.toLowerCase().trim();
            if (q.isEmpty) return true;
            final name = text(item, 'name').toLowerCase();
            final sn = text(item, 'student_number').toLowerCase();
            return name.contains(q) || sn.contains(q);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(delegateStudentsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _StudentsHeader(
                  total: total > 0 ? total : allItems.length,
                  active: number(data, 'active_count').toInt(),
                  male: number(data, 'male_count').toInt(),
                  onImport: () => _importOptionsDialog(context, ref),
                ),
                const SizedBox(height: 24),
                _SearchField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(
                  title: 'قائمة الطلاب',
                  icon: Icons.people_rounded,
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _EmptyState(
                    _searchQuery.isEmpty
                        ? 'لا يوجد طلاب حالياً.'
                        : 'لم يتم العثور على نتائج للبحث.',
                  )
                else ...[
                  ...items.map(
                    (raw) => _StudentCard(
                      student: asMap(raw),
                      onEdit: () =>
                          _studentSheet(context, ref, item: asMap(raw)),
                      onPermissions: () =>
                          _studentPermissionSheet(context, ref, asMap(raw)),
                      onDelete: () => _delete(
                        context,
                        () => ref
                            .read(delegateRepositoryProvider)
                            .deleteStudent(number(raw, 'id').toInt()),
                        () => ref.invalidate(delegateStudentsProvider),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _importOptionsDialog(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'خيارات الاستيراد الجماعي',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر الطريقة المناسبة لإضافة الطلاب',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              _ImportOptionCard(
                title: 'تحميل قالب البيانات',
                subtitle: 'قم بتحميل ملف Excel جاهز لتعبئته ببيانات الطلاب.',
                icon: Icons.file_download_rounded,
                color: AppColors.royalBlue,
                onTap: () {
                  Navigator.pop(context);
                  _downloadTemplate(context, ref);
                },
              ),
              const SizedBox(height: 16),
              _ImportOptionCard(
                title: 'رفع ملف البيانات (CSV)',
                subtitle: 'اختر ملف البيانات من جهازك لرفعه مباشرة.',
                icon: Icons.upload_file_rounded,
                color: AppColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _importCsv(context, ref);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ImportOptionCard extends StatelessWidget {
  const _ImportOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (result == null || result.files.single.path == null) return;

  await _run(
    context,
    () => ref
        .read(delegateRepositoryProvider)
        .importStudents(result.files.single.path!),
    after: () => ref.invalidate(delegateStudentsProvider),
  );
}

Future<void> _downloadTemplate(BuildContext context, WidgetRef ref) async {
  try {
    final bytes = await ref.read(delegateRepositoryProvider).downloadTemplate();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/students_template.csv');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (context.mounted) _showError(context, e);
  }
}

class DelegateSubjectsScreen extends ConsumerStatefulWidget {
  const DelegateSubjectsScreen({super.key});
  static const route = DelegateRoutes.subjects;

  @override
  ConsumerState<DelegateSubjectsScreen> createState() =>
      _DelegateSubjectsScreenState();
}

class _DelegateSubjectsScreenState
    extends ConsumerState<DelegateSubjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_delegateSubjectsProvider);

    return DelegateShell(
      currentIndex: 4,
      title: 'إدارة المواد',
      floatingActionButton: _PremiumAddButton(
        onPressed: () => _subjectSheet(context, ref),
        label: 'إضافة مادة جديدة',
        icon: Icons.library_add_rounded,
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_delegateSubjectsProvider),
        builder: (data) {
          final allItems = asList(data);
          final items = allItems.where((item) {
            final q = _searchQuery.toLowerCase().trim();
            if (q.isEmpty) return true;
            final name = text(item, 'name').toLowerCase();
            final code = text(item, 'code').toLowerCase();
            return name.contains(q) || code.contains(q);
          }).toList();

          // Calculate stats
          final uniqueDoctors = allItems
              .map((e) => asMap(e)['doctor_id'])
              .toSet()
              .length;
          final uniqueTerms = allItems
              .map((e) => asMap(e)['term_id'])
              .toSet()
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_delegateSubjectsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _SubjectsHeader(
                  totalSubjects: allItems.length,
                  totalDoctors: uniqueDoctors,
                  totalTerms: uniqueTerms,
                ),
                const SizedBox(height: 24),
                _SearchField(
                  hintText: 'بحث باسم المادة أو الكود...',

                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(
                  title: 'قائمة المواد الدراسية',
                  icon: Icons.book_rounded,
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _EmptyState(
                    _searchQuery.isEmpty
                        ? 'لا توجد مواد مضافة حالياً.'
                        : 'لم يتم العثور على نتائج للبحث.',
                  )
                else
                  ...items.map(
                    (item) => _SubjectCard(
                      subject: asMap(item),
                      onEdit: () =>
                          _subjectSheet(context, ref, item: asMap(item)),
                      onDelete: () => _delete(
                        context,
                        () => ref
                            .read(delegateRepositoryProvider)
                            .deleteSubject(number(item, 'id').toInt()),
                        () => ref.invalidate(_delegateSubjectsProvider),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
