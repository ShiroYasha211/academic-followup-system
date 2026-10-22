// ignore_for_file: dead_code, unused_element
part of 'student_content_screens.dart';

Future<void> _downloadFlashcardImportTemplate({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  try {
    final bytes = await ref
        .read(studentContentRepositoryProvider)
        .downloadFlashcardImportTemplate();
    final path = await DownloadService.saveBytesToMoeenFolder(
      bytes: bytes,
      fileName: 'one_line_shot_template.csv',
      section: 'OneLineShot',
    );

    if (!context.mounted || path == null) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تم تنزيل القالب',
      message: 'تم حفظ قالب الاستيراد في:\n$path',
      icon: Icons.download_done_rounded,
      color: AppColors.success,
    );
  } on ApiException catch (error) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر تنزيل القالب',
      message: error.message,
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
  }
}

Future<void> _showFlashcardImport({
  required BuildContext context,
  required WidgetRef ref,
  required int packId,
  required Color packColor,
  required VoidCallback onDone,
}) async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withReadStream: true,
    );
  } on PlatformException {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر اختيار الملف',
      message: 'تعذر فتح الملف. جرّب تنزيله إلى الهاتف ثم اختياره مجدداً.',
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
    return;
  }
  if (result == null || result.files.isEmpty) return;

  final file = result.files.single;
  final path = file.path;
  if (file.size > 10 * 1024 * 1024) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'حجم الملف كبير',
      message: 'الحد الأقصى لحجم ملف الاستيراد هو 10 ميجابايت.',
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
    return;
  }
  if ((path == null || path.isEmpty) &&
      file.bytes == null &&
      file.readStream == null) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر قراءة الملف',
      message: 'لم يتمكن التطبيق من الوصول إلى مسار الملف المحدد.',
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
    return;
  }

  Map<String, dynamic> preview;
  try {
    List<int>? bytes = file.bytes;
    if ((path == null || path.isEmpty) && bytes == null) {
      bytes = <int>[];
      await for (final chunk in file.readStream!) {
        if (bytes.length + chunk.length > 10 * 1024 * 1024) {
          throw const FileSystemException('حجم الملف يتجاوز 10 ميجابايت.');
        }
        bytes.addAll(chunk);
      }
    }
    if (!context.mounted) return;
    preview = await ref
        .read(studentContentRepositoryProvider)
        .previewFlashcardImport(
          packId: packId,
          filePath: path,
          fileBytes: bytes,
          fileName: file.name,
        );
  } on ApiException catch (error) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر معاينة الملف',
      message: error.message,
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
    return;
  } on FileSystemException catch (error) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر قراءة الملف',
      message:
          'تعذر الوصول إلى الملف المحدد. جرّب تنزيله إلى الهاتف وإعادة اختياره.\n${error.message}',
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
    return;
  }

  if (!context.mounted) return;
  final payload = await _showFlashcardImportPreviewSheet(
    context: context,
    preview: preview,
    packColor: packColor,
  );
  if (payload == null || !context.mounted) return;

  try {
    final data = await ref
        .read(studentContentRepositoryProvider)
        .confirmFlashcardImport(packId: packId, payload: payload);
    onDone();

    if (!context.mounted) return;
    final report = asMap(data['report']);
    final errors = asList(report['errors'])
        .map(asMap)
        .take(5)
        .map((error) => 'الصف ${text(error, 'row')}: ${text(error, 'reason')}')
        .join('\n');
    final hasFailures = number(report, 'failed_count') > 0;
    final hasChanges =
        number(report, 'success_count') + number(report, 'updated_count') > 0;
    await showMoeenInfoDialog(
      context: context,
      title: hasFailures
          ? (hasChanges ? 'اكتمل الاستيراد جزئياً' : 'لم تتم إضافة بطاقات')
          : 'تم استيراد الملف',
      message:
          '${text(data, 'message', fallback: 'تم استيراد الملف بنجاح.')}\n\n'
          'جديدة: ${number(report, 'success_count').toInt()}\n'
          'محدثة: ${number(report, 'updated_count').toInt()}\n'
          'متجاهلة: ${number(report, 'ignored_count').toInt()}\n'
          'لم تُستورد: ${number(report, 'failed_count').toInt()}'
          '${errors.isEmpty ? '' : '\n\n$errors'}',
      icon: hasFailures
          ? Icons.warning_amber_rounded
          : Icons.check_circle_rounded,
      color: hasFailures ? AppColors.goldDeep : AppColors.success,
    );
  } on ApiException catch (error) {
    if (!context.mounted) return;
    await showMoeenInfoDialog(
      context: context,
      title: 'تعذر تأكيد الاستيراد',
      message: error.message,
      icon: Icons.error_rounded,
      color: AppColors.danger,
    );
  }
}

