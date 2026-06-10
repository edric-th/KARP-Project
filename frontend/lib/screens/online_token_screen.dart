import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/constants/validators.dart';
import 'package:frontend/constants/wait_format.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/models/queue_status_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/bookings_provider.dart';
import 'package:frontend/providers/catalog_provider.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/queue_service.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';

/// Reserve an ONLINE TOKEN ONLY — a hospital reception-desk queue ticket for
/// patients who want to grab their number online and complete the appointment
/// physically at reception. This is intentionally NOT linked to any doctor and
/// takes no payment — booking a doctor appointment is a separate flow.
class OnlineTokenScreen extends StatefulWidget {
  const OnlineTokenScreen({super.key});

  @override
  State<OnlineTokenScreen> createState() => _OnlineTokenScreenState();
}

class _OnlineTokenScreenState extends State<OnlineTokenScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  HospitalModel? _hospital;
  bool _submitting = false;

  // Live reception-queue snapshot per hospital (now-serving + waiting count).
  final Map<String, QueueStatusModel> _receptions = {};
  final Set<String> _loading = {};

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
        _hospital =
            catalog.hospitals.isNotEmpty ? catalog.hospitals.first : null;
      });
      if (_hospital != null) _ensureReception(_hospital!.id);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureReception(String hospitalId) async {
    if (hospitalId.isEmpty ||
        _receptions.containsKey(hospitalId) ||
        _loading.contains(hospitalId)) {
      return;
    }
    _loading.add(hospitalId);
    try {
      final status = await context.read<QueueService>().forReception(hospitalId);
      if (!mounted) return;
      setState(() => _receptions[hospitalId] = status);
    } catch (_) {
      // Leave unknown — the disclaimer falls back to an "estimating" state.
    } finally {
      _loading.remove(hospitalId);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _reserve() async {
    final hospital = _hospital;
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter the patient name.');
      return;
    }
    final phoneErr = validateNepaliPhone(_phoneCtrl.text);
    if (phoneErr != null) {
      _snack(phoneErr);
      return;
    }
    if (hospital == null) {
      _snack('Please choose a hospital.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final booking = await context.read<BookingsProvider>().createReceptionToken(
            hospitalId: hospital.id,
            patientName: _nameCtrl.text.trim(),
            patientPhone: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pushReplacementNamed(
        context,
        '/booking-success',
        arguments: {
          'speciality': 'Reception Token',
          'hospitalName': hospital.name,
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
                  if (_hospital != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Reception Queue'),
                    const SizedBox(height: 10),
                    _receptionDisclaimer(_hospital!),
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
                  'Reserve your reception queue number now — no doctor or '
                  'payment needed. Complete the appointment at the hospital '
                  'reception desk.',
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
                  setState(() => _hospital = h);
                  Navigator.pop(ctx);
                  _ensureReception(h.id);
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

  /// Estimated wait (minutes) for a brand-new walk-in joining this reception
  /// queue: the last waiting person's ETA plus one more handling slot, or just
  /// the remaining slot when nobody is waiting.
  int _newWalkInWait(QueueStatusModel s) {
    final per = s.avgServiceMinutes.round();
    if (s.waiting.isNotEmpty) {
      final last = s.waiting.last.estimatedWaitMinutes ?? 0;
      return last + per;
    }
    return s.nowServing != null ? per : 0;
  }

  Widget _receptionDisclaimer(HospitalModel hospital) {
    final s = _receptions[hospital.id];
    if (s == null) {
      return _disclaimerBox(
        'Estimating your turn…',
        'Fetching the live reception queue for ${hospital.name}.',
        serving: null,
      );
    }
    final now = DateTime.now();
    final wait = _newWalkInWait(s);
    final turn = now.add(Duration(minutes: wait));
    final fmt = DateFormat('h:mm a');
    final ahead = s.waitingCount + (s.nowServing != null ? 1 : 0);
    return _disclaimerBox(
      'As per the reception queue, your turn will be around '
      '${fmt.format(turn)} (about ${formatWait(wait)} from now).',
      ahead == 0
          ? 'The reception desk is free right now — you should be seen shortly.'
          : 'There ${ahead == 1 ? 'is' : 'are'} $ahead ${ahead == 1 ? 'person' : 'people'} ahead of you in the reception queue.',
      serving: s.nowServing?.tokenNumber,
    );
  }

  Widget _disclaimerBox(String title, String body, {int? serving}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.primary, size: 20),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Now serving',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  serving == null
                      ? '—'
                      : '#${serving.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
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
