import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

/// Gate doctor-appointment booking behind a complete profile (name, phone, date
/// of birth, gender). Online/reception tokens intentionally bypass this.
///
/// Returns true when the caller may proceed. Otherwise it shows a prompt to
/// finish the profile (routing to `/complete-profile` if the patient agrees) and
/// returns false so the caller aborts the booking navigation.
Future<bool> ensureProfileComplete(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final profile = auth.profile;
  if (profile != null && profile.isComplete) return true;

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Complete your profile first'),
      content: const Text(
        'Please add your name, phone number, date of birth and gender before '
        'booking a doctor appointment.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Complete now'),
        ),
      ],
    ),
  );

  if (go == true && context.mounted) {
    Navigator.pushNamed(context, '/complete-profile');
  }
  return false;
}
