import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/validators.dart';
import 'package:frontend/constants/wait_format.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/queue_service.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';
import 'package:frontend/widgets/common/doctor_avatar.dart';

/// Reserve an ONLINE TOKEN ONLY — a queue ticket for patients who want to grab
/// their number online but complete the appointment physically at reception.
/// No payment is taken here.
class OnlineTokenScreen extends StatefulWidget {
  const OnlineTokenScreen({super.key});

  @override
  State<OnlineTokenScreen> createState() => _OnlineTokenScreenState();
}

class _OnlineTokenScreenState extends State<OnlineTokenScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  HospitalModel? _hospital;
  DoctorModel? _doctor;
  bool _submitting = false;

  final Map<String, QueueSummaryModel> _summaries = {};
  final Set<String> _loadingSummaries = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = context.read<AuthProvider>().profile;
      _nameCtrl.text = profile?.displayName ?? '';
      _phoneCtrl.text = profile?.phone ?? '';
      final catalog = context.read<CatalogProvider>();
      await catalog.load();
      if (!mounted) return;
      setState(() {
        _hospital = catalog.hospitals.isNotEmpty ? catalog.hospitals.first : null;
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  List<DoctorModel> get _doctors {
    final catalog = context.read<CatalogProvider>();
    if (_hospital == null) return catalog.doctors;
    return catalog.doctorsForHospital(_hospital!.id);
  }

  Future<void> _ensureSummaries(List<String> ids) async {
    final missing = ids
        .where((id) =>
            id.isNotEmpty &&
            !_summaries.containsKey(id) &&
            !_loadingSummaries.contains(id))
        .toList();
    if (missing.isEmpty) return;
    _loadingSummaries.addAll(missing);
    try {
      final res = await context.read<QueueService>().summaryFor(missing);
      if (!mounted) return;
      setState(() {
        for (final s in res) {
          _summaries[s.doctorId] = s;
        }
      });
    } catch (_) {
      // Leave unknown — the disclaimer falls back to an "estimating" state.
    } finally {
      _loadingSummaries.removeAll(missing);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _reserve() async {
    final doctor = _doctor;
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter the patient name.');
      return;
    }
    final phoneErr = validateNepaliPhone(_phoneCtrl.text);
    if (phoneErr != null) {
      _snack(phoneErr);
      return;
    }
    if (doctor == null) {
      _snack('Please choose a doctor.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final booking = await context.read<BookingsProvider>().create(
            doctorId: doctor.id,
            patientName: _nameCtrl.text.trim(),
            patientPhone: _phoneCtrl.text.trim(),
            bookingType: 'first_visit',
            bookingSource: 'online_token',
          );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pushReplacementNamed(
        context,
        '/booking-success',
        arguments: {
          'doctor': doctor,
          'speciality': doctor.specialty,
          'tokenNumber': booking.tokenNumber,
          'estimatedWaitMinutes': booking.estimatedWaitMinutes,
          'expectedCallAt': booking.expectedCallAt,
          'notifyMe': true,
          'patientName': _nameCtrl.text.trim(),
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('Could not reserve a token. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final doctors = _doctors;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureSummaries(doctors.map((d) => d.id).toList()));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Get Online Token', showBack: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _infoBanner(),
                  const SizedBox(height: 18),
                  _sectionTitle('Patient Details'),
                  const SizedBox(height: 10),
                  _patientCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('Choose Hospital'),
                  const SizedBox(height: 10),
                  _hospitalField(catalog),
                  const SizedBox(height: 20),
                  _sectionTitle('Choose Doctor'),
                  const SizedBox(height: 10),
                  if (catalog.loading && doctors.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (doctors.isEmpty)
                    _emptyDoctors()
                  else
                    ...doctors.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _doctorTile(d),
                        )),
                  if (_doctor != null) ...[
                    const SizedBox(height: 6),
                    _turnDisclaimer(_doctor!),
                  ],
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      );

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardGreenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGreenBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online token only',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reserve your queue number now — no payment needed. '
                  'Complete the appointment at the hospital reception.',
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

  Widget _patientCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _inputRow(
            icon: Icons.person_outline_rounded,
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Patient full name',
              ),
              style: _valueStyle,
            ),
          ),
          const Divider(height: 22, color: AppColors.divider),
          _inputRow(
            icon: Icons.phone_outlined,
            child: TextField(
              controller: _phoneCtrl,
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
      ),
    );
  }

  Widget _inputRow({required IconData icon, required Widget child}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  static const _valueStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  Widget _hospitalField(CatalogProvider catalog) {
    return GestureDetector(
      onTap: () => _showHospitalPicker(catalog),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hospital != null ? AppColors.primary : AppColors.border,
            width: _hospital != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_hospital_rounded,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hospital?.name ?? 'Tap to choose a hospital',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _hospital != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showHospitalPicker(CatalogProvider catalog) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            for (final h in catalog.hospitals)
              ListTile(
                onTap: () {
                  setState(() {
                    _hospital = h;
                    _doctor = null;
                  });
                  Navigator.pop(ctx);
                },
                leading: const Icon(Icons.local_hospital_rounded,
                    color: AppColors.primary),
                title: Text(
                  h.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: h.address.isEmpty
                    ? null
                    : Text(h.address,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _hospital?.id == h.id
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyDoctors() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No doctors available at this hospital yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _doctorTile(DoctorModel d) {
    final selected = _doctor?.id == d.id;
    final s = _summaries[d.id];
    final waitLabel = s == null ? 'live…' : formatWait(s.estimatedWaitMinutes);
    return GestureDetector(
      onTap: () => setState(() => _doctor = d),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            DoctorAvatar(
              photoUrl: d.photoUrl,
              size: 44,
              borderRadius: -1,
              iconSize: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (d.availabilityLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      d.availableNow(DateTime.now())
                          ? d.availabilityLabel
                          : 'Closed now • ${d.availabilityLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d.availableNow(DateTime.now())
                            ? AppColors.textSecondary
                            : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  waitLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${s?.waitingCount ?? 0} ahead',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnDisclaimer(DoctorModel doc) {
    final s = _summaries[doc.id];
    final now = DateTime.now();
    final base = doc.effectiveStartFrom(now);
    final fmt = DateFormat('h:mm a');
    if (s == null) {
      return _disclaimerBox(
        'Estimating your turn…',
        'Fetching the live queue for ${doc.name}.',
      );
    }
    final turn = base.add(Duration(minutes: s.estimatedWaitMinutes));
    final notOpenYet = doc.hasAvailability && base.isAfter(now);
    final tokenPos = s.waitingCount + 1;
    final title = notOpenYet
        ? '${doc.name} will be available from ${fmt.format(base)}, so as per your token your turn will be around ${fmt.format(turn)}'
        : 'According to your token number, your turn will be around ${fmt.format(turn)}';
    return _disclaimerBox(
      title,
      'You will be token #$tokenPos with ${s.waitingCount} ${s.waitingCount == 1 ? 'patient' : 'patients'} ahead.',
    );
  }

  Widget _disclaimerBox(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
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

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
      child: PrimaryButton(
        label: 'Reserve Online Token',
        isLoading: _submitting,
        onTap: _reserve,
        icon: const Icon(Icons.confirmation_number_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}
