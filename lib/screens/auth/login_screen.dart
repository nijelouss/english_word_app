import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';

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
            onPressed: () async {
  final userName = _userNameController.text;
  final password = _passwordController.text;
  
  // Boş kontrolü
  if (userName.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
    );
    return;
  }
  
  // DatabaseHelper'a sor
  final user = await DatabaseHelper.instance.getUserByCredentials(
    userName,
    password,
  );
  
  if (user != null) {
    // Giriş başarılı
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hoş geldin! 🎉')),
    );
    // İleride: ana sayfaya yönlendir
  } else {
    // Hatalı
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı adı veya şifre yanlış')),
    );
  }
},
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    ),
  );
}
  }