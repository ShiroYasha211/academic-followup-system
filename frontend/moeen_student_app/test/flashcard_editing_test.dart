import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:moeen_student_app/src/core/network/api_client.dart';
import 'package:moeen_student_app/src/core/notifications/push_notification_service.dart';
import 'package:moeen_student_app/src/core/offline/offline_cache_service.dart';
import 'package:moeen_student_app/src/core/offline/connectivity_service.dart';
import 'package:moeen_student_app/src/features/auth/data/auth_session.dart';
import 'package:moeen_student_app/src/features/auth/logic/auth_controller.dart';
import 'package:moeen_student_app/src/features/student/data/flashcard_local_store.dart';
import 'package:moeen_student_app/src/features/student/data/student_repositories.dart';
import 'package:moeen_student_app/src/features/student/logic/one_line_notification_scheduler.dart';
import 'package:moeen_student_app/src/features/student/presentation/student_content_screens.dart';
import 'package:moeen_student_app/src/features/student/presentation/widgets/student_shell.dart';

class _Auth extends AuthController {
  @override
  Future<AuthSession?> build() async => null;
}

class _Store extends FlashcardLocalStore {
  FlashcardLocalState state = const FlashcardLocalState();
  @override
  Future<FlashcardLocalState> load() async => state;
  @override
  Future<void> save(FlashcardLocalState value) async {
    state = value;
  }

  @override
  Future<void> cacheOneLineNotifications(Map<String, dynamic> data) async {}

  @override
  Future<void> cachePackReview(int id, Map<String, dynamic> data) async {}
  @override
  Future<void> cacheHome(Map<String, dynamic> data) async {}

  @override
  Future<void> cachePackDetails(int id, Map<String, dynamic> data) async {}

  @override
  Future<bool> canShowSmartReview() async => true;
}

class _Offline extends ConnectivityService {
  @override
  Future<bool> isOnline() async => false;
  @override
  Stream<bool> statusChanges() => const Stream.empty();
}

class _Online extends _Offline {
  @override
  Future<bool> isOnline() async => true;
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
  Completer<Map<String, dynamic>>? settingsGate;
  final settings = <String, dynamic>{
    'daily_card_limit': 70,
    'smart_review_frequency_minutes': 11,
  };
  List<Map<String, dynamic>> dueItems = [];
  @override
  Future<Map<String, dynamic>> flashcardSettings() async =>
      settingsGate?.future ?? {'settings': settings};
  @override
  Future<Map<String, dynamic>> updateFlashcardSettings(
    Map<String, dynamic> data,
  ) async {
    saved = data;
    settings.addAll(data);
    return {'settings': settings};
  }

  @override
  Future<Map<String, dynamic>> flashcardDailyQueue() async => {
    'queue': dueItems,
    'settings': settings,
  };
  @override
  Future<Map<String, dynamic>> flashcardOneLineNotifications({
    bool reschedule = false,
  }) async => {'items': [], 'settings': settings};

