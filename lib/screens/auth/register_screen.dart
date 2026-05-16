import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../database/database_helper.dart';
import '../../core/engame_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  String? _selectedQuestion;

  static const List<String> _questions = [
    'Annenizin kızlık soyadı nedir?',
    'İlk evcil hayvanınızın adı nedir?',
    'Doğduğunuz şehir neresi?',
    'İlkokul öğretmeninizin adı nedir?',
    'En sevdiğiniz yemek nedir?',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Center(child: EngameLogo(size: 64)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'engame',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre (En az 6 karakter)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuestion,
              decoration: const InputDecoration(
                labelText: 'Güvenlik Sorusu',
                border: OutlineInputBorder(),
              ),
              items: _questions
                  .map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedQuestion = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _securityAnswerController,
              decoration: const InputDecoration(
                labelText: 'Güvenlik Sorusu Cevabı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                final confirmPassword = _confirmPasswordController.text;
                final answer = _securityAnswerController.text.trim();

                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')),
                  );
                  return;
                }
                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifreler eşleşmiyor')),
                  );
                  return;
                }
                if (_selectedQuestion == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir güvenlik sorusu seçin')),
                  );
                  return;
                }
                if (answer.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Güvenlik cevabı en az 2 karakter olmalıdır')),
                  );
                  return;
                }

                final success = await DatabaseHelper.instance.registerUserWithSecurityQuestion(
                  email,
                  password,
                  _selectedQuestion!,
                  answer.toLowerCase(),
                );

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu e-posta adresi zaten kullanılıyor')),
                  );
                }
              },
              child: const Text('Kayıt Ol'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zaten hesabın var mı? Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
