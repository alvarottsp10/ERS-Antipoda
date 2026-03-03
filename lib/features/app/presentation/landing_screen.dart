import 'package:flutter/material.dart';
import 'app_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      child: _LandingBody(),
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'Conteúdo (Dashboard/landing) aqui',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}