/// Model representing a consultation schedule/appointment in the Doctor Portal.
class DoctorSchedule {
  final String id;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final DateTime dateTime;
  final String sessionType; // 'chat' or 'video'
  final String topic;
  String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final String? notes;

  DoctorSchedule({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatar = '👶',
    required this.dateTime,
    this.sessionType = 'video',
    required this.topic,
    this.status = 'upcoming',
    this.notes,
  });

  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';
  bool get isOngoing => status == 'ongoing';
  bool get isCancelled => status == 'cancelled';

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['dateTime'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return DoctorSchedule(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Pasien',
      patientAvatar: json['patientAvatar'] as String? ?? '👶',
      dateTime: parsedDate,
      sessionType: json['sessionType'] as String? ?? 'video',
      topic: json['topic'] as String? ?? 'Konsultasi Rutin',
      status: json['status'] as String? ?? 'upcoming',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientAvatar': patientAvatar,
      'dateTime': dateTime.toIso8601String(),
      'sessionType': sessionType,
      'topic': topic,
      'status': status,
      'notes': notes,
    };
  }

  DoctorSchedule copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientAvatar,
    DateTime? dateTime,
    String? sessionType,
    String? topic,
    String? status,
    String? notes,
  }) {
    return DoctorSchedule(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAvatar: patientAvatar ?? this.patientAvatar,
      dateTime: dateTime ?? this.dateTime,
      sessionType: sessionType ?? this.sessionType,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
