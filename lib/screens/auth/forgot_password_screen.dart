import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';

enum _ResetStage { username, question, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ResetStage _stage = _ResetStage.username;
  String? _currentQuestion;
  String? _verifiedUsername;

  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı boş olamaz')),
      );
      return;
    }
    final question = await DatabaseHelper.instance.getSecurityQuestion(username);
    if (!mounted) return;
    if (question == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bulunamadı')),
      );
      return;
    }
    setState(() {
      _currentQuestion = question;
      _verifiedUsername = username;
      _stage = _ResetStage.question;
    });
  }

  Future<void> _verifyAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cevap boş olamaz')),
      );
      return;
    }
    final ok = await DatabaseHelper.instance.verifySecurityAnswer(
      _verifiedUsername!,
      answer.toLowerCase(),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cevap hatalı')),
      );
      return;
    }
    setState(() {
      _answerController.clear();
      _stage = _ResetStage.newPassword;
    });
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreler eşleşmiyor')),
      );
      return;
    }
    final ok = await DatabaseHelper.instance.resetPassword(_verifiedUsername!, newPassword);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlandı')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu, tekrar deneyin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_stage == _ResetStage.username) ...[
              Text('Kullanıcı adınızı girin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkUsername,
                child: const Text('Devam'),
              ),
            ],
            if (_stage == _ResetStage.question) ...[
              Text('Güvenlik Sorusu', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_currentQuestion ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Cevabınız',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifyAnswer,
                child: const Text('Doğrula'),
              ),
            ],
            if (_stage == _ResetStage.newPassword) ...[
              Text('Yeni Şifre Belirle', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Şifreyi Sıfırla'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
