import 'package:frontend/models/models.dart';

class DummyData {
  DummyData._();

  // ─── CURRENT USER ─────────────────────────────────────────────────────────

  static const UserModel currentUser = UserModel(
    id: 'u001',
    name: 'Rohan Basnet',
    email: 'rohan.basnet@email.com',
    phone: '+977-9841234567',
    bloodGroup: 'B+',
    age: 24,
    gender: 'Male',
    address: 'Kathmandu, Bagmati Province',
  );

  // ─── DOCTORS ──────────────────────────────────────────────────────────────

  static const List<DoctorModel> doctors = [
    DoctorModel(
      id: 'd001',
      name: 'Dr. Priya Shrestha',
      specialty: 'Cardiology',
      hospital: 'Patan Hospital',
      rating: 4.9,
      reviewCount: 312,
      experience: 14,
      fee: 'NPR 1,500',
      bio:
          'Dr. Priya Shrestha is a leading cardiologist with over 14 years of experience in interventional cardiology and heart disease management. She completed her MD from BPKIHS and fellowship from AIIMS New Delhi.',
      availableSlots: [
        '9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM',
        '11:00 AM', '2:00 PM', '2:30 PM', '3:00 PM',
      ],
    ),
    DoctorModel(
      id: 'd002',
      name: 'Dr. Bikash Thapa',
      specialty: 'General Physician',
      hospital: 'TUTH',
      rating: 4.7,
      reviewCount: 198,
      experience: 9,
      fee: 'NPR 800',
      bio:
          'Dr. Bikash Thapa specializes in general medicine and preventive care. He has a strong background in diagnosing complex conditions and managing chronic diseases.',
      availableSlots: [
        '8:00 AM', '8:30 AM', '9:00 AM', '11:00 AM',
        '11:30 AM', '1:00 PM', '4:00 PM', '4:30 PM',
      ],
    ),
    DoctorModel(
      id: 'd003',
      name: 'Dr. Anita Gurung',
      specialty: 'Pediatrics',
      hospital: 'Kanti Children Hospital',
      rating: 4.8,
      reviewCount: 445,
      experience: 11,
      fee: 'NPR 1,200',
      bio:
          'Dr. Anita Gurung is a renowned pediatrician who has dedicated her career to children\'s health. She specializes in neonatal care and childhood development.',
      availableSlots: [
        '9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM',
        '3:00 PM', '3:30 PM', '4:00 PM',
      ],
    ),
    DoctorModel(
      id: 'd004',
      name: 'Dr. Roshan Khadka',
      specialty: 'Orthopedics',
      hospital: 'Grande Hospital',
      rating: 4.6,
      reviewCount: 267,
      experience: 16,
      fee: 'NPR 2,000',
      bio:
          'Dr. Roshan Khadka is a senior orthopedic surgeon specializing in joint replacement, sports injuries, and spine surgery. He has performed over 2,000 successful surgeries.',
      availableSlots: [
        '10:00 AM', '10:30 AM', '11:00 AM',
        '2:00 PM', '2:30 PM', '3:00 PM', '3:30 PM',
      ],
    ),
    DoctorModel(
      id: 'd005',
      name: 'Dr. Manish Joshi',
      specialty: 'Neurology',
      hospital: 'Mediciti Hospital',
      rating: 4.9,
      reviewCount: 189,
      experience: 18,
      fee: 'NPR 2,500',
      bio:
          'Dr. Manish Joshi is a highly experienced neurologist specializing in stroke management, epilepsy, and neurodegenerative diseases.',
      availableSlots: [
        '9:00 AM', '9:30 AM', '10:00 AM',
        '1:00 PM', '1:30 PM', '2:00 PM',
      ],
    ),
    DoctorModel(
      id: 'd006',
      name: 'Dr. Sita Rai',
      specialty: 'Dermatology',
      hospital: 'Bir Hospital',
      rating: 4.5,
      reviewCount: 334,
      experience: 8,
      fee: 'NPR 1,000',
      bio:
          'Dr. Sita Rai is a skilled dermatologist with expertise in treating skin conditions, cosmetic dermatology, and hair and nail disorders.',
      availableSlots: [
        '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
        '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM',
      ],
    ),
  ];

  // ─── HOSPITALS ────────────────────────────────────────────────────────────

