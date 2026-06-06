part of 'staff_screens.dart';

Color _rareCaseStatusColor(String status) {
  return switch (status) {
    'draft' => AppColors.slate500,
    'closed' => AppColors.warning,
    'archived' => AppColors.danger,
    _ => AppColors.success,
  };
}

class _RareCaseCard extends StatelessWidget {
  const _RareCaseCard({
    required this.rareCase,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  final _Json rareCase;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final active = _docBool(rareCase['is_active']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.slate100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AppColors.success.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (active ? AppColors.success : AppColors.slate500)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: active ? AppColors.success : AppColors.slate500,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(rareCase['diagnosis'], 'حالة نادرة'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نشر: ${_docDate(rareCase['created_at'])}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate400,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DocPill(
                  _docText(
                    rareCase['status_label'],
                    active ? 'منشورة' : 'مخفية',
                  ),
                  _rareCaseStatusColor(_docText(rareCase['status'])),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            if (_docText(rareCase['updated_at']).isNotEmpty &&
                _docText(rareCase['updated_at']) !=
                    _docText(rareCase['created_at'])) ...[
              _DocPill(
                'تم التعديل: ${_docText(rareCase['updated_at_label'], _docDate(rareCase['updated_at']))}',
                AppColors.warning,
                icon: Icons.edit_calendar_rounded,
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'العلامات السريرية:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _docText(
                      rareCase['clinical_signs'],
                      'لا توجد علامات سريرية مضافة.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate700,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      active
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                    ),
                    label: Text(
                      active ? 'إخفاء الحالة' : 'نشر الحالة',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: active
                          ? AppColors.slate700
                          : AppColors.success,
                      backgroundColor:
                          (active ? AppColors.slate100 : AppColors.success)
                              .withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onEdit != null) ...[
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'تعديل',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.royalBlue,
                      backgroundColor: AppColors.royalBlue.withValues(
                        alpha: 0.1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'حذف',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    final active = _docBool(rareCase['is_active']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (active ? AppColors.success : AppColors.slate500).withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (active ? AppColors.success : AppColors.slate500)
                  .withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: active ? AppColors.success : AppColors.slate500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                active
                    ? 'هذه الحالة النادرة منشورة للجميع حالياً'
                    : 'هذه الحالة مخفية وغير معروضة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? AppColors.success : AppColors.slate700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.medical_information_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'البيانات الطبية والتشخيص',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              _DetailRow('التشخيص', _docText(rareCase['diagnosis'])),
              _DetailRow('اسم المريض', _docText(rareCase['patient_name'], '-')),
              _DetailRow(
                'حالة الإعلان',
                _docText(rareCase['status_label'], active ? 'منشورة' : 'مخفية'),
              ),
              _DetailRow(
                'عدد المشاهدات',
                _docText(rareCase['views_count'], '0'),
              ),
              _DetailRow('تاريخ النشر', _docDate(rareCase['created_at'])),
              if (_docText(rareCase['updated_at']).isNotEmpty &&
                  _docText(rareCase['updated_at']) !=
                      _docText(rareCase['created_at']))
                _DetailRow(
                  'آخر تعديل',
                  _docText(
                    rareCase['updated_at_label'],
                    _docDate(rareCase['updated_at']),
                  ),
                ),
              _DetailRow(
                'ملاحظات داخلية',
                _docText(rareCase['internal_notes'], '-'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'موقع الإقامة والسرير',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              _DetailRow('المستشفى / المركز', _docText(rareCase['hospital'])),
              _DetailRow('القسم', _docText(rareCase['department'])),
              _DetailRow('رقم الغرفة', _docText(rareCase['room_number'], '-')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.biotech_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'العلامات السريرية',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 24,
                thickness: 1,
                color: AppColors.slate100,
              ),
              Text(
                _docText(rareCase['clinical_signs'], 'لا توجد علامات سريرية.'),
                style: const TextStyle(
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.slate700,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        if (_docText(rareCase['attachment_url']).isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showImagePreview(
                context,
                _docText(rareCase['attachment_url']),
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.network(
                    _docText(rareCase['attachment_url']),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 220,
                        color: AppColors.slate50,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: AppColors.slate50,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              color: AppColors.slate400,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'تعذر تحميل الصورة المرفقة',
                              style: TextStyle(
                                color: AppColors.slate500,
                                fontFamily: 'Cairo',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _ImageOverlayButton(
                      icon: Icons.open_in_full_rounded,
                      onPressed: () => _showImagePreview(
                        context,
                        _docText(rareCase['attachment_url']),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _ImageOverlayButton(
                      icon: Icons.download_rounded,
                      onPressed: onDownload,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showImagePreview(BuildContext context, String imageUrl) async {
    if (imageUrl.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: const Text(
                      'تعذر عرض الصورة',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageOverlayButton extends StatelessWidget {
  const _ImageOverlayButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.royalBlue, size: 20),
        ),
      ),
    );
  }
}

const _volunteerFollowUpStatuses = <String, String>{
  'not_contacted': 'لم يتم التواصل',
  'contacted': 'تم التواصل',
  'agreed': 'موافق',
  'declined': 'اعتذر',
  'needs_follow_up': 'يحتاج متابعة',
};

const _volunteerContactMethods = <String, String>{
  'phone': 'اتصال',
  'whatsapp': 'واتساب',
  'email': 'بريد إلكتروني',
  'other': 'أخرى',
};

extension _DoctorClinicalRareCaseActions on _DoctorClinicalSectionScreenState {
  Future<void> _openRareCaseForm({_Json? item}) async {
    final formKey = GlobalKey<FormState>();
    final diagnosis = TextEditingController(text: _docText(item?['diagnosis']));
    final hospital = TextEditingController(text: _docText(item?['hospital']));
    final department = TextEditingController(
      text: _docText(item?['department']),
    );
    final room = TextEditingController(text: _docText(item?['room_number']));
    final patientName = TextEditingController(
      text: _docText(item?['patient_name']),
    );
    final signs = TextEditingController(
      text: _docText(item?['clinical_signs']),
    );
    final internalNotes = TextEditingController(
      text: _docText(item?['internal_notes']),
    );
    var status = _docText(item?['status'], 'published');
    if (!{'draft', 'published', 'closed', 'archived'}.contains(status)) {
      status = 'published';
    }
    PlatformFile? attachment;

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: item == null ? 'إعلان حالة نادرة' : 'تعديل إعلان الحالة',
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.medical_information_rounded,
                            color: AppColors.royalBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'البيانات الطبية',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      TextFormField(
                        controller: diagnosis,
                        decoration: InputDecoration(
                          labelText: 'التشخيص الطبي',
                          prefixIcon: const Icon(
                            Icons.medical_services_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'التشخيص مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: signs,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'العلامات السريرية وأعراض الحالة',
                          prefixIcon: const Icon(
                            Icons.description_rounded,
                            color: AppColors.royalBlue,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.royalBlue,
                              width: 1.5,
                            ),
                          ),
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'الموقع والمريض',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      TextFormField(
                        controller: hospital,
                        decoration: InputDecoration(
                          labelText: 'المستشفى / المركز',
                          prefixIcon: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'المستشفى مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: department,
                        decoration: InputDecoration(
                          labelText: 'القسم الطبي',
                          prefixIcon: const Icon(
                            Icons.account_tree_rounded,
                            color: AppColors.teal,
                          ),
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'القسم مطلوب.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: room,
                              decoration: InputDecoration(
                                labelText: 'رقم الغرفة',
                                prefixIcon: const Icon(
                                  Icons.meeting_room_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: patientName,
                              decoration: InputDecoration(
                                labelText: 'اسم المريض (اختياري)',
                                prefixIcon: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.slate500,
                                ),
                                filled: true,
                                fillColor: AppColors.slate50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate500,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.image_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'المرفقات والصور',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      if (item != null &&
                          _docText(item['attachment_url']).isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'اترك الصورة بدون تغيير إذا كنت تريد الاحتفاظ بالمرفق الحالي.',
                                  style: TextStyle(
                                    color: AppColors.slate700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result?.files.single != null) {
                            setLocal(() => attachment = result!.files.single);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: attachment == null
                            ? Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.slate300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: AppColors.slate400,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'إضافة صورة مرفقة (اختياري)',
                                      style: TextStyle(
                                        color: AppColors.slate600,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'اضغط لتحديد ملف الصورة من المعرض',
                                      style: TextStyle(
                                        color: AppColors.slate400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: AppColors.slate50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.royalBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(attachment!.path!),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: FloatingActionButton.small(
                                          heroTag:
                                              'remove_attachment_rare_case',
                                          onPressed: () {
                                            setLocal(() => attachment = null);
                                          },
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.danger,
                                          child: const Icon(
                                            Icons.delete_rounded,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          child: Text(
                                            attachment!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'إعدادات النشر والمتابعة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: AppColors.slate100,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'الحالة'),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('مسودة'),
                          ),
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('منشورة'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('مغلقة'),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text('مؤرشفة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) status = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: internalNotes,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات داخلية لا تظهر للطلاب',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, true);
                  },
                  icon: Icon(
                    item == null ? Icons.send_rounded : Icons.save_rounded,
                  ),
                  label: Text(
                    item == null ? 'نشر الحالة الآن' : 'حفظ التعديلات',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
            'status': status,
            'internal_notes': internalNotes.text.trim(),
          }
        : null;

    Future.delayed(const Duration(milliseconds: 500), () {
      patientName.dispose();
      hospital.dispose();
      department.dispose();
      room.dispose();
      diagnosis.dispose();
      signs.dispose();
      internalNotes.dispose();
    });

    if (ok != true || payload == null) return;
    try {
      if (attachment?.path != null) {
        payload['attachment'] = await MultipartFile.fromFile(
          attachment!.path!,
          filename: attachment!.name,
        );
      }
      if (item == null) {
        await ref.read(staffRepositoryProvider).upload(_endpoint, payload);
      } else {
        await ref
            .read(staffRepositoryProvider)
            .uploadPut('$_endpoint/${item['id']}', payload);
      }
      if (!mounted) return;
      _reload();
      _docSnack(
        context,
        item == null ? 'تم نشر الحالة النادرة.' : 'تم تعديل الحالة النادرة.',
        color: AppColors.success,
      );
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }
}
