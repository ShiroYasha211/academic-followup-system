import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/delegate/presentation/delegate_screens.dart';
import '../../features/delegate/presentation/widgets/delegate_shell.dart';
import '../../features/home/presentation/home_placeholder_screen.dart';
import '../../features/practical_delegate/presentation/practical_delegate_screens.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';
import '../../features/student/presentation/student_content_screens.dart';
import '../../features/student/presentation/student_ledger_screen.dart';
import '../../features/student/presentation/student_placeholder_screen.dart';
import '../../features/student/presentation/student_subscription_screen.dart';
import '../../features/student/presentation/student_support_screen.dart';

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
        path: StudentSupportScreen.route,
        builder: (context, state) => const StudentSupportScreen(),
      ),
      GoRoute(
        path: StudentSubjectsScreen.route,
        builder: (context, state) => const StudentSubjectsScreen(),
      ),
      GoRoute(
        path: '/student/subjects/:id',
        builder: (context, state) => StudentSubjectDetailsScreen(
          subjectId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          initialTabIndex: state.uri.queryParameters['tab'] == 'attendance'
              ? 5
              : 0,
        ),
      ),
      GoRoute(
        path: StudentStudyCenterScreen.route,
        builder: (context, state) => const StudentStudyCenterScreen(),
      ),
      GoRoute(
        path: '/student/study-center/:id/session',
        builder: (context, state) => StudentStudySessionScreen(
          itemId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
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
        path: StudentClinicalScreen.route,
        builder: (context, state) => const StudentClinicalScreen(),
      ),
      GoRoute(
        path: StudentClinicalLogbookScreen.route,
        builder: (context, state) => const StudentClinicalLogbookScreen(),
      ),
      GoRoute(
        path: StudentClinicalEvaluationsScreen.route,
        builder: (context, state) => const StudentClinicalEvaluationsScreen(),
      ),
      GoRoute(
        path: StudentClinicalMockExamsScreen.route,
        builder: (context, state) => const StudentClinicalMockExamsScreen(),
      ),
      GoRoute(
        path: '/student/clinical/mock-exams/:id/take',
        builder: (context, state) => StudentClinicalMockTakeScreen(
          checklistId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/student/clinical/mock-exams/results/:id',
        builder: (context, state) => StudentClinicalMockResultScreen(
          evaluationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: StudentClinicalRareCasesScreen.route,
        builder: (context, state) => const StudentClinicalRareCasesScreen(),
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
      GoRoute(
        path: PracticalDelegateHomeScreen.route,
        builder: (context, state) => const PracticalDelegateHomeScreen(),
      ),
      GoRoute(
        path: PracticalLogbookScreen.route,
        builder: (context, state) => const PracticalLogbookScreen(),
      ),
      GoRoute(
        path: PracticalCasesScreen.route,
        builder: (context, state) => const PracticalCasesScreen(),
      ),
      GoRoute(
        path: PracticalDelegationsScreen.route,
        builder: (context, state) => const PracticalDelegationsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.dashboard,
        builder: (context, state) => const DelegateDashboardScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.news,
        builder: (context, state) => const DelegateNewsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.notifications,
        builder: (context, state) => const DelegateNotificationsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.students,
        builder: (context, state) => const DelegateStudentsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.subjects,
        builder: (context, state) => const DelegateSubjectsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.schedules,
        builder: (context, state) => const DelegateSchedulesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.exams,
        builder: (context, state) => const DelegateExamSchedulesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.assignments,
        builder: (context, state) => const DelegateAssignmentsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.resources,
        builder: (context, state) => const DelegateResourcesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.libraryImport,
        builder: (context, state) => const DelegateSharedLibraryScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.reminders,
        builder: (context, state) => const DelegateRemindersScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.announcements,
        builder: (context, state) => const DelegateAnnouncementsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.attendance,
        builder: (context, state) => const DelegateAttendanceScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.qrAttendance,
        builder: (context, state) => const DelegateAttendanceScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.absenceAlerts,
        builder: (context, state) => const DelegateAbsenceAlertsScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.authorizedGrades,
        builder: (context, state) => const DelegateAuthorizedGradesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.gradeDelegations,
        builder: (context, state) => const DelegateAuthorizedGradesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.messages,
        builder: (context, state) => const DelegateMessagesScreen(),
      ),
      GoRoute(
        path: '${DelegateRoutes.messages}/:id',
        builder: (context, state) => DelegateConversationScreen(
          conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: DelegateRoutes.doctorChats,
        builder: (context, state) => const DelegateDoctorChatsScreen(),
      ),
      GoRoute(
        path: '${DelegateRoutes.doctorChats}/:id',
        builder: (context, state) => DelegateDoctorConversationScreen(
          conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: DelegateRoutes.inquiries,
        builder: (context, state) => const DelegateInquiriesScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.subscription,
        builder: (context, state) => const DelegateSubscriptionScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.ledger,
        builder: (context, state) => const DelegateLedgerScreen(),
      ),
      GoRoute(
        path: DelegateRoutes.profile,
        builder: (context, state) => const DelegateProfileScreen(),
      ),
    ],
  );
});
