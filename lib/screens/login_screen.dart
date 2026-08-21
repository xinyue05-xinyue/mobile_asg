import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/remote/auth_repository.dart';
import '../data/remote/supabase_service.dart';
import '../models/user_role.dart';
import 'registration_screen.dart';
import 'role_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      var role = UserRole.donor;
      final client = SupabaseService.client;
      if (client != null) {
        role = await AuthRepository(client).signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
      if (!mounted) return;
      final destination = homeForRole(role);
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bloodtype, size: 90, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              onSubmitted: (_) => login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                  icon: Icon(
                    hidePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 17)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
              child: const Text('Create a donor account'),
            ),
            if (!SupabaseService.isConfigured) ...[
              const SizedBox(height: 16),
              const Text(
                'Local demo mode: Supabase is not configured yet.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
