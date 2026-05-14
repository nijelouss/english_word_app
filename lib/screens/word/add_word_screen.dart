import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';

class AddWordScreen extends StatefulWidget {
  final int userId;
  
  const AddWordScreen({super.key, required this.userId});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _engWordController = TextEditingController();
  final _turWordController = TextEditingController();
  final _engSampleController = TextEditingController();
  final _turSampleController = TextEditingController();
  final _picturePathController = TextEditingController();

  @override
  void dispose() {
    _engWordController.dispose();
    _turWordController.dispose();
    _engSampleController.dispose();
    _turSampleController.dispose();
    _picturePathController.dispose();
    super.dispose();
  }

  Future<void> _saveWord() async {
    final engText = _engWordController.text.trim();
    final turText = _turWordController.text.trim();
    final engSampleText = _engSampleController.text.trim();
    final turSampleText = _turSampleController.text.trim();
    
    // TODO: Backend'de Picture parametresi eklenince DB'ye gönderilecek
    // final picturePath = _picturePathController.text.trim();

    if (engText.isEmpty || turText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen İngilizce ve Türkçe kelimeyi girin')),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(engText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İngilizce kelime sadece harf içermelidir')),
      );
      return;
    }

    try {
      var folders = await DatabaseHelper.instance.getFolders(widget.userId);
      if (folders.isEmpty) {
        await DatabaseHelper.instance.createFolder(widget.userId, 'Genel');
        folders = await DatabaseHelper.instance.getFolders(widget.userId);
      }
      final folderId = folders.first['FolderID'] as int;

      final success = await DatabaseHelper.instance.addWord(
        folderId,
        engText.toLowerCase(),
        turText,
        engSample: engSampleText.isEmpty ? null : engSampleText,
        turSample: turSampleText.isEmpty ? null : turSampleText,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelime başarıyla eklendi')),
        );
        _engWordController.clear();
        _turWordController.clear();
        _engSampleController.clear();
        _turSampleController.clear();
        _picturePathController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelime eklenemedi, tekrar deneyin')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _engWordController,
              decoration: const InputDecoration(
                labelText: 'İngilizce Kelime',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _turWordController,
              decoration: const InputDecoration(
                labelText: 'Türkçe Karşılık',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _engSampleController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'İngilizce Örnek Cümle (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _turSampleController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Türkçe Örnek Cümle (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _picturePathController,
              decoration: const InputDecoration(
                labelText: 'Resim Yolu (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveWord,
              child: const Text('Kelimeyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}