import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/common/custom_app_bar.dart';
import 'package:frontend/widgets/common/custom_button.dart';

enum PaymentMethod { esewa, khalti, imepay, bank, cash }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.imepay:
        return 'IME Pay';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Pay at Hospital';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.esewa:
        return 'Pay securely with your eSewa wallet';
      case PaymentMethod.khalti:
        return 'Pay securely with your Khalti wallet';
      case PaymentMethod.imepay:
        return 'Pay via IME Pay digital wallet';
      case PaymentMethod.bank:
        return 'Connect Card, NIC ASIA, NMB, Global IME and more';
      case PaymentMethod.cash:
        return 'Pay at the hospital counter before consultation';
    }
  }

  Color get brandColor {
    switch (this) {
      case PaymentMethod.esewa:
        return const Color(0xFF60BB46);
      case PaymentMethod.khalti:
        return const Color(0xFF5C2D91);
      case PaymentMethod.imepay:
        return const Color(0xFFD7252C);
      case PaymentMethod.bank:
        return const Color(0xFF1F4E8C);
      case PaymentMethod.cash:
        return AppColors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.esewa:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.khalti:
        return Icons.wallet_rounded;
      case PaymentMethod.imepay:
        return Icons.payments_rounded;
      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
      case PaymentMethod.cash:
        return Icons.attach_money_rounded;
    }
  }
}

class PaymentScreen extends StatefulWidget {
  final DoctorModel doctor;
  final HospitalModel? hospital;
  final AppointmentType appointmentType;
  final String speciality;
  final String problem;
  final String notes;
  final String patientName;
  final String patientPhone;
  final int patientAge;
  final String patientGender;
  final int tokenNumber;
  final bool notifyMe;

  const PaymentScreen({
    super.key,
    required this.doctor,
    required this.hospital,
    required this.appointmentType,
    required this.speciality,
    required this.problem,
    required this.notes,
    required this.patientName,
    required this.patientPhone,
    required this.patientAge,
    required this.patientGender,
    required this.tokenNumber,
    required this.notifyMe,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.esewa;
  bool _isPaying = false;

  double get _consultationFee {
    final raw = widget.doctor.fee.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(raw) ?? 800;
  }

  double get _serviceFee => 50;
  double get _bookingCharge => 25;
  double get _total => _consultationFee + _serviceFee + _bookingCharge;

  String _fmt(double v) => 'NPR ${v.toStringAsFixed(0)}';

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isPaying = false);

    _showPaymentSuccessSheet();
  }

  void _showPaymentSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.primaryShadow,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Payment Successful',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_fmt(_total)} paid via ${_method.label}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Continue',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  '/booking-success',
                  arguments: {
                    'doctor': widget.doctor,
                    'appointmentType': widget.appointmentType,
                    'speciality': widget.speciality,
                    'tokenNumber': widget.tokenNumber,
                    'notifyMe': widget.notifyMe,
                    'patientName': widget.patientName,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const CustomAppBar(title: 'Payment'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(
                      doctor: widget.doctor,
                      speciality: widget.speciality,
                      hospital:
                          widget.hospital?.name ?? widget.doctor.hospital,
                      patientName: widget.patientName,
                      consultationFee: _consultationFee,
                      serviceFee: _serviceFee,
                      bookingCharge: _bookingCharge,
                      total: _total,
                      fmt: _fmt,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Choose Payment Method',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All transactions are encrypted and secure.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...PaymentMethod.values.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PaymentMethodTile(
                          method: m,
                          selected: _method == m,
                          onTap: () => setState(() => _method = m),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Your payment is protected and refundable until consultation begins.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Payable',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(_total),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: 'Pay & Book',
                  isLoading: _isPaying,
                  onTap: _pay,
                  icon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SUMMARY CARD ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final DoctorModel doctor;
  final String speciality;
  final String hospital;
  final String patientName;
  final double consultationFee;
  final double serviceFee;
  final double bookingCharge;
  final double total;
  final String Function(double) fmt;

  const _SummaryCard({
    required this.doctor,
    required this.speciality,
    required this.hospital,
    required this.patientName,
    required this.consultationFee,
    required this.serviceFee,
    required this.bookingCharge,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreenLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardGreenBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _row('Patient', patientName),
          _row('Doctor', doctor.name),
          _row('Speciality', speciality),
          _row('Hospital', hospital),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.cardGreenBorder),
          const SizedBox(height: 10),
          _amountRow('Consultation fee', fmt(consultationFee)),
          _amountRow('Service charge', fmt(serviceFee)),
          _amountRow('Booking charge', fmt(bookingCharge)),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.cardGreenBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Text(
                fmt(total),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PAYMENT METHOD TILE ────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: method.brandColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: method.brandColor.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                method.icon,
                color: method.brandColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
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
                  color: selected ? AppColors.primary : AppColors.border,
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
    );
  }
}
