import 'models.dart';

class DummyData {
  DummyData._();

  static const UserModel currentUser = UserModel(
    id: 'u001',
    name: 'Aarav Sharma',
    email: 'aarav.sharma@email.com',
    phone: '+977 9812345678',
    bloodGroup: 'B+',
    age: 28,
  );

  static final List<DoctorModel> doctors = [
    const DoctorModel(
      id: 'd001', name: 'Dr. Priya Shrestha', specialty: 'Cardiologist',
      hospital: 'Patan Hospital', rating: 4.9, reviewCount: 312, experience: 12,
      imageUrl: '', isAvailable: true, consultFee: 'Rs. 800',
      availableSlots: ['09:00 AM', '10:30 AM', '02:00 PM', '04:00 PM'],
    ),
    const DoctorModel(
      id: 'd002', name: 'Dr. Bikash Thapa', specialty: 'General Physician',
      hospital: 'TUTH', rating: 4.7, reviewCount: 218, experience: 8,
      imageUrl: '', isAvailable: true, consultFee: 'Rs. 500',
      availableSlots: ['08:30 AM', '11:00 AM', '03:30 PM'],
    ),
    const DoctorModel(
      id: 'd003', name: 'Dr. Sunita Rana', specialty: 'Dermatologist',
      hospital: 'Bir Hospital', rating: 4.8, reviewCount: 187, experience: 10,
      imageUrl: '', isAvailable: false, consultFee: 'Rs. 700',
      availableSlots: ['10:00 AM', '01:00 PM'],
    ),
    const DoctorModel(
      id: 'd004', name: 'Dr. Roshan Khadka', specialty: 'Orthopedics',
      hospital: 'Grande Hospital', rating: 4.6, reviewCount: 143, experience: 15,
      imageUrl: '', isAvailable: true, consultFee: 'Rs. 1200',
      availableSlots: ['09:30 AM', '02:30 PM', '05:00 PM'],
    ),
    const DoctorModel(
      id: 'd005', name: 'Dr. Anita Gurung', specialty: 'Pediatrician',
      hospital: 'Kanti Children Hospital', rating: 4.9, reviewCount: 401, experience: 9,
      imageUrl: '', isAvailable: true, consultFee: 'Rs. 600',
      availableSlots: ['08:00 AM', '10:00 AM', '12:00 PM', '03:00 PM'],
    ),
    const DoctorModel(
      id: 'd006', name: 'Dr. Manish Joshi', specialty: 'Neurologist',
      hospital: 'Mediciti Hospital', rating: 4.7, reviewCount: 265, experience: 14,
      imageUrl: '', isAvailable: true, consultFee: 'Rs. 1000',
      availableSlots: ['11:00 AM', '03:00 PM'],
    ),
  ];

  static final List<HospitalModel> hospitals = [
    const HospitalModel(
      id: 'h001', name: 'Patan Hospital', address: 'Lagankhel, Lalitpur',
      distance: '1.2 km', rating: 4.8, reviewCount: 1240, imageUrl: '',
      isOpen: true, openHours: '24 Hours',
      specialties: ['Cardiology', 'Orthopedics', 'General', 'Emergency'],
      currentQueue: 24,
    ),
    const HospitalModel(
      id: 'h002', name: 'Teaching Hospital (TUTH)', address: 'Maharajgunj, Kathmandu',
      distance: '3.5 km', rating: 4.6, reviewCount: 980, imageUrl: '',
      isOpen: true, openHours: '24 Hours',
      specialties: ['General', 'Neurology', 'Pediatrics', 'Surgery'],
      currentQueue: 42,
    ),
    const HospitalModel(
      id: 'h003', name: 'Grande International Hospital', address: 'Tokha Road, Kathmandu',
      distance: '5.1 km', rating: 4.9, reviewCount: 756, imageUrl: '',
      isOpen: true, openHours: '8 AM - 8 PM',
      specialties: ['Orthopedics', 'Cardiac', 'Cancer', 'Transplant'],
      currentQueue: 11,
    ),
    const HospitalModel(
      id: 'h004', name: 'Bir Hospital', address: 'Mahabauddha, Kathmandu',
      distance: '4.2 km', rating: 4.4, reviewCount: 1560, imageUrl: '',
      isOpen: true, openHours: '24 Hours',
      specialties: ['Emergency', 'General', 'Dermatology', 'ENT'],
      currentQueue: 67,
    ),
  ];

