import 'package:flutter/material.dart';

import '../services/session_controller.dart';
import '../utils/role_navigation.dart';
import 'auth/login_screen.dart';

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

    final user = SessionController.instance.currentUser;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            user != null ? homeScreenForRole(user.role) : const LoginScreen(),
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
