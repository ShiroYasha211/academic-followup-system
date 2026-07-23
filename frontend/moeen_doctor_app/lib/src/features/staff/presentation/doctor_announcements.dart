part of 'staff_screens.dart';

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

  void _reload() => setState(() {
    _future = _fetch();
  });

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
                ),
                const SizedBox(height: 18),

                // Horizontal Capsule Filter Row
                const Text(
                  'تصفية الإعلانات',
                  style: TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterChips(),
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

  Widget _buildFilterChips() {
    final choices = [
      {
        'value': 'all',
        'label': 'الكل',
        'icon': Icons.apps_rounded,
        'color': AppColors.royalBlue,
      },
      {
        'value': 'announcement',
        'label': 'إعلان',
        'icon': Icons.campaign_rounded,
        'color': AppColors.royalBlue,
      },
      {
        'value': 'warning',
        'label': 'تحذير',
        'icon': Icons.warning_rounded,
        'color': AppColors.danger,
      },
      {
        'value': 'quiz_alert',
        'label': 'كويز',
        'icon': Icons.quiz_rounded,
        'color': AppColors.warning,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: choices.map((choice) {
          final val = choice['value'] as String;
          final label = choice['label'] as String;
          final icon = choice['icon'] as IconData;
          final color = choice['color'] as Color;
          final isSelected = _type == val;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              selectedColor: color,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? Colors.transparent : AppColors.slate100,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.slate700,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _type = val;
                    _future = _fetch();
                  });
                }
              },
            ),
          );
        }).toList(),
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

    InputDecoration inputDecoration(
      String label,
      IconData icon, {
      bool alignLabel = false,
    }) {
      return InputDecoration(
          labelText: label,
          alignLabelWithHint: alignLabel,
          prefixIcon: Icon(icon),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
        );
    }

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
              _DocFilterPanel(
                title: 'بيانات الإعلان',
                icon: Icons.tune_rounded,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: subjectId,
                    isExpanded: true,
                    decoration: inputDecoration(
                      'المادة',
                      Icons.menu_book_rounded,
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    decoration: inputDecoration('العنوان', Icons.title_rounded),
                    validator: (value) =>
                        _docText(value).isEmpty ? 'اكتب عنوان الإعلان.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: content,
                    maxLines: 5,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    decoration: inputDecoration(
                      'المحتوى',
                      Icons.notes_rounded,
                      alignLabel: true,
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
                    readOnly: true,
                    onTap: () async {
                      final current =
                          DateTime.tryParse(publishedAt.text.trim()) ??
                          DateTime.now();
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: current,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date == null) return;
                      if (!ctx.mounted) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(current),
                      );
                      if (time == null) return;
                      final selected = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      setLocal(() {
                        publishedAt.text = _docDateTimeForApi(selected);
                      });
                    },
                    decoration:
                        inputDecoration(
                          'جدولة تاريخ النشر (اختياري)',
                          Icons.schedule_rounded,
                        ).copyWith(
                          hintText: 'سيتم النشر فوراً إذا ترك فارغاً',
                          suffixIcon: publishedAt.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () =>
                                      setLocal(() => publishedAt.clear()),
                                )
                              : const Icon(Icons.calendar_month_rounded),
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Bento style File Picker zone
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.isNotEmpty) {
                        setLocal(() => attachment = result.files.first);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: attachment != null
                              ? AppColors.teal.withValues(alpha: 0.4)
                              : AppColors.slate100,
                          width: attachment != null ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  (attachment != null
                                          ? AppColors.teal
                                          : AppColors.royalBlue)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              attachment != null
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_rounded,
                              color: attachment != null
                                  ? AppColors.teal
                                  : AppColors.royalBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment?.name ?? 'إرفاق ملف اختياري',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.midnight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  attachment != null
                                      ? 'تم تحديد الملف بنجاح'
                                      : 'يمكنك إرفاق ملف PDF أو صورة مع الإعلان',
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (attachment != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.danger,
                              ),
                              onPressed: () {
                                setLocal(() => attachment = null);
                              },
                            )
                          else
                            const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.slate300,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.pop(ctx, true);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('حفظ الإعلان'),
                  ),
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

    // Use Stack + ClipRRect to achieve colored right-side accent bar
    // because Flutter does not allow borderRadius with non-uniform border colors.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Outer border simulation using a Container with uniform border
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.slate100),
                    ),
                  ),
                ),
                // Colored right-side accent bar (RTL: start edge)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: 5,
                  child: Container(color: color),
                ),
                // Card content with right padding to clear the accent bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 17, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon avatar container with alpha background
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(
                              _announcementTypeIcon(type),
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
                            const _DocPill(
                              'مرفق',
                              AppColors.teal,
                              icon: Icons.attach_file_rounded,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docText(
                          announcement['attachment_name'],
                          'مرفق الإعلان',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'اضغط لتحميل الملف المرفق',
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAttachment,
                  icon: const Icon(Icons.download_rounded, size: 18),
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
