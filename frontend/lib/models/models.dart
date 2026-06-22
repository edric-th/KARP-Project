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
  // Structured availability (set in the admin panel).
  final List<String> availabilityDays; // e.g. ["Mon", "Tue", ...]
  final String availabilityStart; // "HH:mm" 24h, e.g. "10:00"
  final String availabilityEnd; // "HH:mm" 24h, e.g. "14:00"

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
    this.availabilityDays = const [],
    this.availabilityStart = '',
    this.availabilityEnd = '',
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
      availabilityDays: asStringList(json['availabilityDays']),
      availabilityStart: asString(json['availabilityStart']),
      availabilityEnd: asString(json['availabilityEnd']),
    );
  }

  // ─── AVAILABILITY HELPERS ─────────────────────────────────────────────────
  static const Map<int, String> _dayAbbr = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  /// True only when days + a time range have been configured in the admin panel.
  bool get hasAvailability =>
      availabilityDays.isNotEmpty &&
      availabilityStart.isNotEmpty &&
      availabilityEnd.isNotEmpty;

  bool isAvailableDay(DateTime d) {
    if (availabilityDays.isEmpty) return true;
    final abbr = _dayAbbr[d.weekday]!.toLowerCase();
    return availabilityDays
        .any((x) => x.trim().toLowerCase().startsWith(abbr));
  }

  DateTime? _timeOn(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  DateTime? startOn(DateTime day) =>
      availabilityStart.isEmpty ? null : _timeOn(day, availabilityStart);
  DateTime? endOn(DateTime day) =>
      availabilityEnd.isEmpty ? null : _timeOn(day, availabilityEnd);

  /// Whether the doctor is consultable at [now] (right day + within hours).
  /// Falls back to the simple [isAvailable] flag when no schedule is set.
  bool availableNow(DateTime now) {
    if (!isAvailable) return false;
    if (!hasAvailability) return isAvailable;
    if (!isAvailableDay(now)) return false;
    final s = startOn(now);
    final e = endOn(now);
    if (s == null || e == null) return true;
    return !now.isBefore(s) && now.isBefore(e);
  }

  /// The moment the doctor's queue effectively begins serving, relative to
  /// [from]. Used to compute a realistic turn time:
  ///  • no schedule set → [from] (serve immediately);
  ///  • before today's opening → today's opening time;
  ///  • within hours today → [from] (now);
  ///  • after close / off-day → the next available day's opening time.
  /// Returns [from] if no opening can be resolved within a week.
  DateTime effectiveStartFrom(DateTime from) {
    if (!hasAvailability) return from;
    final startOfFrom = DateTime(from.year, from.month, from.day);
    for (var i = 0; i < 8; i++) {
      final day = startOfFrom.add(Duration(days: i));
      if (!isAvailableDay(day)) continue;
      final open = startOn(day);
      if (open == null) return from;
      if (i == 0) {
        final close = endOn(day);
        if (close != null && !from.isBefore(close)) continue; // past close → next day
        return from.isBefore(open) ? open : from;
      }
      return open; // a future available day → its opening
    }
    return from;
  }

  /// e.g. "Mon–Fri" / "Mon, Wed, Fri" — empty when no days configured.
  String get availabilityDaysLabel {
    if (availabilityDays.isEmpty) return '';
    final ints = <int>{};
    for (final d in availabilityDays) {
      final t = d.trim().toLowerCase();
      _dayAbbr.forEach((k, v) {
        if (t.startsWith(v.toLowerCase())) ints.add(k);
      });
    }
    final sorted = ints.toList()..sort();
    if (sorted.isEmpty) return availabilityDays.join(', ');
    // Group consecutive weekdays into ranges (Mon–Fri).
    final parts = <String>[];
    var runStart = sorted.first;
    var prev = sorted.first;
    for (var i = 1; i <= sorted.length; i++) {
      final cur = i < sorted.length ? sorted[i] : -99;
      if (cur == prev + 1) {
        prev = cur;
        continue;
      }
      parts.add(runStart == prev
          ? _dayAbbr[runStart]!
          : '${_dayAbbr[runStart]}–${_dayAbbr[prev]}');
      runStart = cur;
      prev = cur;
    }
    return parts.join(', ');
  }

  /// e.g. "10:00 AM – 2:00 PM" — empty when no time range configured.
  String get availabilityTimeLabel {
    if (availabilityStart.isEmpty || availabilityEnd.isEmpty) return '';
    final today = DateTime.now();
    final s = _timeOn(today, availabilityStart);
    final e = _timeOn(today, availabilityEnd);
    if (s == null || e == null) return '';
    final f = DateFormat('h:mm a');
    return '${f.format(s)} – ${f.format(e)}';
  }

  /// Full one-line label, e.g. "Mon–Fri · 10:00 AM – 2:00 PM".
  String get availabilityLabel {
    final d = availabilityDaysLabel;
    final t = availabilityTimeLabel;
    if (d.isEmpty && t.isEmpty) return '';
    if (d.isEmpty) return t;
    if (t.isEmpty) return d;
    return '$d · $t';
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

  /// False when the doctor is currently closed (outside availability hours/days).
  /// Defaults to true; reception/online-token queues are always "open".
  final bool doctorAvailableNow;

  /// e.g. "Mon–Fri" — the doctor's working days, shown when they're closed.
  final String availabilityDaysLabel;

  /// Availability-anchored expected turn time, used to show a real day + clock
  /// when the doctor is closed instead of a huge minute count.
  final DateTime? expectedCallTime;

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
    this.doctorAvailableNow = true,
    this.availabilityDaysLabel = '',
    this.expectedCallTime,
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
