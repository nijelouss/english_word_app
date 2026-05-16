import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database_helper.dart';
import '../../core/theme_notifier.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dailyCountController = TextEditingController();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
    _loadPrefs();
  }

  Future<void> _loadCurrentSetting() async {
    final count =
        await DatabaseHelper.instance.getDailyNewWordCount(widget.userId);
    if (!mounted) return;
    setState(() => _dailyCountController.text = count.toString());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final count = int.tryParse(_dailyCountController.text.trim());
    if (count == null || count < 1 || count > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 1 ile 50 arasında bir sayı girin')),
      );
      return;
    }
    final success = await DatabaseHelper.instance
        .setDailyNewWordCount(widget.userId, count);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar kaydedildi')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt sırasında hata oluştu')),
      );
    }
  }

  // ── Şifre Değiştir Dialog ────────────────────────────────────────
  void _showChangePasswordDialog() {
    final oldCtrl     = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld  = true;
    bool obscureNew  = true;
    bool obscureConf = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Şifre Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setInner(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setInner(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConf,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConf
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setInner(() => obscureConf = !obscureConf),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                final oldPass  = oldCtrl.text.trim();
                final newPass  = newCtrl.text.trim();
                final confPass = confirmCtrl.text.trim();

                if (oldPass.isEmpty || newPass.isEmpty || confPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tüm alanları doldurun')),
                  );
                  return;
                }
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Yeni şifre en az 6 karakter olmalı')),
                  );
                  return;
                }
                if (newPass != confPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Yeni şifreler eşleşmiyor')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final success = await DatabaseHelper.instance
                    .updatePassword(widget.userId, oldPass, newPass);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Şifre güncellendi'
                        : 'Mevcut şifre hatalı'),
                  ),
                );
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Çıkış Yap ───────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  // ── Veri Sıfırla ─────────────────────────────────────────────────
  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sıfırla'),
        content: const Text(
          'Tüm kelimeler, klasörler ve hikâyeler kalıcı olarak silinecek.\n\n'
          'Bu işlem geri alınamaz. Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await DatabaseHelper.instance
                  .resetUserData(widget.userId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Veriler silindi'
                      : 'Silme işlemi başarısız'),
                ),
              );
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dailyCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Mevcut: Öğrenme parametreleri ─────────────────────
            _sectionTitle('Günlük Quiz', tt),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Her gün sınavda kaç yeni kelime gösterilsin?',
                        style: tt.bodyMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dailyCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Yeni Kelime Sayısı (1–50)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saveSettings,
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Mevcut: Tema ───────────────────────────────────────
            _sectionTitle('Tema', tt),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, themeMode, _) {
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Açık'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Otomatik'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Koyu'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) =>
                          themeNotifier.value = s.first,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── YENİ: Hesap ────────────────────────────────────────
            _sectionTitle('Hesap', tt),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Şifre Değiştir'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16,
                      color: cs.outlineVariant),
                  ListTile(
                    leading:
                        Icon(Icons.logout, color: cs.error),
                    title: Text('Çıkış Yap',
                        style: TextStyle(color: cs.error)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── YENİ: Öğrenme ──────────────────────────────────────
            _sectionTitle('Öğrenme', tt),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Bildirimler'),
                    subtitle: const Text('Günlük hatırlatıcı al'),
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', val);
                      if (!mounted) return;
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16,
                      color: cs.outlineVariant),
                  ListTile(
                    leading:
                        Icon(Icons.delete_forever, color: cs.error),
                    title: Text('Tüm Verileri Sıfırla',
                        style: TextStyle(color: cs.error)),
                    subtitle: const Text('Kelimeler ve klasörler silinir'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showResetDataDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── YENİ: Uygulama ─────────────────────────────────────
            _sectionTitle('Uygulama', tt),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Hakkında'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'English Word App',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026',
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Leitner sistemi ile kelime öğrenme uygulaması. '
                          'Günlük quiz, analiz grafikleri ve Wordle ile '
                          'öğrenmeyi eğlenceli hale getir.',
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16,
                      color: cs.outlineVariant),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Geri Bildirim Gönder'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bu özellik yakında')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, TextTheme tt) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: tt.titleSmall),
      );
}
