import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Aryan Thakuri');
  final _phoneController = TextEditingController(text: '9845437057');
  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'B+';
  final List<String> _allergies = ['Dust'];
  final List<String> _conditions = ['Hypertension'];
  final List<String> _medications = ['Amlodipine 5mg'];

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfilePhoto(),
                      _buildPersonalInfo(),
                      _buildMedicalInfo(),
                      _buildButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(
                  Icons.close,
                  color: AppColors.textWhite,
                  size: 28,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'AT',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Change profile photo',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildNameField(),
          const SizedBox(height: AppSpacing.md),
          _buildPhoneField(),
          const SizedBox(height: AppSpacing.md),
          _buildDateOfBirthField(),
          const SizedBox(height: AppSpacing.md),
          _buildGenderField(),
          const SizedBox(height: AppSpacing.md),
          _buildBloodGroupField(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FULL NAME',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            suffixIcon: Icon(Icons.close),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHONE NUMBER',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixText: '+977  ',
            hintText: '9845437057',
          ),
          validator: (value) {
            if (value == null || value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Please enter a valid phone number',
          style: TextStyle(
            color: AppColors.errorRed,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATE OF BIRTH',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lightPurpleBg,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                      : '10 Oct 2006',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textMedium,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENDER',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.lightPurpleBg,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGenderOption('Male'),
              ),
              Expanded(
                child: _buildGenderOption('Female'),
              ),
              Expanded(
                child: _buildGenderOption('Other'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Text(
          gender,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.textWhite : AppColors.textMedium,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBloodGroupField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BLOOD GROUP',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
          items: _bloodGroups.map((bg) {
            return DropdownMenuItem(
              value: bg,
              child: Text(bg),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBloodGroup = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical Info',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildAllergiesSection(),
          const SizedBox(height: AppSpacing.md),
          _buildConditionsSection(),
          const SizedBox(height: AppSpacing.md),
          _buildMedicationsSection(),
        ],
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KNOWN ALLERGIES',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ..._allergies.map((allergy) => _buildChip(allergy, AppColors.chipOrange)),
            GestureDetector(
              onTap: () => _addNewItem('allergy'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryGreen,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: const Text(
                  '+ Add allergy',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHRONIC CONDITIONS',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _conditions
              .map((condition) => _buildChip(condition, AppColors.chipRed))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEDICATIONS',
          style: AppTextStyles.labelSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._medications.map((med) => _buildMedicationItem(med)),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.close,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(String medication) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medication_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              medication,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.delete_outline,
            color: AppColors.errorRed,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.check_circle),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Discard Changes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.borderMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2006, 10, 14),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addNewItem(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type.capitalize()}'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter ${type}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add item logic here
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.pop(context);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
