import 'package:flutter/material.dart';

import '../../database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Kullanıcının yazdığı yazıları tutacak olan "Controller"larımız
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Ekran kapatıldığında hafızayı temizlemek için (Best Practice)
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. E-posta Alanı
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress, // Klavyede @ işaretini öne çıkarır
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16), // Araya 16 piksel boşluk koy

            // 2. Şifre Alanı
            TextField(
              controller: _passwordController,
              obscureText: true, // Yazılanları yıldızlar (***)
              decoration: const InputDecoration(
                labelText: 'Şifre (En az 6 karakter)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Şifre Tekrar Alanı
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24), // Buton için daha büyük bir boşluk
            // Kayıt Ol Butonu
            ElevatedButton(
              onPressed: () async {
                // 1. Kutulardaki yazıları okuyup değişkenlere alıyoruz
                // trim() komutu, kullanıcı yanlışlıkla boşluk bırakırsa onu siler
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                final confirmPassword = _confirmPasswordController.text;

                // 2. KONTROL: Boş alan var mı?
                if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return; // Hata varsa kodu burada durdur, aşağıya geçme!
                }

                // 3. KONTROL: Şifre en az 6 karakter mi? (Senin kararın)
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')),
                  );
                  return;
                }

                // 4. KONTROL: Şifreler uyuşuyor mu?
                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifreler eşleşmiyor')),
                  );
                  return;
                }

                // 5. VERİTABANI: Her şey doğruysa arkadaşının yazdığı koda gönder
                final success = await DatabaseHelper.instance.registerUser(email, password);

                // 6. GÜVENLİK: Login ekranında öğrendiğimiz o meşhur kontrol
                if (!context.mounted) return;

                // 7. SONUÇ: Kayıt başarılı mı?
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz. 🎉')),
                  );
                  // Başarılıysa bu sayfayı kapatıp otomatik olarak Login ekranına dön
                  Navigator.pop(context);
                } else {
                  // Eğer kayıt başarısız olursa (Büyük ihtimalle bu e-posta daha önce kaydedilmiş demektir)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu e-posta adresi zaten kullanılıyor')),
                  );
                }
              },
              child: const Text('Kayıt Ol'),
            ),
            
            const SizedBox(height: 12), // İki buton arası küçük boşluk
            
            // Kullanıcı vazgeçerse diye Giriş sayfasına dönme butonu
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Sadece sayfayı kapatır, geri döner
              },
              child: const Text('Zaten hesabın var mı? Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}