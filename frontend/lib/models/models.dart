// Models for Mero Palo Hospital Queue Management System

import 'package:intl/intl.dart';
import 'package:frontend/models/json_utils.dart';

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum QueueStatus { active, waiting, completed, cancelled }

enum AppointmentStatus { upcoming, completed, cancelled }

enum NotificationCategory { queue, appointment, reminder, general }

enum AppointmentType { newPatient, reportShowing, followUp }

extension AppointmentTypeX on AppointmentType {
  String get label {
    switch (this) {
      case AppointmentType.newPatient:
        return 'New Patient';
      case AppointmentType.reportShowing:
        return 'Report Showing';
      case AppointmentType.followUp:
        return 'Follow Up';
    }
  }

  String get description {
    switch (this) {
      case AppointmentType.newPatient:
        return 'Is this your first time visiting this hospital? Select here.';
      case AppointmentType.reportShowing:
        return 'Are you visiting to show lab results, X-rays, or other test reports?';
      case AppointmentType.followUp:
        return 'Are you coming back for a follow-up check after a previous visit?';
    }
  }

  String get duration {
    switch (this) {
      case AppointmentType.newPatient:
        return '~20 MIN';
      case AppointmentType.reportShowing:
        return '~10 MIN';
      case AppointmentType.followUp:
        return '~5 MIN';
    }
  }
}

// ─── BACKEND ENUM MAPPINGS ──────────────────────────────────────────────────
// The backend/Firestore uses: bookingType (first_visit|follow_up|report) and
// status (pending|active|served|no_show|cancelled).

extension AppointmentTypeApi on AppointmentType {
  String get apiValue {
    switch (this) {
      case AppointmentType.newPatient:
        return 'first_visit';
      case AppointmentType.reportShowing:
        return 'report';
      case AppointmentType.followUp:
        return 'follow_up';
    }
  }
}

AppointmentType appointmentTypeFromApi(String? v) {
  switch (v) {
    case 'report':
      return AppointmentType.reportShowing;
    case 'follow_up':
      return AppointmentType.followUp;
    case 'first_visit':
    default:
      return AppointmentType.newPatient;
  }
}

QueueStatus queueStatusFromBooking(String? s) {
  switch (s) {
    case 'active':
      return QueueStatus.active;
    case 'served':
      return QueueStatus.completed;
    case 'cancelled':
    case 'no_show':
      return QueueStatus.cancelled;
    case 'pending':
    default:
      return QueueStatus.waiting;
  }
}

AppointmentStatus appointmentStatusFromBooking(String? s) {
  switch (s) {
    case 'served':
      return AppointmentStatus.completed;
    case 'cancelled':
    case 'no_show':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.upcoming;
  }
}

NotificationCategory notificationCategoryFromApi(String c) {
  switch (c) {
    case 'queue':
      return NotificationCategory.queue;
    case 'booking':
    case 'appointment':
      return NotificationCategory.appointment;
    case 'reminder':
      return NotificationCategory.reminder;
    default:
      return NotificationCategory.general;
  }
}

// ─── USER MODEL ───────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bloodGroup;
  final int age;
  final String gender;
  final String address;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.age,
    required this.gender,
    required this.address,
  });
}

// ─── DOCTOR MODEL ─────────────────────────────────────────────────────────────

class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String hospital; // display name (denormalized from the backend)
  final String hospitalId;
  final double rating;
  final int reviewCount;
  final List<String> availableSlots;
  final String bio;
  final int experience;
  final String fee; // formatted for display, e.g. "NPR 1,500"
  final num? feeAmount; // raw numeric fee from Firestore
  final String photoUrl;
  final bool isAvailable;

  const DoctorModel({
    required this.id,
    required this.name,
    this.specialty = '',
    this.hospital = '',
    this.hospitalId = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.availableSlots = const [],
    this.bio = '',
    this.experience = 0,
    this.fee = '',
    this.feeAmount,
    this.photoUrl = '',
    this.isAvailable = true,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final feeNum = json['fee'] is num ? json['fee'] as num : null;
    return DoctorModel(
      id: asString(json['id']),
      name: asString(json['name']),
      specialty: asString(json['specialty']),
      hospital: asString(json['hospitalName']),
      hospitalId: asString(json['hospitalId']),
      rating: asDouble(json['rating']),
      reviewCount: asInt(json['reviewCount']),
      availableSlots: asStringList(json['availableSlots']),
      bio: asString(json['bio']),
      experience: asInt(json['experience']),
      fee: feeNum != null
          ? 'NPR ${NumberFormat.decimalPattern('en_US').format(feeNum)}'
          : '',
      feeAmount: feeNum,
      photoUrl: asString(json['photoUrl']),
      isAvailable: asBool(json['isAvailable'], true),
    );
  }
}

