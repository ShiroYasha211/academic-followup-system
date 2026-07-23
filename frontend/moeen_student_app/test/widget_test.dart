import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/app.dart';

void main() {
  testWidgets('Moeen app boots and renders splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoeenStudentApp()));

    expect(find.text('مساحتك التعليمية في مكان واحد'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
