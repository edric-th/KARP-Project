import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/validators.dart';
import 'package:frontend/constants/wait_format.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/services/queue_service.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';
import 'package:frontend/widgets/common/doctor_avatar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel? preselectedDoctor;
  const BookAppointmentScreen({super.key, this.preselectedDoctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  int _currentStep = 0;

  // Step 1
  AppointmentType _appointmentType = AppointmentType.newPatient;
  final _patientNameCtrl = TextEditingController();
  DateTime? _patientDob;
  final _patientPhoneCtrl = TextEditingController();
  String _patientGender = 'Male';

  int? get _patientAge {
    final dob = _patientDob;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age -= 1;
    }
    return age;
  }

  // Step 2
  HospitalModel? _selectedHospital;
  String? _selectedSpeciality;
  DoctorModel? _selectedDoctor;
  final _problemCtrl = TextEditingController();

  // Live per-doctor queue snapshots (real waiting count + ETA), keyed by id.
  final Map<String, QueueSummaryModel> _queueSummaries = {};
  final Set<String> _summaryLoading = {};

  /// Fetch live queue summaries for any of [ids] we don't already have.
  Future<void> _ensureSummaries(List<String> ids) async {
    final missing = ids
        .where((id) =>
            id.isNotEmpty &&
            !_queueSummaries.containsKey(id) &&
            !_summaryLoading.contains(id))
        .toList();
    if (missing.isEmpty) return;
    _summaryLoading.addAll(missing);
    try {
      final summaries =
          await context.read<QueueService>().summaryFor(missing);
      if (!mounted) return;
      setState(() {
        for (final s in summaries) {
          _queueSummaries[s.doctorId] = s;
        }
      });
    } catch (_) {
      // Leave unknown — cards fall back to a neutral "live…" state.
    } finally {
      _summaryLoading.removeAll(missing);
    }
  }

  // Learned per-type service minutes for a doctor (first_visit/follow_up/report).
  final Map<String, Map<String, double>> _typeAverages = {};
  final Set<String> _typeAvgLoading = {};

  Future<void> _ensureTypeAverages(String doctorId) async {
    if (doctorId.isEmpty ||
        _typeAverages.containsKey(doctorId) ||
        _typeAvgLoading.contains(doctorId)) {
      return;
    }
    _typeAvgLoading.add(doctorId);
    try {
      final status = await context.read<QueueService>().forDoctor(doctorId);
      if (!mounted) return;
      setState(() => _typeAverages[doctorId] = status.typeAverages);
    } catch (_) {
      // Leave unknown — type cards fall back to the default duration.
    } finally {
      _typeAvgLoading.remove(doctorId);
    }
  }

  String _backendType(AppointmentType t) {
    switch (t) {
      case AppointmentType.newPatient:
        return 'first_visit';
      case AppointmentType.followUp:
        return 'follow_up';
      case AppointmentType.reportShowing:
        return 'report';
    }
  }

  /// Dynamic "~N MIN" label from the selected doctor's learned per-type
  /// averages; null → the card falls back to the static default.
  String? _durationLabelFor(AppointmentType type) {
    final doctorId = _selectedDoctor?.id;
    if (doctorId == null) return null;
    final avg = _typeAverages[doctorId]?[_backendType(type)];
    if (avg == null || avg <= 0) return null;
    return '~${avg.round()} MIN';
  }

  // Step 3
  final _notesController = TextEditingController();
  bool _notifyMe = true;

  static const List<_SpecialityItem> _specialities = [
    _SpecialityItem('General Medicine', Icons.medical_services_outlined),
    _SpecialityItem('Cardiology', Icons.favorite_border_rounded),
    _SpecialityItem('Paediatrics', Icons.child_care_outlined),
    _SpecialityItem('Orthopaedics', Icons.accessibility_new_rounded),
    _SpecialityItem('ENT', Icons.hearing_rounded),
    _SpecialityItem('Dermatology', Icons.face_retouching_natural_rounded),
    _SpecialityItem('Gynaecology', Icons.female_rounded),
    _SpecialityItem('Neurology', Icons.psychology_outlined),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedDoctor != null) {
      _selectedDoctor = widget.preselectedDoctor;
      _selectedSpeciality = widget.preselectedDoctor!.specialty;
    }
    // Otherwise leave _selectedSpeciality null so the patient picks one
    // explicitly — choosing a hospital must NOT auto-select a speciality.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catalog = context.read<CatalogProvider>();
      await catalog.load();
      if (!mounted) return;
      setState(() {
        // Resolve hospital from the preselected doctor, else default to first.
        if (_selectedDoctor != null) {
          _selectedHospital = catalog.hospitalById(_selectedDoctor!.hospitalId);
        }
        _selectedHospital ??=
            catalog.hospitals.isNotEmpty ? catalog.hospitals.first : null;
      });
    });
  }

  List<HospitalModel> get _hospitals => context.read<CatalogProvider>().hospitals;

  /// Doctors at the selected hospital, narrowed by speciality when it matches.
  List<DoctorModel> get _doctorsForSelection {
    var docs = context.read<CatalogProvider>().doctors;
    if (_selectedHospital != null) {
      docs = docs.where((d) => d.hospitalId == _selectedHospital!.id).toList();
    }
    final spec = (_selectedSpeciality ?? '').toLowerCase();
    if (spec.isNotEmpty && spec != 'all') {
      final filtered = docs.where((d) {
        final s = d.specialty.toLowerCase();
        return s.isNotEmpty && (s.contains(spec) || spec.contains(s));
      }).toList();
      if (filtered.isNotEmpty) docs = filtered;
    }
    return docs;
  }

  /// Doctors at the currently selected hospital (used to derive specialities).
  List<DoctorModel> get _doctorsAtHospital {
    final docs = context.read<CatalogProvider>().doctors;
    if (_selectedHospital == null) return docs;
    return docs.where((d) => d.hospitalId == _selectedHospital!.id).toList();
  }

  /// Speciality chips derived from the REAL specialities at the selected
  /// hospital (so a preselected doctor's speciality always matches + highlights).
  /// Falls back to the curated list before the catalog has loaded.
  List<_SpecialityItem> get _specialityItems {
    final names = <String>{};
    for (final d in _doctorsAtHospital) {
      if (d.specialty.trim().isNotEmpty) names.add(d.specialty.trim());
    }
    if ((_selectedSpeciality ?? '').trim().isNotEmpty) {
      names.add(_selectedSpeciality!.trim());
    }
    if (names.isEmpty) return _specialities; // catalog not loaded yet
    final sorted = names.toList()..sort();
    return [for (final n in sorted) _SpecialityItem(n, _iconForSpeciality(n))];
  }

  IconData _iconForSpeciality(String s) {
    final t = s.toLowerCase();
    if (t.contains('cardio')) return Icons.favorite_border_rounded;
    if (t.contains('paed') || t.contains('pediatr') || t.contains('child')) {
      return Icons.child_care_outlined;
    }
    if (t.contains('ortho')) return Icons.accessibility_new_rounded;
    if (t.contains('ent') || t.contains('ear')) return Icons.hearing_rounded;
    if (t.contains('derma') || t.contains('skin')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (t.contains('gyn') || t.contains('obstet')) return Icons.female_rounded;
    if (t.contains('neuro')) return Icons.psychology_outlined;
    if (t.contains('eye') || t.contains('ophthal')) {
      return Icons.remove_red_eye_outlined;
    }
    if (t.contains('dent')) return Icons.medical_information_outlined;
    return Icons.medical_services_outlined; // general / fallback
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _problemCtrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0 && _appointmentType == AppointmentType.newPatient) {
      if (_patientNameCtrl.text.trim().isEmpty || _patientDob == null) {
        _snack('Please fill all new patient details.');
        return;
      }
      final phoneErr = validateNepaliPhone(_patientPhoneCtrl.text);
      if (phoneErr != null) {
        _snack(phoneErr);
        return;
      }
    }
    if (_currentStep == 1) {
      // With a preselected doctor the hospital/doctor are already fixed.
      if (widget.preselectedDoctor == null) {
        if (_selectedHospital == null) {
          _snack('Please choose a hospital.');
          return;
        }
        if (_selectedDoctor == null) {
          _snack('Please choose a doctor.');
          return;
        }
      }
      if (_problemCtrl.text.trim().isEmpty) {
        _snack('Please describe your specific problem.');
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickPatientDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _patientDob ?? DateTime(2000, 1, 1),
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
    if (picked != null) setState(() => _patientDob = picked);
  }

  void _proceedToPayment() {
    final doctor = _selectedDoctor;
    if (doctor == null) {
      _snack('Please choose a doctor before continuing.');
      return;
    }
    final profile = context.read<AuthProvider>().profile;
    final patientName = _appointmentType == AppointmentType.newPatient
        ? _patientNameCtrl.text.trim()
        : (profile?.displayName ?? '');
    final patientPhone = _appointmentType == AppointmentType.newPatient
        ? _patientPhoneCtrl.text.trim()
        : (profile?.phone ?? '');
    final patientAge = _appointmentType == AppointmentType.newPatient
        ? (_patientAge ?? 0)
        : (profile?.age ?? 0);

    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'doctor': doctor,
        'hospital': _selectedHospital,
        'appointmentType': _appointmentType,
        // Speciality may be unset if the user picked a doctor without tapping a
        // speciality chip — fall back to the doctor's own speciality.
        'speciality': _selectedSpeciality ?? doctor.specialty,
        'problem': _problemCtrl.text.trim(),
        'notes': _notesController.text.trim(),
        'patientName': patientName,
        'patientPhone': patientPhone,
        'patientAge': patientAge,
        'patientGender': _patientGender,
        // Real token is assigned by the backend after payment.
        'tokenNumber': 0,
        'notifyMe': _notifyMe,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: CustomAppBar(
        title: 'Book Appointment',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _StepperHeader(
                currentStep: _currentStep,
                labels: widget.preselectedDoctor != null
                    ? const ['APPOINTMENT\nTYPE', 'YOUR\nVISIT', 'CONFIRM']
                    : const ['APPOINTMENT\nTYPE', 'HOSPITAL\n& DOCTOR', 'CONFIRM'],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepBody(),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildStepOne();
      case 1:
        return _buildStepTwo();
      case 2:
        return _buildStepThree();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: APPOINTMENT TYPE + NEW PATIENT FORM ──────────────────────────

  Widget _buildStepOne() {
    final showForm = _appointmentType == AppointmentType.newPatient;
    final docId = _selectedDoctor?.id;
    if (docId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ensureTypeAverages(docId));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Choose Appointment Type'),
          const SizedBox(height: 6),
          Text(
            'Choose the type of appointment to proceed.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ...AppointmentType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AppointmentTypeCard(
                type: type,
                selected: _appointmentType == type,
                durationLabel: _durationLabelFor(type),
                onTap: () => setState(() => _appointmentType = type),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: showForm
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _NewPatientForm(
              nameCtrl: _patientNameCtrl,
              dob: _patientDob,
              age: _patientAge,
              onPickDob: _pickPatientDob,
              phoneCtrl: _patientPhoneCtrl,
              gender: _patientGender,
              onGenderChanged: (g) => setState(() => _patientGender = g),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2 (preselected doctor): read-only summary + problem ─────────────

  Widget _buildPreselectedVisit() {
    final doctor = widget.preselectedDoctor!;
    final hospitalName = _selectedHospital?.name ?? doctor.hospital;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your Doctor'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                DoctorAvatar(
                  photoUrl: doctor.photoUrl,
                  size: 48,
                  borderRadius: -1,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        [doctor.specialty, hospitalName]
                            .where((s) => s.isNotEmpty)
                            .join('  ·  '),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Describe Your Problem'),
          const SizedBox(height: 4),
          Text(
            'Briefly tell the doctor what you are experiencing.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _problemCtrl,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                hintText: 'e.g. Persistent headache for the last 3 days',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: HOSPITAL + DOCTOR + PROBLEM ──────────────────────────────────

  Widget _buildStepTwo() {
    // When opened from a specific doctor, skip the hospital/specialty/doctor
    // pickers entirely — show a read-only summary + the problem field.
    if (widget.preselectedDoctor != null) {
      return _buildPreselectedVisit();
    }
    final doctorsForSpeciality = _doctorsForSelection;
    final specialities = _specialityItems;

    // Pull real queue snapshots for the visible doctors (guarded; one batch call).
    final visibleIds = doctorsForSpeciality.map((d) => d.id).toList();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _ensureSummaries(visibleIds));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Choose Hospital'),
          const SizedBox(height: 12),
          _HospitalPickerField(
            hospital: _selectedHospital,
            onTap: _showHospitalPicker,
          ),
          const SizedBox(height: 22),
          _sectionTitle('Choose Speciality'),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: specialities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.3,
            ),
            itemBuilder: (_, i) {
              final s = specialities[i];
              final isSelected = _selectedSpeciality == s.label;
              return _SpecialityChip(
                item: s,
                selected: isSelected,
                onTap: () => setState(() {
                  _selectedSpeciality = s.label;
                  _selectedDoctor = null;
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showMoreSpecialities,
            child: Text(
              'More specialities +',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('Choose Doctor'),
          const SizedBox(height: 4),
          Text(
            'Available doctors in ${_selectedSpeciality ?? "selected speciality"}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (doctorsForSpeciality.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'No doctors available at this hospital for the selected speciality.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...doctorsForSpeciality.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DoctorPickCard(
                  doctor: doc,
                  summary: _queueSummaries[doc.id],
                  selected: _selectedDoctor?.id == doc.id,
                  onTap: () => setState(() => _selectedDoctor = doc),
                ),
              ),
            ),
          if (_selectedDoctor != null) ...[
            const SizedBox(height: 4),
            _buildTurnDisclaimer(_selectedDoctor!),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Describe Your Problem'),
          const SizedBox(height: 4),
          Text(
            'Briefly tell the doctor what you are experiencing.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _problemCtrl,
              maxLines: 4,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'e.g. Persistent chest pain for the past 3 days, mild fever...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: CONFIRM ──────────────────────────────────────────────────────

  Widget _buildStepThree() {
    final profile = context.read<AuthProvider>().profile;
    final selectedId = _selectedDoctor?.id;
    if (selectedId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ensureSummaries([selectedId]));
    }
    final patientName = _appointmentType == AppointmentType.newPatient
        ? (_patientNameCtrl.text.trim().isEmpty
            ? 'New Patient'
            : _patientNameCtrl.text.trim())
        : (profile?.displayName ?? 'You');
    final patientPhone = _appointmentType == AppointmentType.newPatient
        ? _patientPhoneCtrl.text.trim()
        : (profile?.phone ?? '');
    final patientAge = _appointmentType == AppointmentType.newPatient
        ? (_patientAge ?? 0)
        : (profile?.age ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BookingDetailsCard(
            appointmentType: _appointmentType,
            doctor: _selectedDoctor!,
            hospital:
                _selectedHospital?.name ?? _selectedDoctor!.hospital,
            speciality: _selectedSpeciality ?? _selectedDoctor!.specialty,
            problem: _problemCtrl.text.trim(),
            summary: _queueSummaries[_selectedDoctor!.id],
          ),
          const SizedBox(height: 18),
          _PatientDetailsCard(
            name: patientName,
            phone: patientPhone,
            age: patientAge,
            onEdit: () => setState(() => _currentStep = 0),
          ),
          const SizedBox(height: 22),
          Text(
            'Any extra notes for the doctor?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardGreenLight.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Write here... (optional)',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notify me when my turn is near',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _notifyMe,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => setState(() => _notifyMe = v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Alert me 2 tokens before',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ─── BOTTOM BAR ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    final isFirstStep = _currentStep == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLastStep)
            PrimaryButton(
              label: 'Continue to Payment',
              onTap: _proceedToPayment,
              icon: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            )
          else
            PrimaryButton(
              label: 'Next  →',
              onTap: _next,
            ),
          const SizedBox(height: 10),
          if (isLastStep)
            SecondaryButton(
              label: 'Cancel',
              borderColor: AppColors.border,
              onTap: () => Navigator.pop(context),
            )
          else
            TextButton(
              onPressed: isFirstStep ? () => Navigator.pop(context) : _back,
              child: Text(
                isFirstStep ? 'Cancel' : '← Back',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (isLastStep)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Token assigned after payment confirmation.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
    );
  }

  /// Disclaimer under the selected doctor: either "not available at the moment"
  /// (off-day / after closing) or the patient's expected turn time, computed
  /// from the live queue ETA on top of the doctor's opening time.
  Widget _buildTurnDisclaimer(DoctorModel doc) {
    final summary = _queueSummaries[doc.id];
    if (summary == null) {
      return _disclaimerBox(
        icon: Icons.access_time_rounded,
        color: AppColors.primary,
        title: 'Estimating your turn…',
        body: 'Fetching the live queue for Dr. ${doc.name}.',
      );
    }

    final now = DateTime.now();
    // Serving starts no earlier than the doctor's opening time (handles a
    // patient booking at 7 AM for a doctor whose hours begin at 10 AM, and
    // off-days → the next available session).
    final base = doc.effectiveStartFrom(now);
    final turn = base.add(Duration(minutes: summary.estimatedWaitMinutes));
    final arrive = turn.subtract(const Duration(minutes: 15));
    final timeFmt = DateFormat('h:mm a');
    final notOpenYet = doc.hasAvailability && base.isAfter(now);
    // Include the day when the next session is not today.
    final sameDay = base.year == now.year &&
        base.month == now.month &&
        base.day == now.day;
    final openLabel =
        sameDay ? timeFmt.format(base) : DateFormat('EEE, h:mm a').format(base);
    final tokenPos = summary.waitingCount + 1;

    if (notOpenYet) {
      return _disclaimerBox(
        icon: Icons.schedule_rounded,
        color: AppColors.primary,
        title:
            'Dr. ${doc.name} will be available from $openLabel, so as per your '
            'token number your turn will be around ${timeFmt.format(turn)}',
        body:
            'You will be token #$tokenPos with ${summary.waitingCount} ${summary.waitingCount == 1 ? 'patient' : 'patients'} ahead. '
            'Please reach the hospital about 15 minutes before your turn (by ${timeFmt.format(arrive)}).',
      );
    }

    return _disclaimerBox(
      icon: Icons.schedule_rounded,
      color: AppColors.primary,
      title:
          'According to your token number, your turn will be around ${timeFmt.format(turn)}',
      body:
          'You will be token #$tokenPos with ${summary.waitingCount} ${summary.waitingCount == 1 ? 'patient' : 'patients'} ahead. '
          'Please be at the hospital 15 minutes before your turn (by ${timeFmt.format(arrive)}).',
    );
  }

  Widget _disclaimerBox({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color == AppColors.error
                        ? AppColors.error
                        : AppColors.primaryDark,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

  void _showHospitalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Choose Hospital',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _hospitals.length,
                itemBuilder: (_, i) {
                  final h = _hospitals[i];
                  final isSelected = _selectedHospital?.id == h.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHospital = h;
                        _selectedDoctor = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cardGreenLight
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cardGreenMedium,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.name,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${h.address} • ${h.distance}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSpecialities() {
    final more = ['Oncology', 'Urology', 'Psychiatry', 'Ophthalmology'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
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
              'More Specialities',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...more.map(
              (m) => ListTile(
                onTap: () {
                  setState(() {
                    _selectedSpeciality = m;
                    _selectedDoctor = null;
                  });
                  Navigator.pop(ctx);
                },
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cardGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  m,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Icon(
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

// ─── STEPPER HEADER ─────────────────────────────────────────────────────────

class _StepperHeader extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  const _StepperHeader({
    required this.currentStep,
    this.labels = const ['APPOINTMENT\nTYPE', 'HOSPITAL\n& DOCTOR', 'CONFIRM'],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (i) {
        final isDone = i <= currentStep;
        final isLast = i == 2;
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
    );
  }
}

// ─── APPOINTMENT TYPE CARD ──────────────────────────────────────────────────

class _AppointmentTypeCard extends StatelessWidget {
  final AppointmentType type;
  final bool selected;
  final VoidCallback onTap;
  final String? durationLabel;
  const _AppointmentTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    this.durationLabel,
  });

  IconData _iconFor(AppointmentType t) {
    switch (t) {
      case AppointmentType.newPatient:
        return Icons.person_add_alt_1_rounded;
      case AppointmentType.reportShowing:
        return Icons.description_outlined;
      case AppointmentType.followUp:
        return Icons.assignment_turned_in_outlined;
    }
  }

  Color _badgeColorFor(AppointmentType t) {
    switch (t) {
      case AppointmentType.newPatient:
        return const Color(0xFFFDE0C4);
      case AppointmentType.reportShowing:
        return AppColors.cardGreenMedium;
      case AppointmentType.followUp:
        return AppColors.cardGreenMedium;
    }
  }

  Color _badgeTextFor(AppointmentType t) {
    switch (t) {
      case AppointmentType.newPatient:
        return const Color(0xFF8A4B14);
      case AppointmentType.reportShowing:
        return AppColors.primaryDark;
      case AppointmentType.followUp:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.cardGreenLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected ? AppColors.cardShadow : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardGreenMedium,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            _iconFor(type),
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      type.label,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _badgeColorFor(type),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      durationLabel ?? type.duration,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _badgeTextFor(type),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                type.label,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                type.description,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: selected
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── NEW PATIENT FORM ───────────────────────────────────────────────────────

class _NewPatientForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final DateTime? dob;
  final int? age;
  final VoidCallback onPickDob;
  final TextEditingController phoneCtrl;
  final String gender;
  final ValueChanged<String> onGenderChanged;

  const _NewPatientForm({
    required this.nameCtrl,
    required this.dob,
    required this.age,
    required this.onPickDob,
    required this.phoneCtrl,
    required this.gender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardGreenBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cardGreenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_ind_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'New Patient Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'We will register this patient before booking.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _FormLabel('FULL NAME'),
          const SizedBox(height: 6),
          _FormField(
            controller: nameCtrl,
            hint: 'e.g. Aryan Thakuri',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel('DATE OF BIRTH'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onPickDob,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 17,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dob == null
                                    ? 'Select'
                                    : DateFormat('d MMM y').format(dob!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: dob == null
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel('AGE'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardGreenLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardGreenBorder),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_outlined,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            age == null ? '—' : '$age yrs',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: age == null
                                  ? AppColors.textMuted
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormLabel('GENDER'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: ['Male', 'Female', 'Other']
                  .map(
                    (g) => Expanded(
                      child: GestureDetector(
                        onTap: () => onGenderChanged(g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: gender == g
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            g,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: gender == g
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _FormLabel('PHONE'),
          const SizedBox(height: 6),
          _FormField(
            controller: phoneCtrl,
            hint: '98XXXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [NepaliMobileFormatter()],
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.7,
        ),
      );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── HOSPITAL PICKER FIELD ──────────────────────────────────────────────────

class _HospitalPickerField extends StatelessWidget {
  final HospitalModel? hospital;
  final VoidCallback onTap;
  const _HospitalPickerField({required this.hospital, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hospital != null ? AppColors.primary : AppColors.border,
            width: hospital != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hospital != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital!.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${hospital!.address} • ${hospital!.distance}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Tap to choose a hospital',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SPECIALITY CHIP ─────────────────────────────────────────────────────────

class _SpecialityItem {
  final String label;
  final IconData icon;
  const _SpecialityItem(this.label, this.icon);
}

class _SpecialityChip extends StatelessWidget {
  final _SpecialityItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SpecialityChip({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.cardGreenMedium : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DOCTOR PICK CARD ────────────────────────────────────────────────────────

class _DoctorPickCard extends StatelessWidget {
  final DoctorModel doctor;
  final QueueSummaryModel? summary;
  final bool selected;
  final VoidCallback onTap;
  const _DoctorPickCard({
    required this.doctor,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final queueLabel = s == null
        ? "TODAY'S QUEUE: live…"
        : "TODAY'S QUEUE: ${s.waitingCount} ${s.waitingCount == 1 ? 'PATIENT' : 'PATIENTS'}";
    final waitLabel = s == null ? '—' : formatWait(s.estimatedWaitMinutes);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppColors.cardShadow : [],
        ),
        child: Column(
          children: [
            Row(
              children: [
                DoctorAvatar(
                  photoUrl: doctor.photoUrl,
                  size: 44,
                  borderRadius: -1,
                  iconSize: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE0C4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFE4A24A),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  doctor.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF8A4B14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doctor.specialty}, ${doctor.experience} yrs exp. • ${doctor.fee}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (doctor.availabilityLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              doctor.availableNow(DateTime.now())
                                  ? Icons.schedule_rounded
                                  : Icons.event_busy_rounded,
                              size: 12,
                              color: doctor.availableNow(DateTime.now())
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                doctor.availableNow(DateTime.now())
                                    ? doctor.availabilityLabel
                                    : 'Not available now • ${doctor.availabilityLabel}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: doctor.availableNow(DateTime.now())
                                      ? AppColors.textSecondary
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  selected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  queueLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waitLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOOKING DETAILS CARD ────────────────────────────────────────────────────

class _BookingDetailsCard extends StatelessWidget {
  final AppointmentType appointmentType;
  final DoctorModel doctor;
  final String hospital;
  final String speciality;
  final String problem;
  final QueueSummaryModel? summary;
  const _BookingDetailsCard({
    required this.appointmentType,
    required this.doctor,
    required this.hospital,
    required this.speciality,
    required this.problem,
    required this.summary,
  });

  String _formattedDate() {
    final now = DateTime.now();
    return 'Today, ${DateFormat('d MMMM yyyy').format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final positionLabel =
        s == null ? 'Calculating…' : '#${s.waitingCount + 1} in line (approx)';
    final waitLabel = s == null ? 'Calculating…' : formatWait(s.estimatedWaitMinutes);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
        color: AppColors.cardGreenLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardGreenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Appointment type:', appointmentType.label),
          _detailRow('Doctor:', doctor.name),
          _detailRow('Speciality:', speciality),
          _detailRow('Hospital:', hospital),
          _detailRow('Date:', _formattedDate()),
          _detailRow(
            'Estimated queue position:',
            positionLabel,
            valueColor: AppColors.primaryDark,
          ),
          _detailRow('Consultation fee:', doctor.fee),
          if (problem.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    problem,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          _detailRow(
            'Estimated wait:',
            waitLabel,
            valueColor: AppColors.error,
            withDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool withDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PATIENT DETAILS CARD ────────────────────────────────────────────────────

class _PatientDetailsCard extends StatelessWidget {
  final String name;
  final String phone;
  final int age;
  final VoidCallback onEdit;
  const _PatientDetailsCard({
    required this.name,
    required this.phone,
    required this.age,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Patient Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label('NAME'),
          const SizedBox(height: 2),
          _value(name),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('PHONE'),
                    const SizedBox(height: 2),
                    _value(phone.isEmpty ? '—' : phone),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('AGE'),
                    const SizedBox(height: 2),
                    _value('$age'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      );

  Widget _value(String t) => Text(
        t,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );
}
