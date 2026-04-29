// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/moeen_card.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/status_message.dart';
import '../data/academic_option.dart';
import '../logic/auth_controller.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const route = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _role = 'student';
  String _gender = 'male';
  bool _obscure = true;
  bool _loading = false;
  bool _loadingUniversities = true;
  String? _error;
  String? _success;

  List<AcademicOption> _universities = [];
  List<AcademicOption> _colleges = [];
  List<AcademicOption> _majors = [];
  List<AcademicOption> _levels = [];

  AcademicOption? _university;
  AcademicOption? _college;
  AcademicOption? _major;
  AcademicOption? _level;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentNumberController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _loadingUniversities = true;
      _error = null;
    });
    try {
      _universities = await ref.read(authRepositoryProvider).universities();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loadingUniversities = false);
    }
  }

  Future<void> _selectUniversity(AcademicOption? option) async {
    setState(() {
      _university = option;
      _college = null;
      _major = null;
      _level = null;
      _colleges = [];
      _majors = [];
      _levels = [];
      _error = null;
    });
    if (option == null) return;
    try {
      final colleges = await ref
          .read(authRepositoryProvider)
          .colleges(option.id);
      setState(() => _colleges = colleges);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _selectCollege(AcademicOption? option) async {
    setState(() {
      _college = option;
      _major = null;
      _level = null;
      _majors = [];
      _levels = [];
      _error = null;
    });
    if (option == null) return;
    try {
      final majors = await ref.read(authRepositoryProvider).majors(option.id);
      setState(() => _majors = majors);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _selectMajor(AcademicOption? option) async {
    setState(() {
      _major = option;
      _level = null;
      _levels = [];
      _error = null;
    });
    if (option == null) return;
    try {
      final levels = await ref.read(authRepositoryProvider).levels(option.id);
      setState(() => _levels = levels);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ([_university, _college, _major, _level].any((item) => item == null)) {
      setState(() => _error = 'أكمل بيانات الجامعة والكلية والتخصص والمستوى.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
            gender: _gender,
            universityId: _university!.id,
            collegeId: _college!.id,
            majorId: _major!.id,
            levelId: _level!.id,
            studentNumber: _studentNumberController.text.trim(),
          );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم إنشاء الحساب',
        message:
            'تم إرسال طلب إنشاء الحساب بنجاح. الحساب الآن قيد مراجعة الإدارة.',
        buttonLabel: 'موافق',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      if (mounted) context.go(LoginScreen.route);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: MoeenCard(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: MoeenLogo(compact: true)),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'رجوع',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'إنشاء حساب جديد',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'سيتم إرسال الطلب للإدارة للمراجعة قبل التفعيل.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                StatusMessage.error(_error!),
                const SizedBox(height: 14),
              ],
              if (_success != null) ...[
                StatusMessage.success(_success!),
                const SizedBox(height: 14),
              ],
              _SegmentedChoice(
                label: 'نوع الحساب',
                value: _role,
                options: const {'student': 'طالب', 'delegate': 'مندوب'},
                onChanged: (value) => setState(() => _role = value),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required('أدخل الاسم الكامل.'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'أدخل البريد الإلكتروني.';
                  if (!value.contains('@')) return 'أدخل بريدًا صحيحًا.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم القيد',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: _required('أدخل رقم القيد.'),
              ),
              const SizedBox(height: 12),
              _SegmentedChoice(
                label: 'الجنس',
                value: _gender,
                options: const {'male': 'ذكر', 'female': 'أنثى'},
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 12),
              _OptionDropdown(
                label: _loadingUniversities
                    ? 'جاري تحميل الجامعات...'
                    : 'الجامعة',
                value: _university,
                options: _universities,
                onChanged: _loadingUniversities ? null : _selectUniversity,
              ),
              const SizedBox(height: 12),
              _OptionDropdown(
                label: 'الكلية',
                value: _college,
                options: _colleges,
                onChanged: _selectCollege,
              ),
              const SizedBox(height: 12),
              _OptionDropdown(
                label: 'التخصص',
                value: _major,
                options: _majors,
                onChanged: _selectMajor,
              ),
              const SizedBox(height: 12),
              _OptionDropdown(
                label: 'المستوى',
                value: _level,
                options: _levels,
                onChanged: (value) => setState(() => _level = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8)
                    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) {
                  if (value != _passwordController.text)
                    return 'تأكيد كلمة المرور غير مطابق.';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                label: 'إرسال طلب إنشاء الحساب',
                icon: Icons.person_add_alt_1_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => context.go(LoginScreen.route),
                child: const Text('لدي حساب بالفعل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final AcademicOption? value;
  final List<AcademicOption> options;
  final ValueChanged<AcademicOption?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = options.any((option) => option.id == value?.id)
        ? value
        : null;
    return DropdownButtonFormField<AcademicOption>(
      isExpanded: true,
      initialValue: safeValue,
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(
                option.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.school_outlined),
      ),
      validator: (value) => value == null ? 'هذا الحقل مطلوب.' : null,
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  const _SegmentedChoice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: options.entries.map((entry) {
              final selected = entry.key == value;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.midnight.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.slate500,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
