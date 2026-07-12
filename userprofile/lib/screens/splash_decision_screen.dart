import 'package:flutter/material.dart';

import '../services/session_controller.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

/// Uygulama açıldığında session.txt kontrol edilir; kayıtlı bir oturum
/// varsa doğrudan HomeScreen'e, yoksa LoginScreen'e yönlendirilir.
class SplashDecisionScreen extends StatefulWidget {
  const SplashDecisionScreen({super.key});

  @override
  State<SplashDecisionScreen> createState() => _SplashDecisionScreenState();
}

class _SplashDecisionScreenState extends State<SplashDecisionScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await SessionController.instance.restoreSession();
    if (!mounted) return;

    final loggedIn = SessionController.instance.currentUser != null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
