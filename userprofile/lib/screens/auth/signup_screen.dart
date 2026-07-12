import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/repository_provider.dart';
import '../../services/session_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/disabled_social_button.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthRepository _authRepository = RepositoryProvider.auth;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Devam etmek için kullanım koşullarını kabul etmelisin.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _authRepository.register(
      nickname: _nicknameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success && result.user != null) {
      SessionController.instance.setUser(result.user!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Hesap oluştur',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'YemekYemek? topluluğuna katıl',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname (@kullaniciadi)',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: Validators.nickname,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Eşsizdir, kimseyle aynı olamaz ve profilinde "@" ile görünür.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı adı (görünen isim)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.username,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Diğer kullanıcılarla aynı olabilir, istediğin zaman değiştirebilirsin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'En az 8 karakter, 1 büyük harf, 1 küçük harf ve 1 rakam içermelidir.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre (tekrar)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) => Validators.confirmPassword(
                      v, _passwordController.text),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Kullanım koşullarını ve gizlilik politikasını kabul ediyorum.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSignUp,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kayıt Ol'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'veya',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),
                const DisabledSocialButton(
                  label: 'Google ile bağlan',
                  icon: Icons.g_mobiledata,
                ),
                const SizedBox(height: 12),
                const DisabledSocialButton(
                  label: 'Apple ile bağlan',
                  icon: Icons.apple,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
