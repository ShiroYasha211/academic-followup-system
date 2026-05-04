part of 'student_content_screens.dart';

class StudentSubjectsScreen extends ConsumerWidget {
  const StudentSubjectsScreen({super.key});

  static const route = '/student/subjects';
  static String detailsPath(int id) => '/student/subjects/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_subjectsProvider);
    return StudentShell(
      currentIndex: 3,
      title: 'المقررات الدراسية',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_subjectsProvider),
        builder: (subjects) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_subjectsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _HeroPanel(
                title: '${subjects.length} مقرراً دراسياً',
                subtitle:
                    'استعرض مقرراتك الدراسية، تفاصيل الحضور، والدرجات الأكاديمية.',
                icon: Icons.auto_stories_rounded,
                colors: const [Color(0xFF4338CA), Color(0xFF0EA5E9)],
              ),
              const SizedBox(height: 24),
              const SectionTitle(
                title: 'قائمة المواد المسجلة',
                icon: Icons.library_books_rounded,
              ),
              const SizedBox(height: 16),
              if (subjects.isEmpty)
                const EmptyState(
                  message: 'لا توجد مقررات مرتبطة بحسابك حالياً.',
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
                          : text(subject, 'doctor_name', fallback: 'لم يحدد بعد')),
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
        ),
      ),
    );
  }
}
