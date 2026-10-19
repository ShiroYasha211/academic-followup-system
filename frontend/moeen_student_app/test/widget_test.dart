import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/app.dart';
import 'package:moeen_student_app/src/features/auth/data/auth_session.dart';
import 'package:moeen_student_app/src/features/auth/logic/auth_controller.dart';
import 'package:moeen_student_app/src/features/auth/presentation/splash_screen.dart';

class _SignedOutAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => null;
}

void main() {
  testWidgets('Signed-out app shows splash then login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_SignedOutAuthController.new),
          splashNotificationsProvider.overrideWith((ref) async {}),
        ],
        child: const MoeenStudentApp(),
      ),
    );

    expect(find.text('مساحتك التعليمية في مكان واحد'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(find.text('مساحتك التعليمية في مكان واحد'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
