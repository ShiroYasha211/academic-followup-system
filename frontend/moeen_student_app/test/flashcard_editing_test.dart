import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moeen_student_app/src/core/network/api_client.dart';
import 'package:moeen_student_app/src/core/offline/offline_cache_service.dart';
import 'package:moeen_student_app/src/features/auth/data/auth_session.dart';
import 'package:moeen_student_app/src/features/auth/logic/auth_controller.dart';
import 'package:moeen_student_app/src/features/student/data/flashcard_local_store.dart';
import 'package:moeen_student_app/src/features/student/data/student_repositories.dart';
import 'package:moeen_student_app/src/features/student/presentation/student_content_screens.dart';
import 'package:moeen_student_app/src/features/student/presentation/widgets/student_shell.dart';

class _Auth extends AuthController {
  @override
  Future<AuthSession?> build() async => null;
}

class _Store extends FlashcardLocalStore {
  @override
  Future<void> cacheHome(Map<String, dynamic> data) async {}

  @override
  Future<void> cachePackDetails(int id, Map<String, dynamic> data) async {}

  @override
  Future<bool> canShowSmartReview() async => false;
}

class _Repository extends StudentContentRepository {
  _Repository({
    this.editable = true,
    this.includePermission = true,
    this.linked = false,
  }) : super(ApiClient(), const OfflineCacheService());

  final bool editable;
  final bool includePermission;
  final bool linked;
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>> flashcards() async => {'packs': []};

  @override
  Future<Map<String, dynamic>> flashcardDetails(int id) async => {
    if (includePermission) 'can_manage_items': editable,
    'pack': {
      'id': id,
      'title': 'Personal',
      'is_public': false,
      'is_assigned': linked,
    },
    'items': [
      {
        'id': 7,
        'item_type': 'mcq',
        'front_content': 'Original question',
        'options': ['A', 'B', 'C', 'D', 'E', 'F'],
        'correct_option': 1,
        'priority': 'normal',
      },
    ],
  };

  @override
  Future<String> updateFlashcardItem(int id, Map<String, dynamic> data) async {
    expect(id, 7);
    saved = data;
    return 'Saved';
  }
}

Future<GoRouter> _open(WidgetTester tester, _Repository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, state) => const StudentFlashcardDetailsScreen(packId: 1),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        studentContentRepositoryProvider.overrideWithValue(repository),
        flashcardLocalStoreProvider.overrideWithValue(_Store()),
        studentUnreadNotificationsCountProvider.overrideWith((ref) async => 0),
        studentStarsBalanceProvider.overrideWith((ref) async => 0),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('MCQ editor preserves all six options and selected answer', (
    tester,
  ) async {
    final repository = _Repository();
    final router = await _open(tester, repository);
    await tester.ensureVisible(find.byTooltip('تعديل العنصر'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تعديل العنصر'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل العنصر'), findsOneWidget);
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(7));
    final selected = tester
        .widgetList<Radio<int>>(find.byType(Radio<int>))
        .firstWhere((radio) => radio.value == 1);
    expect(selected.groupValue, 1);
    await tester.enterText(fields.first, 'Edited question');
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(repository.saved?['front_content'], 'Edited question');
    expect(repository.saved?['correct_option'], 1);
    expect(repository.saved?['options'], ['A', 'B', 'C', 'D', 'E', 'F']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Linked packs hide add edit delete and import controls', (
    tester,
  ) async {
    final router = await _open(tester, _Repository(editable: false));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('تعديل العنصر'), findsNothing);
    expect(find.byTooltip('حذف العنصر'), findsNothing);
    expect(find.text('استيراد من Excel / CSV'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Legacy API keeps private pack editing available', (tester) async {
    final router = await _open(tester, _Repository(includePermission: false));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('تعديل العنصر'), findsOneWidget);
    expect(find.byTooltip('حذف العنصر'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Legacy API keeps assigned packs read only', (tester) async {
    final router = await _open(
      tester,
      _Repository(includePermission: false, linked: true),
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('تعديل العنصر'), findsNothing);
    expect(find.byTooltip('حذف العنصر'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
