import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_variant.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/auth_status_message.dart';
import '../../../shared/widgets/moeen_card.dart';
import '../../../shared/widgets/moeen_dialogs.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../../shared/widgets/primary_action_button.dart';
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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _loadingUniversities = true;
  String? _error;

  List<AcademicOption> _universities = [];
  List<AcademicOption> _colleges = [];
  AcademicOption? _university;
  AcademicOption? _college;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      _colleges = [];
      _error = null;
    });
    if (option == null) return;
    try {
      final colleges = await ref
          .read(authRepositoryProvider)
          .colleges(option.id);
      if (mounted) setState(() => _colleges = colleges);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_university == null || _college == null) {
      setState(() => _error = 'أكمل بيانات الجامعة والكلية.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .registerDoctor(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            universityId: _university!.id,
            collegeId: _college!.id,
          );
      if (!mounted) return;
      await showMoeenInfoDialog(
        context: context,
        title: 'تم إنشاء الحساب',
        message:
            'تم إرسال طلب إنشاء حساب الدكتور بنجاح. الحساب الآن قيد مراجعة الإدارة.',
        buttonLabel: 'موافق',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      );
      if (mounted) {
        _resetForm();
        context.go(LoginScreen.route);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    context.go(LoginScreen.route);
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmController.clear();
    setState(() {
      _university = null;
      _college = null;
      _colleges = [];
    });
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToLogin();
      },
      child: AuthShell(
        child: MoeenCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: MoeenLogo(compact: true, centered: true)),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: StaffBrandColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StaffBrandColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: StaffBrandColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'بوابة عضو هيئة التدريس',
                          style: TextStyle(
                            color: StaffBrandColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'طلب انضمام',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'تقديم طلب انضمام لعضوية هيئة التدريس. سيتم مراجعة الطلب من قبل الإدارة قبل تفعيل الحساب.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  AuthStatusMessage.error(_error!),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: _required('أدخل الاسم الكامل.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل البريد الإلكتروني.';
                    }
                    if (!value.contains('@')) return 'أدخل بريدًا صحيحًا.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _OptionDropdown(
                  label: _loadingUniversities
                      ? 'جاري تحميل الجامعات...'
                      : 'الجامعة',
                  value: _university,
                  options: _universities,
                  prefixIcon: Icons.account_balance_rounded,
                  onChanged: _loadingUniversities ? null : _selectUniversity,
                ),
                const SizedBox(height: 12),
                _OptionDropdown(
                  label: 'الكلية',
                  value: _college,
                  options: _colleges,
                  prefixIcon: Icons.school_rounded,
                  onChanged: (value) => setState(() => _college = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                    if (value == null || value.length < 8) {
                      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'تأكيد كلمة المرور غير مطابق.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryActionButton(
                  label: 'تقديم طلب انضمام',
                  icon: Icons.person_add_alt_1_rounded,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟ ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: StaffBrandColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
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

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.prefixIcon,
  });

  final String label;
  final AcademicOption? value;
  final List<AcademicOption> options;
  final ValueChanged<AcademicOption?>? onChanged;
  final IconData prefixIcon;

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
        prefixIcon: Icon(prefixIcon),
      ),
      validator: (value) => value == null ? 'هذا الحقل مطلوب.' : null,
    );
  }
}
