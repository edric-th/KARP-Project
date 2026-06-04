import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/widgets/common/custom_button.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String name;
  final String bloodGroup;

  const RegistrationSuccessScreen({
    super.key,
    required this.name,
    required this.bloodGroup,
  });

  String _firstName() {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'there' : parts.first;
  }

  String get _patientId {
    final now = DateTime.now();
    final suffix =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'MPC-${now.year}-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 18),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (ctx, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardGreenBorder,
                      width: 6,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.primaryShadow,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Registration Complete!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to MeroPalo Care, ${_firstName()}!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              _AccountSummaryCard(
                patientId: _patientId,
                name: name,
                bloodGroup: bloodGroup,
                primaryDoctor: 'Dr. Sarah Jenkins',
                emergencyContact: '+977 980-000-0000 (Family)',
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Go to Home',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'View My Profile',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                  arguments: 3,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your medical data is encrypted and ISO 27001 protected.',
                      textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final String patientId;
  final String name;
  final String bloodGroup;
  final String primaryDoctor;
  final String emergencyContact;
  const _AccountSummaryCard({
    required this.patientId,
    required this.name,
    required this.bloodGroup,
    required this.primaryDoctor,
    required this.emergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ACCOUNT SUMMARY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardGreenMedium,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          _SummaryRow(label: 'PATIENT ID', value: patientId),
          const SizedBox(height: 12),
          _SummaryRow(label: 'FULL NAME', value: name),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'BLOOD GROUP',
            value: bloodGroup,
            valueColor: AppColors.primaryDark,
            isBold: true,
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'PRIMARY DOCTOR', value: primaryDoctor),
          const SizedBox(height: 12),
          _SummaryRow(label: 'EMERGENCY CONTACT', value: emergencyContact),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isBold ? 16 : 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
