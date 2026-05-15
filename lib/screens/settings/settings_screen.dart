import 'package:flutter/material.dart';

import '../../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dailyCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSetting();
  }

  Future<void> _loadCurrentSetting() async {
    final count = await DatabaseHelper.instance.getDailyNewWordCount(widget.userId);
    if (!mounted) return;
    setState(() {
      _dailyCountController.text = count.toString();
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

    final success = await DatabaseHelper.instance.setDailyNewWordCount(widget.userId, count);
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

  @override
  void dispose() {
    _dailyCountController.dispose(); // Hafızayı temizle
    super.dispose();                 // Flutter'ın kendi temizliğini de yap
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Günlük Yeni Kelime Sayısı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Her gün sınavda kaç yeni kelime gösterilsin?'),
            const SizedBox(height: 16),
            TextField(
              controller: _dailyCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Yeni Kelime Sayısı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
