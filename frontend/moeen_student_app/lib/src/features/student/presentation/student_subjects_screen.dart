part of 'student_content_screens.dart';

class StudentSubjectsScreen extends ConsumerStatefulWidget {
  const StudentSubjectsScreen({super.key});

  static const route = '/student/subjects';
  static String detailsPath(int id) => '/student/subjects/$id';

  @override
  ConsumerState<StudentSubjectsScreen> createState() =>
      _StudentSubjectsScreenState();
}

class _StudentSubjectsScreenState extends ConsumerState<StudentSubjectsScreen> {
  int? _termId;
  int? _semesterId;

  @override
  Widget build(BuildContext context) {
    final filters = SubjectFilters(termId: _termId, semesterId: _semesterId);
    final state = ref.watch(_subjectsProvider(filters));
    return StudentShell(
      currentIndex: 3,
      title: 'المقررات الدراسية',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_subjectsProvider(filters)),
        builder: (data) {
          final subjects = asList(data['subjects']);
          final terms = asList(data['terms']).map(asMap).toList();
          final major = asMap(data['major']);
          final hasSemesters = boolValue(major, 'has_semesters');
          final selectedTerm = terms.cast<Map<String, dynamic>?>().firstWhere(
            (term) => number(term ?? const {}, 'id').toInt() == _termId,
            orElse: () => null,
          );
          final semesters = selectedTerm == null
              ? <Map<String, dynamic>>[]
              : asList(selectedTerm['semesters']).map(asMap).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_subjectsProvider(filters)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _HeroPanel(
                  title: '${subjects.length} مقررًا دراسيًا',
                  subtitle:
                      'استعرض مقرراتك الدراسية، تفاصيل الحضور، والدرجات الأكاديمية.',
                  icon: Icons.auto_stories_rounded,
                  colors: const [Color(0xFF4338CA), Color(0xFF0EA5E9)],
                ),
                const SizedBox(height: 24),
                _SubjectFiltersPanel(
                  terms: terms,
                  semesters: semesters,
                  hasSemesters: hasSemesters,
                  termId: _termId,
                  semesterId: _semesterId,
                  onTermChanged: (value) {
                    setState(() {
                      _termId = value;
                      _semesterId = null;
                    });
                  },
                  onSemesterChanged: (value) =>
                      setState(() => _semesterId = value),
                  onClear: () {
                    setState(() {
                      _termId = null;
                      _semesterId = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const SectionTitle(
                  title: 'قائمة المواد المسجلة',
                  icon: Icons.library_books_rounded,
                ),
                const SizedBox(height: 16),
                if (subjects.isEmpty)
                  const EmptyState(
                    message: 'لا توجد مقررات مرتبطة بحسابك حاليًا.',
                  )
                else
                  ...subjects.indexed.map((entry) {
                    final index = entry.$1;
                    final subject = asMap(entry.$2);
                    final doctor = asMap(subject['doctor']);
                    final term = asMap(subject['term']);
                    final semester = asMap(subject['semester']);
                    final color = _palette[index % _palette.length];
                    return _SubjectCard(
                      color: color,
                      subject: subject,
                      doctorName: text(doctor, 'name').isNotEmpty
                          ? text(doctor, 'name')
                          : (subject['doctor'] is String
                                ? subject['doctor'].toString()
                                : text(
                                    subject,
                                    'doctor_name',
                                    fallback: 'لم يحدد بعد',
                                  )),
                      termName: text(
                        term,
                        'name',
                        fallback: text(subject, 'term', fallback: ''),
                      ),
                      semesterName: text(
                        semester,
                        'name',
                        fallback: text(subject, 'semester', fallback: ''),
                      ),
                      onTap: () {
                        final id = number(subject, 'id').toInt();
                        if (id > 0) {
                          context.push(StudentSubjectsScreen.detailsPath(id));
                        }
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubjectFiltersPanel extends StatelessWidget {
  const _SubjectFiltersPanel({
    required this.terms,
    required this.semesters,
    required this.hasSemesters,
    required this.termId,
    required this.semesterId,
    required this.onTermChanged,
    required this.onSemesterChanged,
    required this.onClear,
  });

  final List<Map<String, dynamic>> terms;
  final List<Map<String, dynamic>> semesters;
  final bool hasSemesters;
  final int? termId;
  final int? semesterId;
  final ValueChanged<int?> onTermChanged;
  final ValueChanged<int?> onSemesterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final canClear = termId != null || semesterId != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: termId,
                  decoration: const InputDecoration(
                    labelText: 'الترم',
                    prefixIcon: Icon(Icons.filter_alt_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('كل الأترام'),
                    ),
                    ...terms.map(
                      (term) => DropdownMenuItem<int?>(
                        value: number(term, 'id').toInt(),
                        child: Text(text(term, 'name')),
                      ),
                    ),
                  ],
                  onChanged: onTermChanged,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: canClear ? onClear : null,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'مسح الفلاتر',
              ),
            ],
          ),
          if (hasSemesters && termId != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: semesterId,
              decoration: const InputDecoration(
                labelText: 'السيمستر',
                prefixIcon: Icon(Icons.view_week_rounded),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل السيمسترات'),
                ),
                ...semesters.map(
                  (semester) => DropdownMenuItem<int?>(
                    value: number(semester, 'id').toInt(),
                    child: Text(text(semester, 'name')),
                  ),
                ),
              ],
              onChanged: onSemesterChanged,
            ),
          ],
        ],
      ),
    );
  }
}
