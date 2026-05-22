class AcademicOption {
  const AcademicOption({required this.id, required this.name});

  final int id;
  final String name;

  factory AcademicOption.fromJson(Map<String, dynamic> json) {
    return AcademicOption(
      id: int.parse(json['id'].toString()),
      name: (json['name'] ?? '').toString(),
    );
  }
}
