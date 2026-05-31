part of 'staff_screens.dart';

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.departmentItem,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final _Json departmentItem;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = _docText(departmentItem['name'], 'قسم طبي');
    final description = _docText(departmentItem['description']);
    final isCustom = departmentItem['doctor_id'] != null;
    final createdAt = _docDate(departmentItem['created_at']);

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
              color: AppColors.info.withValues(alpha: 0.05),
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
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                color: AppColors.info,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      height: 1.35,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (description.isNotEmpty && description != '-') ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.45,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [

                      if (createdAt.isNotEmpty && createdAt != '-')
                        _DocPill(
                          createdAt,
                          AppColors.slate400,
                          icon: Icons.calendar_today_rounded,
                        ),
                      if (isCustom) ...[
                        if (onEdit != null)
                          ActionChip(
                            onPressed: onEdit,
                            avatar: const Icon(Icons.edit_rounded, size: 14, color: AppColors.royalBlue),
                            label: const Text(
                              'تعديل',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
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

class _DepartmentDetails extends StatelessWidget {
  const _DepartmentDetails({required this.departmentItem});

  final _Json departmentItem;

  @override
  Widget build(BuildContext context) {
    final name = _docText(departmentItem['name'], 'قسم طبي');
    final description = _docText(departmentItem['description'], 'لا يوجد وصف متاح لهذا القسم.');
    final createdAt = _docDate(departmentItem['created_at']);
    final updatedAt = _docDate(departmentItem['updated_at']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.info.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_tree_rounded,
                    color: AppColors.info,
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
                'تفاصيل القسم',
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
              _DetailRow('تاريخ التسجيل', createdAt),
              if (createdAt != updatedAt && updatedAt.isNotEmpty && updatedAt != '-') ...[
                const Divider(height: 24),
                _DetailRow('آخر تحديث', updatedAt),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
