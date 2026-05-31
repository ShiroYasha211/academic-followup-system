part of 'staff_screens.dart';

Color _volunteerFollowUpColor(String status) {
  return switch (status) {
    'contacted' => AppColors.royalBlue,
    'agreed' => AppColors.success,
    'declined' => AppColors.danger,
    'needs_follow_up' => AppColors.warning,
    _ => AppColors.slate500,
  };
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.volunteer,
    required this.onTap,
    required this.onEdit,
    required this.onFollowUp,
    required this.onToggle,
    required this.onDelete,
    this.onCall,
    this.onWhatsApp,
    this.onCopy,
  });

  final _Json volunteer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onFollowUp;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Future<void> Function()? onCall;
  final Future<void> Function()? onWhatsApp;
  final Future<void> Function()? onCopy;

  @override
  Widget build(BuildContext context) {
    final available = _docBool(volunteer['is_available']);
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
            color: available
                ? AppColors.teal.withValues(alpha: 0.15)
                : AppColors.slate100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: available
                  ? AppColors.teal.withValues(alpha: 0.04)
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (available ? AppColors.teal : AppColors.slate500)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _docText(volunteer['name'], 'م').isNotEmpty
                          ? _docText(volunteer['name'], 'م')[0]
                          : 'م',
                      style: TextStyle(
                        color: available ? AppColors.teal : AppColors.slate700,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
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
                          color: AppColors.slate900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DocPill(
                        available ? 'متاح للتطوع' : 'غير متاح حالياً',
                        available ? AppColors.teal : AppColors.slate500,
                        icon: available
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
                      ),
                      const SizedBox(height: 6),
                      _DocPill(
                        _docText(
                          volunteer['follow_up_status_label'],
                          'لم يتم التواصل',
                        ),
                        _volunteerFollowUpColor(
                          _docText(volunteer['follow_up_status']),
                        ),
                        icon: Icons.event_note_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    AppColors.royalBlue,
                    icon: Icons.email_rounded,
                  ),
                if (_docText(volunteer['phone_secondary']).isNotEmpty)
                  _DocPill(
                    'رقم بديل: ${_docText(volunteer['phone_secondary'])}',
                    AppColors.slate500,
                    icon: Icons.phone_android_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_docText(volunteer['contact_info']).isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: _VolunteerQuickAction(
                      label: 'اتصال',
                      icon: Icons.call_rounded,
                      color: AppColors.success,
                      onPressed: onCall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VolunteerQuickAction(
                      label: 'واتساب',
                      icon: Icons.chat_rounded,
                      color: AppColors.teal,
                      onPressed: onWhatsApp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VolunteerQuickAction(
                      label: 'نسخ',
                      icon: Icons.copy_rounded,
                      color: AppColors.royalBlue,
                      onPressed: onCopy,
                    ),
                  ),
                ],
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
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_information_rounded,
                        size: 14,
                        color: AppColors.slate500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _docText(volunteer['diagnosis'], 'تشخيص الحالة'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  if (_docText(volunteer['clinical_signs']).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _docText(volunteer['clinical_signs']),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onFollowUp,
                    icon: const Icon(Icons.event_note_rounded, size: 16),
                    label: const Text(
                      'متابعة',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.royalBlue,
                    backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      available
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                    ),
                    label: Text(
                      available ? 'تعطيل الحساب' : 'تنشيط متاح',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: available
                          ? AppColors.slate700
                          : AppColors.success,
                      backgroundColor:
                          (available ? AppColors.slate100 : AppColors.success)
                              .withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 16),
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
  const _VolunteerDetails({
    required this.volunteer,
    this.onFollowUp,
    this.onCall,
    this.onWhatsApp,
  });

  final _Json volunteer;
  final VoidCallback? onFollowUp;
  final Future<void> Function()? onCall;
  final Future<void> Function()? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final available = _docBool(volunteer['is_available']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (available ? AppColors.teal : AppColors.slate500).withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (available ? AppColors.teal : AppColors.slate500)
                  .withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                available ? Icons.check_circle_rounded : Icons.block_rounded,
                color: available ? AppColors.teal : AppColors.slate500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                available
                    ? 'هذا المتطوع متاح حالياً لاستقبال الحالات'
                    : 'هذا المتطوع غير متاح حالياً',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: available ? AppColors.teal : AppColors.slate700,
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
                    Icons.badge_rounded,
                    color: AppColors.royalBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'بيانات المتطوع والاتصال',
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
              _DetailRow('الاسم الكامل', _docText(volunteer['name'])),
              _DetailRow(
                'حالة المتابعة',
                _docText(volunteer['follow_up_status_label'], 'لم يتم التواصل'),
              ),
              _DetailRow(
                'آخر تواصل',
                _docText(volunteer['last_contacted_at_label'], '-'),
              ),
              _DetailRow(
                'طريقة مفضلة',
                _docText(volunteer['preferred_contact_method_label'], '-'),
              ),
              _DetailRow(
                'رقم التواصل',
                _docText(volunteer['contact_info']),
                trailing: _VolunteerCopyIcon(
                  value: _docText(volunteer['contact_info']),
                  label: 'رقم التواصل',
                ),
              ),
              _DetailRow(
                'رقم إضافي',
                _docText(volunteer['phone_secondary'], '-'),
                trailing: _VolunteerCopyIcon(
                  value: _docText(volunteer['phone_secondary']),
                  label: 'الرقم الإضافي',
                ),
              ),
              _DetailRow(
                'البريد الإلكتروني',
                _docText(volunteer['email'], '-'),
                trailing: _VolunteerCopyIcon(
                  value: _docText(volunteer['email']),
                  label: 'البريد الإلكتروني',
                ),
              ),
              if (_docText(volunteer['contact_info']).isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _VolunteerQuickAction(
                        label: 'اتصال',
                        icon: Icons.call_rounded,
                        color: AppColors.success,
                        onPressed: onCall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _VolunteerQuickAction(
                        label: 'واتساب',
                        icon: Icons.chat_rounded,
                        color: AppColors.teal,
                        onPressed: onWhatsApp,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onFollowUp,
                icon: const Icon(Icons.event_note_rounded, size: 20),
                label: const Text(
                  'تسجيل متابعة جديدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
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
                    Icons.medical_information_rounded,
                    color: AppColors.teal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'التشخيص والسريريات',
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
              _DetailRow('التشخيص الطبي', _docText(volunteer['diagnosis'])),
              _DetailRow(
                'ملاحظات داخلية',
                _docText(volunteer['internal_notes'], '-'),
              ),
              const SizedBox(height: 10),
              const Text(
                'العلامات السريرية:',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _docText(
                  volunteer['clinical_signs'],
                  'لا توجد علامات سريرية مضافة.',
                ),
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
        if (_docList(volunteer['logs']).isNotEmpty) ...[
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
                      Icons.history_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'آخر المتابعات',
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
                ..._docList(volunteer['logs']).map((log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DocPill(
                          _docText(log['follow_up_status_label']),
                          _volunteerFollowUpColor(
                            _docText(log['follow_up_status']),
                          ),
                          icon: Icons.event_note_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            _docText(log['contacted_at_label']),
                            _docText(log['contact_method_label']),
                          ].where((value) => value.isNotEmpty).join(' - '),
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (_docText(log['notes']).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _docText(log['notes']),
                            style: const TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VolunteerQuickAction extends StatelessWidget {
  const _VolunteerQuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed == null ? null : () => onPressed!(),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _VolunteerCopyIcon extends StatelessWidget {
  const _VolunteerCopyIcon({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
    return IconButton(
      tooltip: 'نسخ $label',
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        _docSnack(context, 'تم نسخ $label.', color: AppColors.success);
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      color: AppColors.royalBlue,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.royalBlue.withValues(alpha: 0.08),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

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
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                height: 1.4,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
