enum AuthWorkspace { student, delegate }

class AuthSession {
  const AuthSession({
    required this.token,
    required this.workspace,
    required this.role,
    required this.name,
    required this.isPracticalDelegate,
    this.email,
  });

  final String token;
  final AuthWorkspace workspace;
  final String role;
  final String name;
  final String? email;
  final bool isPracticalDelegate;

  bool get isDelegate =>
      workspace == AuthWorkspace.delegate || role == 'delegate';
}
