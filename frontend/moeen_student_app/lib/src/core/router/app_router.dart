import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_placeholder_screen.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/student/presentation/student_content_screens.dart';
import '../../features/student/presentation/student_ledger_screen.dart';
import '../../features/student/presentation/student_placeholder_screen.dart';
import '../../features/student/presentation/student_subscription_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.route,
    routes: [
      GoRoute(
        path: SplashScreen.route,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.route,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.route,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: HomePlaceholderScreen.route,
        builder: (context, state) {
          final session = ref.watch(authControllerProvider).valueOrNull;
          return HomePlaceholderScreen(session: session);
        },
      ),
      GoRoute(
        path: StudentDashboardScreen.route,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: StudentSubscriptionScreen.route,
        builder: (context, state) => const StudentSubscriptionScreen(),
      ),
      GoRoute(
        path: StudentLedgerScreen.route,
        builder: (context, state) => const StudentLedgerScreen(),
      ),
      GoRoute(
        path: StudentSubjectsScreen.route,
        builder: (context, state) => const StudentSubjectsScreen(),
      ),
      GoRoute(
        path: '/student/subjects/:id',
        builder: (context, state) => StudentSubjectDetailsScreen(
          subjectId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentStudyCenterScreen.route,
        builder: (context, state) => const StudentStudyCenterScreen(),
      ),
      GoRoute(
        path: StudentScheduleScreen.route,
        builder: (context, state) => const StudentScheduleScreen(),
      ),
      GoRoute(
        path: StudentNewsScreen.route,
        builder: (context, state) => const StudentNewsScreen(),
      ),
      GoRoute(
        path: StudentQuizzesScreen.route,
        builder: (context, state) => const StudentQuizzesScreen(),
      ),
      GoRoute(
        path: '/student/quizzes/:id/take',
        builder: (context, state) => StudentQuizTakeScreen(
          quizId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          accessCode: state.uri.queryParameters['access_code'],
        ),
      ),
      GoRoute(
        path: '/student/quizzes/results/:attemptId',
        builder: (context, state) => StudentQuizResultScreen(
          attemptId: int.tryParse(state.pathParameters['attemptId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentStarsScreen.route,
        builder: (context, state) => const StudentStarsScreen(),
      ),
      GoRoute(
        path: StudentNotificationsScreen.route,
        builder: (context, state) => const StudentNotificationsScreen(),
      ),
      GoRoute(
        path: StudentQrScanScreen.route,
        builder: (context, state) => const StudentQrScanScreen(),
      ),
      GoRoute(
        path: StudentRemindersScreen.route,
        builder: (context, state) => const StudentRemindersScreen(),
      ),
      GoRoute(
        path: StudentMessagesScreen.route,
        builder: (context, state) => const StudentMessagesScreen(),
      ),
      GoRoute(
        path: '/student/messages/:id',
        builder: (context, state) => StudentConversationScreen(
          conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentInquiriesScreen.route,
        builder: (context, state) => const StudentInquiriesScreen(),
      ),
      GoRoute(
        path: '/student/inquiries/:id',
        builder: (context, state) => StudentInquiryDetailsScreen(
          inquiryId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentProfileScreen.route,
        builder: (context, state) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: StudentAssignmentsScreen.route,
        builder: (context, state) => const StudentAssignmentsScreen(),
      ),
      GoRoute(
        path: '/student/assignments/:id',
        builder: (context, state) => StudentAssignmentDetailsScreen(
          assignmentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentFlashcardsScreen.route,
        builder: (context, state) => const StudentFlashcardsScreen(),
      ),
      GoRoute(
        path: StudentFlashcardStoreScreen.route,
        builder: (context, state) => const StudentFlashcardStoreScreen(),
      ),
      GoRoute(
        path: '/student/flashcards/:id/review',
        builder: (context, state) => StudentFlashcardReviewScreen(
          packId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/student/flashcards/:id',
        builder: (context, state) => StudentFlashcardDetailsScreen(
          packId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentExamsScreen.route,
        builder: (context, state) => const StudentExamsScreen(),
      ),
      GoRoute(
        path: StudentResourcesScreen.route,
        builder: (context, state) => const StudentResourcesScreen(),
      ),
      GoRoute(
        path: StudentLibraryScreen.route,
        builder: (context, state) => const StudentLibraryScreen(),
      ),
      GoRoute(
        path: StudentPlaceholderScreen.route,
        builder: (context, state) => StudentPlaceholderScreen(
          feature: state.pathParameters['feature'] ?? 'more',
        ),
      ),
    ],
  );
});
