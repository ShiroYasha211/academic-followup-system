// ignore_for_file: dead_code, unused_element, unused_element_parameter, unused_local_variable
part of 'student_content_screens.dart';

class StudentFlashcardPacksScreen extends ConsumerStatefulWidget {
  const StudentFlashcardPacksScreen({super.key});

  @override
  ConsumerState<StudentFlashcardPacksScreen> createState() =>
      _StudentFlashcardPacksScreenState();
}

class _StudentFlashcardPacksScreenState
    extends ConsumerState<StudentFlashcardPacksScreen> {
  final _search = TextEditingController();
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_flashcardsProvider);
    return StudentShell(
      currentIndex: 15,
      title: 'حزم One Line',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePack(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('حزمة'),
        backgroundColor: AppColors.midnight,
        foregroundColor: Colors.white,
      ),
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_flashcardsProvider),
        builder: (data) {
          final stats = asMap(data['stats']);
          final packs = asList(data['packs']).map(asMap).toList();
          final filtered = _filterPacks(packs);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_flashcardsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _PacksDirectoryHero(stats: stats, packs: packs),
                const SizedBox(height: 16),
                _ShotPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          labelText: 'بحث في الحزم',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 10),
                      _PacksFilterRow(
                        value: _statusFilter,
                        options: const [
                          ('all', 'كل الحالات'),
                          ('active', 'نشطة'),
                          ('paused', 'متوقفة'),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ShotSectionHeader(
                  title: 'الحزم',
                  subtitle: '${filtered.length} من ${packs.length} حزمة',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  _ShotPanel(
                    child: _ShotEmptyBlock(
                      icon: Icons.search_off_rounded,
                      title: 'لا توجد حزم مطابقة',
                      message: 'غيّر البحث أو الفلاتر لعرض حزم أخرى.',
                    ),
                  )
                else
                  ...filtered.map(
                    (pack) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShotPackListTile(pack),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterPacks(List<Map<String, dynamic>> packs) {
    final query = _search.text.trim().toLowerCase();
    final filtered = packs.where((pack) {
      final title = text(pack, 'title').toLowerCase();
      final description = text(pack, 'description').toLowerCase();
      final mode = text(pack, 'display_mode', fallback: 'one_line');
      final active = boolValue(pack, 'is_active');
      final matchesSearch =
          query.isEmpty || title.contains(query) || description.contains(query);
      final matchesType = _typeFilter == 'all' || mode == _typeFilter;
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && active) ||
          (_statusFilter == 'paused' && !active);
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final aActive = boolValue(a, 'is_active') ? 1 : 0;
      final bActive = boolValue(b, 'is_active') ? 1 : 0;
      return bActive.compareTo(aActive);
    });
    return filtered;
  }

  Future<void> _showCreatePack(BuildContext context, WidgetRef ref) =>
      _showCreatePackSheet(context, ref);
}

