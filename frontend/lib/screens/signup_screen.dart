import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/validators.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class SignupScreen extends StatefulWidget {
  /// false = registration (account basics + email verification only).
  /// true  = complete/edit profile (personal + medical + emergency, saved via
  /// PUT /profile). The same rich form serves both completion and editing.
  final bool profileMode;
  final bool isCompletion;
  const SignupScreen({
    super.key,
    this.profileMode = false,
    this.isCompletion = false,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  bool _submitting = false;

  // Which underlying steps are visible, based on mode
  // (0=account, 1=personal, 2=medical, 3=emergency).
  List<int> get _activeSteps =>
      widget.profileMode ? const [1, 2, 3] : const [0];
  List<String> get _activeLabels =>
      [for (final s in _activeSteps) _stepLabels[s]];
  int get _logicalStep => _activeSteps[_step];
  bool get _isLastStep => _step >= _activeSteps.length - 1;
  String get _bottomLabel => widget.profileMode
      ? (_isLastStep ? 'Save Profile' : 'Continue')
      : 'Create Account';

  // ── Step 1 — Account (basics + auth) ─────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _emailVerified = false;

  // ── Step 2 — Personal ────────────────────────────────────────────────
  String? _photoData; // data-URL (or remote URL) of the patient/profile photo
  DateTime? _dob;
  String? _gender;
  String? _nationality;
  final _nationalIdCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _maritalStatus;

  // ── Step 3 — Medical ─────────────────────────────────────────────────
  String? _bloodGroup;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final List<String> _allergies = [];
  final List<String> _conditions = [];
  final _surgeriesCtrl = TextEditingController();
  final List<_Medication> _medications = [];
  final Set<String> _vaccinations = {};
  String? _smoking;
  String? _alcohol;

  // ── Step 4 — Emergency ───────────────────────────────────────────────
  final _emPrimaryName = TextEditingController();
  final _emPrimaryRelation = TextEditingController();
  final _emPrimaryPhone = TextEditingController();
  final _emPrimaryAddress = TextEditingController();
  final _emSecondaryName = TextEditingController();
  final _emSecondaryRelation = TextEditingController();
  final _emSecondaryPhone = TextEditingController();
  final _famDoctorName = TextEditingController();
  final _famDoctorSpecialty = TextEditingController();
  final _famDoctorPhone = TextEditingController();
  final _famDoctorClinic = TextEditingController();
  bool _consent1 = false;
  bool _consent2 = false;
  bool _consent3 = false;
  bool _signed = false;

  static const _stepLabels = ['ACCOUNT', 'PERSONAL', 'MEDICAL', 'EMERGENCY'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  static const _nationalities = ['Nepali', 'Indian', 'Other'];
  static const _maritalOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  static const _smokingOptions = ['Never', 'Former Smoker', 'Occasional', 'Daily'];
  static const _alcoholOptions = ['None', 'Socially', 'Regular'];
  static const _vaccineOptions = [
    'COVID-19 (Complete)',
    'Influenza (Annual)',
    'Hepatitis B',
    'Tetanus / DTaP',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    if (widget.profileMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
    }
  }

  /// Pre-fill the personal/medical/emergency fields from the saved profile so
  /// the same form works for completing AND editing.
  void _prefillFromProfile() {
    final p = context.read<AuthProvider>().profile;
    if (p == null || !mounted) return;
    setState(() {
      _nameCtrl.text = p.name;
      if (p.photoUrl.isNotEmpty) _photoData = p.photoUrl;
      _dob = DateTime.tryParse(p.dateOfBirth) ?? _dob;
      if (p.gender.isNotEmpty) _gender = p.gender;
      if (p.nationality.isNotEmpty) _nationality = p.nationality;
      _nationalIdCtrl.text = p.nationalId;
      _altPhoneCtrl.text = p.alternatePhone;
      _addressCtrl.text = p.address;
      if (p.maritalStatus.isNotEmpty) _maritalStatus = p.maritalStatus;
      if (p.bloodGroup.isNotEmpty) _bloodGroup = p.bloodGroup;
      if (p.height != null) _heightCtrl.text = p.height!.toStringAsFixed(0);
      if (p.weight != null) _weightCtrl.text = p.weight!.toStringAsFixed(0);
      _allergies
        ..clear()
        ..addAll(p.allergies);
      _conditions
        ..clear()
        ..addAll(p.chronicConditions);
      _surgeriesCtrl.text = p.pastSurgeries;
      _medications
        ..clear()
        ..addAll(p.currentMedications.map((m) => _Medication(
              name: (m['name'] ?? '').toString(),
              dose: (m['dose'] ?? '').toString(),
            )));
      _vaccinations
        ..clear()
        ..addAll(p.vaccinations);
      if (p.smokingStatus.isNotEmpty) _smoking = p.smokingStatus;
      if (p.alcoholConsumption.isNotEmpty) _alcohol = p.alcoholConsumption;
      _emPrimaryName.text = (p.primaryContact['name'] ?? '').toString();
      _emPrimaryRelation.text = (p.primaryContact['relation'] ?? '').toString();
      _emPrimaryPhone.text = (p.primaryContact['phone'] ?? '').toString();
      _emPrimaryAddress.text = (p.primaryContact['address'] ?? '').toString();
      _emSecondaryName.text = (p.secondaryContact['name'] ?? '').toString();
      _emSecondaryRelation.text =
          (p.secondaryContact['relation'] ?? '').toString();
      _emSecondaryPhone.text = (p.secondaryContact['phone'] ?? '').toString();
      _famDoctorName.text = (p.familyDoctor['name'] ?? '').toString();
      _famDoctorSpecialty.text = (p.familyDoctor['specialty'] ?? '').toString();
      _famDoctorPhone.text = (p.familyDoctor['clinicPhone'] ?? '').toString();
      _famDoctorClinic.text = (p.familyDoctor['clinicName'] ?? '').toString();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _emPrimaryName.dispose();
    _emPrimaryRelation.dispose();
    _emPrimaryPhone.dispose();
    _emPrimaryAddress.dispose();
    _emSecondaryName.dispose();
    _emSecondaryRelation.dispose();
    _emSecondaryPhone.dispose();
    _famDoctorName.dispose();
    _famDoctorSpecialty.dispose();
    _famDoctorPhone.dispose();
    _famDoctorClinic.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _surgeriesCtrl.dispose();
    super.dispose();
  }

  int? get _age {
    final dob = _dob;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age -= 1;
    }
    return age;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _next() async {
    // Registration (account step): validate basics + require a verified email.
    if (_logicalStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _snack('Please enter your full name.');
        return;
      }
      if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
        _snack('Please enter a valid email.');
        return;
      }
      final phoneErr = validateNepaliPhone(_phoneCtrl.text);
      if (phoneErr != null) {
        _snack(phoneErr);
        return;
      }
      if (_passwordCtrl.text.length < 6 ||
          _passwordCtrl.text != _confirmCtrl.text) {
        _snack('Passwords must match and be 6+ characters.');
        return;
      }
      if (!_emailVerified) {
        _snack('Please verify your email — tap "Verify" next to it.');
        return;
      }
    }

    // Profile completion is optional, so its steps aren't hard-validated —
    // patients can fill in as much as they like and save.

    if (_isLastStep) {
      if (widget.profileMode) {
        await _submitProfile();
      } else {
        await _submitRegistration();
      }
      return;
    }
    setState(() => _step += 1);
  }

  /// Build the flat camelCase profile payload from every collected field.
  Map<String, dynamic> _buildProfileFields() {
    return <String, dynamic>{
      if (_nameCtrl.text.trim().isNotEmpty) 'name': _nameCtrl.text.trim(),
      if (_photoData != null && _photoData!.isNotEmpty) 'photoUrl': _photoData,
      if (_dob != null) 'dateOfBirth': DateFormat('yyyy-MM-dd').format(_dob!),
      if (_age != null) 'age': _age,
      if (_gender != null) 'gender': _gender,
      if (_nationality != null) 'nationality': _nationality,
      if (_nationalIdCtrl.text.trim().isNotEmpty)
        'nationalId': _nationalIdCtrl.text.trim(),
      if (_altPhoneCtrl.text.trim().isNotEmpty)
        'alternatePhone': _altPhoneCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_maritalStatus != null) 'maritalStatus': _maritalStatus,
      if (_bloodGroup != null) 'bloodGroup': _bloodGroup,
      if (double.tryParse(_heightCtrl.text.trim()) != null)
        'height': double.parse(_heightCtrl.text.trim()),
      if (double.tryParse(_weightCtrl.text.trim()) != null)
        'weight': double.parse(_weightCtrl.text.trim()),
      if (_allergies.isNotEmpty) 'allergies': _allergies,
      if (_conditions.isNotEmpty) 'chronicConditions': _conditions,
      if (_surgeriesCtrl.text.trim().isNotEmpty)
        'pastSurgeries': _surgeriesCtrl.text.trim(),
      if (_medications.isNotEmpty)
        'currentMedications':
            _medications.map((m) => {'name': m.name, 'dose': m.dose}).toList(),
      if (_vaccinations.isNotEmpty) 'vaccinations': _vaccinations.toList(),
      if (_smoking != null) 'smokingStatus': _smoking,
      if (_alcohol != null) 'alcoholConsumption': _alcohol,
      'primaryContact': {
        'name': _emPrimaryName.text.trim(),
        'relation': _emPrimaryRelation.text.trim(),
        'phone': _emPrimaryPhone.text.trim(),
        'address': _emPrimaryAddress.text.trim(),
      },
      if (_emSecondaryName.text.trim().isNotEmpty)
        'secondaryContact': {
          'name': _emSecondaryName.text.trim(),
          'relation': _emSecondaryRelation.text.trim(),
          'phone': _emSecondaryPhone.text.trim(),
        },
      if (_famDoctorName.text.trim().isNotEmpty)
        'familyDoctor': {
          'name': _famDoctorName.text.trim(),
          'specialty': _famDoctorSpecialty.text.trim(),
          'clinicPhone': _famDoctorPhone.text.trim(),
          'clinicName': _famDoctorClinic.text.trim(),
        },
    };
  }

  Future<void> _submitRegistration() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    // Lean registration: only the account is created here. The rich
    // profile (personal/medical/emergency) is filled later via /complete-profile.
    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        '/registration-success',
        arguments: {'name': _nameCtrl.text.trim()},
      );
    } else {
      _snack(auth.error ?? 'Could not create your account. Please try again.');
    }
  }

  /// Pick a profile photo from the gallery/local disk. image_picker resizes &
  /// compresses on pick (maxWidth/Height + imageQuality), then we store it as a
  /// small base64 data-URL in `photoUrl` — no external storage needed.
  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ??
          (file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      setState(() => _photoData = 'data:$mime;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) _snack('Could not pick that photo. Please try another.');
    }
  }

  Future<void> _submitProfile() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok =
        await context.read<AuthProvider>().saveProfile(_buildProfileFields());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _snack('Profile saved.');
      Navigator.pop(context);
    } else {
      _snack('Could not save your profile. Please try again.');
    }
  }

  bool get _emailLooksValid {
    final e = _emailCtrl.text.trim();
    return e.contains('@') && e.contains('.') && e.length >= 5;
  }

  /// Inline verification at the email field: open the OTP sheet (which sends
  /// the code) and flip the VERIFIED badge on success.
  Future<void> _verifyEmailInline() async {
    if (!_emailLooksValid) {
      _snack('Enter a valid email first.');
      return;
    }
    final ok = await _showOtpSheet();
    if (ok == true && mounted) setState(() => _emailVerified = true);
  }

  Future<bool?> _showOtpSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _OtpVerificationSheet(email: _emailCtrl.text.trim()),
    );
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _addChip({
    required String title,
    required List<String> target,
  }) async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type and press Add',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Add',
              onTap: () {
                if (ctrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, ctrl.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result != null) setState(() => target.add(result));
  }

  Future<void> _addMedication() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final result = await showModalBottomSheet<_Medication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Add Medication',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Medicine name',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: doseCtrl,
              decoration: InputDecoration(
                hintText: 'Dose & frequency, e.g. 5mg • Daily',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Add',
              onTap: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(
                    ctx,
                    _Medication(
                      name: nameCtrl.text.trim(),
                      dose: doseCtrl.text.trim(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    doseCtrl.dispose();
    if (result != null) setState(() => _medications.add(result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: widget.profileMode
                  ? (widget.isCompletion
                      ? 'Complete your profile'
                      : 'Edit profile')
                  : 'Create account',
              step: _step,
              total: _activeSteps.length,
              onBack: _back,
              onSaveDraft: () => _snack('Draft saved.'),
              showProgress: _activeSteps.length > 1,
            ),
            if (_activeSteps.length > 1)
              _StepperBar(currentStep: _step, labels: _activeLabels),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: _stepBody(),
                  ),
                ),
              ),
            ),
            _BottomBar(
              label: _bottomLabel,
              onNext: _next,
              onSaveDraft: () => _snack('Draft saved.'),
              busy: _submitting,
              showSaveDraft: widget.profileMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_logicalStep) {
      case 0:
        return _accountStep();
      case 1:
        return _personalStep();
      case 2:
        return _medicalStep();
      case 3:
        return _emergencyStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: ACCOUNT ─────────────────────────────────────────────────

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: "Let's get you set up",
          subtitle:
              'A few basics to create your MeroPalo Care account. We will verify your email next.',
        ),
        const SizedBox(height: 18),
        _FieldCard(
          icon: Icons.person_outline_rounded,
          label: 'FULL NAME',
          child: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.email_outlined,
          label: 'EMAIL ADDRESS',
          trailing: _emailVerified
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreenMedium,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                )
              : (_emailLooksValid
                  ? GestureDetector(
                      onTap: _verifyEmailInline,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Verify',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    )
                  : null),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {
              if (_emailVerified) _emailVerified = false;
            }),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.phone_outlined,
          label: 'PHONE NUMBER',
          child: _PhonePrefixField(controller: _phoneCtrl),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.lock_outline_rounded,
          label: 'PASSWORD',
          child: TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.verified_user_outlined,
          label: 'CONFIRM PASSWORD',
          child: TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 14),
        _SecurityNote(
          text:
              'We will send a 6-digit code to your email to confirm it before continuing.',
        ),
      ],
    );
  }

  // ─── STEP 2: PERSONAL ────────────────────────────────────────────────

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompletedStepPill(label: 'Account Setup — Complete'),
        const SizedBox(height: 18),
        Center(
          child: _PhotoUploader(photoData: _photoData, onTap: _pickPhoto),
        ),
        const SizedBox(height: 22),
        _FieldCard(
          icon: Icons.person_outline_rounded,
          label: 'FULL NAME',
          child: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Your full name',
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FieldCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'DATE OF BIRTH',
                  onTap: _pickDob,
                  child: Text(
                    _dob == null
                        ? 'Tap to select'
                        : DateFormat('d MMM y').format(_dob!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _dob == null
                        ? _valueStyle.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          )
                        : _valueStyle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldCard(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'AGE',
                  child: Text(
                    _age == null ? '—' : '$_age years',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _age == null
                        ? _valueStyle.copyWith(color: AppColors.textMuted)
                        : _valueStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LabelOnlyCard(
          label: 'GENDER',
          child: _SegmentedPills(
            options: const ['Male', 'Female', 'Other'],
            selected: _gender ?? '',
            onChanged: (v) => setState(() => _gender = v),
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.public_rounded,
          label: 'NATIONALITY',
          onTap: () async {
            final picked = await _pickFromList('Nationality', _nationalities);
            if (picked != null) setState(() => _nationality = picked);
          },
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          child: Text(
            _nationality ?? 'Tap to select',
            style: _nationality == null
                ? _valueStyle.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  )
                : _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.badge_outlined,
          label: 'NATIONAL ID / CITIZENSHIP',
          child: TextField(
            controller: _nationalIdCtrl,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.contact_phone_outlined,
          label: 'ALTERNATE PHONE',
          child: _PhonePrefixField(controller: _altPhoneCtrl),
        ),
        const SizedBox(height: 12),
        _FieldCard(
          icon: Icons.location_on_outlined,
          label: 'HOME ADDRESS',
          child: TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
            style: _valueStyle,
          ),
        ),
        const SizedBox(height: 14),
        _LabelOnlyCard(
          label: 'MARITAL STATUS',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _maritalOptions
                .map(
                  (m) => _PillChoice(
                    label: m,
                    selected: _maritalStatus == m,
                    onTap: () => setState(() => _maritalStatus = m),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: MEDICAL ─────────────────────────────────────────────────

  Widget _medicalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: 'Medical Information',
          subtitle:
              'Help us provide the best care by sharing your clinical history and current health metrics.',
        ),
        const SizedBox(height: 14),
        _ConfidentialBanner(),
        const SizedBox(height: 22),
        _SubLabel('BLOOD GROUP'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bloodGroups.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (_, i) {
            final bg = _bloodGroups[i];
            final selected = bg == _bloodGroup;
            return GestureDetector(
              onTap: () => setState(() => _bloodGroup = bg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.error : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.error : AppColors.border,
                    width: 1.4,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.error.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  bg,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        _SubLabel('HEIGHT (CM)'),
        const SizedBox(height: 8),
        _SoftFilledField(
          controller: _heightCtrl,
          hint: 'e.g. 175',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _SubLabel('WEIGHT (KG)'),
        const SizedBox(height: 8),
        _SoftFilledField(
          controller: _weightCtrl,
          hint: 'e.g. 72',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _OptionalLabel('KNOWN ALLERGIES'),
        const SizedBox(height: 10),
        _ChipEditor(
          items: _allergies,
          color: const Color(0xFFFDE0C4),
          textColor: const Color(0xFF8A4B14),
          onRemove: (i) => setState(() => _allergies.removeAt(i)),
          onAdd: () => _addChip(title: 'Add Allergy', target: _allergies),
          addLabel: '+ Add Allergy',
        ),
        const SizedBox(height: 18),
        _OptionalLabel('CHRONIC CONDITIONS'),
        const SizedBox(height: 10),
        _ChipEditor(
          items: _conditions,
          color: const Color(0xFFFDE0E0),
          textColor: const Color(0xFFB42323),
          onRemove: (i) => setState(() => _conditions.removeAt(i)),
          onAdd: () => _addChip(title: 'Add Condition', target: _conditions),
          addLabel: '+ Add Condition',
        ),
        const SizedBox(height: 18),
        _SubLabel('PAST SURGERIES / MAJOR PROCEDURES'),
        const SizedBox(height: 10),
        _SoftFilledField(
          controller: _surgeriesCtrl,
          hint: 'e.g. Appendectomy (2015)',
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _SubLabel('CURRENT MEDICATIONS')),
            GestureDetector(
              onTap: _addMedication,
              child: Text(
                '+ Add Medication',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._medications.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MedicationRow(
                  med: e.value,
                  onDelete: () =>
                      setState(() => _medications.removeAt(e.key)),
                ),
              ),
            ),
        const SizedBox(height: 12),
        _SubLabel('VACCINATION HISTORY'),
        const SizedBox(height: 10),
        ..._vaccineOptions.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CheckRow(
              label: v,
              checked: _vaccinations.contains(v),
              onToggle: () => setState(() {
                if (_vaccinations.contains(v)) {
                  _vaccinations.remove(v);
                } else {
                  _vaccinations.add(v);
                }
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SubLabel('SMOKING STATUS'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _smokingOptions
              .map(
                (m) => _PillChoice(
                  label: m,
                  selected: _smoking == m,
                  onTap: () => setState(() => _smoking = m),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        _SubLabel('ALCOHOL CONSUMPTION'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _alcoholOptions
              .map(
                (m) => _PillChoice(
                  label: m,
                  selected: _alcohol == m,
                  onTap: () => setState(() => _alcohol = m),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ─── STEP 4: EMERGENCY ───────────────────────────────────────────────

  Widget _emergencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(
          title: 'Final Verification',
          subtitle:
              'Add the emergency contacts our team can reach, then review and sign your registration.',
        ),
        const SizedBox(height: 22),
        _EmergencyContactForm(
          tag: 'PRIMARY',
          isPrimary: true,
          nameCtrl: _emPrimaryName,
          relationCtrl: _emPrimaryRelation,
          phoneCtrl: _emPrimaryPhone,
          addressCtrl: _emPrimaryAddress,
        ),
        const SizedBox(height: 14),
        _EmergencyContactForm(
          tag: 'SECONDARY (Optional)',
          isPrimary: false,
          nameCtrl: _emSecondaryName,
          relationCtrl: _emSecondaryRelation,
          phoneCtrl: _emSecondaryPhone,
        ),
        const SizedBox(height: 14),
        _EmergencyContactForm(
          tag: 'FAMILY DOCTOR (Optional)',
          isPrimary: false,
          nameCtrl: _famDoctorName,
          relationCtrl: _famDoctorSpecialty,
          phoneCtrl: _famDoctorPhone,
          addressCtrl: _famDoctorClinic,
          nameLabel: "DOCTOR'S NAME",
          relationLabel: 'SPECIALTY',
          phoneLabel: 'CLINIC PHONE',
          addressLabel: 'CLINIC NAME / ADDRESS',
          nameIcon: Icons.local_hospital_outlined,
          relationIcon: Icons.medical_services_outlined,
          addressIcon: Icons.business_outlined,
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEAF6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Declaration & Consent',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              _ConsentRow(
                checked: _consent1,
                onToggle: () => setState(() => _consent1 = !_consent1),
                text:
                    'I hereby certify that the information provided above is true and accurate to the best of my knowledge.',
              ),
              const SizedBox(height: 14),
              _ConsentRow(
                checked: _consent2,
                onToggle: () => setState(() => _consent2 = !_consent2),
                richSegments: const [
                  _RichSeg(
                    'I consent to MeroPalo Care processing my personal and clinical data as outlined in the ',
                  ),
                  _RichSeg('Privacy Policy', isLink: true),
                  _RichSeg('.'),
                ],
              ),
              const SizedBox(height: 14),
              _ConsentRow(
                checked: _consent3,
                onToggle: () => setState(() => _consent3 = !_consent3),
                richSegments: const [
                  _RichSeg('I agree to the '),
                  _RichSeg('Terms of Service', isLink: true),
                  _RichSeg(' regarding medical consultation and emergency hospital procedures.'),
                ],
              ),
              const SizedBox(height: 20),
              _SubLabel('DIGITAL SIGNATURE'),
              const SizedBox(height: 10),
              _SignaturePad(
                signed: _signed,
                onSigned: () => setState(() => _signed = true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'By signing, you validate this electronic record as legally binding.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _signed = false),
                    child: Text(
                      'CLEAR\nSIGNATURE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your data is encrypted using 256-bit SSL protocols.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<String?> _pickFromList(String title, List<String> options) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...options.map(
              (o) => ListTile(
                onTap: () => Navigator.pop(ctx, o),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  o,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// SHARED STYLES
// ──────────────────────────────────────────────────────────────────────────

const TextStyle _valueStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: AppColors.textPrimary,
);

// ──────────────────────────────────────────────────────────────────────────
// HEADER + STEPPER + BOTTOM BAR
// ──────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final bool showProgress;
  const _Header({
    required this.title,
    required this.step,
    required this.total,
    required this.onBack,
    required this.onSaveDraft,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((step + 1) / total * 100).round();
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (showProgress)
                GestureDetector(
                  onTap: onSaveDraft,
                  child: const Text(
                    'Save Draft',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (showProgress) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CURRENT PROGRESS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Step ${step + 1} of $total',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: (step + 1) / total,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _StepperBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  const _StepperBar({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(labels.length, (i) {
          final isDone = i <= currentStep;
          final isLast = i == labels.length - 1;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i == 0)
                      const Expanded(child: SizedBox())
                    else
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i <= currentStep
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDone ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (isLast)
                      const Expanded(child: SizedBox())
                    else
                      Expanded(
                        child: Container(
                          height: 2,
                          color: (i + 1) <= currentStep
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: isDone ? AppColors.primary : AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final VoidCallback onNext;
  final VoidCallback onSaveDraft;
  final bool busy;
  final bool showSaveDraft;
  const _BottomBar({
    required this.label,
    required this.onNext,
    required this.onSaveDraft,
    this.busy = false,
    this.showSaveDraft = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: label,
              onTap: onNext,
              isLoading: busy,
              icon: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
            if (showSaveDraft) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onSaveDraft,
                child: Text(
                  'Save as Draft for later',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// FIELDS / CARDS
// ──────────────────────────────────────────────────────────────────────────

class _StepHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.7,
        ),
      );
}

class _OptionalLabel extends StatelessWidget {
  final String text;
  const _OptionalLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEAF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'OPTIONAL',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      );
}

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _FieldCard({
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _LabelOnlyCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabelOnlyCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SubLabel(label),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SoftFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  const _SoftFilledField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
        ),
        style: _valueStyle.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SegmentedPills extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentedPills({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: options
            .map(
              (o) => Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == o
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      o,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: selected == o
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PillChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : const Color(0xFFEEEAF6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PhotoUploader extends StatelessWidget {
  final VoidCallback onTap;
  final String? photoData;
  const _PhotoUploader({required this.onTap, this.photoData});

  Uint8List? get _bytes {
    final d = photoData;
    if (d == null || !d.startsWith('data:')) return null;
    try {
      return base64Decode(d.substring(d.indexOf(',') + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final hasRemote =
        photoData != null && photoData!.isNotEmpty && bytes == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.cardGreenLight.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 1.4,
                      style: BorderStyle.solid,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: bytes != null
                      ? Image.memory(bytes,
                          width: 110, height: 110, fit: BoxFit.cover)
                      : hasRemote
                          ? Image.network(photoData!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.photo_camera_outlined,
                                  color: AppColors.primary,
                                  size: 30))
                          : const Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (photoData != null && photoData!.isNotEmpty)
                ? 'Change Photo'
                : 'Upload Photo',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap to pick from your photos',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedStepPill extends StatelessWidget {
  final String label;
  const _CompletedStepPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _ConfidentialBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8C7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF8A4B14),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidential & Protected',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8A4B14),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This information is private and strictly encrypted. Only your attending medical team will have access to these records for clinical decision-making.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: const Color(0xFF8A4B14).withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipEditor extends StatelessWidget {
  final List<String> items;
  final Color color;
  final Color textColor;
  final void Function(int) onRemove;
  final VoidCallback onAdd;
  final String addLabel;

  const _ChipEditor({
    required this.items,
    required this.color,
    required this.textColor,
    required this.onRemove,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.asMap().entries.map(
              (e) => Container(
                padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textMuted),
            ),
            child: Text(
              addLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Medication {
  final String name;
  final String dose;
  const _Medication({required this.name, required this.dose});
}

class _MedicationRow extends StatelessWidget {
  final _Medication med;
  final VoidCallback onDelete;
  const _MedicationRow({required this.med, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (med.dose.isNotEmpty)
                  Text(
                    med.dose,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onToggle;
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEAF6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  final String text;
  const _SecurityNote({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAF6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ──────────────────────────────────────────────────────────────────────────
// EMERGENCY CONTACT FORM
// ──────────────────────────────────────────────────────────────────────────

class _EmergencyContactForm extends StatelessWidget {
  final String tag;
  final bool isPrimary;
  final TextEditingController nameCtrl;
  final TextEditingController relationCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController? addressCtrl;
  final String nameLabel;
  final String relationLabel;
  final String phoneLabel;
  final String addressLabel;
  final IconData nameIcon;
  final IconData relationIcon;
  final IconData addressIcon;

  const _EmergencyContactForm({
    required this.tag,
    required this.isPrimary,
    required this.nameCtrl,
    required this.relationCtrl,
    required this.phoneCtrl,
    this.addressCtrl,
    this.nameLabel = 'FULL NAME',
    this.relationLabel = 'RELATIONSHIP',
    this.phoneLabel = 'PHONE NUMBER',
    this.addressLabel = 'ADDRESS',
    this.nameIcon = Icons.person_outline_rounded,
    this.relationIcon = Icons.diversity_3_rounded,
    this.addressIcon = Icons.location_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isPrimary ? AppColors.surface : const Color(0xFFEEEAF6);
    final tagBg = isPrimary ? AppColors.cardGreenLight : AppColors.surface;
    final innerBg = isPrimary ? AppColors.backgroundLight : AppColors.surface;
    // NB: a non-uniform Border (thick left accent) cannot be combined with a
    // borderRadius on one BoxDecoration — that throws and renders the card
    // blank. So we use a uniform border + a separate left accent stripe.
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: isPrimary ? Border.all(color: AppColors.border) : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPrimary)
                Container(width: 4, color: AppColors.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EmFieldRow(
            icon: nameIcon,
            label: nameLabel,
            controller: nameCtrl,
            background: innerBg,
          ),
          const SizedBox(height: 10),
          _EmFieldRow(
            icon: relationIcon,
            label: relationLabel,
            controller: relationCtrl,
            background: innerBg,
          ),
          const SizedBox(height: 10),
          _EmFieldRow(
            icon: Icons.phone_outlined,
            label: phoneLabel,
            controller: phoneCtrl,
            background: innerBg,
            isPhone: true,
          ),
          if (addressCtrl != null) ...[
            const SizedBox(height: 10),
            _EmFieldRow(
              icon: addressIcon,
              label: addressLabel,
              controller: addressCtrl!,
              background: innerBg,
              maxLines: 2,
            ),
          ],
        ],
      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmFieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final Color background;
  final bool isPhone;
  final int maxLines;
  const _EmFieldRow({
    required this.icon,
    required this.label,
    required this.controller,
    required this.background,
    this.isPhone = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                isPhone
                    ? _PhonePrefixField(controller: controller)
                    : TextField(
                        controller: controller,
                        maxLines: maxLines,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                        style: _valueStyle,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RichSeg {
  final String text;
  final bool isLink;
  const _RichSeg(this.text, {this.isLink = false});
}

class _ConsentRow extends StatelessWidget {
  final bool checked;
  final VoidCallback onToggle;
  final String? text;
  final List<_RichSeg>? richSegments;
  const _ConsentRow({
    required this.checked,
    required this.onToggle,
    this.text,
    this.richSegments,
  });

  @override
  Widget build(BuildContext context) {
    final body = richSegments != null
        ? Text.rich(
            TextSpan(
              children: richSegments!
                  .map(
                    (s) => TextSpan(
                      text: s.text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        decoration:
                            s.isLink ? TextDecoration.underline : null,
                        fontWeight:
                            s.isLink ? FontWeight.w700 : FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        : Text(
            text ?? '',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          );

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: checked ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: checked ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: checked
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// SIGNATURE PAD
// ──────────────────────────────────────────────────────────────────────────

class _SignaturePad extends StatefulWidget {
  final bool signed;
  final VoidCallback onSigned;
  const _SignaturePad({required this.signed, required this.onSigned});

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<List<Offset>> _strokes = [];

  @override
  void didUpdateWidget(covariant _SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signed && !widget.signed) {
      setState(_strokes.clear);
    }
  }

  void _start(Offset p) {
    setState(() => _strokes.add([p]));
    if (!widget.signed) widget.onSigned();
  }

  void _update(Offset p) {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.last.add(p));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _start(d.localPosition),
          onPanUpdate: (d) => _update(d.localPosition),
          child: CustomPaint(
            painter: _SignaturePainter(strokes: _strokes),
            child: _strokes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.draw_outlined,
                          color: AppColors.textMuted,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign here using touch or mouse',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  const _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter old) =>
      old.strokes != strokes || old.strokes.length != strokes.length;
}

// ──────────────────────────────────────────────────────────────────────────
// OTP VERIFICATION SHEET
// ──────────────────────────────────────────────────────────────────────────

class _OtpVerificationSheet extends StatefulWidget {
  final String email;
  const _OtpVerificationSheet({required this.email});

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _resendIn = 30;
  bool _verifying = false;
  bool _sending = false;
  String? _error;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes.first.requestFocus();
      _send();
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _startResendTimer() async {
    while (mounted && _resendIn > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendIn -= 1);
    }
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _clearBoxes() {
    for (final c in _ctrls) {
      c.clear();
    }
    if (mounted) _nodes.first.requestFocus();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final res = await context.read<AuthService>().sendOtp(widget.email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _devCode = res['devCode'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        // Surface the real cause: ApiException carries the backend `detail`
        // (e.g. SMTP 502); anything else is a client-side error worth seeing.
        _error = e is ApiException ? e.message : 'Could not send the code: $e';
      });
    }
  }

  Future<void> _verify() async {
    if (_code.length < 6 || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final ok =
          await context.read<AuthService>().verifyOtp(widget.email, _code);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _verifying = false;
        _error = 'Incorrect code, please try again.';
        _clearBoxes();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e is ApiException ? e.message : 'Verification failed.';
        _clearBoxes();
      });
    }
  }

  void _resend() {
    if (_resendIn > 0) return;
    setState(() => _resendIn = 30);
    _startResendTimer();
    _clearBoxes();
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.email;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, viewInsets + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Verify your account',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'We sent a 6-digit code to',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              destination,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _otpBox(i)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
          if (_devCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dev mode — your code is $_devCode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: _sending ? 'Sending…' : 'Verify & Continue',
            isLoading: _verifying,
            onTap: _code.length == 6 ? _verify : null,
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: _resend,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Didn't get the code? ",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: _resendIn > 0
                          ? 'Resend in ${_resendIn}s'
                          : 'Resend now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _resendIn > 0
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int i) {
    final filled = _ctrls[i].text.isNotEmpty;
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: filled
              ? AppColors.cardGreenLight
              : const Color(0xFFEEEAF6),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: filled ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && i < _ctrls.length - 1) {
            _nodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _nodes[i - 1].requestFocus();
          }
          if (_code.length == 6) _verify();
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PHONE PREFIX FIELD
// ──────────────────────────────────────────────────────────────────────────

class _PhonePrefixField extends StatelessWidget {
  final TextEditingController controller;
  const _PhonePrefixField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '+977',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 16, color: AppColors.border),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [NepaliMobileFormatter()],
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: '98XXXXXXXX',
            ),
            style: _valueStyle,
          ),
        ),
      ],
    );
  }
}
