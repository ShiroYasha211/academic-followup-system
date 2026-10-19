import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/shared/widgets/library_browser.dart';

Future<void> _openLibrary(
  WidgetTester tester,
  Map<String, dynamic> counts,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: LibraryBrowser(
            title: 'المكتبة المشتركة',
            subtitle: 'مصادر الدراسة',
            accentColor: Colors.blue,
            load: (node, search, page) async => {
              'children': [
                {
                  'key': 'custom:1',
                  'title': 'المحاضرات',
                  'type': 'section',
                  ...counts,
                },
              ],
            },
            onDownload: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final grid in [false, true]) {
    final mode = grid ? 'grid' : 'list';
    testWidgets('Missing count is not treated as empty in $mode', (
      tester,
    ) async {
      await _openLibrary(tester, {});
      if (grid) {
        await tester.tap(find.byTooltip('عرض كشبكة'));
        await tester.pumpAndSettle();
      }
      expect(find.text('المحاضرات'), findsOneWidget);
      expect(find.text('فارغ حالياً'), findsNothing);
      expect(find.text('لا توجد ملفات في هذا المسار حالياً'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Explicit zero is empty in $mode', (tester) async {
      await _openLibrary(tester, {'items_count': 0, 'is_empty': true});
      if (grid) {
        await tester.tap(find.byTooltip('عرض كشبكة'));
        await tester.pumpAndSettle();
      }
      expect(find.text('فارغ حالياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Positive count is shown in $mode', (tester) async {
      await _openLibrary(tester, {'items_count': 3, 'is_empty': false});
      if (grid) {
        await tester.tap(find.byTooltip('عرض كشبكة'));
        await tester.pumpAndSettle();
      }
      expect(find.text('3 ملفات'), findsOneWidget);
      expect(find.text('فارغ حالياً'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
