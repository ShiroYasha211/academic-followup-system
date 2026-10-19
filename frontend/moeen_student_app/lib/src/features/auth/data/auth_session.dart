enum AuthWorkspace { student, delegate }

class AuthSession {
  const AuthSession({
    required this.token,
    required this.workspace,
    required this.role,
    required this.name,
    required this.isPracticalDelegate,
    required this.hasClinical,
    this.permissions = const [],
    this.email,
    this.deviceType,
    this.isPrimaryDevice,
    this.userId,
  });

  final String token;
  final int? userId;
  final AuthWorkspace workspace;
  final String role;
  final String name;
  final String? email;
  final bool isPracticalDelegate;
  final bool hasClinical;
  final List<String> permissions;
  final String? deviceType;
  final bool? isPrimaryDevice;

  bool get isDelegate => workspace == AuthWorkspace.delegate;
  bool get isSecondaryDevice =>
      deviceType == 'secondary' || isPrimaryDevice == false;

  bool hasPermission(String resource, String action) =>
      permissions.contains('$resource.$action');

  bool hasPermissionSlug(String slug) => permissions.contains(slug);

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
    List<String>? permissions,
    String? deviceType,
    bool? isPrimaryDevice,
  }) {
    return AuthSession(
      token: token ?? this.token,
      userId: userId,
      workspace: workspace ?? this.workspace,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      isPracticalDelegate: isPracticalDelegate ?? this.isPracticalDelegate,
      hasClinical: hasClinical ?? this.hasClinical,
      permissions: permissions ?? this.permissions,
      deviceType: deviceType ?? this.deviceType,
      isPrimaryDevice: isPrimaryDevice ?? this.isPrimaryDevice,
    );
  }
}
