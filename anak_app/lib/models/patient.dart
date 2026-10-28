/// Model representing a patient assigned to a doctor.
class Patient {
  final String id;
  final String name;
  final String avatar;
  final int age;
  final String gender;
  final String? parentName;
  final String? lastVisit;
  final String status; // 'active', 'inactive', 'new'
  final Map<String, dynamic>? latestAssessment;

  Patient({
    required this.id,
    required this.name,
    this.avatar = '👶',
    this.age = 6,
    this.gender = 'Laki-laki',
    this.parentName,
    this.lastVisit,
    this.status = 'active',
    this.latestAssessment,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Anak',
      avatar: json['avatar'] as String? ?? '👶',
      age: json['age'] as int? ?? 6,
      gender: json['gender'] as String? ?? 'Laki-laki',
      parentName: json['parentName'] as String?,
      lastVisit: json['lastVisit'] as String?,
      status: json['status'] as String? ?? 'active',
      latestAssessment: json['latestAssessment'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'age': age,
      'gender': gender,
      'parentName': parentName,
      'lastVisit': lastVisit,
      'status': status,
      'latestAssessment': latestAssessment,
    };
  }
}