// ─── HOSPITAL MODEL ───────────────────────────────────────────────────────────

class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String distance; // computed client-side from geo (optional)
  final double rating;
  final int reviewCount;
  final int currentQueue; // enriched live from the queue, not stored
  final String openHours;
  final bool isOpen;
  final List<String> specialties;
  final String phone;
  final String city;
  final String photoUrl;
  final double? latitude;
  final double? longitude;

  const HospitalModel({
    required this.id,
    required this.name,
    this.address = '',
    this.distance = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.currentQueue = 0,
    this.openHours = '',
    this.isOpen = true,
    this.specialties = const [],
    this.phone = '',
    this.city = '',
    this.photoUrl = '',
    this.latitude,
    this.longitude,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: asString(json['id']),
      name: asString(json['name']),
      address: asString(json['address']),
      distance: asString(json['distance']),
      rating: asDouble(json['rating']),
      reviewCount: asInt(json['reviewCount']),
      currentQueue: asInt(json['currentQueue']),
      openHours: asString(json['openHours']),
      isOpen: asBool(json['isOpen'], true),
      specialties: asStringList(json['specialties']),
      phone: asString(json['phone']),
      city: asString(json['city']),
      photoUrl: asString(json['photoUrl']),
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude:
          json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
    );
  }

  HospitalModel copyWith({int? currentQueue, String? distance}) => HospitalModel(
        id: id,
        name: name,
        address: address,
        distance: distance ?? this.distance,
        rating: rating,
        reviewCount: reviewCount,
        currentQueue: currentQueue ?? this.currentQueue,
        openHours: openHours,
        isOpen: isOpen,
        specialties: specialties,
        phone: phone,
        city: city,
        photoUrl: photoUrl,
        latitude: latitude,
        longitude: longitude,
      );
}

// ─── QUEUE MODEL ──────────────────────────────────────────────────────────────

class QueueModel {
  final String id;
  final String hospitalName;
  final String doctorName;
  final String specialty;
  final int queueNumber;
  final int currentNumber;
  final int totalAhead;
  final int estimatedMinutes;
  final QueueStatus status;
  final String department;

  const QueueModel({
    required this.id,
    required this.hospitalName,
    required this.doctorName,
    required this.specialty,
    required this.queueNumber,
    required this.currentNumber,
    required this.totalAhead,
    required this.estimatedMinutes,
    required this.status,
    required this.department,
  });
}

// ─── QUEUE SUMMARY (booking doctor-picker) ──────────────────────────────────
// Lightweight per-doctor live snapshot from GET /api/queue/summary, used to
// show a real waiting count + ETA on each doctor card instead of fake numbers.

class QueueSummaryModel {
  final String doctorId;
  final int waitingCount;
  final double avgServiceMinutes;
  final int estimatedWaitMinutes;

  const QueueSummaryModel({
    required this.doctorId,
    this.waitingCount = 0,
    this.avgServiceMinutes = 0,
    this.estimatedWaitMinutes = 0,
  });

  factory QueueSummaryModel.fromJson(Map<String, dynamic> json) =>
      QueueSummaryModel(
        doctorId: asString(json['doctorId']),
        waitingCount: asInt(json['waitingCount']),
        avgServiceMinutes: asDouble(json['avgServiceMinutes']),
        estimatedWaitMinutes: asInt(json['estimatedWaitMinutes']),
      );
}

// ─── APPOINTMENT MODEL ────────────────────────────────────────────────────────

class AppointmentModel {
  final String id;
  final DoctorModel doctor;
  final DateTime date;
  final String time;
  final AppointmentStatus status;
  final String reason;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.doctor,
    required this.date,
    required this.time,
    required this.status,
    required this.reason,
    this.notes,
  });
}

// ─── NOTIFICATION MODEL ───────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotificationCategory category;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: asString(json['id']),
        title: asString(json['title']),
        body: asString(json['body']),
        time: asDate(json['createdAt']) ?? DateTime.now(),
        category: notificationCategoryFromApi(asString(json['category'])),
        isRead: asBool(json['isRead']),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        time: time,
        category: category,
        isRead: isRead ?? this.isRead,
      );
}
