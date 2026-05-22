part of 'staff_screens.dart';

typedef _Json = Map<String, dynamic>;

_Json _docMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<_Json> _docList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

String _docText(Object? value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _shortDocText(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}...';
}

num _docNum(Object? value, [num fallback = 0]) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

int _docInt(Object? value, [int fallback = 0]) =>
    _docNum(value, fallback).toInt();

bool _docBool(Object? value) =>
    value == true ||
    value == 1 ||
    value?.toString() == '1' ||
    value?.toString() == 'true';

Object? _docData(Map<String, dynamic> response) => response['data'] ?? response;

String _docDate(Object? raw) {
  final text = _docText(raw);
  if (text.length >= 10) return text.substring(0, 10);
  return text.isEmpty ? '-' : text;
}

String _docDateTimeForInput(Object? raw) {
  final text = _docText(raw);
  if (text.isEmpty) return '';
  return text.replaceFirst('T', ' ').split('.').first;
}

Color _docStatusColor(String status) {
  switch (status) {
    case 'published':
    case 'accepted':
    case 'approved':
    case 'completed':
      return AppColors.success;
    case 'closed':
    case 'overdue':
    case 'rejected':
      return AppColors.danger;
    case 'scheduled':
    case 'pending':
    case 'draft':
      return AppColors.warning;
    default:
      return AppColors.royalBlue;
  }
}

String _docStatusLabel(String status) {
  switch (status) {
    case 'published':
      return 'منشور';
    case 'scheduled':
      return 'مجدول';
    case 'draft':
      return 'مسودة';
    case 'closed':
      return 'مغلق';
    case 'accepted':
      return 'مقبول';
    case 'rejected':
      return 'مرفوض';
    case 'pending':
      return 'بانتظار المراجعة';
    case 'approved':
      return 'معتمد';
    case 'overdue':
      return 'متأخر';
    default:
      return status.isEmpty ? '-' : status;
  }
}

IconData _docFileIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('pdf')) return Icons.picture_as_pdf_rounded;
  if (value.contains('doc')) return Icons.description_rounded;
  if (value.contains('xls')) return Icons.table_chart_rounded;
  if (value.contains('ppt')) return Icons.slideshow_rounded;
  if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(value)) {
    return Icons.image_rounded;
  }
  if (value.contains('zip') || value.contains('rar')) {
    return Icons.folder_zip_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

String _docFileName(_Json item, {String fallback = 'moeen-file'}) {
  final title = _docText(
    item['title'] ?? item['attachment_name'] ?? item['file_name'],
    fallback,
  ).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final type = _docText(item['file_type']).replaceAll('.', '');
  if (type.isEmpty || title.toLowerCase().endsWith('.$type')) return title;
  return '$title.$type';
}

void _docSnack(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
}

Future<void> _docErrorDialog(BuildContext context, Object error) async {
  if (staffIsSubscriptionRequired(error)) {
    await showStaffSubscriptionRequiredDialog(context, error);
    return;
  }
  final message = error is ApiException ? error.message : error.toString();
  await showMoeenInfoDialog(
    context: context,
    title: 'حدث خطأ',
    message: message,
    icon: Icons.error_outline_rounded,
    color: AppColors.danger,
  );
}

class _DocHero extends StatelessWidget {
  const _DocHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          ...?bottom == null ? null : [bottom!],
        ],
      ),
    );
  }
}

