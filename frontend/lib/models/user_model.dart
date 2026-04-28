class UserProfile {
  final String name;
  final String token;
  final String hospital;
  final String phoneNumber;
  final String dateOfBirth;
  final int age;
  final String gender;
  final String bloodGroup;
  final String identityNumber;
  final String email;
  final bool isEmailVerified;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> medications;
  final EmergencyContact? emergencyContact;

  UserProfile({
    required this.name,
    required this.token,
    required this.hospital,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.identityNumber,
    required this.email,
    this.isEmailVerified = false,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.medications = const [],
    this.emergencyContact,
  });
}

class EmergencyContact {
  final String relation;
  final String phoneNumber;

  EmergencyContact({
    required this.relation,
    required this.phoneNumber,
  });
}

class VisitHistory {
  final String date;
  final String hospital;
  final String doctor;
  final String specialization;
  final String waitTime;
  final bool isCompleted;

  VisitHistory({
    required this.date,
    required this.hospital,
    required this.doctor,
    required this.specialization,
    required this.waitTime,
    this.isCompleted = true,
  });
}
