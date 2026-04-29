import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/moeen_logo.dart';
import '../../auth/data/auth_session.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';

class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key, required this.session});

  static const route = '/home';

  final AuthSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSession =
        session ?? ref.watch(authControllerProvider).valueOrNull;
    final profile = _profile(currentSession);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.slate100, Color(0xFFEFF6FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: MoeenLogo(compact: true)),
                    IconButton.filledTonal(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) context.go(LoginScreen.route);
                      },
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.midnight.withValues(alpha: 0.08),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          profile.icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        profile.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSession == null
                            ? 'لم يتم العثور على جلسة محفوظة.'
                            : 'مرحبًا ${currentSession.name}. هذه شاشة مؤقتة للتأكد من نجاح تسجيل الدخول والتوجيه قبل بناء اللوحة الحقيقية.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(label: 'Role: ${currentSession?.role ?? '-'}'),
                          _Chip(
                            label:
                                'Workspace: ${currentSession?.workspace.name ?? '-'}',
                          ),
                          if (currentSession?.isPracticalDelegate == true)
                            const _Chip(label: 'Practical Delegate'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'المرحلة التالية: بناء الداشبورد والوظائف حسب صلاحيات المستخدم.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PlaceholderProfile _profile(AuthSession? session) {
    if (session?.isPracticalDelegate == true) {
      return const _PlaceholderProfile(
        'واجهة المندوب العملي',
        Icons.medical_services_outlined,
      );
    }
    if (session?.isDelegate == true) {
      return const _PlaceholderProfile(
        'واجهة المندوب',
        Icons.groups_2_outlined,
      );
    }
    return const _PlaceholderProfile('واجهة الطالب', Icons.school_outlined);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlaceholderProfile {
  const _PlaceholderProfile(this.title, this.icon);

  final String title;
  final IconData icon;
}
