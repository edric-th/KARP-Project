import 'package:frontend/models/json_utils.dart';

/// Computed visit stats returned alongside the profile.
class ProfileStats {
  final int totalVisits;
  final int completed;
  final int avgWaitMinutes;

  const ProfileStats({
    this.totalVisits = 0,
    this.completed = 0,
    this.avgWaitMinutes = 0,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> j) => ProfileStats(
        totalVisits: asInt(j['totalVisits']),
        completed: asInt(j['completed']),
        avgWaitMinutes: asInt(j['avgWaitMinutes']),
      );
}

/// The full patient profile (GET /api/profile). Top-level name/phone/email live
/// on the users doc; the rest is nested under `profile`.
class ProfileModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;
  final bool emailVerified;
  // personal
  final String dateOfBirth;
  final int? age;
  final String gender;
  final String nationality;
  final String nationalId;
  final String alternatePhone;
  final String address;
  final String maritalStatus;
  // medical
  final String bloodGroup;
  final double? height;
  final double? weight;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String pastSurgeries;
  final List<Map<String, dynamic>> currentMedications;
  final List<String> vaccinations;
  final String smokingStatus;
  final String alcoholConsumption;
  // emergency
  final Map<String, dynamic> primaryContact;
  final Map<String, dynamic> secondaryContact;
  final Map<String, dynamic> familyDoctor;
  final ProfileStats stats;

  const ProfileModel({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.role = 'patient',
    this.photoUrl = '',
    this.emailVerified = false,
    this.dateOfBirth = '',
    this.age,
    this.gender = '',
    this.nationality = '',
    this.nationalId = '',
    this.alternatePhone = '',
    this.address = '',
    this.maritalStatus = '',
    this.bloodGroup = '',
    this.height,
    this.weight,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.pastSurgeries = '',
    this.currentMedications = const [],
    this.vaccinations = const [],
    this.smokingStatus = '',
    this.alcoholConsumption = '',
    this.primaryContact = const {},
    this.secondaryContact = const {},
    this.familyDoctor = const {},
    this.stats = const ProfileStats(),
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final p = asMap(json['profile']);
    num? numOrNull(dynamic v) => v is num ? v : null;
    return ProfileModel(
      uid: asString(json['uid']),
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asString(json['phone']),
      role: asString(json['role'], 'patient'),
      emailVerified: asBool(json['emailVerified']),
      photoUrl: asString(p['photoUrl']),
      dateOfBirth: asString(p['dateOfBirth']),
      age: numOrNull(p['age'])?.toInt(),
      gender: asString(p['gender']),
      nationality: asString(p['nationality']),
      nationalId: asString(p['nationalId']),
      alternatePhone: asString(p['alternatePhone']),
      address: asString(p['address']),
      maritalStatus: asString(p['maritalStatus']),
      bloodGroup: asString(p['bloodGroup']),
      height: numOrNull(p['height'])?.toDouble(),
      weight: numOrNull(p['weight'])?.toDouble(),
      allergies: asStringList(p['allergies']),
      chronicConditions: asStringList(p['chronicConditions']),
      pastSurgeries: asString(p['pastSurgeries']),
      currentMedications: p['currentMedications'] is List
          ? (p['currentMedications'] as List).map((e) => asMap(e)).toList()
          : const [],
      vaccinations: asStringList(p['vaccinations']),
      smokingStatus: asString(p['smokingStatus']),
      alcoholConsumption: asString(p['alcoholConsumption']),
      primaryContact: asMap(p['primaryContact']),
      secondaryContact: asMap(p['secondaryContact']),
      familyDoctor: asMap(p['familyDoctor']),
      stats: ProfileStats.fromJson(asMap(json['stats'])),
    );
  }

  /// The essentials a doctor needs before an appointment can be booked. Online
  /// (reception) tokens intentionally do not require this.
  bool get isComplete =>
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      dateOfBirth.trim().isNotEmpty &&
      gender.trim().isNotEmpty;

  String get displayName => name.isNotEmpty
      ? name
      : (email.isNotEmpty ? email.split('@').first : 'Patient');

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
