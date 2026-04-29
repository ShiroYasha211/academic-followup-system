import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desktop/main.dart';

void main() {
  testWidgets('renders bootstrap loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const MoeenDesktopApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
