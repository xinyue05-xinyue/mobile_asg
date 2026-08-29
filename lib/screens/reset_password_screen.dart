import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/remote/auth_error_message.dart';
import '../data/remote/supabase_service.dart';
import '../widgets/my_darah_brand.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool hidden = true;
  bool saving = false;

  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use at least 6 characters.')),
      );
      return;
    }
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    final client = SupabaseService.client;
    if (client == null) return;
    setState(() => saving = true);
    try {
      await client.auth.updateUser(UserAttributes(password: password.text));
      await client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in again.')),
      );
      widget.onComplete();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create new password')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: MyDarahMark(size: 82)),
        const SizedBox(height: 20),
        Text(
          'Secure your account',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a new password with at least 6 characters.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        TextField(
          controller: password,
          obscureText: hidden,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => hidden = !hidden),
              icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirm,
          obscureText: hidden,
          onSubmitted: (_) => save(),
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update password'),
        ),
      ],
    ),
  );
}