Future<Map<String, dynamic>?> _showFlashcardImportPreviewSheet({
  required BuildContext context,
  required Map<String, dynamic> preview,
  required Color packColor,
}) {
  final columns = asList(preview['columns']).map((value) => '$value').toList();
  final rows = asList(preview['preview_rows']).map(asList).toList();
  final guessed = asMap(preview['guessed_mapping']);
  if (columns.isEmpty) return Future.value(null);
  int safeColumn(Object? value, {bool required = false}) {
    final column = _importInt(value, fallback: -1);
    return column >= 0 && column < columns.length
        ? column
        : (required ? 0 : -1);
  }

  bool hasHeaders = boolValue(preview, 'is_first_row_header');
  String duplicateStrategy = 'ignore';
  int itemTypeCol = safeColumn(guessed['item_type_col']);
  int frontContentCol = safeColumn(
    guessed['front_content_col'],
    required: true,
  );
  int backContentCol = safeColumn(guessed['back_content_col']);
  int correctOptionCol = safeColumn(guessed['correct_option_col']);
  int priorityCol = safeColumn(guessed['priority_col']);
  int colorCol = safeColumn(guessed['color_col']);
  final optionsCols = asList(
    guessed['options_cols'],
  ).map((value) => safeColumn(value)).where((value) => value >= 0).toSet();

  return showMoeenBottomSheet<Map<String, dynamic>>(
    context: context,
    title: 'معاينة الاستيراد',
    icon: Icons.upload_file_rounded,
    color: packColor,
    child: StatefulBuilder(
      builder: (sheetContext, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FlashcardImportSummary(
              columnsCount: columns.length,
              rowsCount: rows.length,
              hasHeaders: hasHeaders,
              color: packColor,
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: hasHeaders,
              activeColor: packColor,
              title: const Text(
                'الملف يحتوي على صف عناوين',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'إذا كان أول صف بطاقة فعلية، ألغِ هذا الخيار حتى لا يتم تجاهله.',
              ),
              onChanged: (value) => setLocal(() => hasHeaders = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: duplicateStrategy,
              decoration: const InputDecoration(labelText: 'معالجة التكرار'),
              items: const [
                DropdownMenuItem(value: 'ignore', child: Text('تجاهل المكرر')),
                DropdownMenuItem(value: 'update', child: Text('تحديث المكرر')),
                DropdownMenuItem(
                  value: 'allow',
                  child: Text('السماح بالتكرار'),
                ),
              ],
              onChanged: (value) => setLocal(
                () => duplicateStrategy = value ?? duplicateStrategy,
              ),
            ),
            const SizedBox(height: 14),
            _ImportColumnSelect(
              label: 'المحتوى الأمامي أو السؤال',
              value: frontContentCol,
              columns: columns,
              allowDefault: false,
              onChanged: (value) => setLocal(() => frontContentCol = value),
            ),
            const SizedBox(height: 12),
            _ImportColumnSelect(
              label: 'نوع البطاقة',
              value: itemTypeCol,
              columns: columns,
              defaultLabel: 'استخدم نوع الحزمة الافتراضي',
              onChanged: (value) => setLocal(() => itemTypeCol = value),
            ),
            const SizedBox(height: 12),
            _ImportColumnSelect(
              label: 'الإجابة أو المحتوى الخلفي',
              value: backContentCol,
              columns: columns,
              defaultLabel: 'بدون إجابة',
              onChanged: (value) => setLocal(() => backContentCol = value),
            ),
            const SizedBox(height: 12),
            _ImportColumnSelect(
              label: 'رقم الإجابة الصحيحة للاختيار المتعدد',
              value: correctOptionCol,
              columns: columns,
              defaultLabel: 'الخيار الأول افتراضيًا',
              onChanged: (value) => setLocal(() => correctOptionCol = value),
            ),
            const SizedBox(height: 12),
            _ImportColumnSelect(
              label: 'الأولوية',
              value: priorityCol,
              columns: columns,
              defaultLabel: 'عادي',
              onChanged: (value) => setLocal(() => priorityCol = value),
            ),
            const SizedBox(height: 12),
            _ImportColumnSelect(
              label: 'لون البطاقة',
              value: colorCol,
              columns: columns,
              defaultLabel: 'لون الحزمة',
              onChanged: (value) => setLocal(() => colorCol = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'أعمدة خيارات الاختيار المتعدد',
              style: TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < columns.length; i++)
                  FilterChip(
                    selected: optionsCols.contains(i),
                    label: Text('عمود ${i + 1}'),
                    selectedColor: packColor.withValues(alpha: 0.18),
                    checkmarkColor: packColor,
                    onSelected: (selected) => setLocal(() {
                      selected ? optionsCols.add(i) : optionsCols.remove(i);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _FlashcardImportPreviewTable(columns: columns, rows: rows),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext, {
                  'temp_file': text(preview, 'temp_file'),
                  'duplicate_strategy': duplicateStrategy,
                  'has_headers': hasHeaders,
                  'front_content_col': frontContentCol,
                  'item_type_col': itemTypeCol,
                  'back_content_col': backContentCol,
                  'options_cols': optionsCols.toList()..sort(),
                  'correct_option_col': correctOptionCol,
                  'priority_col': priorityCol,
                  'color_col': colorCol,
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: packColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'تأكيد الاستيراد',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _FlashcardImportSummary extends StatelessWidget {
  const _FlashcardImportSummary({
    required this.columnsCount,
    required this.rowsCount,
    required this.hasHeaders,
    required this.color,
  });

  final int columnsCount;
  final int rowsCount;
  final bool hasHeaders;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$columnsCount أعمدة · معاينة $rowsCount صفوف · ${hasHeaders ? 'تم اكتشاف صف عناوين' : 'لم يتم اكتشاف صف عناوين'}',
              style: const TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportColumnSelect extends StatelessWidget {
  const _ImportColumnSelect({
    required this.label,
    required this.value,
    required this.columns,
    required this.onChanged,
    this.allowDefault = true,
    this.defaultLabel = 'افتراضي',
  });

  final String label;
  final int value;
  final List<String> columns;
  final ValueChanged<int> onChanged;
  final bool allowDefault;
  final String defaultLabel;

  @override
  Widget build(BuildContext context) {
    final safeValue = value >= 0 && value < columns.length
        ? value
        : allowDefault
        ? -1
        : 0;
    return DropdownButtonFormField<int>(
      value: safeValue,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowDefault)
          DropdownMenuItem(value: -1, child: Text(defaultLabel)),
        for (var i = 0; i < columns.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(
              'العمود ${i + 1}: ${columns[i]}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => onChanged(value ?? safeValue),
    );
  }
}

class _FlashcardImportPreviewTable extends StatelessWidget {
  const _FlashcardImportPreviewTable({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const EmptyState(message: 'لا توجد صفوف للمعاينة.');
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate500.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 42,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 62,
            columns: [
              const DataColumn(label: Text('#')),
              for (var i = 0; i < columns.length; i++)
                DataColumn(label: Text('عمود ${i + 1}')),
            ],
            rows: [
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                DataRow(
                  cells: [
                    DataCell(Text('${rowIndex + 1}')),
                    for (
                      var colIndex = 0;
                      colIndex < columns.length;
                      colIndex++
                    )
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: Text(
                            colIndex < rows[rowIndex].length
                                ? '${rows[rowIndex][colIndex] ?? ''}'
                                : '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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

int _importInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}
