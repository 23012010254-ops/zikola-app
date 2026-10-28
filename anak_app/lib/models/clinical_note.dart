/// Model representing a doctor's clinical observation / EMR note for a patient.
class ClinicalNote {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorName;
  final String category; // 'Sensori & Motorik', 'Wicara & Bahasa', 'Kognitif & Perilaku', 'Nutrisi', 'Umum'
  final String observation;
  final String recommendation;
  final DateTime createdAt;
  final bool isActionPlan; // if true, syncs as official action plan in child progress report

  ClinicalNote({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorName = 'Dokter Spesialis Anak',
    required this.category,
    required this.observation,
    required this.recommendation,
    DateTime? createdAt,
    this.isActionPlan = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ClinicalNote.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ClinicalNote(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Pasien',
      doctorName: json['doctorName'] as String? ?? 'Dokter Spesialis Anak',
      category: json['category'] as String? ?? 'Umum',
      observation: json['observation'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
      createdAt: parsedDate,
      isActionPlan: json['isActionPlan'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorName': doctorName,
      'category': category,
      'observation': observation,
      'recommendation': recommendation,
      'createdAt': createdAt.toIso8601String(),
      'isActionPlan': isActionPlan,
    };
  }
}
