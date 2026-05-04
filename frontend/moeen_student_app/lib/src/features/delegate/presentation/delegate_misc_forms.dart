part of 'delegate_screens.dart';

// Kept for direct import actions from resource cards.
// ignore: unused_element
Future<void> _importResourceSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> resource,
) async {
  final subjects = await ref.read(delegateRepositoryProvider).subjects();
  if (!context.mounted) return;
  var subjectId = subjects.isNotEmpty
      ? number(subjects.first, 'id').toInt()
      : 0;
  await _formSheet(
    context,
    title: 'استيراد الملف',
    fields: [
      Text(
        text(resource, 'title'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      DropdownButtonFormField<int>(
        value: subjectId == 0 ? null : subjectId,
        items: subjects
            .map(
              (subject) => DropdownMenuItem(
                value: number(subject, 'id').toInt(),
                child: Text(text(subject, 'name')),
              ),
            )
            .toList(),
        onChanged: (value) => subjectId = value ?? 0,
        decoration: const InputDecoration(labelText: 'استيراد إلى المادة'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .importResource(
          resourceId: number(resource, 'id').toInt(),
          subjectId: subjectId,
        ),
    after: () {},
  );
}

Future<void> _replyInquirySheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> inquiry,
) async {
  final reply = TextEditingController();
  await _formSheet(
    context,
    title: 'الرد على الاستفسار',
    fields: [
      Text(
        text(inquiry, 'question', fallback: text(inquiry, 'title')),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextField(
        controller: reply,
        minLines: 4,
        maxLines: 7,
        decoration: const InputDecoration(labelText: 'الرد'),
      ),
    ],
    onSave: () => ref
        .read(delegateRepositoryProvider)
        .replyInquiry(
          id: number(inquiry, 'id').toInt(),
          reply: reply.text.trim(),
        ),
    after: () => ref.invalidate(_delegateInquiriesProvider('all')),
  );
}

Future<void> _formSheet(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  required Future<String> Function() onSave,
  required VoidCallback after,
}) async {
  var saving = false;
  final formKey = GlobalKey<FormState>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.midnight,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...fields.expand(
                      (field) => [field, const SizedBox(height: 16)],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (formKey.currentState?.validate() != true)
                                  return;
                                setState(() => saving = true);
                                try {
                                  final message = await onSave();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _toast(context, message);
                                  }
                                  after();
                                } catch (error) {
                                  if (context.mounted)
                                    _showError(context, error);
                                } finally {
                                  if (context.mounted)
                                    setState(() => saving = false);
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
                        child: saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'حفظ البيانات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _delete(
  BuildContext context,
  Future<String> Function() action,
  VoidCallback after,
) async {
  final confirmed = await showMoeenConfirmDialog(
    context: context,
    title: 'تأكيد الحذف',
    message: 'هل تريد حذف هذا العنصر؟',
    confirmLabel: 'حذف',
    icon: Icons.delete_rounded,
    color: AppColors.danger,
    danger: true,
  );
  if (!confirmed) return;
  await _run(context, action, after: after);
}

Future<void> _run(
  BuildContext context,
  Future<dynamic> Function() action, {
  required VoidCallback after,
}) async {
  try {
    final result = await action();
    after();
    if (context.mounted)
      _toast(context, result?.toString() ?? 'تم تنفيذ العملية.');
  } catch (error) {
    if (context.mounted) _showError(context, error);
  }
}

// Chat widgets
