part of 'staff_screens.dart';

class _TrainingCenterCard extends StatelessWidget {
  const _TrainingCenterCard({
    required this.centerItem,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final _Json centerItem;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = _docText(centerItem['name'], 'مركز تدريب');
    final location = _docText(centerItem['location']);
    final description = _docText(centerItem['description']);
    final casesList = _docList(centerItem['cases']);
    final casesCount = _docInt(centerItem['cases_count'], casesList.length);

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
              color: AppColors.royalBlue.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.royalBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (location.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        fontFamily: 'Cairo',
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _DocPill(
                        'الحالات السريرية: $casesCount',
                        casesCount > 0 ? AppColors.success : AppColors.slate500,
                        icon: Icons.personal_injury_rounded,
                      ),
                      if (onEdit != null)
                        ActionChip(
                          onPressed: onEdit,
                          avatar: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text(
                            'تعديل',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: AppColors.slate50,
                          side: const BorderSide(color: AppColors.slate100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      if (onDelete != null)
                        ActionChip(
                          onPressed: onDelete,
                          avatar: const Icon(
                            Icons.delete_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          label: const Text(
                            'حذف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.05,
                          ),
                          side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

class _TrainingCenterDetails extends StatelessWidget {
  const _TrainingCenterDetails({required this.centerItem});

  final _Json centerItem;

  @override
  Widget build(BuildContext context) {
    final name = _docText(centerItem['name'], 'مركز تدريب');
    final location = _docText(centerItem['location'], '-');
    final description = _docText(centerItem['description'], '-');
    final casesList = _docList(centerItem['cases']);
    final casesCount = _docInt(centerItem['cases_count'], casesList.length);
    final createdAt = _docDate(centerItem['created_at']);
    final updatedAt = _docDate(centerItem['updated_at']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.royalBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.royalBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.royalBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              if (location != '-') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.slate400,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bento/Grid Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل المركز',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                  fontFamily: 'Cairo',
                ),
              ),
              const Divider(height: 24),
              _DetailRow('الوصف', description),
              const Divider(height: 24),
              _DetailRow('عدد الحالات المرتبطة', '$casesCount حالة'),
              const Divider(height: 24),
              _DetailRow('تاريخ التسجيل', createdAt),
              if (createdAt != updatedAt && updatedAt.isNotEmpty) ...[
                const Divider(height: 24),
                _DetailRow('آخر تحديث', updatedAt),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cases Sublist if any
        if (casesCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الحالات السريرية المرتبطة بالمركز',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    _DocPill(
                      '$casesCount حالة',
                      AppColors.success,
                      icon: Icons.personal_injury_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: casesCount,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = _docMap(casesList[index]);
                    final patientName = _docText(
                      item['patient_name'],
                      'مريض بدون اسم',
                    );
                    final diagnosis = _docText(
                      item['diagnosis_or_description'],
                      'لا يوجد تشخيص',
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.personal_injury_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.midnight,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      subtitle: Text(
                        diagnosis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
