import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          if (isWide) {
            return Row(
              children: const [
                Expanded(flex: 5, child: _LeftPanel()),
                Expanded(flex: 6, child: _RightPanel()),
              ],
            );
          }

          // Mobile / narrow: stack
          return const Column(
            children: [
              Expanded(flex: 4, child: _RightPanel()),
              Expanded(flex: 6, child: _LeftPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _LeftPanel extends StatefulWidget {
  const _LeftPanel();

  @override
  State<_LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<_LeftPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Efetue o Login na sua conta',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                  onPressed: () async {
                    final email = _email.text.trim();
                    final password = _password.text;

                    try {
                      await Supabase.instance.client.auth.signInWithPassword(
                        email: email,
                        password: password,
                      );

                      if (!context.mounted) return;

                      context.go(AppRoutes.dashboard);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro no login: $e')),
                      );
                    }
                  },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB1121D), // vermelho corporate
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final email = _email.text.trim();

                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your email first')),
                          );
                          return;
                        }

                        try {
                          await Supabase.instance.client.auth.resetPasswordForEmail(
                            email,
                            redirectTo: 'http://localhost:63083/reset-password',
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error sending email: $e')),
                          );
                        }
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB1121D),
            Color(0xFF7A0F1D),
            Color(0xFF2A0E1C),
            Color(0xFF0B1220),
          ],
          stops: [0.0, 0.30, 0.65, 1.0],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Image.asset(
            'assets/images/logo_white.png',
            fit: BoxFit.contain,
            // se precisares limitar tamanho:
            // width: 420,
          ),
        ),
      ),
    );
  }
}
