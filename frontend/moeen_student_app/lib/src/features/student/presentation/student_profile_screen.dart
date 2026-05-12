part of 'student_content_screens.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  static const route = '/student/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_studentProfileProvider);
    return StudentShell(
      currentIndex: 18,
      title: 'ملفي الشخصي',
      child: _AsyncBody(
        state: state,
        onRetry: () => ref.invalidate(_studentProfileProvider),
        builder: (profile) {
          final major = asMap(profile['major']);
          final level = asMap(profile['level']);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_studentProfileProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(profile: profile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'البيانات الأكاديمية',
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _AcademicCard(
                                  icon: Icons.badge_rounded,
                                  label: 'رقم القيد',
                                  value: text(
                                    profile,
                                    'student_number',
                                    fallback: '-',
                                  ),
                                  color: AppColors.royalBlue,
                                ),
                                const SizedBox(height: 12),
                                _AcademicCard(
                                  icon: Icons.apartment_rounded,
                                  label: 'الكلية',
                                  value: text(
                                    profile,
                                    'college',
                                    fallback: '-',
                                  ),
                                  color: AppColors.info,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _AcademicCard(
                                  icon: Icons.account_balance_rounded,
                                  label: 'الجامعة',
                                  value: text(
                                    profile,
                                    'university',
                                    fallback: '-',
                                  ),
                                  color: AppColors.goldDeep,
                                ),
                                const SizedBox(height: 12),
                                _AcademicCard(
                                  icon: Icons.menu_book_rounded,
                                  label: 'التخصص',
                                  value: text(major, 'name', fallback: '-'),
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AcademicCard(
                        icon: Icons.layers_rounded,
                        label: 'المستوى الدراسي الحالي',
                        value: text(level, 'name', fallback: '-'),
                        color: AppColors.rose,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 32),
                      const _SectionHeader(
                        title: 'معلومات الحساب',
                        icon: Icons.manage_accounts_rounded,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.slate100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _AccountDetailRow(
                              icon: Icons.email_rounded,
                              label: 'البريد الإلكتروني',
                              value: text(profile, 'email', fallback: '-'),
                              color: AppColors.royalBlue,
                            ),
                            const Divider(height: 32),
                            _AccountDetailRow(
                              icon: Icons.verified_user_rounded,
                              label: 'حالة الحساب',
                              value: _accountStatusLabel(
                                text(profile, 'status'),
                              ),
                              color: AppColors.success,
                            ),
                            if (boolValue(
                              profile,
                              'is_practical_delegate',
                            )) ...[
                              const Divider(height: 32),
                              const _AccountDetailRow(
                                icon: Icons.workspace_premium_rounded,
                                label: 'الصلاحية الإضافية',
                                value: 'مندوب عملي معتمد',
                                color: AppColors.goldDeep,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showChangeEmail(
                            context,
                            ref,
                            text(profile, 'email'),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: AppColors.royalBlue,
                          ),
                          icon: const Icon(Icons.alternate_email_rounded),
                          label: const Text(
                            'تعديل البريد الإلكتروني',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showChangePassword(context, ref),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: AppColors.midnight,
                          ),
                          icon: const Icon(Icons.password_rounded),
                          label: const Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showChangeEmail(
    BuildContext context,
    WidgetRef ref,
    String currentEmail,
  ) async {
    await showMoeenBottomSheet(
      context: context,
      title: 'تعديل البريد الإلكتروني',
      icon: Icons.alternate_email_rounded,
      color: AppColors.royalBlue,
      child: _ChangeEmailForm(
        currentEmail: currentEmail,
        onSubmit: (email, currentPassword) async {
          final updated = await ref
              .read(studentContentRepositoryProvider)
              .updateEmail(email: email, currentPassword: currentPassword);
          final newEmail = text(updated, 'email', fallback: email);
          await ref.read(authControllerProvider.notifier).updateEmail(newEmail);
          ref.invalidate(_studentProfileProvider);
        },
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context, WidgetRef ref) async {
    await showMoeenBottomSheet(
      context: context,
      title: 'تغيير كلمة المرور',
      icon: Icons.password_rounded,
      color: AppColors.royalBlue,
      child: _ChangePasswordForm(
        onSubmit: (current, password, confirm) => ref
            .read(studentContentRepositoryProvider)
            .changePassword(
              currentPassword: current,
              newPassword: password,
              confirmation: confirm,
            ),
      ),
    );
  }
}

class _ChangeEmailForm extends StatefulWidget {
  const _ChangeEmailForm({required this.currentEmail, required this.onSubmit});

  final String currentEmail;
  final Future<void> Function(String email, String currentPassword) onSubmit;

  @override
  State<_ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<_ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'اكتب البريد الإلكتروني الجديد.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'اكتب بريدًا إلكترونيًا صحيحًا.';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني الجديد',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) => value == null || value.isEmpty
                ? 'اكتب كلمة المرور الحالية.'
                : null,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _handleSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'حفظ البريد الإلكتروني',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البريد الإلكتروني بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.onSubmit});
  final Future<void> Function(String current, String password, String confirm)
  onSubmit;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validate);
    _confirmController.addListener(_validate);
  }

  void _validate() {
    setState(() {
      final p = _passwordController.text;
      final c = _confirmController.text;

      if (p.isNotEmpty && p.length < 8) {
        _passwordError = 'يجب أن تكون 8 أحرف على الأقل';
      } else {
        _passwordError = null;
      }

      if (c.isNotEmpty && c != p) {
        _confirmError = 'كلمة المرور غير متطابقة';
      } else {
        _confirmError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _currentController,
            obscureText: _obscureCurrent,
            validator: (value) => value == null || value.isEmpty
                ? 'اكتب كلمة المرور الحالية.'
                : null,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الحالية',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => _validate(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'اكتب كلمة المرور الجديدة.';
              }
              if (value.length < 8) {
                return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              errorText: _passwordError,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            onChanged: (_) => _validate(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'أكد كلمة المرور الجديدة.';
              }
              if (value != _passwordController.text) {
                return 'كلمة المرور غير متطابقة.';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور الجديدة',
              errorText: _confirmError,
              prefixIcon: const Icon(Icons.verified_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _handleSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'حفظ التغييرات',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        _currentController.text,
        _passwordController.text,
        _confirmController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final avatar = absoluteUrl(text(profile, 'avatar'));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 60,
        20,
        40,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? Text(
                          text(profile, 'name', fallback: 'ط').characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            text(profile, 'name', fallback: 'طالب معين'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text(profile, 'email', fallback: 'student@moeen.edu'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderBadge(
                label: _roleLabel(text(profile, 'role')),
                icon: Icons.verified_user_rounded,
              ),
              if (boolValue(profile, 'is_practical_delegate')) ...[
                const SizedBox(width: 12),
                const _HeaderBadge(
                  label: 'مندوب عملي',
                  icon: Icons.stars_rounded,
                  isPremium: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.label,
    required this.icon,
    this.isPremium = false,
  });
  final String label;
  final IconData icon;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPremium
            ? AppColors.gold.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPremium
              ? AppColors.gold.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isPremium ? AppColors.gold : Colors.white,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPremium ? AppColors.gold : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.midnight, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.midnight,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AcademicCard extends StatelessWidget {
  const _AcademicCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isFullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
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

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.midnight,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _roleLabel(String role) {
  return switch (role) {
    'delegate' => 'مندوب',
    'doctor' => 'دكتور',
    'student' => 'طالب',
    _ => role.isEmpty ? 'طالب' : role,
  };
}

String _accountStatusLabel(String status) {
  return switch (status) {
    'active' => 'نشط',
    'inactive' => 'غير نشط',
    'pending' => 'قيد المراجعة',
    'suspended' => 'موقوف',
    _ => status.isEmpty ? '-' : status,
  };
}
