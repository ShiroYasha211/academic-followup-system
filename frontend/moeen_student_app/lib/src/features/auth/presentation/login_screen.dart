import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/push_notification_service.dart';
import '../../../core/router/landing_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_shell.dart';
import '../../../shared/widgets/moeen_card.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/status_message.dart';
import '../logic/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(
          login: _loginController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session != null) {
      final pendingPath = PushNotificationService.takePendingNavigationPath();
      context.go(pendingPath ?? landingRouteFor(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final error = authState.hasError ? authState.error.toString() : null;

    return AuthShell(
      child: MoeenCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: MoeenLogo(compact: true, centered: true)),
              const SizedBox(height: 28),
              Text(
                'تسجيل الدخول',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'ادخل بحساب الطالب أو المندوب للوصول إلى خدمات معين.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (error != null) ...[
                StatusMessage.error(error),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _loginController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'البريد أو رقم القيد',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'أدخل البريد أو رقم القيد.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
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
                  if (value == null || value.isEmpty) {
                    return 'أدخل كلمة المرور.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                label: 'دخول إلى التطبيق',
                icon: Icons.login_rounded,
                loading: authState.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'لا تملك حسابًا؟ ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push(RegisterScreen.route),
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        color: AppColors.primary,
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
    );
  }
}
