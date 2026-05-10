import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'widgets/common/custom_button.dart';
import 'widgets/common/custom_input_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms & Privacy Policy')));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.darkGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
                    ),
                    const SizedBox(height: 24),
                    Text('Create your\naccount', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15, letterSpacing: -0.5)),
                    const SizedBox(height: 10),
                    Text('Join thousands managing their health queue smarter', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textOnDarkSecondary)),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CustomInputField(label: AppStrings.fullName, hint: 'Aarav Sharma', controller: _nameController, keyboardType: TextInputType.name, prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20), validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 20),
                  CustomInputField(label: AppStrings.email, hint: 'your@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress, prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20), validator: (v) { if (v == null || v.isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                  const SizedBox(height: 20),
                  CustomInputField(label: AppStrings.phone, hint: '+977 98XXXXXXXX', controller: _phoneController, keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 20), validator: (v) => (v == null || v.isEmpty) ? 'Phone is required' : null),
                  const SizedBox(height: 20),
                  CustomInputField(label: AppStrings.password, hint: '••••••••', controller: _passwordController, isPassword: true, prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20), validator: (v) { if (v == null || v.isEmpty) return 'Password is required'; if (v.length < 6) return 'Minimum 6 characters'; return null; }),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200), width: 22, height: 22,
                        decoration: BoxDecoration(color: _agreed ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: _agreed ? AppColors.primary : AppColors.border, width: 1.5)),
                        child: _agreed ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: RichText(text: TextSpan(style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ]))),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Create Account', onTap: _signup, isLoading: _isLoading),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(AppStrings.alreadyHaveAccount, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                    GhostButton(label: AppStrings.login, onTap: () => Navigator.pop(context), fontSize: 14),
                  ]),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}