part of 'staff_screens.dart';

extension _DoctorClinicalSectionContent on _DoctorClinicalSectionScreenState {
  bool get _showsFilters =>
      !{'scanner', 'evaluation-start'}.contains(widget.section);

  Widget _buildSectionShortcuts() {
    if (widget.section == 'checklists') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.royalBlue, Color(0xFF4D6FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(
                      DoctorClinicalSectionScreen.path('evaluation-start'),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بدء تقييم جديد',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'أجرِ اختبار OSCE فوري للطلبة',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(
                      DoctorClinicalSectionScreen.path('results'),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: AppColors.royalBlue,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سجل النتائج',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.midnight,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'استعرض الدرجات والتقييمات',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (widget.section == 'records') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF3CD1C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  context.push(DoctorClinicalSectionScreen.path('scanner')),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مسح رمز QR السريع لتسجيل الحضور وتأكيد النشاط',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFilters([_Json? data]) {
    return _DocFilterPanel(
      title: 'بحث وتصفية',
      icon: Icons.tune_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (text) {
                  if (widget.section == 'records' ||
                      widget.section == 'checklists' ||
                      widget.section == 'results' ||
                      widget.section == 'portfolios') {
                    _update(() {});
                  }
                },
                onSubmitted:
                    {
                      'rare-cases',
                      'volunteers',
                      'cases',
                      'assignments',
                      'centers',
                      'departments',
                      'body-systems',
                      'records',
                      'checklists',
                      'results',
                      'portfolios',
                    }.contains(widget.section)
                    ? null
                    : (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      {
                        'rare-cases',
                        'volunteers',
                        'cases',
                        'assignments',
                        'centers',
                        'departments',
                        'body-systems',
                        'records',
                        'checklists',
                        'results',
                        'portfolios',
                      }.contains(widget.section)
                      ? (_search.text.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  if (widget.section == 'portfolios') {
                                    _portfolioMajor = null;
                                    _portfolioLevel = null;
                                    _portfolioSort = 'name_asc';
                                  }
                                  if (widget.section == 'records' ||
                                      widget.section == 'checklists' ||
                                      widget.section == 'results' ||
                                      widget.section == 'portfolios') {
                                    _update(() {});
                                  }
                                },
                                icon: const Icon(Icons.close_rounded),
                              ))
                      : IconButton(
                          onPressed: _reload,
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                ),
              ),
            ),
            if (widget.section == 'portfolios') ...[
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showPortfolioFiltersBottomSheet(data),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (_portfolioMajor != null ||
                              _portfolioLevel != null ||
                              _portfolioSort != 'name_asc')
                          ? AppColors.royalBlue.withValues(alpha: 0.1)
                          : AppColors.slate50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            (_portfolioMajor != null ||
                                _portfolioLevel != null ||
                                _portfolioSort != 'name_asc')
                            ? AppColors.royalBlue
                            : AppColors.slate200,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color:
                          (_portfolioMajor != null ||
                              _portfolioLevel != null ||
                              _portfolioSort != 'name_asc')
                          ? AppColors.royalBlue
                          : AppColors.slate600,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if ({
          'cases',
          'assignments',
          'records',
          'results',
          'volunteers',
          'rare-cases',
        }.contains(widget.section)) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: widget.section == 'volunteers'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'available', child: Text('متاح')),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('غير متاح'),
                    ),
                  ]
                : widget.section == 'rare-cases'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'draft', child: Text('مسودات')),
                    DropdownMenuItem(value: 'published', child: Text('منشورة')),
                    DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
                    DropdownMenuItem(value: 'archived', child: Text('مؤرشفة')),
                  ]
                : widget.section == 'cases'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('حالة نشطة')),
                    DropdownMenuItem(
                      value: 'discharged',
                      child: Text('تم الخروج'),
                    ),
                    DropdownMenuItem(
                      value: 'transferred',
                      child: Text('تم التحويل'),
                    ),
                  ]
                : widget.section == 'assignments'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(
                      value: 'assigned',
                      child: Text('قيد العمل'),
                    ),
                    DropdownMenuItem(
                      value: 'submitted_for_review',
                      child: Text('بانتظار المراجعة'),
                    ),
                    DropdownMenuItem(value: 'overdue', child: Text('متأخر')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('تم الاعتماد'),
                    ),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                  ]
                : widget.section == 'results'
                ? const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'excellent', child: Text('ممتاز')),
                    DropdownMenuItem(value: 'good', child: Text('جيد جدا')),
                    DropdownMenuItem(value: 'acceptable', child: Text('مقبول')),
                    DropdownMenuItem(value: 'weak', child: Text('ضعيف')),
                    DropdownMenuItem(value: 'fail', child: Text('راسب')),
                  ]
                : const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'pending', child: Text('بانتظار')),
                    DropdownMenuItem(value: 'confirmed', child: Text('معتمد')),
                    DropdownMenuItem(
                      value: 'partially_confirmed',
                      child: Text('اعتماد جزئي'),
                    ),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'assigned', child: Text('مكلف')),
                    DropdownMenuItem(
                      value: 'submitted_for_review',
                      child: Text('بانتظار المراجعة'),
                    ),
                    DropdownMenuItem(value: 'approved', child: Text('مقبول')),
                  ],
            onChanged: (value) {
              _status = value;
              if (widget.section == 'volunteers' ||
                  widget.section == 'rare-cases' ||
                  widget.section == 'cases' ||
                  widget.section == 'assignments' ||
                  widget.section == 'results') {
                _update(() {});
              } else {
                _reload();
              }
            },
          ),
        ],
      ],
    );
  }

  void _showPortfolioFiltersBottomSheet(_Json? data) {
    showMoeenBottomSheet<void>(
      context: context,
      title: 'خيارات التصفية والفرز',
      icon: Icons.tune_rounded,
      color: AppColors.royalBlue,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final allItems = _itemsFrom(data ?? const {});
          final majors = allItems
              .map((item) => _docText(_docMap(item['major'])['name']))
              .where((val) => val.isNotEmpty)
              .toSet()
              .toList();
          final levels = allItems
              .map((item) => _docText(_docMap(item['level'])['name']))
              .where((val) => val.isNotEmpty)
              .toSet()
              .toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _portfolioMajor,
                decoration: const InputDecoration(
                  labelText: 'التخصص',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('كل التخصصات'),
                  ),
                  ...majors.map(
                    (m) => DropdownMenuItem(value: m, child: Text(m)),
                  ),
                ],
                onChanged: (val) {
                  _update(() {
                    _portfolioMajor = val;
                  });
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _portfolioLevel,
                decoration: const InputDecoration(
                  labelText: 'المستوى الدراسي',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('كل المستويات'),
                  ),
                  ...levels.map(
                    (l) => DropdownMenuItem(value: l, child: Text(l)),
                  ),
                ],
                onChanged: (val) {
                  _update(() {
                    _portfolioLevel = val;
                  });
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _portfolioSort,
                decoration: const InputDecoration(
                  labelText: 'ترتيب حسب',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'name_asc',
                    child: Text('الاسم (أ - ي)'),
                  ),
                  DropdownMenuItem(
                    value: 'name_desc',
                    child: Text('الاسم (ي - أ)'),
                  ),
                  DropdownMenuItem(
                    value: 'activities_desc',
                    child: Text('الأكثر إنجازاً للأنشطة'),
                  ),
                  DropdownMenuItem(
                    value: 'activities_asc',
                    child: Text('الأقل إنجازاً للأنشطة'),
                  ),
                ],
                onChanged: (val) {
                  _update(() {
                    _portfolioSort = val ?? 'name_asc';
                  });
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'تطبيق الفلاتر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordsStats(List<_Json> items) {
    int pending = 0;
    int confirmed = 0;
    int rejected = 0;
    for (final item in items) {
      final status = _docText(item['status']);
      if (status == 'pending' || status == 'partially_confirmed') {
        pending++;
      } else if (status == 'confirmed' || status == 'approved') {
        confirmed++;
      } else if (status == 'rejected') {
        rejected++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBentoStatCard(
              title: 'معلقة',
              count: pending,
              color: AppColors.warning,
              icon: Icons.hourglass_empty_rounded,
              isActive: _status == 'pending',
              onTap: () {
                _update(() {
                  _status = _status == 'pending' ? null : 'pending';
                });
                _reload();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'معتمدة',
              count: confirmed,
              color: AppColors.success,
              icon: Icons.verified_rounded,
              isActive: _status == 'confirmed',
              onTap: () {
                _update(() {
                  _status = _status == 'confirmed' ? null : 'confirmed';
                });
                _reload();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'مرفوضة',
              count: rejected,
              color: AppColors.danger,
              icon: Icons.cancel_rounded,
              isActive: _status == 'rejected',
              onTap: () {
                _update(() {
                  _status = _status == 'rejected' ? null : 'rejected';
                });
                _reload();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : AppColors.slate100,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isActive ? 0.08 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const Spacer(),
                      if (isActive)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isActive ? color : AppColors.midnight,
                      fontFamily: 'Cairo',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistsStats(List<_Json> items) {
    int history = 0;
    int exam = 0;
    int procComm = 0;
    for (final item in items) {
      final skill = _docText(item['skill_type']);
      if (skill == 'history_taking') {
        history++;
      } else if (skill == 'clinical_examination') {
        exam++;
      } else if (skill == 'procedure' || skill == 'communication') {
        procComm++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBentoStatCard(
              title: 'أخذ القصة',
              count: history,
              color: AppColors.royalBlue,
              icon: Icons.history_edu_rounded,
              isActive: _status == 'history_taking',
              onTap: () {
                _update(() {
                  _status = _status == 'history_taking'
                      ? null
                      : 'history_taking';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'الفحص السريري',
              count: exam,
              color: AppColors.gold,
              icon: Icons.person_search_rounded,
              isActive: _status == 'clinical_examination',
              onTap: () {
                _update(() {
                  _status = _status == 'clinical_examination'
                      ? null
                      : 'clinical_examination';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBentoStatCard(
              title: 'الإجراءات والتواصل',
              count: procComm,
              color: AppColors.teal,
              icon: Icons.healing_rounded,
              isActive: _status == 'procedure',
              onTap: () {
                _update(() {
                  _status = _status == 'procedure' ? null : 'procedure';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistsModeSwitch(_Json data) {
    final hiddenCount = _docInt(data['hidden_count']);

    Widget buildOption({
      required bool hidden,
      required IconData icon,
      required String title,
      required String subtitle,
      int? count,
    }) {
      final active = _showHiddenChecklists == hidden;
      final color = hidden ? AppColors.warning : AppColors.royalBlue;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.35) : AppColors.slate100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? color.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.015),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: active
                ? null
                : () {
                    _update(() {
                      _showHiddenChecklists = hidden;
                      _status = null;
                      _future = _fetch();
                    });
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active ? color : AppColors.slate50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: active ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: active ? color : AppColors.midnight,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (count != null && count > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                            fontFamily: 'Cairo',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    active
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: active ? color : AppColors.slate300,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          buildOption(
            hidden: false,
            icon: Icons.fact_check_rounded,
            title: 'القوائم الظاهرة',
            subtitle: 'القوائم المتاحة حاليًا للتقييم والتدريب السريري',
          ),
          buildOption(
            hidden: true,
            icon: Icons.visibility_off_rounded,
            title: 'الثوابت المخفية',
            subtitle:
                'استرجاع قوائم التقييم الأساسية المخفية مسبقاً من الإدارة',
            count: hiddenCount,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(_Json data) {
    return switch (widget.section) {
      'scanner' => [_buildScanner()],
      'evaluation-start' => [_buildEvaluationStart(data)],
      'results' => _buildResults(data),
      'checklists' => _buildChecklists(data),
      'assignments' => _buildAssignments(data),
      'records' => _buildRecords(data),
      'portfolios' => _buildPortfolios(data),
      'rare-cases' => _buildRareCasesList(data),
      'volunteers' => _buildVolunteersList(data),
      'cases' => _buildCasesList(data),
      'centers' => _buildCentersList(data),
      'departments' => _buildDepartmentsList(data),
      'body-systems' => _buildBodySystemsList(data),
      _ => _buildGenericItems(data),
    };
  }

  List<Widget> _buildCasesList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((caseItem) {
      final matchesSearch =
          query.isEmpty || _matchesCaseSearch(caseItem, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          _docText(caseItem['status']) == _status;
      return matchesSearch && matchesStatus;
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد حالات سريرية مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة حالة سريرية جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (caseItem) => _CaseCard(
            caseItem: caseItem,
            onTap: () => _showCaseDetails(caseItem),
            onEdit: () => _openCaseForm(item: caseItem),
            onDelete: () => _deleteItem(caseItem),
          ),
        )
        .toList();
  }

  bool _matchesCaseSearch(_Json caseItem, String query) {
    final normalized = query.toLowerCase();
    final center = _docText(_docMap(caseItem['training_center'])['name']);
    final dept = _docText(_docMap(caseItem['clinical_department'])['name']);
    final system = _docText(_docMap(caseItem['body_system'])['name']);
    return [
      caseItem['patient_name'],
      caseItem['diagnosis_or_description'],
      center,
      dept,
      system,
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
  }

  List<Widget> _buildCentersList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((centerItem) {
      return query.isEmpty || _matchesCenterSearch(centerItem, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد مراكز تدريب مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openTrainingCenterForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة مركز تدريب جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (centerItem) => _TrainingCenterCard(
            centerItem: centerItem,
            onTap: () => _showTrainingCenterDetails(centerItem),
            onEdit: _canAdd
                ? () => _openTrainingCenterForm(item: centerItem)
                : null,
            onDelete: _canAdd ? () => _deleteItem(centerItem) : null,
          ),
        )
        .toList();
  }

  bool _matchesCenterSearch(_Json centerItem, String query) {
    final normalized = query.toLowerCase();
    return _docText(centerItem['name']).toLowerCase().contains(normalized) ||
        _docText(centerItem['location']).toLowerCase().contains(normalized) ||
        _docText(centerItem['description']).toLowerCase().contains(normalized);
  }

  List<Widget> _buildDepartmentsList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      return query.isEmpty || _matchesDepartmentSearch(item, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد أقسام طبية مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openDepartmentForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة قسم طبي جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (item) => _DepartmentCard(
            departmentItem: item,
            onTap: () => _showDepartmentDetails(item),
            onEdit: _canAdd && item['doctor_id'] != null
                ? () => _openDepartmentForm(item: item)
                : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  bool _matchesDepartmentSearch(_Json item, String query) {
    final normalized = query.toLowerCase();
    return _docText(item['name']).toLowerCase().contains(normalized) ||
        _docText(item['description']).toLowerCase().contains(normalized);
  }

  List<Widget> _buildBodySystemsList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      return query.isEmpty || _matchesBodySystemSearch(item, query);
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد أنظمة جسم مسجلة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty && _canAdd) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openBodySystemForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة نظام جسم جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (item) => _BodySystemCard(
            bodySystemItem: item,
            onTap: () => _showBodySystemDetails(item),
            onEdit: _canAdd && item['doctor_id'] != null
                ? () => _openBodySystemForm(item: item)
                : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  bool _matchesBodySystemSearch(_Json item, String query) {
    final normalized = query.toLowerCase();
    return _docText(item['name']).toLowerCase().contains(normalized) ||
        _docText(item['description']).toLowerCase().contains(normalized);
  }

  Future<void> _showCaseDetails(_Json caseItem) async {
    var details = caseItem;
    try {
      final response = await ref
          .read(staffRepositoryProvider)
          .get(
            '/doctor/clinical/cases/${caseItem['id']}',
            query: const {'include_assignments': 1},
          );
      details = _docMap(_docData(response));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
      return;
    }
    if (!mounted) return;
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل الحالة السريرية',
      icon: Icons.medical_information_rounded,
      color: AppColors.success,
      child: _CaseDetails(caseItem: details),
    );
  }

  List<Widget> _buildVolunteersList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((volunteer) {
      final matchesSearch =
          query.isEmpty || _matchesVolunteerSearch(volunteer, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          (_status == 'available' && _docBool(volunteer['is_available'])) ||
          (_status == 'unavailable' && !_docBool(volunteer['is_available']));
      return matchesSearch && matchesStatus;
    }).toList();
    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا يوجد متطوعون في السجل بعد.'
              : 'لا توجد نتائج مطابقة للبحث أو الفلتر الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openVolunteerForm(),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text(
                'إضافة متطوع جديد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (volunteer) => _VolunteerCard(
            volunteer: volunteer,
            onTap: () => _showVolunteerDetails(volunteer),
            onEdit: () => _openVolunteerForm(item: volunteer),
            onFollowUp: () => _openVolunteerFollowUpForm(volunteer),
            onCall: () => _callVolunteer(volunteer),
            onWhatsApp: () => _openVolunteerWhatsApp(volunteer),
            onCopy: () => _copyVolunteerContact(volunteer),
            onToggle: () => _toggleVolunteer(volunteer),
            onDelete: () => _deleteVolunteer(volunteer),
          ),
        )
        .toList();
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

  bool _matchesVolunteerSearch(_Json volunteer, String query) {
    final normalized = query.toLowerCase();
    return [
      volunteer['name'],
      volunteer['contact_info'],
      volunteer['phone_secondary'],
      volunteer['email'],
      volunteer['diagnosis'],
      volunteer['clinical_signs'],
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
  }

  Future<void> _showVolunteerDetails(_Json volunteer) async {
    await showMoeenBottomSheet<void>(
      context: context,
      title: 'تفاصيل المتطوع',
      icon: Icons.person_rounded,
      color: _docBool(volunteer['is_available'])
          ? AppColors.success
          : AppColors.slate500,
      child: _VolunteerDetails(
        volunteer: volunteer,
        onFollowUp: () => _openVolunteerFollowUpForm(volunteer),
        onCall: () => _callVolunteer(volunteer),
        onWhatsApp: () => _openVolunteerWhatsApp(volunteer),
      ),
    );
  }

  Future<void> _openVolunteerFollowUpForm(_Json volunteer) async {
    final formKey = GlobalKey<FormState>();
    var status = _docText(volunteer['follow_up_status'], 'contacted');
    if (!_volunteerFollowUpStatuses.containsKey(status)) status = 'contacted';
    var method = _docText(volunteer['preferred_contact_method'], 'whatsapp');
    if (!_volunteerContactMethods.containsKey(method)) method = 'whatsapp';
    final notes = TextEditingController();

    final ok = await showMoeenBottomSheet<bool>(
      context: context,
      title: 'تسجيل متابعة',
      icon: Icons.event_note_rounded,
      color: AppColors.teal,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow('المتطوع', _docText(volunteer['name'], 'متطوع')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'حالة المتابعة'),
              items: _volunteerFollowUpStatuses.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => status = value ?? status,
              validator: (value) =>
                  value == null || value.isEmpty ? 'حدد حالة المتابعة.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'طريقة التواصل'),
              items: _volunteerContactMethods.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => method = value ?? method,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'ملاحظات المتابعة',
                hintText: 'مثال: تم التواصل ووافق على الحضور يوم الخميس.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ المتابعة'),
            ),
          ],
        ),
      ),
    );

    final payload = ok == true
        ? {
            'follow_up_status': status,
            'contact_method': method,
            'notes': notes.text.trim(),
          }
        : null;
    Future.delayed(const Duration(milliseconds: 500), notes.dispose);
    if (payload == null) return;

    try {
      await ref
          .read(staffRepositoryProvider)
          .post(
            '/doctor/clinical/volunteers/${volunteer['id']}/follow-up',
            payload,
          );
      if (!mounted) return;
      _reload();
      _docSnack(context, 'تم تسجيل المتابعة.', color: AppColors.success);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  Future<void> _callVolunteer(_Json volunteer) async {
    final phone = _docText(volunteer['contact_info']);
    if (phone.isEmpty) return;
    await _launchExternal(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openVolunteerWhatsApp(_Json volunteer) async {
    final phone = _normalizedPhone(_docText(volunteer['contact_info']));
    if (phone.isEmpty) {
      _docSnack(context, 'رقم التواصل غير صالح.', color: AppColors.warning);
      return;
    }
    await _launchExternal(Uri.parse('https://wa.me/$phone'));
  }

  Future<void> _copyVolunteerContact(_Json volunteer) async {
    final phone = _docText(volunteer['contact_info']);
    if (phone.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    _docSnack(context, 'تم نسخ رقم التواصل.', color: AppColors.success);
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || launched) return;
      _docSnack(context, 'تعذر فتح التطبيق المناسب.', color: AppColors.warning);
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    }
  }

  String _normalizedPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits.substring(1);
    if (digits.startsWith('00')) return digits.substring(2);
    return digits;
  }

  List<Widget> _buildRareCasesList(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim();
    final items = allItems.where((item) {
      final matchesSearch =
          query.isEmpty || _matchesRareCaseSearch(item, query);
      final matchesStatus =
          _status == null ||
          _status!.isEmpty ||
          _docText(item['status']) == _status;
      return matchesSearch && matchesStatus;
    }).toList();
    if (items.isEmpty) {
      return [
        _DocEmpty(
          allItems.isEmpty
              ? 'لا توجد حالات نادرة منشورة بعد.'
              : 'لا توجد نتائج مطابقة للبحث الحالي.',
        ),
        if (allItems.isEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _openRareCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إعلان حالة نادرة جديدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ];
    }
    return items
        .map(
          (rareCase) => _RareCaseCard(
            rareCase: rareCase,
            onTap: () => _showRareCaseDetails(rareCase),
            onEdit: () => _openRareCaseForm(item: rareCase),
            onToggle: () => _toggleRareCase(rareCase),
            onDelete: () => _deleteRareCase(rareCase),
          ),
        )
        .toList();
  }

  bool _matchesRareCaseSearch(_Json rareCase, String query) {
    final normalized = query.toLowerCase();
    return [
      rareCase['diagnosis'],
      rareCase['hospital'],
      rareCase['department'],
      rareCase['patient_name'],
      rareCase['room_number'],
      rareCase['clinical_signs'],
    ].any((value) => _docText(value).toLowerCase().contains(normalized));
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

  List<_Json> _itemsFrom(_Json data) {
    if (data.containsKey('checklists')) return _docList(data['checklists']);
    final nestedData = _docMap(data['data']);
    if (nestedData['data'] is List) return _docList(nestedData['data']);
    return _docList(data['data'] ?? data['items'] ?? data);
  }

  List<Widget> _buildGenericItems(_Json data) {
    final items = _itemsFrom(data);
    return items
        .map(
          (item) => _ClinicalListCard(
            title: _genericTitle(item),
            subtitle: _genericSubtitle(item),
            icon: _icon,
            color: _docStatusColor(_docText(item['status'], 'active')),
            status: _docText(item['status_label'], _docText(item['status'])),
            onTap: () => _showGenericDetails(item),
            onEdit: _canAdd ? () => _openEdit(item) : null,
            onDelete: _canAdd ? () => _deleteItem(item) : null,
          ),
        )
        .toList();
  }

  String _genericTitle(_Json item) {
    return _docText(
      item['name'] ??
          item['title'] ??
          item['patient_name'] ??
          item['diagnosis'] ??
          item['student_name'],
      'عنصر',
    );
  }

  String _genericSubtitle(_Json item) {
    final parts = [
      _docText(item['description']),
      _docText(item['location']),
      _docText(item['diagnosis_or_description']),
      _docText(item['hospital']),
      _docText(item['department']),
      _docText(_docMap(item['training_center'])['name']),
      _docText(_docMap(item['clinical_department'])['name']),
      _docText(_docMap(item['body_system'])['name']),
      _docDate(item['created_at']),
    ].where((value) => value.isNotEmpty && value != '-').take(3).join(' • ');
    return parts.isEmpty ? 'اضغط لعرض التفاصيل' : parts;
  }

  List<Widget> _buildAssignments(_Json data) {
    final items = _itemsFrom(data);
    if (items.isEmpty) {
      return [const _DocEmpty('لا توجد تكليفات حالات.')];
    }
    return items.map((item) {
      final status = _docText(item['status']);
      return _ClinicalAssignmentCard(
        item: item,
        onTap: () => _showGenericDetails(item),
        onEdit: status == 'submitted_for_review'
            ? () => _reviewAssignment(item)
            : null,
        editLabel: status == 'submitted_for_review' ? 'مراجعة التكليف' : null,
      );
    }).toList();
  }

  List<Widget> _buildRecords(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();
    final items = allItems.where((item) {
      if (query.isEmpty) return true;
      final student = _docMap(item['student']);
      final name = _docText(
        student['name'],
        _docText(item['student_name']),
      ).toLowerCase();
      final number = _docText(
        student['student_number'],
        _docText(item['student_number']),
      ).toLowerCase();
      final center = _docText(
        _docMap(item['training_center'])['name'],
        _docText(item['training_center']),
      ).toLowerCase();
      final dept = _docText(
        _docMap(item['department'])['name'],
        _docText(item['department']),
      ).toLowerCase();
      final date = _docDate(item['log_date']).toLowerCase();
      return name.contains(query) ||
          number.contains(query) ||
          center.contains(query) ||
          dept.contains(query) ||
          date.contains(query);
    }).toList();

    if (items.isEmpty) {
      return [const _DocEmpty('لا توجد سجلات مطابقة للبحث.')];
    }
    return items.map((item) {
      return _ClinicalRecordCard(
        item: item,
        onTap: () => _showLogDetails(item),
      );
    }).toList();
  }

  List<Widget> _buildPortfolios(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();

    var items = allItems.where((item) {
      if (query.isNotEmpty) {
        final major = _docText(_docMap(item['major'])['name']).toLowerCase();
        final level = _docText(_docMap(item['level'])['name']).toLowerCase();
        final matches =
            _docText(item['name']).toLowerCase().contains(query) ||
            _docText(item['student_number']).toLowerCase().contains(query) ||
            _docText(item['email']).toLowerCase().contains(query) ||
            major.contains(query) ||
            level.contains(query);
        if (!matches) return false;
      }

      if (_portfolioMajor != null && _portfolioMajor!.isNotEmpty) {
        final major = _docText(_docMap(item['major'])['name']);
        if (major != _portfolioMajor) return false;
      }

      if (_portfolioLevel != null && _portfolioLevel!.isNotEmpty) {
        final level = _docText(_docMap(item['level'])['name']);
        if (level != _portfolioLevel) return false;
      }

      return true;
    }).toList();

    if (_portfolioSort != null) {
      items.sort((a, b) {
        switch (_portfolioSort) {
          case 'name_desc':
            return _docText(b['name']).compareTo(_docText(a['name']));
          case 'activities_desc':
            final aCount = _docInt(
              _docMap(a['summary'])['approved_activities'],
            );
            final bCount = _docInt(
              _docMap(b['summary'])['approved_activities'],
            );
            return bCount.compareTo(aCount);
          case 'activities_asc':
            final aCount = _docInt(
              _docMap(a['summary'])['approved_activities'],
            );
            final bCount = _docInt(
              _docMap(b['summary'])['approved_activities'],
            );
            return aCount.compareTo(bCount);
          case 'name_asc':
          default:
            return _docText(a['name']).compareTo(_docText(b['name']));
        }
      });
    }

    if (items.isEmpty) {
      return [
        const _DocEmpty(
          'لا توجد إنجازات عملية معتمدة مطابقة للبحث أو الفلتر الحالي.',
        ),
      ];
    }

    return items.map((item) {
      final summary = _docMap(item['summary']);
      return _ClinicalPortfolioStudentCard(
        student: item,
        summary: summary,
        onTap: () => context.push(
          DoctorClinicalPortfolioDetailsScreen.path(_docText(item['id'])),
          extra: item,
        ),
      );
    }).toList();
  }

  List<Widget> _buildChecklists(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();

    final items = allItems.where((item) {
      if (query.isNotEmpty) {
        final title = _docText(item['title']).toLowerCase();
        final skill = _docText(item['skill_type']).toLowerCase();
        final desc = _docText(item['description']).toLowerCase();
        if (!title.contains(query) &&
            !skill.contains(query) &&
            !desc.contains(query)) {
          return false;
        }
      }

      if (_status != null && _status!.isNotEmpty) {
        final skill = _docText(item['skill_type']);
        if (_status == 'procedure') {
          if (skill != 'procedure' && skill != 'communication') return false;
        } else {
          if (skill != _status) return false;
        }
      }

      return true;
    }).toList();

    if (items.isEmpty) {
      return [
        _DocEmpty(
          _showHiddenChecklists
              ? 'لا توجد قوائم تقييم مخفية مطابقة.'
              : 'لا توجد قوائم تقييم مطابقة.',
        ),
      ];
    }
    return items.map((item) {
      return _ClinicalChecklistCard(
        item: item,
        onTap: () => _showGenericDetails(item),
        onEdit: _showHiddenChecklists ? null : () => _openEdit(item),
        onDelete: _showHiddenChecklists ? null : () => _deleteItem(item),
        onRestore: _showHiddenChecklists ? () => _restoreChecklist(item) : null,
        onSyncAdminUpdate: _showHiddenChecklists
            ? null
            : () => _syncChecklistAdminUpdate(item),
        isHidden: _showHiddenChecklists,
      );
    }).toList();
  }

  List<Widget> _buildResults(_Json data) {
    final allItems = _itemsFrom(data);
    final query = _search.text.trim().toLowerCase();

    final items = allItems.where((item) {
      if (query.isNotEmpty) {
        final studentName = _docText(
          _docMap(item['student'])['name'],
        ).toLowerCase();
        final studentNo = _docText(
          _docMap(item['student'])['student_number'],
        ).toLowerCase();
        final checklistTitle = _docText(
          _docMap(item['checklist'])['title'],
        ).toLowerCase();
        final grade = _docText(item['grade']).toLowerCase();
        if (!studentName.contains(query) &&
            !studentNo.contains(query) &&
            !checklistTitle.contains(query) &&
            !grade.contains(query)) {
          return false;
        }
      }

      if (_status != null && _status!.isNotEmpty) {
        final grade = _docText(item['grade']);
        if (grade != _status) return false;
      }

      return true;
    }).toList();

    return [
      _EvaluationPortfoliosEntryCard(
        onTap: () => context.push(DoctorEvaluationPortfoliosScreen.route),
      ),
      if (items.isEmpty)
        const _DocEmpty('لا توجد نتائج تقييم مطابقة.')
      else
        ...items.map((item) {
          return _ClinicalEvaluationResultCard(
            item: item,
            onTap: () => _showEvaluationResult(item),
          );
        }),
    ];
  }

  Widget _buildScanner() {
    if (_scannerController == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      height: 420,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_processingQr) return;
                final code = capture.barcodes
                    .map((item) => item.rawValue ?? '')
                    .firstWhere((value) => value.isNotEmpty, orElse: () => '');
                if (code.isNotEmpty) _processLogQr(code);
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScannerOverlayPainter()),
            ),
          ),
          const _ScannerLaserLine(),
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder(
              valueListenable: _scannerController!,
              builder: (context, state, child) {
                final isTorchOn =
                    _scannerController!.value.torchState == TorchState.on;
                return IconButton(
                  onPressed: () => _scannerController!.toggleTorch(),
                  icon: Icon(
                    isTorchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: isTorchOn ? AppColors.gold : Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                _processingQr
                    ? 'جاري قراءة السجل السريري...'
                    : 'وجّه الكاميرا إلى QR السجل العملي للطالب',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationStart(_Json data) {
    return _ClinicalEvaluationForm(
      data: data,
      onSubmit: (payload) async {
        final response = await ref
            .read(staffRepositoryProvider)
            .post('/doctor/clinical/evaluations/submit', payload);
        if (!mounted) return;
        await showMoeenInfoDialog(
          context: context,
          title: 'تم حفظ التقييم',
          message: _docText(response['message'], 'تم حفظ نتيجة التقييم بنجاح.'),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
      },
    );
  }

  Future<void> _processLogQr(String token) async {
    _update(() => _processingQr = true);
    try {
      final response = await ref.read(staffRepositoryProvider).post(
        '/doctor/clinical/logbook/scan',
        {'qr_token': token},
      );
      if (!mounted) return;
      await _showLogDetails(_docMap(_docData(response)));
    } catch (error) {
      if (mounted) await _docErrorDialog(context, error);
    } finally {
      if (mounted) _update(() => _processingQr = false);
    }
  }
}