class _DocMetric extends StatelessWidget {
  const _DocMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      height: 98,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: -18,
              top: -18,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 22,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocEmpty extends StatelessWidget {
  const _DocEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.slate400, size: 38),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocPill extends StatelessWidget {
  const _DocPill(this.label, this.color, {this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocFilterChoice {
  const _DocFilterChoice({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _DocFilterPanel extends StatelessWidget {
  const _DocFilterPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.royalBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DocSubjectPicker extends StatelessWidget {
  const _DocSubjectPicker({
    required this.subjects,
    required this.subjectId,
    required this.onChanged,
  });

  final List<_Json> subjects;
  final int? subjectId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: subjectId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.slate500,
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.midnight,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Text('كل المواد'),
                ],
              ),
            ),
            ...subjects.map(
              (subject) => DropdownMenuItem<int?>(
                value: _docInt(subject['id']),
                child: Row(
                  children: [
                    const Icon(
                      Icons.book_rounded,
                      color: AppColors.royalBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _docText(subject['name']),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DocSegmentFilter extends StatelessWidget {
  const _DocSegmentFilter({
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String value;
  final List<_DocFilterChoice> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: choices.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final choice = choices[index];
          final selected = value == choice.value;
          return InkWell(
            onTap: () => onChanged(choice.value),
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? choice.color.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? choice.color : AppColors.slate200,
                  width: selected ? 1.4 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: choice.color.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_rounded : choice.icon,
                    color: selected ? choice.color : AppColors.slate500,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    choice.label,
                    style: TextStyle(
                      color: selected ? choice.color : AppColors.slate600,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocPanelTabBar extends StatelessWidget {
  const _DocPanelTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.slate100.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.slate600,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.royalBlue, AppColors.teal],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        tabs: tabs,
      ),
    );
  }
}

class DoctorAssignmentsScreen extends ConsumerStatefulWidget {
  const DoctorAssignmentsScreen({super.key});

  static const route = '/doctor/assignments';

  @override
  ConsumerState<DoctorAssignmentsScreen> createState() =>
      _DoctorAssignmentsScreenState();
}

class _DoctorAssignmentsScreenState
    extends ConsumerState<DoctorAssignmentsScreen> {
  String _status = 'all';
  int? _subjectId;
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/assignments',
          query: {
            if (_status != 'all') 'status': _status,
            if (_subjectId != null) 'subject_id': _subjectId,
          },
        );
  }

  void _reload() {
    setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'التكاليف',
      currentRoute: DoctorAssignmentsScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.royalBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () async {
          final data = await _future;
          if (!context.mounted) return;
          final subjects = _docList(
            _docMap(_docMap(_docData(data))['filters'])['subjects'],
          );
          await _showAssignmentForm(subjects: subjects);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'تكليف جديد',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error!);
          }
          final payload = _docMap(_docData(snapshot.data ?? const {}));
          final stats = _docMap(payload['stats']);
          final filters = _docMap(payload['filters']);
          final subjects = _docList(filters['subjects']);
          final assignments = _docList(payload['assignments']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'إدارة التكاليف',
                  subtitle: 'إنشاء التكاليف ومراجعة تسليمات الطلاب وتصديرها.',
                  icon: Icons.assignment_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showAssignmentForm(subjects: subjects),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'كل التكاليف',
                      value: _docText(stats['total'], '0'),
                      color: AppColors.royalBlue,
                      icon: Icons.assignment_rounded,
                    ),
                    _DocMetric(
                      label: 'القادمة',
                      value: _docText(stats['upcoming'], '0'),
                      color: AppColors.success,
                      icon: Icons.upcoming_rounded,
                    ),
                    _DocMetric(
                      label: 'المتأخرة',
                      value: _docText(stats['overdue'], '0'),
                      color: AppColors.danger,
                      icon: Icons.warning_rounded,
                    ),
                    _DocMetric(
                      label: 'التسليمات',
                      value: _docText(stats['submissions'], '0'),
                      color: AppColors.warning,
                      icon: Icons.upload_file_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AssignmentsFilters(
                  subjects: subjects,
                  subjectId: _subjectId,
                  status: _status,
                  onSubjectChanged: (value) {
                    setState(() {
                      _subjectId = value;
                      _future = _fetch();
                    });
                  },
                  onStatusChanged: (value) {
                    setState(() {
                      _status = value;
                      _future = _fetch();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  const _DocEmpty('لا توجد تكاليف مطابقة للفلاتر الحالية.')
                else
                  ...assignments.map(
                    (assignment) => _AssignmentCard(
                      assignment: assignment,
                      onDetails: () => context.push(
                        DoctorAssignmentDetailsScreen.path(
                          _docInt(assignment['id']),
                        ),
                      ),
                      onEdit: () => _showAssignmentForm(
                        subjects: subjects,
                        assignment: assignment,
                      ),
                      onDelete: () => _deleteAssignment(assignment),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAssignmentForm({
    required List<_Json> subjects,
    _Json? assignment,
  }) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: _docText(assignment?['title']));
    final description = TextEditingController(
      text: _docText(assignment?['description']),
    );
    final dueDate = TextEditingController(
      text: _docDate(assignment?['due_date']),
    );
    int? subjectId = _docInt(assignment?['subject_id']) > 0
        ? _docInt(assignment?['subject_id'])
        : (subjects.isNotEmpty ? _docInt(subjects.first['id']) : null);
    var requiresSubmission = _docBool(assignment?['requires_submission']);

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: assignment == null ? 'إضافة تكليف' : 'تعديل التكليف',
      icon: Icons.assignment_add,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Form(
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
                      (subject) => DropdownMenuItem(
                        value: _docInt(subject['id']),
                        child: Text(_docText(subject['name'])),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setLocal(() => subjectId = value),
                validator: (value) => value == null ? 'اختر المادة.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'عنوان التكليف'),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب عنوان التكليف.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'الوصف'),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب وصف التكليف.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dueDate,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate:
                        DateTime.tryParse(dueDate.text) ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setLocal(() {
                      dueDate.text = picked.toIso8601String().substring(0, 10);
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'تاريخ التسليم',
                  prefixIcon: Icon(Icons.calendar_month_rounded),
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اختر تاريخ التسليم.' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('يتطلب تسليم ملف من الطالب'),
                value: requiresSubmission,
                onChanged: (value) =>
                    setLocal(() => requiresSubmission = value),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(sheetContext, true);
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || subjectId == null) return;
    try {
      final payload = {
        if (assignment == null) 'subject_id': subjectId,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'due_date': dueDate.text.trim(),
        'requires_submission': requiresSubmission,
      };
      if (assignment == null) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/assignments', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/assignments/${assignment['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حفظ التكليف بنجاح.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteAssignment(_Json assignment) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف التكليف',
      message: 'هل تريد حذف هذا التكليف؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/assignments/${assignment['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف التكليف.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorAssignmentDetailsScreen extends ConsumerStatefulWidget {
  const DoctorAssignmentDetailsScreen({super.key, required this.assignmentId});

  static const route = '/doctor/assignments/:assignmentId';

  final int assignmentId;

  static String path(int assignmentId) => '/doctor/assignments/$assignmentId';

  @override
  ConsumerState<DoctorAssignmentDetailsScreen> createState() =>
      _DoctorAssignmentDetailsScreenState();
}

class _DoctorAssignmentDetailsScreenState
    extends ConsumerState<DoctorAssignmentDetailsScreen> {
  late Future<_Json> _future = _fetch();

  Future<_Json> _fetch() async {
    final response = await ref
        .read(staffRepositoryProvider)
        .get('/doctor/assignments/${widget.assignmentId}');
    return _docMap(_docMap(_docData(response))['assignment']);
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'تفاصيل التكليف',
      currentRoute: DoctorAssignmentsScreen.route,
      child: FutureBuilder<_Json>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final assignment = snapshot.data ?? const <String, dynamic>{};

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _AssignmentDetailsHeader(assignment: assignment),
                const SizedBox(height: 16),
                _AssignmentSubmissionsPanel(
                  assignment: assignment,
                  showHeader: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentDetailsHeader extends StatelessWidget {
  const _AssignmentDetailsHeader({required this.assignment});

  final _Json assignment;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(assignment['subject']);
    final due = DateTime.tryParse(_docText(assignment['due_date']));
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final requiresSubmission = _docBool(assignment['requires_submission']);

    return _DocHero(
      title: _docText(assignment['title'], 'تكليف'),
      subtitle: _docText(
        assignment['description'],
        'لا يوجد وصف لهذا التكليف.',
      ),
      icon: Icons.assignment_turned_in_rounded,
      trailing: _DocPill(
        isOverdue ? 'متأخر' : 'قادم',
        isOverdue ? AppColors.danger : AppColors.success,
        icon: isOverdue ? Icons.warning_rounded : Icons.event_available_rounded,
      ),
      bottom: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DocPill(
              _docText(subject['name'], '-'),
              AppColors.royalBlue,
              icon: Icons.menu_book_rounded,
            ),
            _DocPill(
              'موعد التسليم: ${_docDate(assignment['due_date'])}',
              AppColors.warning,
              icon: Icons.calendar_month_rounded,
            ),
            _DocPill(
              '${_docInt(assignment['submissions_count'])} تسليم',
              AppColors.teal,
              icon: Icons.upload_file_rounded,
            ),
            _DocPill(
              requiresSubmission ? 'يتطلب تسليم ملف' : 'بدون ملف مطلوب',
              requiresSubmission ? AppColors.goldDeep : AppColors.slate500,
              icon: requiresSubmission
                  ? Icons.task_alt_rounded
                  : Icons.visibility_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsFilters extends StatelessWidget {
  const _AssignmentsFilters({
    required this.subjects,
    required this.subjectId,
    required this.status,
    required this.onSubjectChanged,
    required this.onStatusChanged,
  });

  final List<_Json> subjects;
  final int? subjectId;
  final String status;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return _DocFilterPanel(
      title: 'تصفية التكاليف',
      icon: Icons.tune_rounded,
      children: [
        _DocSubjectPicker(
          subjects: subjects,
          subjectId: subjectId,
          onChanged: onSubjectChanged,
        ),
        const SizedBox(height: 12),
        _DocSegmentFilter(
          value: status,
          onChanged: onStatusChanged,
          choices: const [
            _DocFilterChoice(
              value: 'all',
              label: 'الكل',
              icon: Icons.apps_rounded,
              color: AppColors.royalBlue,
            ),
            _DocFilterChoice(
              value: 'upcoming',
              label: 'قادمة',
              icon: Icons.upcoming_rounded,
              color: AppColors.success,
            ),
            _DocFilterChoice(
              value: 'overdue',
              label: 'متأخرة',
              icon: Icons.warning_rounded,
              color: AppColors.danger,
            ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final _Json assignment;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(assignment['subject']);
    final due = DateTime.tryParse(_docText(assignment['due_date']));
    final isOverdue = due != null && due.isBefore(DateTime.now());
    final statusColor = isOverdue ? AppColors.danger : AppColors.success;
    final requiresSubmission = _docBool(assignment['requires_submission']);

    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.royalBlue,
                        AppColors.royalBlueDark.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.royalBlue.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(assignment['title'], 'تكليف'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _docText(subject['name'], '-'),
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
                  isOverdue ? 'متأخر' : 'قادم',
                  statusColor,
                  icon: isOverdue
                      ? Icons.warning_rounded
                      : Icons.event_available_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'موعد التسليم: ${_docDate(assignment['due_date'])}',
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  '${_docInt(assignment['submissions_count'])} تسليم',
                  AppColors.royalBlue,
                  icon: Icons.upload_file_rounded,
                ),
                _DocPill(
                  requiresSubmission ? 'يتطلب تسليم' : 'بدون تسليم',
                  requiresSubmission ? AppColors.warning : AppColors.slate500,
                  icon: requiresSubmission
                      ? Icons.task_alt_rounded
                      : Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('التسليمات'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded),
                  color: AppColors.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentSubmissionsPanel extends ConsumerStatefulWidget {
  const _AssignmentSubmissionsPanel({
    required this.assignment,
    this.showHeader = true,
  });

  final _Json assignment;
  final bool showHeader;

  @override
  ConsumerState<_AssignmentSubmissionsPanel> createState() =>
      _AssignmentSubmissionsPanelState();
}

class _AssignmentSubmissionsPanelState
    extends ConsumerState<_AssignmentSubmissionsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _exporting = false;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/assignments/${widget.assignment['id']}/submissions');
  }

  void _reload() => setState(() => _future = _fetch());

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download(
            '/doctor/assignments/${widget.assignment['id']}/submissions/export',
          );
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'assignment_submissions_${widget.assignment['id']}.csv',
        section: 'AssignmentReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التصدير',
        message: 'تم حفظ ملف التسليمات في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _downloadSubmissionFile(_Json submission) async {
    final url = _docText(submission['file_url']);
    if (url.isEmpty) {
      await showMoeenInfoDialog(
        context: context,
        title: 'لا يوجد مرفق',
        message: 'هذا التسليم لا يحتوي على ملف قابل للتحميل.',
        icon: Icons.info_rounded,
        color: AppColors.warning,
      );
      return;
    }

    try {
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: _docText(submission['file_name'], 'assignment_submission'),
        section: 'AssignmentSubmissions',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: result.opened ? 'تم فتح المرفق' : 'تم تحميل المرفق',
        message: result.opened
            ? 'تم تحميل وفتح ملف التسليم بنجاح.\n${result.path}'
            : 'تم حفظ ملف التسليم في:\n${result.path}',
        icon: result.opened
            ? Icons.check_circle_rounded
            : Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final submissions = _docList(_docData(snapshot.data ?? const {}));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              Text(
                _docText(widget.assignment['title'], 'تكليف'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _docText(widget.assignment['description'], '-'),
                style: const TextStyle(color: AppColors.slate500),
              ),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.table_chart_rounded),
              label: const Text('تصدير التسليمات'),
            ),
            const SizedBox(height: 16),
            if (submissions.isEmpty)
              const _DocEmpty('لا توجد تسليمات لهذا التكليف.')
            else
              ...submissions.map(
                (submission) => _SubmissionCard(
                  submission: submission,
                  onReview: () => _showReview(submission),
                  onDownload: () => _downloadSubmissionFile(submission),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showReview(_Json submission) async {
    final grade = TextEditingController(text: _docText(submission['grade']));
    final feedback = TextEditingController(
      text: _docText(submission['feedback']),
    );
    var status = _docText(submission['status'], 'accepted');

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'مراجعة التسليم',
      icon: Icons.rate_review_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (sheetContext, setLocal) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SubmissionReviewSummary(
              submission: submission,
              onDownload: () => _downloadSubmissionFile(submission),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'accepted', label: Text('قبول')),
                ButtonSegment(value: 'rejected', label: Text('رفض')),
              ],
              selected: {status == 'rejected' ? 'rejected' : 'accepted'},
              onSelectionChanged: (value) =>
                  setLocal(() => status = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: grade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الدرجة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedback,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'الملاحظات'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('حفظ المراجعة'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/submissions/${submission['id']}/review', {
            'status': status,
            'feedback': feedback.text.trim(),
            'grade': int.tryParse(grade.text.trim()),
          });
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم تقييم التسليم.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.onReview,
    required this.onDownload,
  });

  final _Json submission;
  final VoidCallback onReview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(submission['student']);
    final status = _docText(submission['status'], 'pending');
    final fileName = _shortDocText(_docText(submission['file_name']), 34);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _docText(student['name'], 'طالب'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _DocPill(_docStatusLabel(status), _docStatusColor(status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _docText(student['student_number'], '-'),
            style: const TextStyle(color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocPill(
                'الدرجة: ${_docText(submission['grade'], '-')}',
                AppColors.royalBlue,
              ),
              _DocPill(
                'تاريخ: ${_docDate(submission['submitted_at'])}',
                AppColors.warning,
              ),
              if (_docText(submission['file_name']).isNotEmpty)
                _DocPill(
                  fileName,
                  AppColors.teal,
                  icon: Icons.attach_file_rounded,
                ),
            ],
          ),
          if (_docText(submission['notes']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _docText(submission['notes']),
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
          if (_docText(submission['feedback']).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_docText(submission['feedback'])),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (_docText(submission['file_url']).isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text('فتح المرفق'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text('مراجعة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionReviewSummary extends StatelessWidget {
  const _SubmissionReviewSummary({
    required this.submission,
    required this.onDownload,
  });

  final _Json submission;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(submission['student']);
    final hasFile = _docText(submission['file_url']).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                foregroundColor: AppColors.royalBlue,
                child: Text(
                  _docText(student['name'], '?').characters.first,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(student['name'], 'طالب'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _docText(student['student_number'], '-'),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                _docStatusLabel(_docText(submission['status'], 'pending')),
                _docStatusColor(_docText(submission['status'], 'pending')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DocPill(
                'تاريخ التسليم: ${_docDate(submission['submitted_at'])}',
                AppColors.warning,
                icon: Icons.calendar_month_rounded,
              ),
              _DocPill(
                _docBool(submission['is_late']) ? 'متأخر' : 'ضمن الموعد',
                _docBool(submission['is_late'])
                    ? AppColors.danger
                    : AppColors.success,
                icon: _docBool(submission['is_late'])
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
              ),
              _DocPill(
                'الدرجة: ${_docText(submission['grade'], '-')}',
                AppColors.royalBlue,
                icon: Icons.grade_rounded,
              ),
              if (_docText(submission['formatted_file_size']).isNotEmpty)
                _DocPill(
                  _docText(submission['formatted_file_size']),
                  AppColors.teal,
                  icon: Icons.data_object_rounded,
                ),
            ],
          ),
          if (_docText(submission['notes']).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'ملاحظات الطالب',
              style: TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(_docText(submission['notes'])),
          ],
          if (_docText(submission['feedback']).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'ملاحظات الدكتور الحالية',
              style: TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(_docText(submission['feedback'])),
          ],
          if (hasFile) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.file_download_rounded),
              label: Text(_docText(submission['file_name'], 'تحميل المرفق')),
            ),
          ],
        ],
      ),
    );
  }
}

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
          },
        );
  }

  void _reload() => setState(() => _future = _fetch());

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
              final page = _docMap(payload['resources']);
              final resources = _docList(page['data']);

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
                              onPressed: () => _showUpload(subjects),
                              icon: const Icon(Icons.cloud_upload_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _LibraryToolbar(
                            search: _search,
                            isGrid: _isGrid,
                            onSearch: _reload,
                            onFilter: () => _showLibraryFilters(subjects),
                            onUpload: () => _showUpload(subjects),
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
                    final items = cat.$1 == 'all'
                        ? resources
                        : resources
                              .where(
                                (item) => _docText(item['category']) == cat.$1,
                              )
                              .toList();
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: _DocEmpty('لا توجد ملفات في هذا التصنيف.'),
                      );
                    }
                    if (_isGrid) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _LibraryGridCard(
                          item: items[index],
                          onTap: () => _showResourceDetails(items[index]),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _LibraryListCard(
                        item: items[index],
                        onTap: () => _showResourceDetails(items[index]),
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

class DoctorAnnouncementsScreen extends ConsumerStatefulWidget {
  const DoctorAnnouncementsScreen({super.key});

  static const route = '/doctor/announcements';

  @override
  ConsumerState<DoctorAnnouncementsScreen> createState() =>
      _DoctorAnnouncementsScreenState();
}

class _DoctorAnnouncementsScreenState
    extends ConsumerState<DoctorAnnouncementsScreen> {
  String _type = 'all';
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/announcements',
          query: {if (_type != 'all') 'type': _type},
        );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'إعلاناتي',
      currentRoute: DoctorAnnouncementsScreen.route,
      floatingActionButton: _AnnouncementFloatingButton(
        onPressed: () async {
          final data = await _future;
          if (!context.mounted) return;
          final subjects = _docList(_docMap(data['filters'])['subjects']);
          await _showAnnouncementForm(subjects: subjects);
        },
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final response = snapshot.data ?? const <String, dynamic>{};
          final subjects = _docList(_docMap(response['filters'])['subjects']);
          final announcements = _docList(response['data']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'إعلاناتي',
                  subtitle: 'إعلانات وتحذيرات وتنبيهات الكويزات الخاصة بموادك.',
                  icon: Icons.campaign_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showAnnouncementForm(subjects: subjects),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                _DocFilterPanel(
                  title: 'تصفية الإعلانات',
                  icon: Icons.tune_rounded,
                  children: [
                    _DocSegmentFilter(
                      value: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value;
                          _future = _fetch();
                        });
                      },
                      choices: const [
                        _DocFilterChoice(
                          value: 'all',
                          label: 'الكل',
                          icon: Icons.apps_rounded,
                          color: AppColors.royalBlue,
                        ),
                        _DocFilterChoice(
                          value: 'announcement',
                          label: 'إعلان',
                          icon: Icons.campaign_rounded,
                          color: AppColors.royalBlue,
                        ),
                        _DocFilterChoice(
                          value: 'warning',
                          label: 'تحذير',
                          icon: Icons.warning_rounded,
                          color: AppColors.danger,
                        ),
                        _DocFilterChoice(
                          value: 'quiz_alert',
                          label: 'كويز',
                          icon: Icons.quiz_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (announcements.isEmpty)
                  const _DocEmpty('لا توجد إعلانات في هذا التصنيف.')
                else
                  ...announcements.map(
                    (announcement) => _AnnouncementCard(
                      announcement: announcement,
                      onTap: () =>
                          _showAnnouncementDetails(announcement, subjects),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAnnouncementDetails(
    _Json announcement,
    List<_Json> subjects,
  ) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الإعلان',
      icon: Icons.campaign_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _AnnouncementDetailsPanel(
        announcement: announcement,
        onEdit: () async {
          Navigator.pop(context);
          await _showAnnouncementForm(
            subjects: subjects,
            announcement: announcement,
          );
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteAnnouncement(announcement);
        },
        onAttachment: () => _downloadAnnouncementAttachment(announcement),
      ),
    );
  }

  Future<void> _showAnnouncementForm({
    required List<_Json> subjects,
    _Json? announcement,
  }) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: _docText(announcement?['title']));
    final content = TextEditingController(
      text: _docText(announcement?['content']),
    );
    final publishedAt = TextEditingController(
      text: _docDateTimeForInput(announcement?['published_at']),
    );
    int? subjectId = _docInt(announcement?['subject_id']) > 0
        ? _docInt(announcement?['subject_id'])
        : (subjects.isNotEmpty ? _docInt(subjects.first['id']) : null);
    var type = _docText(announcement?['type'], 'announcement');
    PlatformFile? attachment;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: announcement == null ? 'إنشاء إعلان' : 'تعديل الإعلان',
      icon: Icons.campaign_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        announcement == null
                            ? Icons.campaign_rounded
                            : Icons.edit_note_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement == null
                                ? 'إنشاء إعلان جديد'
                                : 'تعديل الإعلان',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'حدد المادة والنوع ثم اكتب رسالة واضحة للطلاب.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DocFilterPanel(
                title: 'بيانات الإعلان',
                icon: Icons.tune_rounded,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: subjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المادة',
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                    items: subjects
                        .map(
                          (subject) => DropdownMenuItem(
                            value: _docInt(subject['id']),
                            child: Text(_docText(subject['name'])),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setLocal(() => subjectId = value),
                    validator: (value) => value == null ? 'اختر المادة.' : null,
                  ),
                  const SizedBox(height: 12),
                  _DocSegmentFilter(
                    value: type,
                    onChanged: (value) => setLocal(() => type = value),
                    choices: const [
                      _DocFilterChoice(
                        value: 'announcement',
                        label: 'إعلان',
                        icon: Icons.campaign_rounded,
                        color: AppColors.royalBlue,
                      ),
                      _DocFilterChoice(
                        value: 'warning',
                        label: 'تحذير',
                        icon: Icons.warning_rounded,
                        color: AppColors.danger,
                      ),
                      _DocFilterChoice(
                        value: 'quiz_alert',
                        label: 'كويز',
                        icon: Icons.quiz_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DocFilterPanel(
                title: 'محتوى الإعلان',
                icon: Icons.edit_note_rounded,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) =>
                        _docText(value).isEmpty ? 'اكتب عنوان الإعلان.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: content,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'المحتوى',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (value) =>
                        _docText(value).isEmpty ? 'اكتب محتوى الإعلان.' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DocFilterPanel(
                title: 'النشر والمرفقات',
                icon: Icons.attach_file_rounded,
                children: [
                  TextField(
                    controller: publishedAt,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ النشر اختياري',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.isNotEmpty) {
                        setLocal(() => attachment = result.files.first);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.attach_file_rounded,
                              color: AppColors.teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              attachment?.name ?? 'إرفاق ملف اختياري',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.midnight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.upload_file_rounded,
                            color: AppColors.slate400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('حفظ الإعلان'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || subjectId == null) return;
    try {
      final payload = <String, dynamic>{
        'subject_id': subjectId,
        'type': type,
        'title': title.text.trim(),
        'content': content.text.trim(),
        if (publishedAt.text.trim().isNotEmpty)
          'published_at': publishedAt.text.trim(),
        if (attachment?.path != null)
          'attachment': await MultipartFile.fromFile(
            attachment!.path!,
            filename: attachment!.name,
          ),
      };
      if (announcement == null) {
        await ref
            .read(staffRepositoryProvider)
            .upload('/doctor/announcements', payload);
      } else if (attachment?.path != null) {
        await ref
            .read(staffRepositoryProvider)
            .uploadPut('/doctor/announcements/${announcement['id']}', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/announcements/${announcement['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حفظ الإعلان.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteAnnouncement(_Json announcement) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الإعلان',
      message: 'هل تريد حذف هذا الإعلان؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/announcements/${announcement['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف الإعلان.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _downloadAnnouncementAttachment(_Json announcement) async {
    final url = _docText(announcement['attachment_url']);
    if (url.isEmpty) return;
    try {
      final fileName = _docText(
        announcement['attachment_name'],
        'announcement_${announcement['id']}',
      );
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: fileName,
        section: 'Announcements',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تحميل المرفق',
        message: 'تم حفظ المرفق في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _AnnouncementFloatingButton extends StatelessWidget {
  const _AnnouncementFloatingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 18, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'إعلان جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final _Json announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(announcement['subject']);
    final type = _docText(announcement['type'], 'announcement');
    final color = _announcementTypeColor(type);
    final isPublished = _docBool(announcement['is_published']);
    final hasAttachment = _docText(announcement['attachment_url']).isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(_announcementTypeIcon(type), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(announcement['title'], 'إعلان'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _docText(subject['name'], '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  _announcementTypeLabel(type),
                  color,
                  icon: _announcementTypeIcon(type),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Text(
                _docText(announcement['content'], '-'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docDate(announcement['published_at']),
                  AppColors.info,
                  icon: Icons.calendar_month_rounded,
                ),
                _DocPill(
                  isPublished ? 'منشور' : 'مجدول',
                  isPublished ? AppColors.success : AppColors.warning,
                  icon: isPublished
                      ? Icons.public_rounded
                      : Icons.schedule_rounded,
                ),
                if (hasAttachment)
                  _DocPill(
                    'مرفق',
                    AppColors.teal,
                    icon: Icons.attach_file_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementDetailsPanel extends StatelessWidget {
  const _AnnouncementDetailsPanel({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
    required this.onAttachment,
  });

  final _Json announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAttachment;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(announcement['subject']);
    final type = _docText(announcement['type']);
    final color = _announcementTypeColor(type);
    final hasAttachment = _docText(announcement['attachment_url']).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_announcementTypeIcon(type), color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(announcement['title'], 'إعلان'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _docText(subject['name'], '-'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DocPill(
              _announcementTypeLabel(type),
              color,
              icon: _announcementTypeIcon(type),
            ),
            _DocPill(
              _docBool(announcement['is_published']) ? 'منشور' : 'مجدول',
              _docBool(announcement['is_published'])
                  ? AppColors.success
                  : AppColors.warning,
              icon: _docBool(announcement['is_published'])
                  ? Icons.public_rounded
                  : Icons.schedule_rounded,
            ),
            _DocPill(
              _docDate(announcement['published_at']),
              AppColors.info,
              icon: Icons.calendar_month_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InquiryMessageBlock(
          title: 'محتوى الإعلان',
          icon: _announcementTypeIcon(type),
          color: color,
          text: _docText(announcement['content'], '-'),
        ),
        if (hasAttachment) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _docText(announcement['attachment_name'], 'مرفق الإعلان'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAttachment,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('تحميل'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('حذف'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _announcementTypeLabel(String type) {
  switch (type) {
    case 'warning':
      return 'تحذير';
    case 'quiz_alert':
      return 'تنبيه كويز';
    default:
      return 'إعلان';
  }
}

IconData _announcementTypeIcon(String type) {
  switch (type) {
    case 'warning':
      return Icons.warning_rounded;
    case 'quiz_alert':
      return Icons.quiz_rounded;
    default:
      return Icons.campaign_rounded;
  }
}

Color _announcementTypeColor(String type) {
  switch (type) {
    case 'warning':
      return AppColors.danger;
    case 'quiz_alert':
      return AppColors.warning;
    default:
      return AppColors.royalBlue;
  }
}

class DoctorGradesScreen extends ConsumerStatefulWidget {
  const DoctorGradesScreen({super.key});

  static const route = '/doctor/grades';

  @override
  ConsumerState<DoctorGradesScreen> createState() => _DoctorGradesScreenState();
}

class _DoctorGradesScreenState extends ConsumerState<DoctorGradesScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/grades');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'إدارة الدرجات',
      currentRoute: DoctorGradesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final subjects = _docList(_docData(snapshot.data ?? const {}));
          final totalStudents = subjects.fold<int>(
            0,
            (sum, subject) => sum + _docInt(subject['students_count']),
          );
          final graded = subjects.fold<int>(
            0,
            (sum, subject) => sum + _docInt(subject['graded_students']),
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                const _DocHero(
                  title: 'إدارة الدرجات',
                  subtitle: 'إدخال الدرجات والتصنيفات والتفويضات والاعتمادات.',
                  icon: Icons.grade_rounded,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'المواد',
                      value: subjects.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.menu_book_rounded,
                    ),
                    _DocMetric(
                      label: 'الطلاب',
                      value: totalStudents.toString(),
                      color: AppColors.info,
                      icon: Icons.groups_rounded,
                    ),
                    _DocMetric(
                      label: 'مدخل لهم',
                      value: graded.toString(),
                      color: AppColors.success,
                      icon: Icons.done_all_rounded,
                    ),
                    _DocMetric(
                      label: 'نسبة الإنجاز',
                      value: totalStudents == 0
                          ? '0%'
                          : '${((graded / totalStudents) * 100).round()}%',
                      color: AppColors.warning,
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (subjects.isEmpty)
                  const _DocEmpty('لا توجد مواد مرتبطة بحسابك.')
                else
                  ...subjects.map(
                    (subject) => _GradeSubjectCard(
                      subject: subject,
                      onTap: () => _openSubject(subject),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSubject(_Json subject) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'درجات ${_docText(subject['name'])}',
      icon: Icons.grade_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _GradeSubjectPanel(subject: subject),
    );
    _reload();
  }
}

class _GradeSubjectCard extends StatelessWidget {
  const _GradeSubjectCard({required this.subject, required this.onTap});

  final _Json subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final students = _docInt(subject['students_count']);
    final graded = _docInt(subject['graded_students']);
    final progress = students == 0 ? 0.0 : graded / students;
    final progressColor = progress >= 0.8
        ? AppColors.success
        : progress >= 0.45
        ? AppColors.warning
        : AppColors.royalBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: progressColor.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: progressColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(Icons.grade_rounded, color: progressColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(subject['name'], 'مادة'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_docText(subject['major'], '-')} • ${_docText(subject['level'], '-')}',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 9,
                color: progressColor,
                backgroundColor: AppColors.slate100,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  '$students طالب',
                  AppColors.info,
                  icon: Icons.groups_rounded,
                ),
                _DocPill(
                  '$graded مدخل',
                  AppColors.success,
                  icon: Icons.done_all_rounded,
                ),
                _DocPill(
                  'المتوسط ${_docText(subject['average_grade'], '-')}',
                  AppColors.warning,
                  icon: Icons.analytics_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSubjectPanel extends ConsumerStatefulWidget {
  const _GradeSubjectPanel({required this.subject});

  final _Json subject;

  @override
  ConsumerState<_GradeSubjectPanel> createState() => _GradeSubjectPanelState();
}

class _GradeSubjectPanelState extends ConsumerState<_GradeSubjectPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Map<String, dynamic>> _future = _fetch();
  String _search = '';
  bool _saving = false;
  final Map<int, TextEditingController> _continuous = {};
  final Map<int, TextEditingController> _final = {};
  final Map<String, TextEditingController> _categoryScores = {};

  int get _subjectId => _docInt(widget.subject['id']);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final controller in _continuous.values) {
      controller.dispose();
    }
    for (final controller in _final.values) {
      controller.dispose();
    }
    for (final controller in _categoryScores.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/grades/$_subjectId');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final students = _docList(data['students']);
        final categories = _docList(data['categories']);
        final stats = _docMap(data['stats']);
        _ensureGradeControllers(students, categories);

        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DocMetric(
                    label: 'الطلاب',
                    value: _docText(
                      stats['total_students'],
                      students.length.toString(),
                    ),
                    color: AppColors.info,
                    icon: Icons.groups_rounded,
                  ),
                  _DocMetric(
                    label: 'المتوسط',
                    value: _docText(stats['average'], '0'),
                    color: AppColors.royalBlue,
                    icon: Icons.analytics_rounded,
                  ),
                  _DocMetric(
                    label: 'أعلى درجة',
                    value: _docText(stats['highest'], '0'),
                    color: AppColors.success,
                    icon: Icons.trending_up_rounded,
                  ),
                  _DocMetric(
                    label: 'بانتظار الاعتماد',
                    value: _docText(data['pending_count'], '0'),
                    color: AppColors.warning,
                    icon: Icons.pending_actions_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DocPanelTabBar(
                controller: _tabs,
                tabs: const [
                  Tab(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 17),
                        SizedBox(width: 6),
                        Text('إدخال الدرجات'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.category_rounded, size: 17),
                        SizedBox(width: 6),
                        Text('التصنيفات'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_rounded, size: 17),
                        SizedBox(width: 6),
                        Text('التفويضات'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.fact_check_rounded, size: 17),
                        SizedBox(width: 6),
                        Text('الاعتمادات'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      children: [
                        Icon(Icons.analytics_rounded, size: 17),
                        SizedBox(width: 6),
                        Text('التقرير'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildEntryTab(students, categories),
                    _GradeCategoriesTab(
                      subjectId: _subjectId,
                      categories: categories,
                      onChanged: _reload,
                    ),
                    _GradeDelegationsTab(subjectId: _subjectId),
                    _GradeApprovalsTab(
                      subjectId: _subjectId,
                      onChanged: _reload,
                    ),
                    _GradeReportTab(subjectId: _subjectId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureGradeControllers(List<_Json> students, List<_Json> categories) {
    for (final student in students) {
      final id = _docInt(student['id']);
      _continuous.putIfAbsent(
        id,
        () => TextEditingController(text: _docText(student['continuous'])),
      );
      _final.putIfAbsent(
        id,
        () => TextEditingController(text: _docText(student['final'])),
      );
      final categoryGrades = {
        for (final grade in _docList(student['category_grades']))
          _docInt(grade['category_id']): _docText(grade['score']),
      };
      for (final category in categories) {
        final catId = _docInt(category['id']);
        _categoryScores.putIfAbsent(
          '$id:$catId',
          () => TextEditingController(text: categoryGrades[catId] ?? ''),
        );
      }
    }
  }

  Widget _buildEntryTab(List<_Json> students, List<_Json> categories) {
    final filtered = students.where((student) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return _docText(student['name']).toLowerCase().contains(q) ||
          _docText(student['student_number']).toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _DocFilterPanel(
          title: 'البحث داخل الطلاب',
          icon: Icons.search_rounded,
          children: [
            TextField(
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الطالب أو رقم القيد...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.royalBlue,
                ),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.royalBlue,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const _DocEmpty('لا يوجد طلاب مطابقون للبحث.')
        else
          ...filtered.map(
            (student) => _GradeStudentCard(
              student: student,
              categories: categories,
              continuous: _continuous[_docInt(student['id'])]!,
              finalGrade: _final[_docInt(student['id'])]!,
              categoryControllers: {
                for (final category in categories)
                  _docInt(
                    category['id'],
                  ): _categoryScores['${_docInt(student['id'])}:${_docInt(category['id'])}']!,
              },
              onNote: () => _addNote(student),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _saveGrades(students, categories),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('حفظ الدرجات'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveGrades(List<_Json> students, List<_Json> categories) async {
    setState(() => _saving = true);
    try {
      final grades = students.map((student) {
        final id = _docInt(student['id']);
        return {
          'student_id': id,
          'continuous': _continuous[id]?.text.trim(),
          'final': _final[id]?.text.trim(),
          'categories': {
            for (final category in categories)
              '${_docInt(category['id'])}':
                  _categoryScores['$id:${_docInt(category['id'])}']?.text
                      .trim(),
          },
        };
      }).toList();
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/$_subjectId',
        {'grades': grades},
      );
      if (!mounted) return;
      _reload();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم حفظ الدرجات',
        message: 'تم تحديث درجات الطلاب بنجاح.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addNote(_Json student) async {
    final note = TextEditingController();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'ملاحظة للطالب',
      icon: Icons.note_add_rounded,
      color: AppColors.royalBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_docText(student['name'])),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'الملاحظة'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (ok != true || note.text.trim().isEmpty) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/$_subjectId/note/${student['id']}',
        {'note': note.text.trim()},
      );
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم إرسال الملاحظة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _GradeStudentCard extends StatelessWidget {
  const _GradeStudentCard({
    required this.student,
    required this.categories,
    required this.continuous,
    required this.finalGrade,
    required this.categoryControllers,
    required this.onNote,
  });

  final _Json student;
  final List<_Json> categories;
  final TextEditingController continuous;
  final TextEditingController finalGrade;
  final Map<int, TextEditingController> categoryControllers;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.royalBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docText(student['name']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      _docText(student['student_number'], '-'),
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _DocPill(
                'المجموع ${_docText(student['total'], '0')}',
                AppColors.royalBlue,
                icon: Icons.functions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: continuous,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'أعمال السنة',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: finalGrade,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'النهائي',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: categoryControllers[_docInt(category['id'])],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        '${_docText(category['name'])} / ${_docText(category['max_score'])}',
                  ),
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onNote,
              icon: const Icon(Icons.note_add_rounded),
              label: const Text('إضافة ملاحظة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCategoriesTab extends ConsumerStatefulWidget {
  const _GradeCategoriesTab({
    required this.subjectId,
    required this.categories,
    required this.onChanged,
  });

  final int subjectId;
  final List<_Json> categories;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeCategoriesTab> createState() =>
      _GradeCategoriesTabState();
}

class _GradeCategoriesTabState extends ConsumerState<_GradeCategoriesTab> {
  Future<void> _add() async {
    final name = TextEditingController();
    final score = TextEditingController();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تصنيف جديد',
      icon: Icons.category_rounded,
      color: AppColors.royalBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: score,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الدرجة العظمى'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/${widget.subjectId}/categories',
        {
          'name': name.text.trim(),
          'max_score': num.tryParse(score.text.trim()),
        },
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _delete(_Json category) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف التصنيف',
      message: 'هل تريد حذف هذا التصنيف؟',
      confirmLabel: 'حذف',
      color: AppColors.danger,
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/grades/categories/${category['id']}');
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<num>(
      0,
      (sum, item) => sum + _docNum(item['max_score']),
    );
    return ListView(
      children: [
        _DocMetric(
          label: 'مجموع التصنيفات',
          value: '$total / 40',
          color: total > 40 ? AppColors.danger : AppColors.royalBlue,
          icon: Icons.calculate_rounded,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة تصنيف'),
        ),
        const SizedBox(height: 12),
        if (widget.categories.isEmpty)
          const _DocEmpty('لا توجد تصنيفات بعد.')
        else
          ...widget.categories.map(
            (category) => ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.white,
              title: Text(_docText(category['name'])),
              subtitle: Text('الدرجة: ${_docText(category['max_score'])}'),
              trailing: IconButton(
                onPressed: () => _delete(category),
                icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradeDelegationsTab extends ConsumerStatefulWidget {
  const _GradeDelegationsTab({required this.subjectId});

  final int subjectId;

  @override
  ConsumerState<_GradeDelegationsTab> createState() =>
      _GradeDelegationsTabState();
}

class _GradeDelegationsTabState extends ConsumerState<_GradeDelegationsTab> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/delegations');

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final categories = _docList(data['categories']);
        final students = _docList(data['students']);
        if (categories.isEmpty) {
          return const _DocEmpty('أنشئ تصنيفات الدرجات قبل التفويض.');
        }
        return ListView(
          children: categories
              .map(
                (category) => _DelegationCategoryCard(
                  category: category,
                  students: students,
                  onChanged: _reload,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DelegationCategoryCard extends ConsumerStatefulWidget {
  const _DelegationCategoryCard({
    required this.category,
    required this.students,
    required this.onChanged,
  });

  final _Json category;
  final List<_Json> students;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DelegationCategoryCard> createState() =>
      _DelegationCategoryCardState();
}

class _DelegationCategoryCardState
    extends ConsumerState<_DelegationCategoryCard> {
  int? _studentId;

  @override
  Widget build(BuildContext context) {
    final permissions = _docList(widget.category['permissions']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _docText(widget.category['name']),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _studentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'اختر الطالب/المندوب'),
            items: widget.students
                .map(
                  (student) => DropdownMenuItem(
                    value: _docInt(student['id']),
                    child: Text(
                      '${_docText(student['name'])} - ${_docText(student['student_number'])}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _studentId = value),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _studentId == null ? null : _delegate,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('إضافة التفويض'),
          ),
          if (permissions.isNotEmpty) ...[
            const Divider(height: 24),
            ...permissions.map((permission) {
              final user = _docMap(permission['authorized_user']);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_docText(user['name'])),
                subtitle: Text(_docText(user['student_number'])),
                trailing: IconButton(
                  onPressed: () => _revoke(_docInt(user['id'])),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _delegate() async {
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/delegate',
        {'authorized_user_id': _studentId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _revoke(int userId) async {
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/categories/${widget.category['id']}/revoke',
        {'authorized_user_id': userId},
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _GradeApprovalsTab extends ConsumerStatefulWidget {
  const _GradeApprovalsTab({required this.subjectId, required this.onChanged});

  final int subjectId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_GradeApprovalsTab> createState() => _GradeApprovalsTabState();
}

class _GradeApprovalsTabState extends ConsumerState<_GradeApprovalsTab> {
  late Future<Map<String, dynamic>> _future = _fetch();
  final Set<int> _selected = {};

  Future<Map<String, dynamic>> _fetch() => ref
      .read(staffRepositoryProvider)
      .get('/doctor/grades/${widget.subjectId}/approvals');

  void _reload() => setState(() => _future = _fetch());

  Future<void> _bulk(String action) async {
    if (_selected.isEmpty) return;
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/grades/approvals/bulk-action',
        {'grade_ids': _selected.toList(), 'action': action},
      );
      _selected.clear();
      _reload();
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final pending = _docList(data['pending_grades']);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _bulk('approve'),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('اعتماد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selected.isEmpty ? null : () => _bulk('reject'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const _DocEmpty('لا توجد درجات معلقة.')
            else
              ...pending.map((grade) {
                final id = _docInt(grade['id']);
                final student = _docMap(grade['student']);
                final category = _docMap(grade['grade_category']);
                return CheckboxListTile(
                  value: _selected.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(id);
                      } else {
                        _selected.remove(id);
                      }
                    });
                  },
                  title: Text(_docText(student['name'])),
                  subtitle: Text(
                    '${_docText(category['name'], 'درجة')} - ${_docText(grade['score'])}',
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _GradeReportTab extends ConsumerWidget {
  const _GradeReportTab({required this.subjectId});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
          .read(staffRepositoryProvider)
          .get('/doctor/grades/$subjectId/report'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final stats = _docMap(data['stats']);
        final students = _docList(data['students']);
        return ListView(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DocMetric(
                  label: 'المتوسط',
                  value: _docText(stats['average'], '0'),
                  color: AppColors.royalBlue,
                  icon: Icons.analytics_rounded,
                ),
                _DocMetric(
                  label: 'النجاح',
                  value: '${_docText(stats['pass_rate'], '0')}%',
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                ),
                _DocMetric(
                  label: 'الأعلى',
                  value: _docText(stats['highest'], '0'),
                  color: AppColors.warning,
                  icon: Icons.trending_up_rounded,
                ),
                _DocMetric(
                  label: 'الأدنى',
                  value: _docText(stats['lowest'], '0'),
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...students.map(
              (student) => ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(_docText(student['name'])),
                subtitle: Text(_docText(student['student_number'])),
                trailing: Text(
                  _docText(student['total'], '0'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DoctorQuizzesScreen extends ConsumerStatefulWidget {
  const DoctorQuizzesScreen({super.key});

  static const route = '/doctor/quizzes';

  @override
  ConsumerState<DoctorQuizzesScreen> createState() =>
      _DoctorQuizzesScreenState();
}

class _DoctorQuizzesScreenState extends ConsumerState<DoctorQuizzesScreen> {
  String _status = 'all';
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/quizzes',
          query: {if (_status != 'all') 'status': _status, 'per_page': 50},
        );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'كويزاتي',
      currentRoute: DoctorQuizzesScreen.route,
      floatingActionButton: _QuizFloatingButton(
        onPressed: () async {
          final data = await _future;
          if (!context.mounted) return;
          final subjects = _docList(
            _docMap(_docMap(_docData(data))['filters'])['subjects'],
          );
          await _showQuizForm(subjects: subjects);
        },
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final payload = _docMap(_docData(snapshot.data ?? const {}));
          final quizzes = _docList(payload['quizzes']);
          final subjects = _docList(_docMap(payload['filters'])['subjects']);
          final stats = _docMap(payload['stats']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'كويزاتي',
                  subtitle: 'إنشاء الكويزات وإدارتها ومتابعة النتائج.',
                  icon: Icons.quiz_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showQuizForm(subjects: subjects),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الكل',
                      value: _docText(
                        stats['total'],
                        quizzes.length.toString(),
                      ),
                      color: AppColors.royalBlue,
                      icon: Icons.quiz_rounded,
                    ),
                    _DocMetric(
                      label: 'منشور',
                      value: _docText(stats['published'], '0'),
                      color: AppColors.success,
                      icon: Icons.public_rounded,
                    ),
                    _DocMetric(
                      label: 'مجدول',
                      value: _docText(stats['scheduled'], '0'),
                      color: AppColors.warning,
                      icon: Icons.schedule_rounded,
                    ),
                    _DocMetric(
                      label: 'مغلق',
                      value: _docText(stats['closed'], '0'),
                      color: AppColors.danger,
                      icon: Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DocFilterPanel(
                  title: 'تصفية الكويزات',
                  icon: Icons.tune_rounded,
                  children: [
                    _DocSegmentFilter(
                      value: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value;
                          _future = _fetch();
                        });
                      },
                      choices: const [
                        _DocFilterChoice(
                          value: 'all',
                          label: 'الكل',
                          icon: Icons.apps_rounded,
                          color: AppColors.royalBlue,
                        ),
                        _DocFilterChoice(
                          value: 'draft',
                          label: 'مسودة',
                          icon: Icons.edit_note_rounded,
                          color: AppColors.warning,
                        ),
                        _DocFilterChoice(
                          value: 'published',
                          label: 'منشور',
                          icon: Icons.public_rounded,
                          color: AppColors.success,
                        ),
                        _DocFilterChoice(
                          value: 'scheduled',
                          label: 'مجدول',
                          icon: Icons.schedule_rounded,
                          color: AppColors.info,
                        ),
                        _DocFilterChoice(
                          value: 'closed',
                          label: 'مغلق',
                          icon: Icons.lock_rounded,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (quizzes.isEmpty)
                  const _DocEmpty('لا توجد كويزات في هذا التصنيف.')
                else
                  ...quizzes.map(
                    (quiz) => _QuizCard(
                      quiz: quiz,
                      onTap: () => _showQuizDetails(quiz, subjects),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showQuizDetails(_Json quiz, List<_Json> subjects) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الكويز',
      icon: Icons.quiz_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizDetailsPanel(
        quizId: _docInt(quiz['id']),
        subjects: subjects,
        onChanged: _reload,
        onEdit: (details) async {
          Navigator.pop(context);
          await _showQuizForm(subjects: subjects, quizDetails: details);
        },
      ),
    );
    _reload();
  }

  Future<void> _showQuizForm({
    required List<_Json> subjects,
    _Json? quizDetails,
  }) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: quizDetails == null ? 'إنشاء كويز' : 'تعديل كويز',
      icon: Icons.quiz_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizFormSheet(
        subjects: subjects,
        quizDetails: quizDetails,
        onSaved: _reload,
      ),
    );
  }
}

class _QuizFloatingButton extends StatelessWidget {
  const _QuizFloatingButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 18, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'كويز جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _quizStatusIcon(String status) {
  switch (status) {
    case 'published':
      return Icons.public_rounded;
    case 'scheduled':
      return Icons.schedule_rounded;
    case 'closed':
      return Icons.lock_rounded;
    case 'draft':
      return Icons.edit_note_rounded;
    default:
      return Icons.quiz_rounded;
  }
}

String _quizTimerLabel(_Json quiz) {
  return _docText(quiz['timer_mode']) == 'per_question'
      ? 'وقت لكل سؤال'
      : '${_docText(quiz['time_limit_minutes'], '-')} دقيقة';
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.onTap});

  final _Json quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = _docMap(quiz['subject']);
    final status = _docText(quiz['status'], 'draft');
    final models = _docList(quiz['models']);
    final color = _docStatusColor(status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(_quizStatusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(quiz['title'], 'كويز'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _docText(subject['name'], '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  _docStatusLabel(status),
                  color,
                  icon: _quizStatusIcon(status),
                ),
              ],
            ),
            if (_docText(quiz['description']).isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Text(
                  _docText(quiz['description']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w700,
                    height: 1.55,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  '${models.length} نموذج',
                  AppColors.royalBlue,
                  icon: Icons.view_module_rounded,
                ),
                _DocPill(
                  '${_docInt(quiz['attempts_count'])} محاولة',
                  AppColors.success,
                  icon: Icons.groups_rounded,
                ),
                _DocPill(
                  _quizTimerLabel(quiz),
                  AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizDetailsPanel extends ConsumerStatefulWidget {
  const _QuizDetailsPanel({
    required this.quizId,
    required this.subjects,
    required this.onChanged,
    required this.onEdit,
  });

  final int quizId;
  final List<_Json> subjects;
  final VoidCallback onChanged;
  final Future<void> Function(_Json details) onEdit;

  @override
  ConsumerState<_QuizDetailsPanel> createState() => _QuizDetailsPanelState();
}

class _QuizDetailsPanelState extends ConsumerState<_QuizDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _busy = false;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/quizzes/${widget.quizId}');
  }

  void _reload() => setState(() => _future = _fetch());

  Future<void> _action(
    String path,
    String success, {
    Map<String, dynamic>? data,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (data == null) {
        await ref.read(staffRepositoryProvider).patch(path, {});
      } else {
        await ref.read(staffRepositoryProvider).post(path, data);
      }
      if (!mounted) return;
      _reload();
      widget.onChanged();
      _docSnack(context, success, color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الكويز',
      message: 'هل تريد حذف هذا الكويز؟',
      confirmLabel: 'حذف',
      color: AppColors.danger,
      icon: Icons.delete_rounded,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/quizzes/${widget.quizId}');
      if (!mounted) return;
      Navigator.pop(context);
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _results() async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'نتائج الكويز',
      icon: Icons.analytics_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _QuizResultsPanel(quizId: widget.quizId),
    );
  }

  Future<void> _shareResults(String visibility) {
    return _action(
      '/doctor/quizzes/${widget.quizId}/share-results',
      'تم تحديث ظهور النتائج.',
      data: {'visibility': visibility},
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final quiz = _docMap(data['quiz']);
        final stats = _docMap(data['stats']);
        final models = _docList(quiz['models']);
        final canEditContent = _docBool(data['can_edit_content']);
        final status = _docText(quiz['status'], 'draft');
        final statusColor = _docStatusColor(status);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_quizStatusIcon(status), color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(quiz['title'], 'كويز'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _quizTimerLabel(quiz),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docStatusLabel(status),
                  statusColor,
                  icon: _quizStatusIcon(status),
                ),
                _DocPill(
                  _quizTimerLabel(quiz),
                  AppColors.warning,
                  icon: Icons.timer_rounded,
                ),
                _DocPill(
                  _docText(quiz['results_visibility'], 'hidden'),
                  AppColors.royalBlue,
                  icon: Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DocMetric(
                  label: 'المحاولات',
                  value: _docText(stats['total_attempts'], '0'),
                  color: AppColors.info,
                  icon: Icons.people_rounded,
                ),
                _DocMetric(
                  label: 'المتوسط',
                  value: _docText(stats['avg_score'], '0'),
                  color: AppColors.royalBlue,
                  icon: Icons.analytics_rounded,
                ),
                _DocMetric(
                  label: 'الأعلى',
                  value: _docText(stats['highest_score'], '0'),
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
                _DocMetric(
                  label: 'الأدنى',
                  value: _docText(stats['lowest_score'], '0'),
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InquiryMessageBlock(
              title: 'وصف الكويز',
              icon: Icons.notes_rounded,
              color: AppColors.royalBlue,
              text: _docText(quiz['description'], 'لا يوجد وصف.'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الجدولة',
                    value: _docDate(quiz['scheduled_at']),
                    icon: Icons.event_available_rounded,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuizInfoCard(
                    label: 'الإغلاق',
                    value: _docDate(quiz['closes_at']),
                    icon: Icons.event_busy_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'نماذج الكويز',
              icon: Icons.view_module_rounded,
              children: [
                if (models.isEmpty)
                  const _DocEmpty('لا توجد نماذج مرتبطة بهذا الكويز.')
                else
                  ...models.map((model) {
                    final questions = _docList(model['questions']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.slate100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.royalBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.ballot_rounded,
                              color: AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(model['name'], 'نموذج'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${questions.length} سؤال • كود الدخول: ${_docText(model['access_code'], 'بدون')}',
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
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 14),
            _DocFilterPanel(
              title: 'إجراءات الكويز',
              icon: Icons.tune_rounded,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy || status == 'published'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/publish',
                              'تم نشر الكويز.',
                            ),
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('نشر'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || status == 'closed'
                          ? null
                          : () => _action(
                              '/doctor/quizzes/${widget.quizId}/close',
                              'تم إغلاق الكويز.',
                            ),
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('إغلاق'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _results,
                      icon: const Icon(Icons.analytics_rounded),
                      label: const Text('النتائج'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => widget.onEdit(data),
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(
                        canEditContent ? 'تعديل كامل' : 'تعديل الإعدادات',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _docText(quiz['results_visibility'], 'hidden'),
                  decoration: const InputDecoration(
                    labelText: 'ظهور النتائج',
                    prefixIcon: Icon(Icons.visibility_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'hidden', child: Text('مخفية')),
                    DropdownMenuItem(value: 'individual', child: Text('فردية')),
                    DropdownMenuItem(value: 'public', child: Text('عامة')),
                  ],
                  onChanged: (value) {
                    if (value != null) _shareResults(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
              label: const Text(
                'حذف الكويز',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuizInfoCard extends StatelessWidget {
  const _QuizInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.midnight,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResultsPanel extends ConsumerStatefulWidget {
  const _QuizResultsPanel({required this.quizId});

  final int quizId;

  @override
  ConsumerState<_QuizResultsPanel> createState() => _QuizResultsPanelState();
}

class _QuizResultsPanelState extends ConsumerState<_QuizResultsPanel> {
  late final Future<Map<String, dynamic>> _future = ref
      .read(staffRepositoryProvider)
      .get('/doctor/quizzes/${widget.quizId}/results');
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(staffRepositoryProvider)
          .download('/doctor/quizzes/${widget.quizId}/results/export');
      final result = await DownloadService.saveBytes(
        bytes: bytes,
        fileName: 'quiz_results_${widget.quizId}.csv',
        section: 'QuizReports',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم تصدير النتائج',
        message: 'تم حفظ الملف في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final attempts = _docList(data['attempts']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نتائج المحاولات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'راجع أداء الطلاب أو صدّر التقرير.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _exporting ? null : _export,
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('تصدير'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (attempts.isEmpty)
              const _DocEmpty('لا توجد محاولات بعد.')
            else
              ...attempts.map((attempt) {
                final student = _docMap(attempt['student']);
                final model = _docMap(attempt['quiz_model']);
                final percentage = _docNum(attempt['percentage']);
                final color = percentage >= 80
                    ? AppColors.success
                    : percentage >= 50
                    ? AppColors.warning
                    : AppColors.danger;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withValues(alpha: 0.14)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.045),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _docText(student['name'], 'طالب'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${_docText(student['student_number'], '-')} • ${_docText(model['name'], '-')}',
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
                            '${_docText(attempt['percentage'], '0')}%',
                            color,
                            icon: Icons.percent_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DocPill(
                            'الدرجة ${_docText(attempt['score'], '0')} / ${_docText(attempt['max_score'], '0')}',
                            AppColors.success,
                            icon: Icons.grade_rounded,
                          ),
                          _DocPill(
                            'صحيح ${_docText(attempt['correct_count'], '0')}',
                            AppColors.royalBlue,
                            icon: Icons.check_circle_rounded,
                          ),
                          _DocPill(
                            'خاطئ ${_docText(attempt['wrong_count'], '0')}',
                            AppColors.danger,
                            icon: Icons.cancel_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _QuizFormSheet extends ConsumerStatefulWidget {
  const _QuizFormSheet({
    required this.subjects,
    required this.onSaved,
    this.quizDetails,
  });

  final List<_Json> subjects;
  final _Json? quizDetails;
  final VoidCallback onSaved;

  @override
  ConsumerState<_QuizFormSheet> createState() => _QuizFormSheetState();
}

class _QuizFormSheetState extends ConsumerState<_QuizFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _timeLimit = TextEditingController(text: '30');
  final _scheduledAt = TextEditingController();
  final _closesAt = TextEditingController();
  final List<_QuizModelDraft> _models = [];
  int? _subjectId;
  String _timerMode = 'quiz';
  String _resultsVisibility = 'hidden';
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;
  bool _showCorrectAnswers = false;
  bool _showCorrectionNotes = true;
  bool _notifyStudents = false;
  bool _showCountdown = true;
  bool _useAccessCode = false;
  bool _saving = false;
  bool _canEditContent = true;

  _Json? get _quiz => _docMap(widget.quizDetails?['quiz']);

  @override
  void initState() {
    super.initState();
    final quiz = _quiz;
    if (quiz != null && quiz.isNotEmpty) {
      _subjectId = _docInt(quiz['subject_id']);
      _title.text = _docText(quiz['title']);
      _description.text = _docText(quiz['description']);
      _timeLimit.text = _docText(quiz['time_limit_minutes'], '30');
      _timerMode = _docText(quiz['timer_mode'], 'quiz');
      _resultsVisibility = _docText(quiz['results_visibility'], 'hidden');
      _scheduledAt.text = _docDateTimeForInput(quiz['scheduled_at']);
      _closesAt.text = _docDateTimeForInput(quiz['closes_at']);
      _shuffleQuestions = _docBool(quiz['shuffle_questions']);
      _shuffleOptions = _docBool(quiz['shuffle_options']);
      _showCorrectAnswers = _docBool(quiz['show_correct_answers']);
      _showCorrectionNotes = _docBool(quiz['show_correction_notes']);
      _notifyStudents = _docBool(quiz['notify_students']);
      _showCountdown = _docBool(quiz['show_countdown']);
      _canEditContent = _docBool(widget.quizDetails?['can_edit_content']);
      final models = _docList(quiz['models']);
      _models.addAll(models.map(_QuizModelDraft.fromJson));
      _useAccessCode = models.any(
        (model) => _docText(model['access_code']).isNotEmpty,
      );
    } else {
      _subjectId = widget.subjects.isEmpty
          ? null
          : _docInt(widget.subjects.first['id']);
      _models.add(_QuizModelDraft.empty());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _timeLimit.dispose();
    _scheduledAt.dispose();
    _closesAt.dispose();
    for (final model in _models) {
      model.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalBlue.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _quiz == null || _quiz!.isEmpty
                        ? Icons.quiz_rounded
                        : Icons.edit_note_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quiz == null || _quiz!.isEmpty
                            ? 'إنشاء كويز جديد'
                            : 'تعديل الكويز',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'قسّم الإعدادات والنماذج والأسئلة بوضوح قبل النشر.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DocFilterPanel(
            title: 'البيانات الأساسية',
            icon: Icons.assignment_rounded,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _subjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'المادة',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: widget.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: _docInt(subject['id']),
                        child: Text(_docText(subject['name'])),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _subjectId = value),
                validator: (value) => value == null ? 'اختر المادة.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'عنوان الكويز',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) =>
                    _docText(value).isEmpty ? 'اكتب عنوان الكويز.' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocFilterPanel(
            title: 'التوقيت والظهور',
            icon: Icons.timer_rounded,
            children: [
              _DocSegmentFilter(
                value: _timerMode,
                onChanged: (value) => setState(() => _timerMode = value),
                choices: const [
                  _DocFilterChoice(
                    value: 'quiz',
                    label: 'وقت عام',
                    icon: Icons.timer_rounded,
                    color: AppColors.royalBlue,
                  ),
                  _DocFilterChoice(
                    value: 'per_question',
                    label: 'لكل سؤال',
                    icon: Icons.av_timer_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
              if (_timerMode == 'quiz') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeLimit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'مدة الاختبار بالدقائق',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  validator: (value) => int.tryParse(_docText(value)) == null
                      ? 'اكتب مدة صحيحة.'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _scheduledAt,
                      decoration: const InputDecoration(
                        labelText: 'النشر/الجدولة',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        prefixIcon: Icon(Icons.event_available_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _closesAt,
                      decoration: const InputDecoration(
                        labelText: 'الإغلاق',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        prefixIcon: Icon(Icons.event_busy_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _resultsVisibility,
                decoration: const InputDecoration(
                  labelText: 'ظهور النتائج',
                  prefixIcon: Icon(Icons.visibility_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'hidden', child: Text('مخفية')),
                  DropdownMenuItem(value: 'individual', child: Text('فردية')),
                  DropdownMenuItem(value: 'public', child: Text('عامة')),
                ],
                onChanged: (value) =>
                    setState(() => _resultsVisibility = value ?? 'hidden'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DocFilterPanel(
            title: 'خيارات التشغيل',
            icon: Icons.settings_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuizSwitch(
                    label: 'كود دخول',
                    value: _useAccessCode,
                    onChanged: (v) => setState(() => _useAccessCode = v),
                  ),
                  _QuizSwitch(
                    label: 'خلط الأسئلة',
                    value: _shuffleQuestions,
                    onChanged: (v) => setState(() => _shuffleQuestions = v),
                  ),
                  _QuizSwitch(
                    label: 'خلط الخيارات',
                    value: _shuffleOptions,
                    onChanged: (v) => setState(() => _shuffleOptions = v),
                  ),
                  _QuizSwitch(
                    label: 'إظهار الصحيح',
                    value: _showCorrectAnswers,
                    onChanged: (v) => setState(() => _showCorrectAnswers = v),
                  ),
                  _QuizSwitch(
                    label: 'ملاحظات التصحيح',
                    value: _showCorrectionNotes,
                    onChanged: (v) => setState(() => _showCorrectionNotes = v),
                  ),
                  _QuizSwitch(
                    label: 'إشعار الطلاب',
                    value: _notifyStudents,
                    onChanged: (v) => setState(() => _notifyStudents = v),
                  ),
                  _QuizSwitch(
                    label: 'إظهار العداد',
                    value: _showCountdown,
                    onChanged: (v) => setState(() => _showCountdown = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!_canEditContent)
            const _DocEmpty(
              'لا يمكن تعديل الأسئلة بعد وجود محاولات. يمكنك تعديل الإعدادات فقط.',
            )
          else ...[
            _DocFilterPanel(
              title: 'النماذج والأسئلة',
              icon: Icons.schema_rounded,
              children: [
                ..._models.asMap().entries.map(
                  (entry) => _QuizModelEditor(
                    index: entry.key,
                    model: entry.value,
                    timerMode: _timerMode,
                    onDelete: _models.length == 1
                        ? null
                        : () => setState(() {
                            _models.removeAt(entry.key).dispose();
                          }),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      setState(() => _models.add(_QuizModelDraft.empty())),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.royalBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_rounded),
                        SizedBox(width: 8),
                        Text(
                          'إضافة نموذج جديد',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.slate100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _quiz == null || _quiz!.isEmpty
                    ? 'حفظ إعدادات الكويز'
                    : 'حفظ تعديلات الكويز',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true || _subjectId == null) return;
    if (_canEditContent && !_validateModels()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'subject_id': _subjectId,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'timer_mode': _timerMode,
        'time_limit_minutes': _timerMode == 'quiz'
            ? int.tryParse(_timeLimit.text.trim())
            : null,
        'shuffle_questions': _shuffleQuestions,
        'shuffle_options': _shuffleOptions,
        'show_correct_answers': _showCorrectAnswers,
        'show_correction_notes': _showCorrectionNotes,
        'notify_students': _notifyStudents,
        'show_countdown': _showCountdown,
        'use_access_code': _useAccessCode,
        'results_visibility': _resultsVisibility,
        if (_scheduledAt.text.trim().isNotEmpty)
          'scheduled_at': _scheduledAt.text.trim(),
        if (_closesAt.text.trim().isNotEmpty)
          'closes_at': _closesAt.text.trim(),
        if (_canEditContent)
          'models': _models
              .map((model) => model.toPayload(_timerMode))
              .toList(),
      };
      final quiz = _quiz;
      if (quiz == null || quiz.isEmpty) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/quizzes', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/quizzes/${quiz['id']}', payload);
      }
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
      _docSnack(context, 'تم حفظ الكويز.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _validateModels() {
    for (final model in _models) {
      if (model.name.text.trim().isEmpty || model.questions.isEmpty) {
        _docSnack(
          context,
          'أكمل أسماء النماذج والأسئلة.',
          color: AppColors.warning,
        );
        return false;
      }
      for (final question in model.questions) {
        if (question.question.text.trim().isEmpty ||
            question.options.length < 2) {
          _docSnack(
            context,
            'كل سؤال يحتاج نصًا وخيارين على الأقل.',
            color: AppColors.warning,
          );
          return false;
        }
        if (!question.options.any((option) => option.isCorrect)) {
          _docSnack(
            context,
            'حدد إجابة صحيحة لكل سؤال.',
            color: AppColors.warning,
          );
          return false;
        }
        if (_timerMode == 'per_question' &&
            int.tryParse(question.timeLimit.text.trim()) == null) {
          _docSnack(
            context,
            'حدد وقت كل سؤال بالثواني.',
            color: AppColors.warning,
          );
          return false;
        }
      }
    }
    return true;
  }
}

class _QuizSwitch extends StatelessWidget {
  const _QuizSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: value
              ? AppColors.royalBlue.withValues(alpha: 0.11)
              : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: value ? AppColors.royalBlue : AppColors.slate200,
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_rounded : Icons.circle_outlined,
              size: 16,
              color: value ? AppColors.royalBlue : AppColors.slate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.royalBlue : AppColors.slate600,
                fontSize: 12,
                fontWeight: value ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizModelEditor extends StatefulWidget {
  const _QuizModelEditor({
    required this.index,
    required this.model,
    required this.timerMode,
    required this.onDelete,
  });

  final int index;
  final _QuizModelDraft model;
  final String timerMode;
  final VoidCallback? onDelete;

  @override
  State<_QuizModelEditor> createState() => _QuizModelEditorState();
}

class _QuizModelEditorState extends State<_QuizModelEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نموذج ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.model.questions.length} سؤال في هذا النموذج',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                Tooltip(
                  message: 'حذف النموذج',
                  child: IconButton.filledTonal(
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.model.name,
            decoration: const InputDecoration(
              labelText: 'اسم النموذج',
              prefixIcon: Icon(Icons.bookmark_rounded),
            ),
          ),
          const SizedBox(height: 14),
          ...widget.model.questions.asMap().entries.map(
            (entry) => _QuizQuestionEditor(
              index: entry.key,
              question: entry.value,
              timerMode: widget.timerMode,
              onDelete: widget.model.questions.length == 1
                  ? null
                  : () => setState(() {
                      widget.model.questions.removeAt(entry.key).dispose();
                    }),
            ),
          ),
          InkWell(
            onTap: () => setState(
              () => widget.model.questions.add(_QuizQuestionDraft.empty()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'إضافة سؤال داخل النموذج',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionEditor extends StatefulWidget {
  const _QuizQuestionEditor({
    required this.index,
    required this.question,
    required this.timerMode,
    required this.onDelete,
  });

  final int index;
  final _QuizQuestionDraft question;
  final String timerMode;
  final VoidCallback? onDelete;

  @override
  State<_QuizQuestionEditor> createState() => _QuizQuestionEditorState();
}

class _QuizQuestionEditorState extends State<_QuizQuestionEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.help_rounded,
                  color: AppColors.royalBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سؤال ${widget.index + 1}',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.question.type == 'true_false'
                          ? 'صح أو خطأ'
                          : 'اختيار من متعدد',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                Tooltip(
                  message: 'حذف السؤال',
                  child: IconButton(
                    onPressed: widget.onDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.question.question,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'نص السؤال',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.question.type,
                  decoration: const InputDecoration(
                    labelText: 'نوع السؤال',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'multiple_choice',
                      child: Text('اختيار من متعدد'),
                    ),
                    DropdownMenuItem(
                      value: 'true_false',
                      child: Text('صح/خطأ'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    widget.question.type = value ?? 'multiple_choice';
                    if (widget.question.type == 'true_false') {
                      widget.question.setTrueFalseOptions();
                    }
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.question.score,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الدرجة',
                    prefixIcon: Icon(Icons.grade_rounded),
                  ),
                ),
              ),
            ],
          ),
          if (widget.timerMode == 'per_question') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.question.timeLimit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'وقت السؤال بالثواني',
                prefixIcon: Icon(Icons.av_timer_rounded),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.question.correctionNote,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة التصحيح',
                    prefixIcon: Icon(Icons.fact_check_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.question.infoSource,
                  decoration: const InputDecoration(
                    labelText: 'مصدر المعلومة',
                    prefixIcon: Icon(Icons.source_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'الخيارات والإجابة الصحيحة',
            style: TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.question.options.asMap().entries.map((entry) {
            final option = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsetsDirectional.only(
                start: 8,
                end: 8,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: option.isCorrect
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: option.isCorrect
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.slate100,
                ),
              ),
              child: Row(
                children: [
                  Tooltip(
                    message: 'تحديد كإجابة صحيحة',
                    child: Checkbox(
                      value: option.isCorrect,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (value) => setState(() {
                        for (final item in widget.question.options) {
                          item.isCorrect = false;
                        }
                        option.isCorrect = value == true;
                      }),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: option.text,
                      readOnly: widget.question.type == 'true_false',
                      decoration: InputDecoration(
                        labelText: 'خيار ${entry.key + 1}',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  if (widget.question.type != 'true_false' &&
                      widget.question.options.length > 2)
                    IconButton(
                      onPressed: () => setState(() {
                        widget.question.options.removeAt(entry.key).dispose();
                      }),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            );
          }),
          if (widget.question.type != 'true_false')
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => widget.question.options.add(_QuizOptionDraft.empty()),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة خيار'),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizModelDraft {
  _QuizModelDraft({required this.name, required this.questions});

  final TextEditingController name;
  final List<_QuizQuestionDraft> questions;

  factory _QuizModelDraft.empty() => _QuizModelDraft(
    name: TextEditingController(text: 'نموذج A'),
    questions: [_QuizQuestionDraft.empty()],
  );

  factory _QuizModelDraft.fromJson(_Json json) => _QuizModelDraft(
    name: TextEditingController(text: _docText(json['name'])),
    questions: _docList(json['questions']).isEmpty
        ? [_QuizQuestionDraft.empty()]
        : _docList(json['questions']).map(_QuizQuestionDraft.fromJson).toList(),
  );

  Map<String, dynamic> toPayload(String timerMode) => {
    'name': name.text.trim(),
    'questions': questions
        .map((question) => question.toPayload(timerMode))
        .toList(),
  };

  void dispose() {
    name.dispose();
    for (final question in questions) {
      question.dispose();
    }
  }
}

class _QuizQuestionDraft {
  _QuizQuestionDraft({
    required this.question,
    required this.score,
    required this.timeLimit,
    required this.correctionNote,
    required this.infoSource,
    required this.options,
    required this.type,
  });

  final TextEditingController question;
  final TextEditingController score;
  final TextEditingController timeLimit;
  final TextEditingController correctionNote;
  final TextEditingController infoSource;
  final List<_QuizOptionDraft> options;
  String type;

  factory _QuizQuestionDraft.empty() => _QuizQuestionDraft(
    question: TextEditingController(),
    score: TextEditingController(text: '1'),
    timeLimit: TextEditingController(text: '60'),
    correctionNote: TextEditingController(),
    infoSource: TextEditingController(),
    type: 'multiple_choice',
    options: [_QuizOptionDraft.empty(), _QuizOptionDraft.empty()],
  );

  factory _QuizQuestionDraft.fromJson(_Json json) => _QuizQuestionDraft(
    question: TextEditingController(text: _docText(json['question_text'])),
    score: TextEditingController(text: _docText(json['score'], '1')),
    timeLimit: TextEditingController(
      text: _docText(json['time_limit_seconds'], '60'),
    ),
    correctionNote: TextEditingController(
      text: _docText(json['correction_note']),
    ),
    infoSource: TextEditingController(text: _docText(json['info_source'])),
    type: _docText(json['question_type'], 'multiple_choice'),
    options: _docList(json['options']).isEmpty
        ? [_QuizOptionDraft.empty(), _QuizOptionDraft.empty()]
        : _docList(json['options']).map(_QuizOptionDraft.fromJson).toList(),
  );

  void setTrueFalseOptions() {
    for (final option in options) {
      option.dispose();
    }
    options
      ..clear()
      ..addAll([
        _QuizOptionDraft(
          text: TextEditingController(text: 'صح'),
          isCorrect: true,
        ),
        _QuizOptionDraft(
          text: TextEditingController(text: 'خطأ'),
          isCorrect: false,
        ),
      ]);
  }

  Map<String, dynamic> toPayload(String timerMode) => {
    'question_text': question.text.trim(),
    'question_type': type,
    'score': num.tryParse(score.text.trim()) ?? 1,
    if (timerMode == 'per_question')
      'time_limit_seconds': int.tryParse(timeLimit.text.trim()) ?? 60,
    'correction_note': correctionNote.text.trim(),
    'info_source': infoSource.text.trim(),
    'options': options.map((option) => option.toPayload()).toList(),
  };

  void dispose() {
    question.dispose();
    score.dispose();
    timeLimit.dispose();
    correctionNote.dispose();
    infoSource.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _QuizOptionDraft {
  _QuizOptionDraft({required this.text, required this.isCorrect});

  final TextEditingController text;
  bool isCorrect;

  factory _QuizOptionDraft.empty() =>
      _QuizOptionDraft(text: TextEditingController(), isCorrect: false);

  factory _QuizOptionDraft.fromJson(_Json json) => _QuizOptionDraft(
    text: TextEditingController(text: _docText(json['option_text'])),
    isCorrect: _docBool(json['is_correct']),
  );

  Map<String, dynamic> toPayload() => {
    'option_text': text.text.trim(),
    'is_correct': isCorrect,
  };

  void dispose() => text.dispose();
}

class DoctorStarsScreen extends ConsumerStatefulWidget {
  const DoctorStarsScreen({super.key});

  static const route = '/doctor/stars';

  @override
  ConsumerState<DoctorStarsScreen> createState() => _DoctorStarsScreenState();
}

class _DoctorStarsScreenState extends ConsumerState<DoctorStarsScreen> {
  final _search = TextEditingController();
  int? _subjectId;
  final Set<int> _selected = {};
  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/stars',
          query: {
            if (_subjectId != null) 'subject_id': _subjectId,
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
            'per_page': 100,
          },
        );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'منح النجوم',
      currentRoute: DoctorStarsScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected.isEmpty ? null : _grantStars,
        icon: const Icon(Icons.stars_rounded),
        label: Text(
          _selected.isEmpty ? 'اختر طلاب' : 'منح ${_selected.length}',
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _docMap(_docData(snapshot.data ?? const {}));
          final subjects = _docList(data['subjects']);
          final page = _docMap(data['students']);
          final students = _docList(page['data']);
          final total = _docInt(page['total'], students.length);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'منح النجوم',
                  subtitle:
                      'اختر طالبًا أو أكثر وامنحهم نقاط تحفيزية ضمن نطاق موادك.',
                  icon: Icons.stars_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _selected.isEmpty ? null : _grantStars,
                    icon: const Icon(Icons.card_giftcard_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'طلاب متاحون',
                      value: total.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.groups_rounded,
                    ),
                    _DocMetric(
                      label: 'محدد',
                      value: _selected.length.toString(),
                      color: AppColors.success,
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StarFilters(
                  search: _search,
                  subjects: subjects,
                  subjectId: _subjectId,
                  onSearch: _reload,
                  onSubjectChanged: (value) {
                    setState(() {
                      _subjectId = value;
                      _selected.clear();
                      _future = _fetch();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: students.isEmpty
                            ? null
                            : () => setState(() {
                                _selected
                                  ..clear()
                                  ..addAll(
                                    students.map((s) => _docInt(s['id'])),
                                  );
                              }),
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('تحديد الكل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(_selected.clear),
                        icon: const Icon(Icons.clear_rounded),
                        label: const Text('مسح التحديد'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (students.isEmpty)
                  const _DocEmpty('لا يوجد طلاب مطابقون للفلاتر.')
                else
                  ...students.map(
                    (student) => _StarStudentCard(
                      student: student,
                      selected: _selected.contains(_docInt(student['id'])),
                      onChanged: (selected) {
                        setState(() {
                          final id = _docInt(student['id']);
                          if (selected) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        });
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _grantStars() async {
    final amount = TextEditingController(text: '1');
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'منح النجوم',
      icon: Icons.card_giftcard_rounded,
      color: AppColors.royalBlue,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيتم منح النجوم إلى ${_selected.length} طالب/مندوب.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد النجوم'),
              validator: (value) {
                final parsed = int.tryParse(_docText(value));
                if (parsed == null || parsed < 1 || parsed > 100) {
                  return 'اكتب عددًا من 1 إلى 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'سبب المنح اختياري'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.stars_rounded),
              label: const Text('منح النجوم'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .post('/doctor/stars/grant', {
            'student_ids': _selected.toList(),
            'amount': int.parse(amount.text.trim()),
            if (description.text.trim().isNotEmpty)
              'description': description.text.trim(),
          });
      if (!mounted) return;
      _selected.clear();
      _reload();
      await showMoeenInfoDialog(
        context: context,
        title: 'تم منح النجوم',
        message: _docText(response['message'], 'تم منح النجوم بنجاح.'),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _StarFilters extends StatelessWidget {
  const _StarFilters({
    required this.search,
    required this.subjects,
    required this.subjectId,
    required this.onSearch,
    required this.onSubjectChanged,
  });

  final TextEditingController search;
  final List<_Json> subjects;
  final int? subjectId;
  final VoidCallback onSearch;
  final ValueChanged<int?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'بحث باسم الطالب أو رقم القيد...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: subjectId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المادة'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('كل المواد'),
              ),
              ...subjects.map(
                (subject) => DropdownMenuItem<int?>(
                  value: _docInt(subject['id']),
                  child: Text(_docText(subject['name'])),
                ),
              ),
            ],
            onChanged: onSubjectChanged,
          ),
        ],
      ),
    );
  }
}

class _StarStudentCard extends StatelessWidget {
  const _StarStudentCard({
    required this.student,
    required this.selected,
    required this.onChanged,
  });

  final _Json student;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value == true),
        secondary: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.12),
          child: const Icon(Icons.stars_rounded, color: AppColors.warning),
        ),
        title: Text(
          _docText(student['name'], 'طالب'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${_docText(student['student_number'], '-')} • الرصيد ${_docText(student['stars_balance'], '0')}',
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        dense: false,
        isThreeLine: false,
      ),
    );
  }
}

class DoctorInquiriesScreen extends ConsumerStatefulWidget {
  const DoctorInquiriesScreen({super.key});

  static const route = '/doctor/inquiries';

  @override
  ConsumerState<DoctorInquiriesScreen> createState() =>
      _DoctorInquiriesScreenState();
}

class _DoctorInquiriesScreenState extends ConsumerState<DoctorInquiriesScreen> {
  String _status = 'all';
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/inquiries',
          query: {if (_status != 'all') 'status': _status},
        );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'استفسارات الطلاب',
      currentRoute: DoctorInquiriesScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final data = _docMap(_docData(snapshot.data ?? const {}));
          final stats = _docMap(data['stats']);
          final settings = _docMap(data['settings']);
          final subjects = _docList(settings['subjects']);
          final inquiries = _docList(data['inquiries']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'استفسارات الطلاب',
                  subtitle:
                      'إدارة الاستفسارات المحولة وإعدادات فتح الأسئلة لكل مادة.',
                  icon: Icons.forum_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: () => _showSettings(subjects),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الكل',
                      value: _docText(stats['total'], '0'),
                      color: AppColors.royalBlue,
                      icon: Icons.forum_rounded,
                    ),
                    _DocMetric(
                      label: 'محولة',
                      value: _docText(stats['forwarded'], '0'),
                      color: AppColors.warning,
                      icon: Icons.forward_rounded,
                    ),
                    _DocMetric(
                      label: 'مجاب عنها',
                      value: _docText(stats['answered'], '0'),
                      color: AppColors.success,
                      icon: Icons.check_circle_rounded,
                    ),
                    _DocMetric(
                      label: 'مغلقة',
                      value: _docText(stats['closed'], '0'),
                      color: AppColors.danger,
                      icon: Icons.lock_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DocFilterPanel(
                  title: 'تصفية الاستفسارات',
                  icon: Icons.tune_rounded,
                  children: [
                    _DocSegmentFilter(
                      value: _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value;
                          _future = _fetch();
                        });
                      },
                      choices: const [
                        _DocFilterChoice(
                          value: 'all',
                          label: 'الكل',
                          icon: Icons.apps_rounded,
                          color: AppColors.royalBlue,
                        ),
                        _DocFilterChoice(
                          value: 'forwarded',
                          label: 'محولة',
                          icon: Icons.forward_rounded,
                          color: AppColors.warning,
                        ),
                        _DocFilterChoice(
                          value: 'answered',
                          label: 'مجاب عنها',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                        _DocFilterChoice(
                          value: 'closed',
                          label: 'مغلقة',
                          icon: Icons.lock_rounded,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (inquiries.isEmpty)
                  const _DocEmpty('لا توجد استفسارات في هذا التصنيف.')
                else
                  ...inquiries.map(
                    (inquiry) => _InquiryCard(
                      inquiry: inquiry,
                      onTap: () => _showInquiry(inquiry),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSettings(List<_Json> subjects) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'إعدادات الاستفسارات',
      icon: Icons.settings_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _InquirySettingsPanel(subjects: subjects, onChanged: _reload),
    );
  }

  Future<void> _showInquiry(_Json inquiry) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الاستفسار',
      icon: Icons.question_answer_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _InquiryDetailsPanel(
        inquiryId: _docInt(inquiry['id']),
        onAnswered: _reload,
      ),
    );
  }
}

IconData _inquiryStatusIcon(String status) {
  switch (status) {
    case 'answered':
      return Icons.mark_chat_read_rounded;
    case 'closed':
      return Icons.lock_rounded;
    case 'forwarded':
      return Icons.forward_to_inbox_rounded;
    default:
      return Icons.contact_support_rounded;
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry, required this.onTap});

  final _Json inquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final student = _docMap(inquiry['student']);
    final subject = _docMap(inquiry['subject']);
    final status = _docText(inquiry['status']);
    final color = _docStatusColor(status);
    final title = _docText(inquiry['title'] ?? inquiry['question'], 'استفسار');
    final body = _docText(inquiry['question'] ?? inquiry['body'], '-');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(_inquiryStatusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _docText(student['name'], '-'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  _docStatusLabel(status),
                  color,
                  icon: _inquiryStatusIcon(status),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.royalBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _docText(subject['name'], '-'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.slate300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryDetailsPanel extends ConsumerStatefulWidget {
  const _InquiryDetailsPanel({
    required this.inquiryId,
    required this.onAnswered,
  });

  final int inquiryId;
  final VoidCallback onAnswered;

  @override
  ConsumerState<_InquiryDetailsPanel> createState() =>
      _InquiryDetailsPanelState();
}

class _InquiryDetailsPanelState extends ConsumerState<_InquiryDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  final _answer = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/inquiries/${widget.inquiryId}');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final inquiry = _docMap(_docData(snapshot.data ?? const {}));
        final student = _docMap(inquiry['student']);
        final subject = _docMap(inquiry['subject']);
        final status = _docText(inquiry['status']);
        final color = _docStatusColor(status);
        final canAnswer = status == 'forwarded';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _inquiryStatusIcon(status),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(student['name'], 'طالب'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_docText(subject['name'], '-')} • ${_docText(student['student_number'], '-')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _docText(
                        inquiry['title'] ?? inquiry['question'],
                        'استفسار',
                      ),
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _DocPill(
                    _docStatusLabel(status),
                    color,
                    icon: _inquiryStatusIcon(status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InquiryMessageBlock(
              title: 'سؤال الطالب',
              icon: Icons.help_rounded,
              color: AppColors.royalBlue,
              text: _docText(inquiry['question'] ?? inquiry['body'], '-'),
            ),
            if (_docText(inquiry['answer']).isNotEmpty)
              _InquiryMessageBlock(
                title: 'رد الدكتور',
                icon: Icons.mark_chat_read_rounded,
                color: AppColors.success,
                text: _docText(inquiry['answer']),
              ),
            if (canAnswer) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.045),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'كتابة الرد',
                      style: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _answer,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'اكتب رداً واضحاً ومباشراً للطالب...',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: AppColors.slate50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.royalBlue,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _sending ? null : _sendAnswer,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('إرسال الرد'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _sendAnswer() async {
    if (_answer.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/inquiries/${widget.inquiryId}/answer',
        {'answer': _answer.text.trim()},
      );
      if (!mounted) return;
      widget.onAnswered();
      setState(() => _future = _fetch());
      _docSnack(context, 'تم إرسال الرد.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _InquiryMessageBlock extends StatelessWidget {
  const _InquiryMessageBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.text,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _InquirySettingsPanel extends ConsumerStatefulWidget {
  const _InquirySettingsPanel({
    required this.subjects,
    required this.onChanged,
  });

  final List<_Json> subjects;
  final VoidCallback onChanged;

  @override
  ConsumerState<_InquirySettingsPanel> createState() =>
      _InquirySettingsPanelState();
}

class _InquirySettingsPanelState extends ConsumerState<_InquirySettingsPanel> {
  late final List<_Json> _subjects = widget.subjects
      .map(Map<String, dynamic>.from)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_subjects.isEmpty) {
      return const _DocEmpty('لا توجد مواد لإعداد الاستفسارات.');
    }
    return Column(
      children: _subjects.asMap().entries.map((entry) {
        final index = entry.key;
        final subject = entry.value;
        final enabled = _docBool(subject['inquiries_enabled']);
        final color = enabled ? AppColors.success : AppColors.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      enabled ? Icons.forum_rounded : Icons.forum_outlined,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docText(subject['subject_name'], 'مادة'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enabled
                              ? 'متاحة لاستقبال الاستفسارات'
                              : 'الاستفسارات مغلقة',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeThumbColor: AppColors.success,
                    onChanged: (value) => _update(index, value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: Text(
                  _docText(
                    subject['status_message'],
                    enabled
                        ? 'الاستفسارات مفتوحة لهذه المادة.'
                        : 'الاستفسارات مغلقة لهذه المادة.',
                  ),
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              if (!enabled && _docText(subject['closed_reason']).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _docText(subject['closed_reason']),
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _update(int index, bool enabled) async {
    final subject = _subjects[index];
    var reason = _docText(subject['closed_reason']);
    if (!enabled) {
      final controller = TextEditingController(text: reason);
      final ok = await showMoeenBottomSheet<bool>(
        context: context,
        title: 'سبب إغلاق الاستفسارات',
        icon: Icons.lock_rounded,
        color: AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'السبب اختياري'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = controller.text.trim();
    }
    try {
      final response = await ref.read(staffRepositoryProvider).patch(
        '/doctor/inquiries/subjects/${subject['subject_id']}/settings',
        {'inquiries_enabled': enabled, 'inquiries_closed_reason': reason},
      );
      final updated = _docMap(_docMap(_docData(response))['subject']);
      setState(
        () => _subjects[index] = {
          ...subject,
          ...updated,
          'status_message': enabled
              ? 'الاستفسارات مفتوحة لهذه المادة.'
              : (reason.isNotEmpty ? reason : 'الاستفسارات مغلقة لهذه المادة.'),
        },
      );
      widget.onChanged();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorMessagesScreen extends ConsumerStatefulWidget {
  const DoctorMessagesScreen({super.key});

  static const route = '/doctor/messages';

  @override
  ConsumerState<DoctorMessagesScreen> createState() =>
      _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends ConsumerState<DoctorMessagesScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/messages');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'محادثات المندوبين',
      currentRoute: DoctorMessagesScreen.route,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startConversation,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('محادثة'),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final conversations = _docList(_docData(snapshot.data ?? const {}));
          final unread = conversations.fold<int>(
            0,
            (sum, item) => sum + _docInt(item['unread_count']),
          );
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'محادثات المندوبين',
                  subtitle:
                      'متابعة الرسائل مع مندوبي موادك والرد عليهم مباشرة.',
                  icon: Icons.chat_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _startConversation,
                    icon: const Icon(Icons.add_comment_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'المحادثات',
                      value: conversations.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.forum_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unread.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_chat_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (conversations.isEmpty)
                  const _DocEmpty('لا توجد محادثات بعد.')
                else
                  ...conversations.map(
                    (conversation) => _ConversationCard(
                      conversation: conversation,
                      onTap: () =>
                          _openConversation(_docInt(conversation['id'])),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _startConversation() async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'بدء محادثة',
      icon: Icons.add_comment_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _StartConversationPanel(
        onStarted: (conversationId) async {
          Navigator.pop(context);
          _reload();
          await _openConversation(conversationId);
        },
      ),
    );
  }

  Future<void> _openConversation(int conversationId) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'المحادثة',
      icon: Icons.chat_bubble_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _ConversationPanel(conversationId: conversationId),
    );
    _reload();
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.onTap});

  final _Json conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delegate = _docMap(conversation['delegate']);
    final unread = _docInt(conversation['unread_count']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.royalBlue.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.royalBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _docText(delegate['name'], 'مندوب'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docText(
                      conversation['last_message'],
                      'لا توجد رسائل بعد.',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docDate(conversation['last_message_at']),
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0) _DocPill(unread.toString(), AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _StartConversationPanel extends ConsumerStatefulWidget {
  const _StartConversationPanel({required this.onStarted});

  final Future<void> Function(int conversationId) onStarted;

  @override
  ConsumerState<_StartConversationPanel> createState() =>
      _StartConversationPanelState();
}

class _StartConversationPanelState
    extends ConsumerState<_StartConversationPanel> {
  final _search = TextEditingController();
  late Future<Map<String, dynamic>> _future = _fetch();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get(
          '/doctor/messages/delegates',
          query: {
            if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
          },
        );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _search,
          onSubmitted: (_) => _reload(),
          decoration: InputDecoration(
            hintText: 'ابحث عن مندوب...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
            final delegates = _docList(_docData(snapshot.data ?? const {}));
            if (delegates.isEmpty) {
              return const _DocEmpty('لا يوجد مندوبون ضمن نطاق موادك.');
            }
            return Column(
              children: delegates.map((delegate) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_rounded),
                    ),
                    title: Text(_docText(delegate['name'])),
                    subtitle: Text(
                      '${_docText(delegate['student_number'], '-')} • ${_delegateRoleLabel(_docText(delegate['role']))}',
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _start(delegate),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _start(_Json delegate) async {
    try {
      final response = await ref.read(staffRepositoryProvider).post(
        '/doctor/messages',
        {'delegate_id': _docInt(delegate['id'])},
      );
      final id = _docInt(_docMap(_docData(response))['conversation_id']);
      if (id > 0) await widget.onStarted(id);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _ConversationPanel extends ConsumerStatefulWidget {
  const _ConversationPanel({required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<_ConversationPanel> {
  final _message = TextEditingController();
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/messages/${widget.conversationId}');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
        final data = _docMap(_docData(snapshot.data ?? const {}));
        final conversation = _docMap(data['conversation']);
        final delegate = _docMap(conversation['delegate']);
        final messages = _docList(data['messages']);
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _docText(delegate['name'], 'مندوب'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: messages.isEmpty
                    ? const _DocEmpty('لا توجد رسائل بعد.')
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine = _docBool(message['is_mine']);
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.72,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.royalBlue
                                    : AppColors.slate100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _docText(message['body']),
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : AppColors.midnight,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _docDate(message['created_at']),
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white.withValues(alpha: 0.72)
                                          : AppColors.slate500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    final body = _message.text.trim();
    setState(() => _sending = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/messages/${widget.conversationId}/send',
        {'body': body},
      );
      _message.clear();
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

String _delegateRoleLabel(String role) {
  switch (role) {
    case 'practical_delegate':
      return 'مندوب عملي';
    case 'delegate':
      return 'مندوب';
    default:
      return role;
  }
}

class DoctorNewsScreen extends ConsumerStatefulWidget {
  const DoctorNewsScreen({super.key});

  static const route = '/doctor/news';

  @override
  ConsumerState<DoctorNewsScreen> createState() => _DoctorNewsScreenState();
}

class _DoctorNewsScreenState extends ConsumerState<DoctorNewsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/news', query: const {'per_page': 30});
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'المركز الإخباري',
      currentRoute: DoctorNewsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

          final items = _docList(_docData(snapshot.data ?? const {}));
          final unread = items.where((item) => item['read_at'] == null).length;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _DocHero(
                  title: 'المركز الإخباري',
                  subtitle:
                      'آخر الأخبار والتنبيهات الجماعية والاستبيانات المرتبطة بحسابك.',
                  icon: Icons.newspaper_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الأخبار',
                      value: items.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.newspaper_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unread.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_email_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const _DocEmpty('لا توجد أخبار حالياً.')
                else
                  ...items.map(
                    (item) => _DoctorNewsCard(
                      item: item,
                      onTap: () => _showNewsDetails(item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewsDetails(_Json item) async {
    final batchId = _docText(item['batch_id']);
    if (batchId.isEmpty) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الخبر',
      icon: Icons.article_rounded,
      color: AppColors.royalBlue,
      fullScreen: true,
      child: _DoctorNewsDetailsPanel(batchId: batchId, onChanged: _reload),
    );
  }
}

class _DoctorNewsCard extends StatelessWidget {
  const _DoctorNewsCard({required this.item, required this.onTap});

  final _Json item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(item['type'], 'announcement');
    final unread = item['read_at'] == null;
    final sender = _docMap(item['sender']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration().copyWith(
          border: unread
              ? Border.all(color: AppColors.royalBlue.withValues(alpha: 0.28))
              : Border.all(color: AppColors.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _notificationTypeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _notificationTypeIcon(type),
                    color: _notificationTypeColor(type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _docText(item['title'], 'خبر جديد'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _DocPill(
                  _notificationTypeLabel(type),
                  _notificationTypeColor(type),
                  icon: unread ? Icons.fiber_manual_record_rounded : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _docText(item['message']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(sender['name'], 'النظام'),
                  AppColors.slate500,
                  icon: Icons.person_rounded,
                ),
                _DocPill(
                  _docDate(item['created_at']),
                  AppColors.slate500,
                  icon: Icons.schedule_rounded,
                ),
                if (_docText(item['attachment_name']).isNotEmpty)
                  const _DocPill(
                    'مرفق',
                    AppColors.royalBlue,
                    icon: Icons.attach_file_rounded,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorNewsDetailsPanel extends ConsumerStatefulWidget {
  const _DoctorNewsDetailsPanel({
    required this.batchId,
    required this.onChanged,
  });

  final String batchId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DoctorNewsDetailsPanel> createState() =>
      _DoctorNewsDetailsPanelState();
}

class _DoctorNewsDetailsPanelState
    extends ConsumerState<_DoctorNewsDetailsPanel> {
  late Future<Map<String, dynamic>> _future = _fetch();
  bool _voting = false;

  Future<Map<String, dynamic>> _fetch() {
    return ref
        .read(staffRepositoryProvider)
        .get('/doctor/news/${widget.batchId}');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

        final data = _docMap(_docData(snapshot.data ?? const {}));
        final item = _docMap(data['item']);
        final related = _docList(data['related_notifications']);
        final options = _docList(data['poll_options']);
        final hasVoted = _docBool(data['has_voted']);
        final sender = _docMap(item['sender']);
        final type = _docText(item['type'], 'announcement');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _DocPill(
                  _notificationTypeLabel(type),
                  _notificationTypeColor(type),
                ),
                const SizedBox(width: 8),
                _DocPill(_docDate(item['created_at']), AppColors.slate500),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _docText(item['title'], 'خبر جديد'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _docText(sender['name'], 'النظام'),
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _docText(item['message']),
              style: const TextStyle(
                color: AppColors.midnight,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_docText(item['attachment_url']).isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _downloadAttachment(item),
                icon: Icon(_docFileIcon(_docText(item['attachment_name']))),
                label: Text(_docText(item['attachment_name'], 'تحميل المرفق')),
              ),
            ],
            if (type == 'poll') ...[
              const SizedBox(height: 18),
              Text(
                hasVoted ? 'تم تسجيل تصويتك' : 'اختر إجابتك',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...options.map((option) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: _cardDecoration(),
                  child: ListTile(
                    title: Text(
                      _docText(option['option_text'] ?? option['text']),
                    ),
                    trailing: hasVoted
                        ? const Icon(Icons.check_circle_outline_rounded)
                        : FilledButton(
                            onPressed: _voting
                                ? null
                                : () => _vote(_docInt(option['id'])),
                            child: const Text('تصويت'),
                          ),
                  ),
                );
              }),
            ],
            if (related.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                'الإشعارات المرتبطة (${related.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...related.map(
                (notification) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: _cardDecoration(),
                  child: Text(
                    _docText(notification['message']),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _vote(int optionId) async {
    if (optionId <= 0) return;
    setState(() => _voting = true);
    try {
      await ref.read(staffRepositoryProvider).post(
        '/doctor/news/${widget.batchId}/vote',
        {'option_id': optionId},
      );
      widget.onChanged();
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _downloadAttachment(_Json item) async {
    try {
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: _docText(item['attachment_url']),
        fileName: _docText(item['attachment_name'], 'news_attachment'),
        section: 'DoctorNews',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التحميل',
        message: 'تم حفظ المرفق في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class DoctorNotificationsScreen extends ConsumerStatefulWidget {
  const DoctorNotificationsScreen({super.key});

  static const route = '/doctor/notifications';

  @override
  ConsumerState<DoctorNotificationsScreen> createState() =>
      _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState
    extends ConsumerState<DoctorNotificationsScreen> {
  late Future<Map<String, dynamic>> _future = _fetch();

  Future<Map<String, dynamic>> _fetch() {
    return ref.read(staffRepositoryProvider).get('/doctor/notifications');
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'الإشعارات',
      currentRoute: DoctorNotificationsScreen.route,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);

          final data = _docMap(_docData(snapshot.data ?? const {}));
          final notifications = _docList(data['notifications']);
          final unreadCount = _docInt(data['unread_count']);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _DocHero(
                  title: 'الإشعارات',
                  subtitle: 'متابعة إشعارات النظام والتعليم عليها كمقروءة.',
                  icon: Icons.notifications_rounded,
                  trailing: unreadCount > 0
                      ? TextButton(
                          onPressed: _markAllRead,
                          child: const Text('قراءة الكل'),
                        )
                      : IconButton.filledTonal(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DocMetric(
                      label: 'الإجمالي',
                      value: notifications.length.toString(),
                      color: AppColors.royalBlue,
                      icon: Icons.notifications_rounded,
                    ),
                    _DocMetric(
                      label: 'غير مقروء',
                      value: unreadCount.toString(),
                      color: AppColors.warning,
                      icon: Icons.mark_email_unread_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (notifications.isEmpty)
                  const _DocEmpty('لا توجد إشعارات حالياً.')
                else
                  ...notifications.map(
                    (notification) => _DoctorNotificationCard(
                      notification: notification,
                      onTap: () => _openNotification(notification),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotification(_Json notification) async {
    final id = _docInt(notification['id']);
    if (id > 0 && notification['read_at'] == null) {
      try {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/notifications/$id/read', const {});
        _reload();
      } catch (_) {
        // Showing details is more important than failing because read tracking failed.
      }
    }
    if (!mounted) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الإشعار',
      icon: Icons.notifications_active_rounded,
      color: _notificationTypeColor(_docText(notification['type'])),
      child: _NotificationDetailsPanel(notification: notification),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .post('/doctor/notifications/mark-all-read', const {});
      if (!mounted) return;
      _reload();
      _docSnack(
        context,
        'تم تعليم جميع الإشعارات كمقروءة.',
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _DoctorNotificationCard extends StatelessWidget {
  const _DoctorNotificationCard({
    required this.notification,
    required this.onTap,
  });

  final _Json notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    final unread = notification['read_at'] == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration().copyWith(
          border: Border.all(
            color: unread
                ? _notificationTypeColor(type).withValues(alpha: 0.32)
                : AppColors.slate100,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _notificationTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _notificationTypeIcon(type),
                color: _notificationTypeColor(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _docText(notification['title'], 'إشعار جديد'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (unread)
                        const Icon(
                          Icons.fiber_manual_record_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _docText(notification['message']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DocPill(
                        _notificationTypeLabel(type),
                        _notificationTypeColor(type),
                      ),
                      _DocPill(
                        _docDate(notification['created_at']),
                        AppColors.slate500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDetailsPanel extends StatelessWidget {
  const _NotificationDetailsPanel({required this.notification});

  final _Json notification;

  @override
  Widget build(BuildContext context) {
    final type = _docText(notification['type'], 'notification');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _DocPill(
              _notificationTypeLabel(type),
              _notificationTypeColor(type),
            ),
            const SizedBox(width: 8),
            _DocPill(_docDate(notification['created_at']), AppColors.slate500),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _docText(notification['title'], 'إشعار جديد'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          _docText(notification['message']),
          style: const TextStyle(
            height: 1.6,
            fontWeight: FontWeight.w700,
            color: AppColors.midnight,
          ),
        ),
        if (_docText(notification['attachment_name']).isNotEmpty) ...[
          const SizedBox(height: 16),
          _DocPill(
            _docText(notification['attachment_name']),
            AppColors.royalBlue,
            icon: Icons.attach_file_rounded,
          ),
        ],
      ],
    );
  }
}

class DoctorClinicalScreen extends ConsumerStatefulWidget {
  const DoctorClinicalScreen({super.key});

  static const route = '/doctor/clinical';

  @override
  ConsumerState<DoctorClinicalScreen> createState() =>
      _DoctorClinicalScreenState();
}

class _DoctorClinicalScreenState extends ConsumerState<DoctorClinicalScreen> {
  int _section = 0;
  late Future<_ClinicalBundle> _future = _fetch();

  Future<_ClinicalBundle> _fetch() async {
    final results = await Future.wait<Map<String, dynamic>>([
      ref.read(staffRepositoryProvider).get('/doctor/clinical/overview'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/rare-cases'),
      ref.read(staffRepositoryProvider).get('/doctor/clinical/volunteers'),
    ]);
    return _ClinicalBundle(
      overview: _docMap(_docData(results[0])),
      rareCases: _clinicalPagedItems(results[1]),
      volunteers: _clinicalPagedItems(results[2]),
    );
  }

  void _reload() => setState(() => _future = _fetch());

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'القسم العملي',
      currentRoute: DoctorClinicalScreen.route,
      floatingActionButton: _section == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showRareCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('حالة نادرة'),
            )
          : _section == 2
          ? FloatingActionButton.extended(
              onPressed: () => _showVolunteerForm(),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('متطوع'),
            )
          : null,
      child: FutureBuilder<_ClinicalBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorView(error: snapshot.error!);
          final bundle = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _DocHero(
                  title: 'القسم العملي والسريري',
                  subtitle:
                      'متابعة الحالات العملية، إعلان الحالات النادرة، وإدارة سجل المتطوعين.',
                  icon: Icons.medical_services_rounded,
                  trailing: IconButton.filledTonal(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('نظرة عامة'),
                      icon: Icon(Icons.dashboard_rounded),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('حالات نادرة'),
                      icon: Icon(Icons.campaign_rounded),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('المتطوعون'),
                      icon: Icon(Icons.groups_rounded),
                    ),
                  ],
                  selected: {_section},
                  onSelectionChanged: (value) {
                    setState(() => _section = value.first);
                  },
                ),
                const SizedBox(height: 16),
                if (_section == 0) _buildOverview(bundle),
                if (_section == 1) _buildRareCases(bundle.rareCases),
                if (_section == 2) _buildVolunteers(bundle.volunteers),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(_ClinicalBundle bundle) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DocMetric(
              label: 'الحالات',
              value: _docText(bundle.overview['total_cases'], '0'),
              color: AppColors.royalBlue,
              icon: Icons.medical_information_rounded,
            ),
            _DocMetric(
              label: 'نشطة',
              value: _docText(bundle.overview['active_cases'], '0'),
              color: AppColors.success,
              icon: Icons.play_circle_rounded,
            ),
            _DocMetric(
              label: 'حالات نادرة',
              value: _docText(
                bundle.overview['rare_cases'],
                bundle.rareCases.length.toString(),
              ),
              color: AppColors.warning,
              icon: Icons.campaign_rounded,
            ),
            _DocMetric(
              label: 'متطوعون',
              value: _docText(
                bundle.overview['volunteers'],
                bundle.volunteers.length.toString(),
              ),
              color: AppColors.teal,
              icon: Icons.groups_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ClinicalActionCard(
          title: 'إعلان حالة نادرة',
          subtitle:
              'انشر حالة سريرية مهمة للطلاب مع تفاصيل المستشفى والقسم والمرفق.',
          icon: Icons.campaign_rounded,
          color: AppColors.warning,
          onTap: () => setState(() => _section = 1),
        ),
        _ClinicalActionCard(
          title: 'سجل المتطوعين',
          subtitle:
              'أضف متطوعين للحالات العملية وتابع حالة توفرهم ومعلومات التواصل.',
          icon: Icons.groups_rounded,
          color: AppColors.teal,
          onTap: () => setState(() => _section = 2),
        ),
      ],
    );
  }

  Widget _buildRareCases(List<_Json> cases) {
    if (cases.isEmpty) {
      return Column(
        children: [
          const _DocEmpty('لا توجد حالات نادرة منشورة بعد.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showRareCaseForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إعلان حالة نادرة'),
          ),
        ],
      );
    }
    return Column(
      children: cases
          .map(
            (rareCase) => _RareCaseCard(
              rareCase: rareCase,
              onTap: () => _showRareCaseDetails(rareCase),
              onToggle: () => _toggleRareCase(rareCase),
              onDelete: () => _deleteRareCase(rareCase),
            ),
          )
          .toList(),
    );
  }

  Widget _buildVolunteers(List<_Json> volunteers) {
    if (volunteers.isEmpty) {
      return Column(
        children: [
          const _DocEmpty('لا يوجد متطوعون في السجل بعد.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showVolunteerForm(),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('إضافة متطوع'),
          ),
        ],
      );
    }
    return Column(
      children: volunteers
          .map(
            (volunteer) => _VolunteerCard(
              volunteer: volunteer,
              onTap: () => _showVolunteerDetails(volunteer),
              onEdit: () => _showVolunteerForm(volunteer: volunteer),
              onToggle: () => _toggleVolunteer(volunteer),
              onDelete: () => _deleteVolunteer(volunteer),
            ),
          )
          .toList(),
    );
  }

  Future<void> _showRareCaseDetails(_Json rareCase) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الحالة النادرة',
      icon: Icons.campaign_rounded,
      color: _docBool(rareCase['is_active'])
          ? AppColors.success
          : AppColors.slate500,
      child: _RareCaseDetails(
        rareCase: rareCase,
        onDownload: () => _downloadRareCaseAttachment(rareCase),
      ),
    );
  }

  Future<void> _showRareCaseForm() async {
    final formKey = GlobalKey<FormState>();
    final patientName = TextEditingController();
    final hospital = TextEditingController();
    final department = TextEditingController();
    final room = TextEditingController();
    final diagnosis = TextEditingController();
    final signs = TextEditingController();
    PlatformFile? attachment;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'إعلان حالة نادرة',
      icon: Icons.campaign_rounded,
      color: AppColors.warning,
      fullScreen: true,
      child: StatefulBuilder(
        builder: (context, setLocal) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: diagnosis,
                  decoration: const InputDecoration(labelText: 'التشخيص'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'التشخيص مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hospital,
                  decoration: const InputDecoration(
                    labelText: 'المستشفى / المركز',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'المستشفى مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: department,
                  decoration: const InputDecoration(labelText: 'القسم'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'القسم مطلوب.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: room,
                  decoration: const InputDecoration(labelText: 'رقم الغرفة'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: patientName,
                  decoration: const InputDecoration(
                    labelText: 'اسم المريض (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: signs,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'العلامات السريرية',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result?.files.single != null) {
                      setLocal(() => attachment = result!.files.single);
                    }
                  },
                  icon: const Icon(Icons.image_rounded),
                  label: Text(attachment?.name ?? 'إضافة صورة مرفقة'),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, true);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('نشر الحالة'),
                ),
              ],
            ),
          );
        },
      ),
    );

    final payload = ok == true
        ? <String, dynamic>{
            'patient_name': patientName.text.trim(),
            'hospital': hospital.text.trim(),
            'department': department.text.trim(),
            'room_number': room.text.trim(),
            'diagnosis': diagnosis.text.trim(),
            'clinical_signs': signs.text.trim(),
          }
        : null;

    patientName.dispose();
    hospital.dispose();
    department.dispose();
    room.dispose();
    diagnosis.dispose();
    signs.dispose();

    if (ok != true || payload == null) return;
    try {
      if (attachment?.path != null) {
        payload['attachment'] = await MultipartFile.fromFile(
          attachment!.path!,
          filename: attachment!.name,
        );
      }
      await ref
          .read(staffRepositoryProvider)
          .upload('/doctor/clinical/rare-cases', payload);
      if (!mounted) return;
      _reload();
      setState(() => _section = 1);
      _docSnack(context, 'تم نشر الحالة النادرة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _toggleRareCase(_Json rareCase) async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .patch(
            '/doctor/clinical/rare-cases/${rareCase['id']}/toggle',
            const {},
          );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteRareCase(_Json rareCase) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف الحالة النادرة',
      message: 'هل تريد حذف هذا الإعلان؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/clinical/rare-cases/${rareCase['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف الحالة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _downloadRareCaseAttachment(_Json rareCase) async {
    final url = _docText(rareCase['attachment_url']);
    if (url.isEmpty) return;
    try {
      final result = await DownloadService.downloadUrlToMoeenFolder(
        url: url,
        fileName: 'rare_case_${rareCase['id']}.jpg',
        section: 'RareCases',
      );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم التحميل',
        message: 'تم حفظ المرفق في:\n${result.path}',
        icon: Icons.file_download_done_rounded,
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _showVolunteerDetails(_Json volunteer) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'بيانات المتطوع',
      icon: Icons.person_rounded,
      color: _docBool(volunteer['is_available'])
          ? AppColors.success
          : AppColors.slate500,
      child: _VolunteerDetails(volunteer: volunteer),
    );
  }

  Future<void> _showVolunteerForm({_Json? volunteer}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: _docText(volunteer?['name']));
    final contact = TextEditingController(
      text: _docText(volunteer?['contact_info']),
    );
    final secondary = TextEditingController(
      text: _docText(volunteer?['phone_secondary']),
    );
    final email = TextEditingController(text: _docText(volunteer?['email']));
    final diagnosis = TextEditingController(
      text: _docText(volunteer?['diagnosis']),
    );
    final signs = TextEditingController(
      text: _docText(volunteer?['clinical_signs']),
    );

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: volunteer == null ? 'إضافة متطوع' : 'تعديل متطوع',
      icon: Icons.person_add_alt_rounded,
      color: AppColors.teal,
      fullScreen: true,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسم المتطوع'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'اسم المتطوع مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contact,
              decoration: const InputDecoration(
                labelText: 'رقم التواصل / واتساب',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'رقم التواصل مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: secondary,
              decoration: const InputDecoration(labelText: 'رقم إضافي'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: diagnosis,
              decoration: const InputDecoration(labelText: 'التشخيص'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'التشخيص مطلوب.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: signs,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'العلامات السريرية'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    final payload = ok == true
        ? {
            'name': name.text.trim(),
            'contact_info': contact.text.trim(),
            'phone_secondary': secondary.text.trim(),
            'email': email.text.trim(),
            'diagnosis': diagnosis.text.trim(),
            'clinical_signs': signs.text.trim(),
          }
        : null;

    name.dispose();
    contact.dispose();
    secondary.dispose();
    email.dispose();
    diagnosis.dispose();
    signs.dispose();

    if (ok != true || payload == null) return;
    try {
      if (volunteer == null) {
        await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/volunteers', payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .put('/doctor/clinical/volunteers/${volunteer['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      setState(() => _section = 2);
      _docSnack(context, 'تم حفظ بيانات المتطوع.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _toggleVolunteer(_Json volunteer) async {
    try {
      await ref
          .read(staffRepositoryProvider)
          .patch(
            '/doctor/clinical/volunteers/${volunteer['id']}/toggle',
            const {},
          );
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _deleteVolunteer(_Json volunteer) async {
    final ok = await showMoeenConfirmDialog(
      context: context,
      title: 'حذف المتطوع',
      message: 'هل تريد حذف هذا المتطوع من السجل؟',
      confirmLabel: 'حذف',
      icon: Icons.delete_rounded,
      color: AppColors.danger,
    );
    if (!ok) return;
    try {
      await ref
          .read(staffRepositoryProvider)
          .delete('/doctor/clinical/volunteers/${volunteer['id']}');
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم حذف المتطوع.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}

class _ClinicalBundle {
  const _ClinicalBundle({
    required this.overview,
    required this.rareCases,
    required this.volunteers,
  });

  final _Json overview;
  final List<_Json> rareCases;
  final List<_Json> volunteers;
}

List<_Json> _clinicalPagedItems(Map<String, dynamic> response) {
  final payload = _docData(response);
  if (payload is List) return _docList(payload);
  final map = _docMap(payload);
  return _docList(map['data'] ?? map['items'] ?? map);
}

class _ClinicalActionCard extends StatelessWidget {
  const _ClinicalActionCard({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

class _RareCaseCard extends StatelessWidget {
  const _RareCaseCard({
    required this.rareCase,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  final _Json rareCase;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = _docBool(rareCase['is_active']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _docText(rareCase['diagnosis'], 'حالة نادرة'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _DocPill(
                  active ? 'منشورة' : 'مخفية',
                  active ? AppColors.success : AppColors.slate500,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(rareCase['hospital'], '-'),
                  AppColors.royalBlue,
                  icon: Icons.local_hospital_rounded,
                ),
                _DocPill(
                  _docText(rareCase['department'], '-'),
                  AppColors.teal,
                  icon: Icons.account_tree_rounded,
                ),
                if (_docText(rareCase['room_number']).isNotEmpty)
                  _DocPill(
                    'غرفة ${_docText(rareCase['room_number'])}',
                    AppColors.slate500,
                    icon: Icons.meeting_room_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _docText(
                rareCase['clinical_signs'],
                'لا توجد علامات سريرية مضافة.',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate600,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    active
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  label: Text(active ? 'إخفاء' : 'نشر'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RareCaseDetails extends StatelessWidget {
  const _RareCaseDetails({required this.rareCase, required this.onDownload});

  final _Json rareCase;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow('التشخيص', _docText(rareCase['diagnosis'])),
        _DetailRow('المستشفى / المركز', _docText(rareCase['hospital'])),
        _DetailRow('القسم', _docText(rareCase['department'])),
        _DetailRow('رقم الغرفة', _docText(rareCase['room_number'], '-')),
        _DetailRow('اسم المريض', _docText(rareCase['patient_name'], '-')),
        _DetailRow('تاريخ النشر', _docDate(rareCase['created_at'])),
        const SizedBox(height: 12),
        Text(
          'العلامات السريرية',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _docText(rareCase['clinical_signs'], 'لا توجد علامات سريرية.'),
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
        ),
        if (_docText(rareCase['attachment_url']).isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.image_rounded),
            label: const Text('تحميل المرفق'),
          ),
        ],
      ],
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.volunteer,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final _Json volunteer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final available = _docBool(volunteer['is_available']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(volunteer['name'], 'متطوع'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _docText(volunteer['diagnosis']),
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _DocPill(
                  available ? 'متاح' : 'غير متاح',
                  available ? AppColors.success : AppColors.slate500,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocPill(
                  _docText(volunteer['contact_info'], '-'),
                  AppColors.royalBlue,
                  icon: Icons.phone_rounded,
                ),
                if (_docText(volunteer['email']).isNotEmpty)
                  _DocPill(
                    _docText(volunteer['email']),
                    AppColors.teal,
                    icon: Icons.email_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل'),
                ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    available
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                  ),
                  label: Text(available ? 'غير متاح' : 'متاح'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VolunteerDetails extends StatelessWidget {
  const _VolunteerDetails({required this.volunteer});

  final _Json volunteer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailRow('الاسم', _docText(volunteer['name'])),
        _DetailRow('رقم التواصل', _docText(volunteer['contact_info'])),
        _DetailRow('رقم إضافي', _docText(volunteer['phone_secondary'], '-')),
        _DetailRow('البريد الإلكتروني', _docText(volunteer['email'], '-')),
        _DetailRow('التشخيص', _docText(volunteer['diagnosis'])),
        _DetailRow(
          'الحالة',
          _docBool(volunteer['is_available']) ? 'متاح' : 'غير متاح',
        ),
        const SizedBox(height: 12),
        Text(
          'العلامات السريرية',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _docText(volunteer['clinical_signs'], 'لا توجد علامات سريرية.'),
          style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

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
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

String _notificationTypeLabel(String type) {
  switch (type) {
    case 'announcement':
      return 'إعلان';
    case 'exam':
      return 'اختبار';
    case 'assignment':
      return 'تكليف';
    case 'attendance':
      return 'حضور';
    case 'poll':
      return 'استبيان';
    case 'resource':
      return 'مورد';
    default:
      return 'إشعار';
  }
}

Color _notificationTypeColor(String type) {
  switch (type) {
    case 'exam':
      return AppColors.danger;
    case 'assignment':
      return AppColors.warning;
    case 'poll':
      return AppColors.teal;
    case 'attendance':
      return AppColors.danger;
    case 'resource':
      return AppColors.royalBlue;
    case 'announcement':
      return AppColors.success;
    default:
      return AppColors.slate500;
  }
}

IconData _notificationTypeIcon(String type) {
  switch (type) {
    case 'exam':
      return Icons.event_available_rounded;
    case 'assignment':
      return Icons.assignment_rounded;
    case 'poll':
      return Icons.poll_rounded;
    case 'attendance':
      return Icons.fact_check_rounded;
    case 'resource':
      return Icons.folder_rounded;
    case 'announcement':
      return Icons.campaign_rounded;
    default:
      return Icons.notifications_rounded;
  }
}
