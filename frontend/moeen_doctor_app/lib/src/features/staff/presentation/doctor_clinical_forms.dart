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
