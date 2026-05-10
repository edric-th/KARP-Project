// Models for Mero Palo Hospital Queue Management System

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum QueueStatus { active, waiting, completed, cancelled }

enum AppointmentStatus { upcoming, completed, cancelled }

enum NotificationCategory { queue, appointment, reminder, general }

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
  final String hospital;
  final double rating;
  final int reviewCount;
  final List<String> availableSlots;
  final String bio;
  final int experience;
  final String fee;
  final bool isAvailable;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.reviewCount,
    required this.availableSlots,
    required this.bio,
    required this.experience,
    required this.fee,
    this.isAvailable = true,
  });
}

// ─── HOSPITAL MODEL ───────────────────────────────────────────────────────────

class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String distance;
  final double rating;
  final int reviewCount;
  final int currentQueue;
  final String openHours;
  final bool isOpen;
  final List<String> specialties;
  final String phone;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.currentQueue,
    required this.openHours,
    required this.isOpen,
    required this.specialties,
    required this.phone,
  });
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
}
