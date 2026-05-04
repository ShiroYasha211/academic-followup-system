enum AuthWorkspace { student, delegate }

class AuthSession {
  const AuthSession({
    required this.token,
    required this.workspace,
    required this.role,
    required this.name,
    required this.isPracticalDelegate,
    required this.hasClinical,
    this.email,
  });

  final String token;
  final AuthWorkspace workspace;
  final String role;
  final String name;
  final String? email;
  final bool isPracticalDelegate;
  final bool hasClinical;

  bool get isDelegate => workspace == AuthWorkspace.delegate;

  bool get canAccessDelegateWorkspace =>
      role == 'delegate' || role == 'practical_delegate' || isPracticalDelegate;

  bool get canAccessStudentWorkspace =>
      role == 'student' ||
      role == 'delegate' ||
      role == 'practical_delegate' ||
      isPracticalDelegate;

  AuthSession copyWith({
    String? token,
    AuthWorkspace? workspace,
    String? role,
    String? name,
    String? email,
    bool? isPracticalDelegate,
    bool? hasClinical,
  }) {
    return AuthSession(
      token: token ?? this.token,
      workspace: workspace ?? this.workspace,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      isPracticalDelegate: isPracticalDelegate ?? this.isPracticalDelegate,
      hasClinical: hasClinical ?? this.hasClinical,
    );
  }
}
