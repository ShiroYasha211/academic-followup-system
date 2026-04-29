import '../../features/auth/data/auth_session.dart';
import '../../features/home/presentation/home_placeholder_screen.dart';
import '../../features/student/presentation/student_dashboard_screen.dart';

String landingRouteFor(AuthSession session) {
  if (session.isDelegate && !session.isPracticalDelegate) {
    return HomePlaceholderScreen.route;
  }

  return StudentDashboardScreen.route;
}
