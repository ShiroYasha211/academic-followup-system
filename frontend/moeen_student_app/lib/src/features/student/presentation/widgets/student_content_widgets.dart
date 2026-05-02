part of '../student_content_screens.dart';

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child, this.height = 64});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _AsyncBody<T> extends StatelessWidget {
  const _AsyncBody({
    required this.state,
    required this.builder,
    required this.onRetry,
    this.loading,
  });

  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(message: error.toString(), onRetry: onRetry),
      data: builder,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.color,
    required this.subject,
    required this.doctorName,
    required this.termName,
    required this.semesterName,
    required this.onTap,
  });

  final Color color;
  final Map<String, dynamic> subject;
  final String doctorName;
  final String termName;
  final String semesterName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 18,
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(subject, 'name', fallback: 'مقرر'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'د. $doctorName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (termName.isNotEmpty)
                            _MiniBadge(label: termName, color: color),
                          if (semesterName.isNotEmpty)
                            _MiniBadge(
                              label: semesterName,
                              color: AppColors.info,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: color.withValues(alpha: 0.10)),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color, {this.id});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? id;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items, this.onTap, this.selectedId});

  final List<_Metric> items;
  final ValueChanged<String>? onTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.68,
      children: items
          .map(
            (item) => _MetricCard(
              item: item,
              onTap: onTap != null && item.id != null
                  ? () => onTap!(item.id!)
                  : null,
              isSelected: selectedId != null && item.id == selectedId,
            ),
          )
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item, this.onTap, this.isSelected = false});

  final _Metric item;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? item.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : item.color.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isSelected ? Colors.white : item.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : item.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _DeprivationCard extends StatelessWidget {
  const _DeprivationCard({required this.info});

  final Map<String, dynamic> info;

  @override
  Widget build(BuildContext context) {
    final warning = text(info, 'warning_level').isNotEmpty;
    final color = warning ? AppColors.danger : AppColors.success;
    return _ColorSection(
      title: 'حالة الحرمان',
      icon: warning ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
      color: color,
      child: Column(
        children: [
          _InfoRow(
            label: 'نسبة الغياب',
            value: '${text(info, 'absence_percent', fallback: '0')}%',
          ),
          _InfoRow(
            label: 'الحد الأقصى للغياب',
            value: text(info, 'max_absences_allowed', fallback: '-'),
          ),
          _InfoRow(
            label: 'الحالة',
            value: warning ? 'يوجد تنبيه حرمان' : 'ضمن النطاق الآمن',
          ),
        ],
      ),
    );
  }
}

class _StudyStats extends StatelessWidget {
  const _StudyStats({
    required this.stats,
    this.activeFilter,
    this.onFilterChanged,
  });

  final Map<String, dynamic> stats;
  final String? activeFilter;
  final ValueChanged<String>? onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return _MetricGrid(
      onTap: onFilterChanged,
      selectedId: activeFilter,
      items: [
        _Metric(
          'مهام اليوم',
          text(stats, 'today', fallback: '0'),
          Icons.today_rounded,
          AppColors.primary,
          id: 'today',
        ),
        _Metric(
          'متأخرة',
          text(stats, 'overdue', fallback: '0'),
          Icons.error_outline_rounded,
          AppColors.danger,
          id: 'overdue',
        ),
        _Metric(
          'مكتملة',
          text(stats, 'completed', fallback: '0'),
          Icons.check_circle_outline_rounded,
          AppColors.success,
          id: 'completed',
        ),
        _Metric(
          'أولوية قصوى',
          text(stats, 'high_priority', fallback: '0'),
          Icons.bolt_rounded,
          AppColors.gold,
          id: 'high',
        ),
      ],
    );
  }
}

class _LectureTile extends ConsumerWidget {
  const _LectureTile(this.lecture, {required this.subjectId});

