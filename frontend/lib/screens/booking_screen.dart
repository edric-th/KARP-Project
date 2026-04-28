import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 1;
  int _selectedNavIndex = 3;

  // Step 1 selections
  String? _appointmentType;

  // Step 2 selections
  String? _selectedSpecialty;
  String? _selectedDoctor;

  // Step 3 data
  final Map<String, String> _bookingDetails = {
    'patientName': 'Aryan Thakuri',
    'phone': '+977 9845437057',
    'age': '20',
  };

  final List<Map<String, dynamic>> _appointmentTypes = [
    {
      'type': 'New Patient',
      'duration': '~20 MIN',
      'durationColor': AppColors.chipOrange,
      'description': 'Is this your first time visiting this hospital? Select here.',
      'icon': Icons.person_add_outlined,
    },
    {
      'type': 'Report Showing',
      'duration': '~10 MIN',
      'durationColor': AppColors.chipBlue,
      'description': 'Are you visiting to show lab results, X-rays, or other test reports?',
      'icon': Icons.description_outlined,
    },
    {
      'type': 'Follow Up',
      'duration': '~5 MIN',
      'durationColor': AppColors.chipGreen,
      'description': 'Are you coming back for a follow-up check after a previous visit?',
      'icon': Icons.repeat_outlined,
    },
  ];

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'General Medicine', 'icon': Icons.local_hospital},
    {'name': 'Cardiology', 'icon': Icons.favorite},
    {'name': 'Paediatrics', 'icon': Icons.child_care},
    {'name': 'Orthopaedics', 'icon': Icons.accessibility},
    {'name': 'ENT', 'icon': Icons.hearing},
    {'name': 'Dermatology', 'icon': Icons.healing},
    {'name': 'Gynaecology', 'icon': Icons.female},
    {'name': 'Neurology', 'icon': Icons.psychology},
  ];

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Rounak',
      'specialty': 'General Medicine',
      'status': 'Available',
      'statusColor': AppColors.availableGreen,
      'waiting': null,
    },
    {
      'name': 'Dr. Niraj',
      'specialty': 'General Medicine',
      'status': '12 waiting',
      'statusColor': AppColors.lightPurpleBg,
      'waiting': 12,
    },
    {
      'name': 'Dr. Prawnis',
      'specialty': 'General Medicine',
      'status': 'Busy',
      'statusColor': AppColors.busyRed,
      'waiting': null,
    },
    {
      'name': 'Dr. Kull',
      'specialty': 'General Medicine',
      'status': '23 waiting',
      'statusColor': AppColors.lightPurpleBg,
      'waiting': 23,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStepper(),
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _handleNavTap(index);
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textWhite,
                size: 28,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Book Appointment',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const CircleAvatar(
            backgroundColor: AppColors.mintGreen,
            child: Icon(
              Icons.person,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStepIndicator(1, 'APPOINTMENT\nTYPE'),
          ),
          _buildConnector(2),
          Expanded(
            child: _buildStepIndicator(2, 'SPECIALITY\n& DOCTOR'),
          ),
          _buildConnector(3),
          Expanded(
            child: _buildStepIndicator(3, 'CONFIRM'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primaryGreen : AppColors.borderMedium,
              width: 2,
            ),
          ),
          child: Center(
            child: isCurrent
                ? const Text(
                    '$step',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : isActive
                    ? const Icon(
                        Icons.check,
                        color: AppColors.textWhite,
                        size: 20,
                      )
                    : Text(
                        '$step',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppColors.textDark : AppColors.textLight,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        color: isActive ? AppColors.primaryGreen : AppColors.borderLight,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Appointment Type',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose the type of appointment to proceed.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._appointmentTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            return _buildAppointmentTypeCard(
              type: type['type'],
              duration: type['duration'],
              durationColor: type['durationColor'],
              description: type['description'],
              icon: type['icon'],
              isSelected: _appointmentType == type['type'],
              onTap: () {
                setState(() {
                  _appointmentType = type['type'];
                });
              },
            );
          }).toList(),
          const Spacer(),
          _buildNextButton(),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeCard({
    required String type,
    required String duration,
    required Color durationColor,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightMint : AppColors.lightPurpleBg,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: durationColor,
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryGreen,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Radio<String>(
              value: type,
              groupValue: _appointmentType,
              onChanged: (value) {
                setState(() {
                  _appointmentType = value;
                });
              },
              activeColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Speciality',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSpecialtyGrid(),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Choose Doctor',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Available doctors in General Medicine',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDoctorList(),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedSpecialty != null && _selectedDoctor != null
                      ? () {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.5,
      ),
      itemCount: _specialties.length,
      itemBuilder: (context, index) {
        final specialty = _specialties[index];
        final isSelected = _selectedSpecialty == specialty['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpecialty = specialty['name'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.mintGreen : Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  specialty['icon'],
                  size: 18,
                  color: isSelected ? AppColors.primaryGreen : AppColors.textMedium,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    specialty['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.primaryGreen : AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        final isSelected = _selectedDoctor == doctor['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDoctor = doctor['name'];
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightPurpleBg,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        doctor['specialty'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (doctor['rating'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chipOrange,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: AppColors.waitingOrangeText,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          doctor['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: doctor['statusColor'],
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    doctor['status'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: doctor['status'] == 'Available'
                          ? AppColors.primaryGreen
                          : doctor['status'] == 'Busy'
                              ? AppColors.busyRedText
                              : AppColors.textMedium,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Radio<String>(
                  value: doctor['name'],
                  groupValue: _selectedDoctor,
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctor = value;
                    });
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingDetails(),
          const SizedBox(height: AppSpacing.md),
          _buildPatientDetails(),
          const SizedBox(height: AppSpacing.md),
          _buildNotesSection(),
          const SizedBox(height: AppSpacing.md),
          _buildNotificationToggle(),
          const Spacer(),
          _buildConfirmButton(),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Token number will be assigned after booking.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightMint,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow('Appointment type:', _appointmentType ?? ''),
          _buildDetailRow('Doctor:', _selectedDoctor ?? ''),
          _buildDetailRow('Speciality:', _selectedSpecialty ?? ''),
          _buildDetailRow('Hospital:', 'Chameli Hospital'),
          _buildDetailRow('Date:', 'Today, 22 April 2026'),
          _buildDetailRow('Estimated queue position:', 'Token 047 (approx)'),
          _buildDetailRow(
            'Estimated wait:',
            '~1 Hours',
            valueColor: AppColors.errorRed,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightPurpleBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Patient Details',
                style: AppTextStyles.titleMedium,
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NAME',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Aryan Thakuri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHONE',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '+977 9845437057',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AGE',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '20',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Any notes for the doctor?',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightPurpleBg,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write here... (optional)',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notify me when my turn is near',
                style: AppTextStyles.titleMedium,
              ),
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 16,
                color: AppColors.textLight,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Alert me 2 tokens before',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _appointmentType != null
            ? () {
                setState(() {
                  _currentStep++;
                });
              }
            : null,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/booking-success');
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Confirm Booking'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/queue');
        break;
      case 3:
        // Already on booking
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
}
