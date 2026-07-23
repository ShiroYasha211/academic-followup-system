part of 'staff_screens.dart';

class _ClinicalListCard extends StatelessWidget {
  const _ClinicalListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.status,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_docText(status).isNotEmpty)
                        _DocPill(status!, color, icon: Icons.circle_rounded),
                      if (onEdit != null)
                        ActionChip(
                          onPressed: onEdit,
                          avatar: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('تعديل'),
                        ),
                      if (onDelete != null)
                        ActionChip(
                          onPressed: onDelete,
                          avatar: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          label: const Text('حذف'),
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

class _JsonDetailsView extends StatelessWidget {
  const _JsonDetailsView({required this.item});

  final _Json item;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(
      item,
    ).entries.where((entry) => entry.value.isNotEmpty).take(28).toList();
    if (rows.isEmpty) return const _DocEmpty('لا توجد تفاصيل إضافية.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map((entry) => _DetailRow(_label(entry.key), entry.value))
          .toList(),
    );
  }

  Map<String, String> _flatten(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final result = <String, String>{};
    for (final entry in source.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value == null) continue;
      if (value is Map) {
        result.addAll(_flatten(Map<String, dynamic>.from(value), key));
      } else if (value is List) {
        if (value.isNotEmpty) result[key] = '${value.length} عناصر';
      } else {
        final text = value.toString();
        if (text.isNotEmpty) result[key] = text;
      }
    }
    return result;
  }

  String _label(String key) {
    return switch (key) {
      'id' => 'المعرف',
      'name' => 'الاسم',
      'title' => 'العنوان',
      'description' => 'الوصف',
      'patient_name' => 'اسم المريض',
      'student.name' => 'الطالب',
      'student.student_number' => 'رقم القيد',
      'status' => 'الحالة',
      'status_label' => 'وصف الحالة',
      'created_at' => 'تاريخ الإنشاء',
      'updated_at' => 'آخر تحديث',
      'diagnosis' => 'التشخيص',
      'diagnosis_or_description' => 'التشخيص / الوصف',
      'clinical_signs' => 'العلامات السريرية',
      'doctor_notes' => 'ملاحظات الدكتور',
      _ => key.replaceAll('_', ' '),
    };
  }
}
