part of 'staff_screens.dart';

class _ClinicalManualAttendanceForm extends StatefulWidget {
  const _ClinicalManualAttendanceForm({
    required this.data,
    required this.onSubmit,
  });

  final _Json data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_ClinicalManualAttendanceForm> createState() =>
      _ClinicalManualAttendanceFormState();
}

class _ClinicalManualAttendanceFormState
    extends State<_ClinicalManualAttendanceForm> {
  int? _studentId;
  int? _centerId;
  int? _departmentId;
  bool _saving = false;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = _docList(widget.data['students']);
    final centers = _docList(
      widget.data['training_centers'] ?? widget.data['centers'],
    );
    final departments = _docList(widget.data['departments']);
    return _DocFilterPanel(
      title: 'تسجيل حضور يدوي',
      icon: Icons.edit_calendar_rounded,
      children: [
        _dropdown(
          'الطالب',
          students,
          _studentId,
          (v) => setState(() => _studentId = v),
        ),
        const SizedBox(height: 12),
        _dropdown(
          'المركز',
          centers,
          _centerId,
          (v) => setState(() => _centerId = v),
        ),
        const SizedBox(height: 12),
        _dropdown(
          'القسم',
          departments,
          _departmentId,
          (v) => setState(() => _departmentId = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'ملاحظات'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
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
          label: const Text('تسجيل الحضور'),
        ),
      ],
    );
  }

  DropdownButtonFormField<int> _dropdown(
    String label,
    List<_Json> items,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item['name'], _docText(item['student_number'], '-')),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'student_id': _studentId,
        'training_center_id': _centerId,
        'department_id': _departmentId,
        'doctor_notes': _notes.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ignore: unused_element
class _LegacyClinicalEvaluationForm extends StatefulWidget {
  const _LegacyClinicalEvaluationForm({
    required this.data,
    required this.onSubmit,
  });

  final _Json data;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_LegacyClinicalEvaluationForm> createState() =>
      _LegacyClinicalEvaluationFormState();
}

// ignore: unused_element
class _LegacyClinicalEvaluationFormState
    extends State<_LegacyClinicalEvaluationForm> {
  int? _studentId;
  int? _checklistId;
  int? _bodySystemId;
  String _timerType = 'fixed';
  final _feedback = TextEditingController();
  final Map<int, String> _scores = {};
  bool _saving = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  _Json? get _selectedChecklist {
    return _docList(widget.data['checklists'])
        .where((item) => _docInt(item['id']) == _checklistId)
        .cast<_Json?>()
        .firstWhere((item) => item != null, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final students = _docList(widget.data['students']);
    final checklists = _docList(widget.data['checklists']);
    final systems = _docList(widget.data['body_systems']);
    final checklist = _selectedChecklist;
    final items = _docList(checklist?['items'])
        .where(
          (item) =>
              _docText(item['parent_id']).isEmpty ||
              _docText(item['parent_id']) == '0',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Basic Evaluation Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      color: AppColors.royalBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'بيانات التقييم السريري الأساسية',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModernDropdown(
                label: 'الطالب المراد تقييمه',
                icon: Icons.person_rounded,
                items: students,
                value: _studentId,
                onChanged: (v) => setState(() => _studentId = v),
              ),
              const SizedBox(height: 14),
              _buildModernDropdown(
                label: 'نموذج / قائمة التقييم السريري',
                icon: Icons.fact_check_rounded,
                items: checklists,
                value: _checklistId,
                titleKey: 'title',
                onChanged: (v) {
                  setState(() {
                    _checklistId = v;
                    _scores.clear();
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildModernDropdown(
                label: 'نظام وأجهزة الجسم المقترنة',
                icon: Icons.settings_accessibility_rounded,
                items: systems,
                value: _bodySystemId,
                onChanged: (v) => setState(() => _bodySystemId = v),
              ),
              const SizedBox(height: 16),
              const Text(
                'نوع المؤقت السريري للاختبار',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate600,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTimerChoice(
                      type: 'fixed',
                      label: 'مؤقت رسمي / ثابت',
                      icon: Icons.timer_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTimerChoice(
                      type: 'open',
                      label: 'مؤقت مفتوح',
                      icon: Icons.av_timer_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Checklist Steps / Empty State
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 44,
                  color: AppColors.slate400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'بانتظار اختيار نموذج التقييم السريري',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnight,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'يرجى تحديد قائمة التقييم السريري من القائمة أعلاه لعرض الخطوات الطبية والمعايير المطلوب تقييم الطالب على أساسها.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'خطوات التقييم والدرجات المستحقة',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: AppColors.midnight,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final id = _docInt(item['id']);
            final score = _scores[id] ?? 'not_done';
            final maxMarks = _docText(item['marks'], '1');

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'الخطوة ${index + 1}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.royalBlue,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الدرجة المحددة: $maxMarks درجة',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _docText(item['description']),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScorePill(
                          id: id,
                          value: 'done',
                          label: 'تم بالكامل',
                          icon: Icons.check_circle_rounded,
                          activeColor: AppColors.success,
                          inactiveColor: const Color(0xFFE8F5E9),
                          currentValue: score,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScorePill(
                          id: id,
                          value: 'partial',
                          label: 'تم جزئياً',
                          icon: Icons.pending_rounded,
                          activeColor: AppColors.gold,
                          inactiveColor: const Color(0xFFFFF8E1),
                          currentValue: score,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScorePill(
                          id: id,
                          value: 'not_done',
                          label: 'لم يتم',
                          icon: Icons.cancel_rounded,
                          activeColor: AppColors.danger,
                          inactiveColor: const Color(0xFFFFEBEE),
                          currentValue: score,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 14),

        // 3. Feedback Notes Field
        TextField(
          controller: _feedback,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.midnight,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            labelText: 'ملاحظات وتوجيهات التقييم (اختياري)',
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.slate600,
              fontFamily: 'Cairo',
            ),
            alignLabelWithHint: true,
            hintText: 'اكتب ملاحظاتك وتوجيهاتك السريرية للطالب لتحسين أدائه...',
            hintStyle: const TextStyle(
              fontSize: 11.5,
              color: AppColors.slate400,
              fontFamily: 'Cairo',
            ),
            prefixIcon: const Icon(Icons.comment_rounded, size: 18),
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.slate100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.slate100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.royalBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. Save Submit Button
        Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.royalBlue, Color(0xFF4D6FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saving || items.isEmpty ? null : _submit,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(24),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'حفظ التقييم واعتماد النتيجة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required List<_Json> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    String titleKey = 'name',
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.slate600,
          fontFamily: 'Cairo',
        ),
        prefixIcon: Icon(icon, size: 18),
        fillColor: AppColors.slate50,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: _docInt(item['id']),
              child: Text(
                _docText(item[titleKey], _docText(item['name'], '-')),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnight,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimerChoice({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final active = _timerType == type;
    final color = AppColors.royalBlue;

    return Container(
      decoration: BoxDecoration(
        color: active ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? color : AppColors.slate100,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _timerType = type),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.slate600,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : AppColors.slate700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScorePill({
    required int id,
    required String value,
    required String label,
    required IconData icon,
    required Color activeColor,
    required Color inactiveColor,
    required String currentValue,
  }) {
    final active = currentValue == value;

    return Container(
      decoration: BoxDecoration(
        color: active ? activeColor : inactiveColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? activeColor : inactiveColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _scores[id] = value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? Colors.white : activeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : activeColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final checklist = _selectedChecklist;
      final items = _docList(checklist?['items'])
          .where(
            (item) =>
                _docText(item['parent_id']).isEmpty ||
                _docText(item['parent_id']) == '0',
          )
          .toList();
      await widget.onSubmit({
        'checklist_id': _checklistId,
        'student_id': _studentId,
        'body_system_id': _bodySystemId,
        'timer_type': _timerType,
        'time_taken_seconds': 0,
        'doctor_feedback': _feedback.text.trim(),
        'scores': {
          for (final item in items)
            '${_docInt(item['id'])}': {
              'score': _scores[_docInt(item['id'])] ?? 'not_done',
            },
        },
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