  @override
  Future<Map<String, dynamic>> flashcardReview(int id) async => {
    'items': [
      {
        'id': 9,
        'item_type': 'one_line',
        'front_content': 'A text message to study',
        'pack': {'title': 'Text pack'},
      },
      {
        'id': 10,
        'item_type': 'mcq',
        'front_content': 'The next question',
        'options': ['A', 'B'],
        'correct_option': 0,
      },
    ],
  };

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

Future<GoRouter> _open(
  WidgetTester tester,
  _Repository repository, {
  bool review = false,
  bool home = false,
  bool shellOnly = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, state) => shellOnly
            ? const StudentShell(currentIndex: 0, title: 'Home', disableDrawer: true, child: Text('Normal page'))
            : home
            ? const StudentFlashcardsScreen()
            : review
            ? const StudentFlashcardReviewScreen(packId: 1)
            : const StudentFlashcardDetailsScreen(packId: 1),
      ),
      GoRoute(
        path: StudentFlashcardsScreen.packsRoute,
        builder: (_, state) => const Scaffold(body: Text('Pack directory')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        studentContentRepositoryProvider.overrideWithValue(repository),
        flashcardLocalStoreProvider.overrideWithValue(_Store()),
        oneLineNotificationSchedulerProvider.overrideWith(
          (ref) => OneLineNotificationScheduler(
            repository,
            _Store(),
            isCurrentSession: () async => false,
          ),
        ),
        connectivityServiceProvider.overrideWithValue(
          home ? _Online() : _Offline(),
        ),
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
  final nativeCalls = <MethodCall>[];
  bool granted = false;
  setUp(() {
    nativeCalls.clear();
    granted = false;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    PushNotificationService.backgroundMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            if (call.method == 'initialize') return true;
            if (call.method == 'pendingNotificationRequests' ||
                call.method == 'getActiveNotifications')
              return [];
            if (call.method == 'getNotificationAppLaunchDetails')
              return {'notificationLaunchedApp': false};
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('moeen/review_overlay'), (
          call,
        ) async {
          nativeCalls.add(call);
          return call.method == 'status'
              ? {
                  'supported': true,
                  'permission': granted,
                  'notifications_allowed': granted,
                }
              : null;
        });
  });
  tearDown(() {
    PushNotificationService.backgroundMode = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('moeen/review_overlay'),
          null,
        );
  });
  testWidgets(
    'Shell never opens due cards automatically on entry timer or resume',
    (tester) async {
      final repository = _Repository();
      repository.dueItems = [
        {
          'item_id': 91,
          'item_type': 'mcq',
          'review_key': 'cycle:91',
          'scheduled_at': DateTime.now()
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
          'front_content': 'A due card must not interrupt navigation',
          'options': ['A', 'B'],
          'correct_option': 0,
        },
      ];
      final router = await _open(tester, repository, shellOnly: true);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudentShell)),
      );
      expect(await container.read(studentDueFlashcardCountProvider.future), 1);
      await tester.pump(const Duration(seconds: 31));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(nativeCalls.where((call) => call.method == 'beginInApp'), isEmpty);
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'Denied permissions reopen settings and update after app resume',
    (tester) async {
      final router = await _open(tester, _Repository(), home: true);
      final notifications = find.byTooltip('إعدادات الإشعارات');
      await tester.scrollUntilVisible(
        notifications,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('غير مسموح'), findsNWidgets(2));
      await tester.tap(notifications);
      await tester.pumpAndSettle();
      expect(
        nativeCalls.any((call) => call.method == 'notificationSettings'),
        isTrue,
      );
      await tester.tap(find.byTooltip('إعدادات الظهور فوق التطبيقات'));
      await tester.pumpAndSettle();
      expect(nativeCalls.any((call) => call.method == 'permission'), isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      granted = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('مسموح'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );
  testWidgets('Empty review starts the pack directory, not pack creation', (
    tester,
  ) async {
    final router = await _open(tester, _Repository(), home: true);
    await tester.tap(find.text('ابدأ المراجعة').first);
    await tester.pumpAndSettle();
    expect(find.text('Pack directory'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets(
    'Delayed settings keep server values and numbers save only on confirmation',
    (tester) async {
      final repository = _Repository();
      final router = await _open(tester, repository, home: true);
      repository.settingsGate = Completer<Map<String, dynamic>>();
      final settingsLink = find.text('اضغط لتعديل الإعدادات والتكرار اليومي');
      await tester.scrollUntilVisible(
        settingsLink,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(settingsLink);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextFormField), findsNothing);
      repository.settingsGate!.complete({'settings': repository.settings});
      repository.settingsGate = null;
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, '70');
      expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, '11');
      await tester.enterText(fields.at(0), '٧٨');
      await tester.enterText(fields.at(1), '١٣');
      await tester.pump(const Duration(seconds: 1));
      expect(repository.saved, isNull);
      await tester.ensureVisible(find.text('حفظ وإغلاق'));
      await tester.tap(find.text('حفظ وإغلاق'));
      await tester.pumpAndSettle();
      expect(repository.saved?['daily_card_limit'], 78);
      expect(repository.saved?['smart_review_frequency_minutes'], 13);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );
  testWidgets(
    'Manual review includes text messages and can advance to a question',
    (tester) async {
      final router = await _open(tester, _Repository(), review: true);
      expect(find.text('A text message to study'), findsOneWidget);
      expect(find.text('تمت القراءة · التالي'), findsOneWidget);
      expect(
        find.text('هذه الحزمة لا تحتوي على عناصر للمراجعة.'),
        findsNothing,
      );
      await tester.tap(find.text('تخطي'));
      await tester.pumpAndSettle();
      expect(find.text('The next question'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );
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

  testWidgets('Legacy API keeps private pack editing available', (
    tester,
  ) async {
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
