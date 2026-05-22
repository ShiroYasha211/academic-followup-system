enum StaffWorkspace { doctor, administrative }

class StaffAuthSession {
  const StaffAuthSession({
    required this.token,
    required this.workspace,
    required this.availableWorkspaces,
    required this.name,
    required this.email,
    required this.role,
    this.university,
    this.college,
    this.major,
  });

  final String token;
  final StaffWorkspace workspace;
  final List<StaffWorkspace> availableWorkspaces;
  final String name;
  final String email;
  final String role;
  final String? university;
  final String? college;
  final String? major;

  bool get canUseAdministrative =>
      availableWorkspaces.contains(StaffWorkspace.administrative);

  StaffAuthSession copyWith({
    StaffWorkspace? workspace,
    List<StaffWorkspace>? availableWorkspaces,
    String? name,
    String? email,
    String? role,
    String? university,
    String? college,
    String? major,
  }) {
    return StaffAuthSession(
      token: token,
      workspace: workspace ?? this.workspace,
      availableWorkspaces: availableWorkspaces ?? this.availableWorkspaces,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      university: university ?? this.university,
      college: college ?? this.college,
      major: major ?? this.major,
    );
  }
}