  static final List<AppointmentModel> appointments = [
    AppointmentModel(
      id: 'a001', doctor: doctors[0],
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 9, minutes: 30)),
      reason: 'Chest pain follow-up', status: AppointmentStatus.upcoming, tokenNumber: 'A-014',
    ),
    AppointmentModel(
      id: 'a002', doctor: doctors[4],
      dateTime: DateTime.now().add(const Duration(days: 5, hours: 10)),
      reason: 'Child vaccination', status: AppointmentStatus.upcoming, tokenNumber: 'B-007',
    ),
    AppointmentModel(
      id: 'a003', doctor: doctors[1],
      dateTime: DateTime.now().subtract(const Duration(days: 3, hours: 11)),
      reason: 'Regular check-up', status: AppointmentStatus.completed, tokenNumber: 'C-023',
    ),
    AppointmentModel(
      id: 'a004', doctor: doctors[2],
      dateTime: DateTime.now().subtract(const Duration(days: 8)),
      reason: 'Skin allergy', status: AppointmentStatus.cancelled, tokenNumber: 'D-009',
    ),
  ];

  static final List<QueueModel> queues = [
    const QueueModel(
      id: 'q001', hospitalName: 'Patan Hospital', doctorName: 'Dr. Priya Shrestha',
      specialty: 'Cardiologist', queueNumber: 14, currentNumber: 10, totalAhead: 4,
      estimatedMinutes: 20, status: QueueStatus.active, department: 'Cardiology, OPD Block A',
    ),
    const QueueModel(
      id: 'q002', hospitalName: 'TUTH', doctorName: 'Dr. Bikash Thapa',
      specialty: 'General Physician', queueNumber: 7, currentNumber: 5, totalAhead: 2,
      estimatedMinutes: 10, status: QueueStatus.waiting, department: 'General OPD, Block B',
    ),
    const QueueModel(
      id: 'q003', hospitalName: 'Grande Hospital', doctorName: 'Dr. Roshan Khadka',
      specialty: 'Orthopedics', queueNumber: 32, currentNumber: 28, totalAhead: 4,
      estimatedMinutes: 25, status: QueueStatus.completed, department: 'Orthopedics Wing',
    ),
  ];

  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n001', title: "It's almost your turn!",
      body: 'Only 2 people ahead at Patan Hospital. Head to OPD Block A now.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      category: NotificationCategory.queue, isRead: false,
    ),
    NotificationModel(
      id: 'n002', title: 'Appointment Confirmed',
      body: 'Your appointment with Dr. Priya Shrestha on Apr 30 at 9:30 AM is confirmed.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      category: NotificationCategory.appointment, isRead: false,
    ),
    NotificationModel(
      id: 'n003', title: 'Appointment Reminder',
      body: 'You have an appointment with Dr. Anita Gurung tomorrow at 10:00 AM.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      category: NotificationCategory.reminder, isRead: true,
    ),
    NotificationModel(
      id: 'n004', title: 'Queue Update',
      body: 'Your queue at TUTH is now #7. You have just joined the live queue.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.queue, isRead: true,
    ),
    NotificationModel(
      id: 'n005', title: 'New Doctors Available',
      body: 'Dr. Manish Joshi (Neurologist) is now accepting appointments at Mediciti.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      category: NotificationCategory.general, isRead: true,
    ),
  ];

  static const List<String> specialties = [
    'All', 'Cardiology', 'General', 'Pediatrics', 'Orthopedics',
    'Dermatology', 'Neurology', 'Gynecology', 'ENT', 'Oncology',
  ];
}