class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final int reviewCount;
  final int experience;
  final String imageUrl;
  final bool isAvailable;
  final String consultFee;
  final List<String> availableSlots;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.imageUrl,
    required this.isAvailable,
    required this.consultFee,
    required this.availableSlots,
  });
}

class HospitalModel {
  final String id;
  final String name;
  final String address;
  final String distance;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool isOpen;
  final String openHours;
  final List<String> specialties;
  final int currentQueue;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.isOpen,
    required this.openHours,
    required this.specialties,
    required this.currentQueue,
  });
}

class AppointmentModel {
  final String id;
  final DoctorModel doctor;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;
  final String tokenNumber;

  const AppointmentModel({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.reason,
    required this.status,
    required this.tokenNumber,
  });
}

enum AppointmentStatus { upcoming, completed, cancelled }

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

enum QueueStatus { active, waiting, completed, cancelled }

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

enum NotificationCategory { queue, appointment, general, reminder }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String bloodGroup;
  final int age;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.bloodGroup,
    required this.age,
  });
}