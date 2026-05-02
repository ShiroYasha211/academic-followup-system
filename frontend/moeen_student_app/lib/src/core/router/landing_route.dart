import '../../features/auth/data/auth_session.dart';
import '../../features/delegate/presentation/widgets/delegate_shell.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';

String landingRouteFor(AuthSession session) {
  if (session.isDelegate && !session.isPracticalDelegate) {
    return DelegateRoutes.dashboard;
  }

  return StudentDashboardScreen.route;
}
