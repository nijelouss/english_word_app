import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/screens/auth/register_screen.dart';
import 'package:english_word_app/screens/auth/forgot_password_screen.dart';
// Senin yazdığın ana menüyü buraya bağladık!
import 'package:english_word_app/screens/home/home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // GİRİŞ YAP BUTONU
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text;
                final password = _passwordController.text;

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final userId = await DatabaseHelper.instance.loginUser(
                  email,
                  password,
                );

                if (!mounted) return;

                if (userId != null) {
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userId: userId,
                        userName: email.split('@')[0],
                      ),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('E-posta veya şifre yanlış')),
                  );
                }
              },
              child: const Text('Giriş Yap'),
            ),
            
            const SizedBox(height: 12),
            
            // KAYIT OL BUTONU (Artık sadece 1 tane var ve hatasız)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterScreen(),
                  ),
                );
              },
              child: const Text('Hesabın yok mu? Kayıt Ol'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text('Şifremi Unuttum'),
            ),
          ],
        ),
      ),
    );
  }
}