  final Map<String, dynamic> lecture;
  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studied = boolValue(lecture, 'is_studied');
    final color = studied ? AppColors.success : AppColors.royalBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    studied
                        ? Icons.check_circle_rounded
                        : Icons.play_lesson_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(lecture, 'title', fallback: 'محاضرة'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                              dateOnly(text(lecture, 'date')),
                              if (text(lecture, 'description').isNotEmpty)
                                text(lecture, 'description'),
                            ]
                            .where((item) => item.isNotEmpty && item != '-')
                            .join(' • '),
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: studied,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) async {
                          final id = number(lecture, 'id').toInt();
                          if (id <= 0) return;
                          await ref
                              .read(studentContentRepositoryProvider)
                              .toggleLectureListen(id);
                          ref.invalidate(_subjectDetailsProvider(subjectId));
                        },
                      ),
                    ),
                    Text(
                      studied ? 'تمت الدراسة' : 'لم تدرس',
                      style: TextStyle(
                        color: studied ? AppColors.success : AppColors.slate400,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final status = text(item, 'status');
    final color = switch (status) {
      'submitted' => AppColors.success,
      'missing' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/student/assignments/${item['id']}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.assignment_rounded, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text(item, 'title', fallback: 'تكليف دراسي'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 10,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الموعد: ${dateOnly(text(item, 'due_date'))}',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.grade_rounded,
                            size: 10,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الدرجة: ${text(item, 'marks', fallback: '-')}',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _MiniBadge(label: _assignmentStatus(status), color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceTile extends ConsumerWidget {
  const _AttendanceTile(this.item, {required this.subjectId});

  final Map<String, dynamic> item;
  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = text(item, 'status');
    final color = _attendanceColor(status);
    final excuse = asMap(item['excuse']);
    final canSubmit = boolValue(item, 'can_submit_excuse');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(_attendanceIcon(status), color: color, size: 20),
              ),
              Container(width: 2, height: 30, color: AppColors.slate100),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateOnly(text(item, 'date')),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.midnight,
                        ),
                      ),
                      _MiniBadge(label: _attendanceLabel(status), color: color),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    excuse.isEmpty
                        ? 'لم يتم تقديم عذر لهذا اليوم'
                        : 'العذر: ${text(excuse, 'status', fallback: '-')}',
                    style: TextStyle(
                      color: excuse.isEmpty
                          ? AppColors.slate400
                          : AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (canSubmit) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _showSubmitExcuseSheet(context, ref),
                        icon: const Icon(Icons.add_moderator_rounded, size: 16),
                        label: const Text(
                          'تقديم عذر طبي/رسمي',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.royalBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitExcuseSheet(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    String? filePath;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تقديم عذر غياب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnight,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'تاريخ الغياب: ${dateOnly(text(item, 'date'))}',
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'سبب الغياب',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل العذر هنا...',
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'المرفقات (اختياري)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (result != null) {
                    setModalState(() {
                      filePath = result.files.single.path;
                      fileName = result.files.single.name;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: filePath != null
                          ? AppColors.success
                          : AppColors.slate200,
                      style: BorderStyle.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        filePath != null
                            ? Icons.file_present_rounded
                            : Icons.upload_file_rounded,
                        color: filePath != null
                            ? AppColors.success
                            : AppColors.slate400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName ?? 'ارفق ملف (PDF, Image)',
                          style: TextStyle(
                            color: fileName != null
                                ? AppColors.midnight
                                : AppColors.slate400,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (fileName != null)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      MoeenDialogs.showError(
                        context,
                        message: 'يرجى كتابة سبب العذر.',
                      );
                      return;
                    }
                    try {
                      MoeenDialogs.showLoading(context);
                      final msg = await ref
                          .read(studentContentRepositoryProvider)
                          .submitExcuse(
                            attendanceId: number(item, 'id').toInt(),
                            reason: reasonController.text.trim(),
                            filePath: filePath,
                            fileName: fileName,
                          );
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading
                        Navigator.pop(context); // Close sheet
                        MoeenDialogs.showSuccess(context, message: msg);
                        ref.invalidate(_subjectDetailsProvider(subjectId));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading
                        MoeenDialogs.showError(context, message: e.toString());
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'إرسال الطلب الآن',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceMiniTile extends StatelessWidget {
  const _ResourceMiniTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final fileType = text(item, 'file_type').toLowerCase();
    final color = switch (fileType) {
      'pdf' => AppColors.danger,
      'doc' || 'docx' => AppColors.info,
      'xls' || 'xlsx' => AppColors.success,
      'ppt' || 'pptx' => AppColors.orange,
      _ => AppColors.royalBlue,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            fileType == 'pdf'
                ? Icons.picture_as_pdf_rounded
                : Icons.insert_drive_file_rounded,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          text(
            item,
            'title',
            fallback: text(item, 'name', fallback: 'مورد تعليمي'),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: AppColors.midnight,
          ),
        ),
        subtitle: Text(
          text(item, 'category', fallback: fileType.toUpperCase()),
          style: const TextStyle(
            color: AppColors.slate400,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Icons.download_for_offline_rounded,
          color: AppColors.slate300,
        ),
        onTap: () {},
      ),
    );
  }
}

class _StudyItemCard extends ConsumerWidget {
  const _StudyItemCard(this.item, {required this.tab});

  final Map<String, dynamic> item;
  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = number(item, 'id').toInt();
    final completed =
        boolValue(item, 'is_completed') || text(item, 'status') == 'completed';
    final priority = text(item, 'priority');
    final priorityColor = _priorityColor(priority);
    final reference = asMap(item['reference']);
    final subject = asMap(reference['subject']);
    final scheduledDate = text(item, 'scheduled_date');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: priorityColor,
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: completed,
                            activeColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            onChanged: id <= 0
                                ? null
                                : (value) async {
                                    await ref
                                        .read(studentContentRepositoryProvider)
                                        .updateStudyItem(id, {
                                          'is_completed': value,
                                        });
                                    ref.invalidate(_studyProvider(tab));
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text(item, 'title', fallback: 'عنصر دراسي'),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: completed
                                  ? AppColors.slate400
                                  : AppColors.midnight,
                            ),
                          ),
                        ),
                        _PriorityBadge(priority: priority),
                      ],
                    ),
                    if (text(item, 'note').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 36),
                        child: Text(
                          text(item, 'note'),
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 36),
                      child: Row(
                        children: [
                          if (text(subject, 'name').isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    text(subject, 'name'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateOnly(scheduledDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate500,
                            ),
                          ),
                          const Spacer(),
                          _ActionIconButton(
                            icon: Icons.edit_note_rounded,
                            onPressed: id <= 0
                                ? null
                                : () => _showEditStudyItem(
                                    context,
                                    ref,
                                    item,
                                    tab,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          _ActionIconButton(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            onPressed: id <= 0
                                ? null
                                : () => _deleteStudyItem(context, ref, id, tab),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    this.onPressed,
    this.color = AppColors.primary,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _ScheduleStatsRow extends StatelessWidget {
  const _ScheduleStatsRow({
    required this.totalLectures,
    required this.totalHours,
    required this.totalSubjects,
  });

  final int totalLectures;
  final String totalHours;
  final int totalSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScheduleStatItem(
            value: totalLectures.toString(),
            label: 'محاضرة',
            icon: Icons.school_rounded,
            color: AppColors.primary,
          ),
          _VerticalDivider(),
          _ScheduleStatItem(
            value: totalHours,
            label: 'ساعة',
            icon: Icons.timer_rounded,
            color: AppColors.orange,
          ),
          _VerticalDivider(),
          _ScheduleStatItem(
            value: totalSubjects.toString(),
            label: 'مواد',
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _ScheduleStatItem extends StatelessWidget {
  const _ScheduleStatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.midnight,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.slate200);
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final startTime = text(item, 'start_time');
    final endTime = text(item, 'end_time');
    final isLive = isTimeInRange(startTime, endTime);

    final subject = asMap(item['subject']);
    final doctor = asMap(subject['doctor']).isNotEmpty
        ? asMap(subject['doctor'])
        : asMap(item['doctor']);

    final creator = asMap(item['creator']);
    final isOfficial = creator.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLive
              ? AppColors.primary
              : (isOfficial
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.slate200),
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? AppColors.primary : AppColors.midnight).withValues(
              alpha: 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Side
            Container(
              width: 85,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isLive
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : AppColors.slate50,
                border: BorderDirectional(
                  end: BorderSide(
                    color: isLive
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.slate200,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeOnly(startTime),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isLive ? AppColors.primary : AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 24,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isLive ? AppColors.primary : AppColors.slate300,
                          isLive
                              ? AppColors.primary.withValues(alpha: 0)
                              : AppColors.slate200.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeOnly(endTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            // Content Side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLive) ...[_LiveBadge(), const SizedBox(width: 8)],
                        Expanded(
                          child: Text(
                            text(
                              subject,
                              'name',
                              fallback: text(
                                item,
                                'subject_name',
                                fallback: 'محاضرة',
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.midnight,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isOfficial)
                          _MiniBadge(label: 'رسمي', color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _IconInfo(
                      icon: Icons.account_circle_rounded,
                      text: text(
                        doctor,
                        'name',
                        fallback: text(
                          item,
                          'doctor_name',
                          fallback: 'دكتور غير محدد',
                        ),
                      ),
                      color: AppColors.slate600,
                    ),
                    const SizedBox(height: 6),
                    _IconInfo(
                      icon: Icons.room_preferences_rounded,
                      text: text(
                        item,
                        'hall_name',
                        fallback: text(
                          item,
                          'location',
                          fallback: 'قاعة غير محددة',
                        ),
                      ),
                      color: AppColors.goldDeep,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconInfo extends StatelessWidget {
  const _IconInfo({
    required this.icon,
    required this.text,
    this.color = AppColors.slate500,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard(this.item, {this.isLast = false});

  final Map<String, dynamic> item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final source = text(item, 'source');
    final color = _sourceColor(source);
    final attachment = absoluteUrl(text(item, 'attachment_url'));
    final hasImage = attachment.isNotEmpty && isImageUrl(attachment);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.5),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topRight: Radius.circular(4),
                ),
                border: Border.all(color: color.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.midnight.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showNewsDetails(context, item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage)
                      Stack(
                        children: [
                          Image.network(
                            attachment,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _MiniBadge(
                              label: _sourceLabel(source),
                              color: color,
                              blur: true,
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasImage)
                            Row(
                              children: [
                                _MiniBadge(
                                  label: _sourceLabel(source),
                                  color: color,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  text(
                                    item,
                                    'created_at_human',
                                    fallback: dateOnly(
                                      text(item, 'created_at'),
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.slate500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          if (!hasImage) const SizedBox(height: 12),
                          Text(
                            text(item, 'title', fallback: 'إعلان'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text(item, 'excerpt', fallback: text(item, 'body')),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.slate600,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                          if (hasImage) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  text(
                                    item,
                                    'created_at_human',
                                    fallback: dateOnly(
                                      text(item, 'created_at'),
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.slate500),
                                ),
                                const Spacer(),
                                Text(
                                  'عرض التفاصيل',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 10,
                                  color: color,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: Container(width: 2, color: AppColors.slate100)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 80,
                          height: 16,
                          color: AppColors.ghostWhite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.ghostWhite,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.ghostWhite,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.ghostWhite,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.ghostWhite,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageSkeleton extends StatelessWidget {
  const _MessageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.ghostWhite,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.ghostWhite,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile(this.quiz);
  final Map<String, dynamic> quiz;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF7C3AED);
    final subjectName = text(quiz, 'subject_name', fallback: 'مقرر دراسي');
    final title = text(quiz, 'title', fallback: 'كويز');
    final questionsCount = number(quiz, 'questions_count').toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleStart(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.quiz_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.midnight,
                          ),
                        ),
                        Text(
                          subjectName,
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: AppColors.royalBlue,
                    size: 32,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  _InfoTag(
                    icon: Icons.help_outline_rounded,
                    label: '$questionsCount سؤال',
                  ),
                  const SizedBox(width: 12),
                  _InfoTag(
                    icon: Icons.timer_outlined,
                    label: '${number(quiz, 'duration_minutes').toInt()} دقيقة',
                  ),
                  const Spacer(),
                  Text(
                    dateOnly(text(quiz, 'starts_at')),
                    style: const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStart(BuildContext context) async {
    final id = number(quiz, 'id').toInt();
    if (id <= 0) return;
    String? code;
    if (boolValue(quiz, 'requires_access_code') ||
        boolValue(quiz, 'has_access_code')) {
      code = await _askAccessCode(context);
      if (code == null || code.isEmpty) return;
    }
    if (!context.mounted) return;
    final path = StudentQuizzesScreen.takePath(id);
    context.push(
      code == null
          ? path
          : '$path?access_code=${Uri.encodeQueryComponent(code)}',
    );
  }

  Future<String?> _askAccessCode(BuildContext context) async {
    final controller = TextEditingController();
    return showMoeenBottomSheet<String>(
      context: context,
      title: 'كود الدخول',
      icon: Icons.password_rounded,
      color: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'هذا الكويز يحتاج إلى كود دخول. أدخل الكود ثم تابع.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'كود الكويز',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'بدء الاختبار الآن',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile(this.attempt);
  final Map<String, dynamic> attempt;

  @override
  Widget build(BuildContext context) {
    final quiz = asMap(attempt['quiz']);
    final score = number(attempt, 'score').toDouble();
    final color = score >= 50 ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
      ),
      child: InkWell(
        onTap: () {
          final id = number(attempt, 'id').toInt();
          if (id > 0) context.push(StudentQuizzesScreen.resultPath(id));
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  score >= 50
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(
                        quiz,
                        'title',
                        fallback: text(attempt, 'quiz_title'),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      dateOnly(text(attempt, 'submitted_at')),
                      style: const TextStyle(
                        color: AppColors.slate400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'النتيجة',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.slate400,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamScheduleCard extends StatefulWidget {
  const _ExamScheduleCard(this.schedule);

  final Map<String, dynamic> schedule;

  @override
  State<_ExamScheduleCard> createState() => _ExamScheduleCardState();
}

class _ExamScheduleCardState extends State<_ExamScheduleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final items = asList(widget.schedule['items']).map(asMap).toList()
      ..sort((a, b) => text(a, 'exam_date').compareTo(text(b, 'exam_date')));
    final term = asMap(widget.schedule['term']);
    final isOfficial = boolValue(widget.schedule, 'is_official');
    final color = isOfficial
        ? const Color(0xFF0F172A)
        : const Color(0xFF475569);

    // Calculate days until next exam if any
    int daysDiff = -1;
    if (items.isNotEmpty) {
      final nextExam = items.first;
      final examDate = DateTime.tryParse(text(nextExam, 'exam_date'));
      if (examDate != null) {
        daysDiff = examDate.difference(DateTime.now()).inDays;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: isOfficial ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.85)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOfficial
                                  ? Icons.verified_rounded
                                  : Icons.person_pin_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOfficial ? 'جدول معتمد' : 'بواسطة المندوب',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text(widget.schedule, 'title'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _HeaderStat(
                        icon: Icons.school_rounded,
                        text: text(term, 'name', fallback: 'الفصل الحالي'),
                      ),
                      _HeaderStat(
                        icon: Icons.auto_stories_rounded,
                        text: '${items.length} مقرر',
                      ),
                      if (daysDiff >= 0)
                        _HeaderStat(
                          icon: Icons.timer_rounded,
                          text: daysDiff == 0 ? 'اليوم' : 'بقي $daysDiff يوم',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (text(widget.schedule, 'description').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text(widget.schedule, 'description'),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _ExamTimelineItem(
                        items[index],
                        isLast: index == items.length - 1,
                        color: color,
                      );
                    },
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _ExamTimelineItem extends StatelessWidget {
  const _ExamTimelineItem(
    this.item, {
    this.isLast = false,
    required this.color,
  });
  final Map<String, dynamic> item;
  final bool isLast;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(item['subject']);
    final dateStr = text(item, 'exam_date');
    final date = DateTime.tryParse(dateStr);

    final day = date != null ? date.day.toString().padLeft(2, '0') : '--';
    final month = _monthName(date?.month ?? 0);
    final dayLabel = _dayLabel(date?.weekday.toString() ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator
          Container(
            width: 50,
            margin: const EdgeInsetsDirectional.only(start: 16),
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 3),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          // Exam Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 10 : 20,
                left: 20,
                right: 4,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.slate100),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.midnight.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Calendar Style Date
                  Container(
                    width: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          child: Text(
                            dayLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              Text(
                                month,
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.7),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(subject, 'name', fallback: 'مقرر غير معروف'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _TimelineIconInfo(
                              icon: Icons.access_time_filled_rounded,
                              text:
                                  '${timeOnly(text(item, 'start_time'))} - ${timeOnly(text(item, 'end_time'))}',
                              color: AppColors.slate500,
                            ),
                            _TimelineIconInfo(
                              icon: Icons.location_on_rounded,
                              text: text(
                                item,
                                'location',
                                fallback: 'قاعة غير محددة',
                              ),
                              color: AppColors.goldDeep,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return month > 0 && month <= 12 ? names[month] : '';
  }
}

class _TimelineIconInfo extends StatelessWidget {
  const _TimelineIconInfo({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _CourseResourceCard extends StatefulWidget {
  const _CourseResourceCard({required this.item, required this.onDownload});

  final Map<String, dynamic> item;
  final VoidCallback onDownload;

  @override
  State<_CourseResourceCard> createState() => _CourseResourceCardState();
}

class _CourseResourceCardState extends State<_CourseResourceCard> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final subject = asMap(widget.item['subject']);
    final fileType = text(
      widget.item,
      'file_type',
      fallback: 'file',
    ).toLowerCase();
    final color = _fileColor(fileType);
    final size = text(widget.item, 'file_size', fallback: '---');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPreview(context, widget.item, widget.onDownload),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(_fileIcon(fileType), color: color, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(widget.item, 'title', fallback: 'ملف دراسي'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnight,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text(subject, 'name', fallback: 'المادة الدراسية'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _FileMeta(label: size, icon: Icons.sd_storage_rounded),
                        const SizedBox(width: 12),
                        _FileMeta(
                          label: prettyDate(text(widget.item, 'created_at')),
                          icon: Icons.calendar_today_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _isDownloading
                    ? null
                    : () async {
                        setState(() => _isDownloading = true);
                        widget.onDownload();
                        await Future.delayed(const Duration(seconds: 2));
                        if (mounted) setState(() => _isDownloading = false);
                      },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.slate100,
                  foregroundColor: AppColors.midnight,
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.midnight,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ModernBadge extends StatelessWidget {
  const _ModernBadge({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _fileIcon(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('pdf')) return Icons.picture_as_pdf_rounded;
  if (lower.contains('ppt')) return Icons.slideshow_rounded;
  if (lower.contains('doc')) return Icons.description_rounded;
  if (lower.contains('xls')) return Icons.table_chart_rounded;
  if (lower.contains('zip') || lower.contains('rar')) {
    return Icons.archive_rounded;
  }
  if (lower.contains('jpg') ||
      lower.contains('png') ||
      lower.contains('jpeg')) {
    return Icons.image_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

Color _fileColor(String type) {
  final lower = type.toLowerCase();
  if (lower.contains('pdf')) return const Color(0xFFE11D48); // Rose 600
  if (lower.contains('ppt')) return const Color(0xFFEA580C); // Orange 600
  if (lower.contains('doc')) return const Color(0xFF2563EB); // Blue 600
  if (lower.contains('xls')) return const Color(0xFF16A34A); // Green 600
  if (lower.contains('zip') || lower.contains('rar')) {
    return const Color(0xFF7C3AED); // Violet 600
  }
  return AppColors.slate500;
}

// ignore: unused_element
class _ResourceSkeleton extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ResourceSkeleton({this.isGrid = false});
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate200),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _SkeletonBox(height: 60, width: 60, radius: 16),
            const SizedBox(height: 12),
            _SkeletonBox(height: 14, width: 100),
            const SizedBox(height: 8),
            _SkeletonBox(height: 10, width: 60),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          _SkeletonBox(height: 50, width: 50, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(height: 14, width: 140),
                const SizedBox(height: 8),
                _SkeletonBox(height: 10, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.width,
    this.radius = 4,
  });
  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EntryAnimation extends StatelessWidget {
  const _EntryAnimation({required this.child, required this.index});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _CourseResourceGridCard extends StatefulWidget {
  const _CourseResourceGridCard({required this.item, required this.onDownload});
  final Map<String, dynamic> item;
  final VoidCallback onDownload;

  @override
  State<_CourseResourceGridCard> createState() =>
      _CourseResourceGridCardState();
}

class _CourseResourceGridCardState extends State<_CourseResourceGridCard> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final fileType = text(
      widget.item,
      'file_type',
      fallback: 'file',
    ).toLowerCase();
    final color = _fileColor(fileType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPreview(context, widget.item, widget.onDownload),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_fileIcon(fileType), color: color, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text(widget.item, 'title', fallback: 'ملف دراسي'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.midnight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                text(widget.item, 'file_size', fallback: '---'),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _isDownloading
                      ? null
                      : () async {
                          setState(() => _isDownloading = true);
                          widget.onDownload();
                          await Future.delayed(const Duration(seconds: 2));
                          if (mounted) setState(() => _isDownloading = false);
                        },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileMeta extends StatelessWidget {
  const _FileMeta({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.slate400),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slate500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

void _showPreview(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback onDownload,
) {
  final fileType = text(item, 'file_type', fallback: 'file');
  final color = _fileColor(fileType);
  final subject = asMap(item['subject']);
  final uploader = asMap(item['uploader']);

  showMoeenBottomSheet(
    context: context,
    title: 'تفاصيل المصدر',
    icon: Icons.info_outline_rounded,
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_fileIcon(fileType), color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text(item, 'title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    text(subject, 'name', fallback: 'مقرر غير محدد'),
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (text(item, 'description').isNotEmpty) ...[
          const Text(
            'الوصف',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            text(item, 'description'),
            style: TextStyle(color: AppColors.slate700, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        _PreviewInfoTile(
          icon: Icons.person_rounded,
          label: 'المرفوع بواسطة',
          value: text(uploader, 'name', fallback: 'غير معروف'),
        ),
        _PreviewInfoTile(
          icon: Icons.calendar_month_rounded,
          label: 'تاريخ الرفع',
          value: dateOnly(text(item, 'created_at')),
        ),
        _PreviewInfoTile(
          icon: Icons.download_done_rounded,
          label: 'مرات التحميل',
          value: text(item, 'downloads_count', fallback: '0'),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onDownload();
          },
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.download_rounded),
          label: const Text(
            'تحميل الملف الآن',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

class _PreviewInfoTile extends StatelessWidget {
  const _PreviewInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.slate400),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
    required this.answers,
    required this.onOptionSelected,
  });

  final Map<String, dynamic> question;
  final int index;
  final int total;
  final Map<String, dynamic> answers;
  final VoidCallback onOptionSelected;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  @override
  Widget build(BuildContext context) {
    final questionId = number(widget.question, 'id').toInt().toString();
    final options = asList(widget.question['options']);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'السؤال ${widget.index + 1} من ${widget.total}',
            style: const TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text(
              widget.question,
              'question_text',
              fallback: text(widget.question, 'title'),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.midnight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, idx) {
                final map = asMap(options[idx]);
                final optionId = number(map, 'id').toInt();
                final selected = widget.answers[questionId] == optionId;
                final color = selected
                    ? AppColors.royalBlue
                    : AppColors.slate100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => widget.answers[questionId] = optionId);
                      widget.onOptionSelected();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : AppColors.slate200,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? color : AppColors.slate300,
                                width: 2,
                              ),
                              color: selected ? color : Colors.transparent,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              text(
                                map,
                                'option_text',
                                fallback: text(map, 'text'),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: selected
                                    ? AppColors.midnight
                                    : AppColors.slate600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftTile extends StatelessWidget {
  const _SoftTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
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
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    this.textColor,
    this.blur = false,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: blur
            ? color.withValues(alpha: 0.7)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: blur ? null : Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: blur ? Colors.white : (textColor ?? color),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (blur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: child,
        ),
      );
    }

    return child;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _CategoryScrollRow extends StatelessWidget {
  const _CategoryScrollRow({
    required this.selected,
    required this.options,
    required this.onChanged,
  });
  final String selected;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (val) => onChanged(entry.key),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.slate700,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.slate200,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.iconColor,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.slate100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: iconColor ?? AppColors.slate700, size: 22),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
