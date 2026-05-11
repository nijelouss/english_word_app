import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userNameController = TextEditingController();
    final _passwordController = TextEditingController();
    
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
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı Adı',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true, // şifreyi gizler
            decoration: const InputDecoration(
              labelText: 'Şifre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Şimdilik boş, sonra dolduracağız
              print('Giriş butonu basıldı');
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    ),
  );
}
  }