  static const List<HospitalModel> hospitals = [
    HospitalModel(
      id: 'h001',
      name: 'Patan Hospital',
      address: 'Lagankhel, Lalitpur',
      distance: '1.2 km',
      rating: 4.7,
      reviewCount: 1240,
      currentQueue: 23,
      openHours: '8:00 AM – 8:00 PM',
      isOpen: true,
      phone: '01-5522266',
      specialties: ['Cardiology', 'General', 'Orthopedics', 'Gynecology'],
    ),
    HospitalModel(
      id: 'h002',
      name: 'TUTH',
      address: 'Maharajgunj, Kathmandu',
      distance: '3.5 km',
      rating: 4.5,
      reviewCount: 2100,
      currentQueue: 41,
      openHours: '7:00 AM – 10:00 PM',
      isOpen: true,
      phone: '01-4412303',
      specialties: ['General', 'Pediatrics', 'Neurology', 'ENT', 'Oncology'],
    ),
    HospitalModel(
      id: 'h003',
      name: 'Grande Hospital',
      address: 'Tokha Road, Kathmandu',
      distance: '4.8 km',
      rating: 4.8,
      reviewCount: 980,
      currentQueue: 15,
      openHours: '24 Hours',
      isOpen: true,
      phone: '01-5159266',
      specialties: ['Orthopedics', 'Cardiology', 'Dermatology', 'Neurology'],
    ),
    HospitalModel(
      id: 'h004',
      name: 'Bir Hospital',
      address: 'Mahaboudha, Kathmandu',
      distance: '2.1 km',
      rating: 4.3,
      reviewCount: 3200,
      currentQueue: 67,
      openHours: '7:00 AM – 9:00 PM',
      isOpen: true,
      phone: '01-4221119',
      specialties: ['General', 'Dermatology', 'ENT', 'Pediatrics'],
    ),
    HospitalModel(
      id: 'h005',
      name: 'Mediciti Hospital',
      address: 'Minbhawan, Kathmandu',
      distance: '5.2 km',
      rating: 4.9,
      reviewCount: 760,
      currentQueue: 9,
      openHours: '24 Hours',
      isOpen: true,
      phone: '01-4785786',
      specialties: ['Neurology', 'Cardiology', 'Oncology', 'Orthopedics'],
    ),
    HospitalModel(
      id: 'h006',
      name: 'Kanti Children Hospital',
      address: 'Maharajgunj, Kathmandu',
      distance: '3.7 km',
      rating: 4.6,
      reviewCount: 1890,
      currentQueue: 34,
      openHours: '8:00 AM – 6:00 PM',
      isOpen: false,
      phone: '01-4412698',
      specialties: ['Pediatrics', 'Gynecology', 'General'],
    ),
  ];

  // ─── APPOINTMENTS ─────────────────────────────────────────────────────────

  static final List<AppointmentModel> appointments = [
    AppointmentModel(
      id: 'a001',
      doctor: doctors[0],
      date: DateTime.now().add(const Duration(days: 3)),
      time: '9:30 AM',
      status: AppointmentStatus.upcoming,
      reason: 'Annual cardiac checkup and ECG review',
    ),
    AppointmentModel(
      id: 'a002',
      doctor: doctors[2],
      date: DateTime.now().add(const Duration(days: 7)),
      time: '10:00 AM',
      status: AppointmentStatus.upcoming,
      reason: 'Child vaccination and growth monitoring',
    ),
    AppointmentModel(
      id: 'a003',
      doctor: doctors[1],
      date: DateTime.now().subtract(const Duration(days: 10)),
      time: '8:00 AM',
      status: AppointmentStatus.completed,
      reason: 'Fever and general body checkup',
    ),
    AppointmentModel(
      id: 'a004',
      doctor: doctors[3],
      date: DateTime.now().subtract(const Duration(days: 25)),
      time: '2:30 PM',
      status: AppointmentStatus.completed,
      reason: 'Knee pain and physiotherapy consultation',
    ),
    AppointmentModel(
      id: 'a005',
      doctor: doctors[5],
      date: DateTime.now().subtract(const Duration(days: 5)),
      time: '4:00 PM',
      status: AppointmentStatus.cancelled,
      reason: 'Skin rash and allergy consultation',
    ),
  ];

  // ─── QUEUES ───────────────────────────────────────────────────────────────

  static const List<QueueModel> queues = [
    QueueModel(
      id: 'q001',
      hospitalName: 'Patan Hospital',
      doctorName: 'Dr. Priya Shrestha',
      specialty: 'Cardiology',
      queueNumber: 14,
      currentNumber: 11,
      totalAhead: 3,
      estimatedMinutes: 18,
      status: QueueStatus.active,
      department: 'Cardiology OPD, Block C',
    ),
    QueueModel(
      id: 'q002',
      hospitalName: 'TUTH',
      doctorName: 'Dr. Bikash Thapa',
      specialty: 'General Physician',
      queueNumber: 7,
      currentNumber: 5,
      totalAhead: 2,
      estimatedMinutes: 10,
      status: QueueStatus.waiting,
      department: 'General OPD, Block B',
    ),
    QueueModel(
      id: 'q003',
      hospitalName: 'Grande Hospital',
      doctorName: 'Dr. Roshan Khadka',
      specialty: 'Orthopedics',
      queueNumber: 32,
      currentNumber: 28,
      totalAhead: 4,
      estimatedMinutes: 25,
      status: QueueStatus.completed,
      department: 'Orthopedics Wing',
    ),
  ];

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  static final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n001',
      title: "It's almost your turn!",
      body: 'Only 2 people ahead at Patan Hospital. Head to OPD Block A now.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      category: NotificationCategory.queue,
      isRead: false,
    ),
    NotificationModel(
      id: 'n002',
      title: 'Appointment Confirmed',
      body: 'Your appointment with Dr. Priya Shrestha on Apr 30 at 9:30 AM is confirmed.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      category: NotificationCategory.appointment,
      isRead: false,
    ),
    NotificationModel(
      id: 'n003',
      title: 'Appointment Reminder',
      body: 'You have an appointment with Dr. Anita Gurung tomorrow at 10:00 AM.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      category: NotificationCategory.reminder,
      isRead: true,
    ),
    NotificationModel(
      id: 'n004',
      title: 'Queue Update',
      body: 'Your queue at TUTH is now #7. You have just joined the live queue.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.queue,
      isRead: true,
    ),
    NotificationModel(
      id: 'n005',
      title: 'New Doctors Available',
      body: 'Dr. Manish Joshi (Neurologist) is now accepting appointments at Mediciti.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      category: NotificationCategory.general,
      isRead: true,
    ),
  ];

  // ─── SPECIALTIES ──────────────────────────────────────────────────────────

  static const List<String> specialties = [
    'All', 'Cardiology', 'General', 'Pediatrics', 'Orthopedics',
    'Dermatology', 'Neurology', 'Gynecology', 'ENT', 'Oncology',
  ];
}
