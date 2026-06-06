import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_widgets.dart';
import 'supabase_service.dart';

class LoginPage extends StatefulWidget {
  final SupabaseService service;
  final Future<void> Function() onLoggedIn;

  const LoginPage({
    super.key,
    required this.service,
    required this.onLoggedIn,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool signupMode = false;

  Future<void> submit() async {
    setState(() => loading = true);

    try {
      if (signupMode) {
        await widget.service.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await widget.service.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      await widget.onLoggedIn();
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final cardWidth = math.min(440.0, screen.width - 28);
    final cardPadding = screen.width < 520 ? 18.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screen.width < 520 ? 14 : 20),
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.all(cardPadding),
              decoration: cardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Smart Account Manager',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: screen.width < 520 ? 21 : 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Supabase DSR Cloud Version',
                style: TextStyle(color: Color(0xff6b7280)),
              ),
              const SizedBox(height: 18),
              textInput(label: 'Email', controller: emailController),
              textInput(label: 'Password', controller: passwordController, obscure: true),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: primaryButton(
                  loading
                      ? 'Please wait...'
                      : signupMode
                          ? 'Create Account'
                          : 'Login',
                  signupMode ? Icons.person_add_rounded : Icons.login_rounded,
                  loading ? () {} : submit,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => signupMode = !signupMode),
                child: Text(signupMode ? 'Already have account? Login' : 'Create new account'),
              ),
              const SizedBox(height: 8),
              const Text(
                'For easiest testing, disable email confirmation in Supabase Auth settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff6b7280), fontSize: 12),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
