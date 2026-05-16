import 'dart:async';
import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/core/animated_press_button.dart';

class AddWordScreen extends StatefulWidget {
  final int userId;

  const AddWordScreen({super.key, required this.userId});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _engWordController    = TextEditingController();
  final _turWordController    = TextEditingController();
  final _engSampleController  = TextEditingController();
  final _turSampleController  = TextEditingController();
  final _picturePathController = TextEditingController();

  Timer?  _debounce;
  String? _engWordError;   // null → hata yok, non-null → errorText

  @override
  void dispose() {
    _debounce?.cancel();
    _engWordController.dispose();
    _turWordController.dispose();
    _engSampleController.dispose();
    _turSampleController.dispose();
    _picturePathController.dispose();
    super.dispose();
  }

  // ── Anlık duplicate kontrolü (300 ms debounce) ──────────────────
  void _onEngWordChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    // Boş veya regex geçmiyorsa anlık kontrol yapma; kaydet butonunda zaten uyarılacak
    if (trimmed.isEmpty || !RegExp(r'^[a-zA-Z\s-]+$').hasMatch(trimmed)) {
      if (_engWordError != null) setState(() => _engWordError = null);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final exists = await DatabaseHelper.instance
          .wordExists(widget.userId, trimmed);
      if (!mounted) return;
      setState(() {
        _engWordError = exists ? 'Bu kelime zaten eklenmiş' : null;
      });
    });
  }

  // ── Kaydet ──────────────────────────────────────────────────────
  Future<void> _saveWord() async {
    final engText        = _engWordController.text.trim();
    final turText        = _turWordController.text.trim();
    final engSampleText  = _engSampleController.text.trim();
    final turSampleText  = _turSampleController.text.trim();

    // 1) Boş alan kontrolü
    if (engText.isEmpty || turText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen İngilizce ve Türkçe kelimeyi girin')),
      );
      return;
    }

    // 2) Sadece harf kontrolü
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(engText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İngilizce kelime sadece harf içermelidir')),
      );
      return;
    }

    // 3) Duplicate kontrolü (case-insensitive + trimmed)
    final exists = await DatabaseHelper.instance
        .wordExists(widget.userId, engText);
    if (!mounted) return;
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kelime zaten eklenmiş')),
      );
      return;
    }

    // 4) Kaydet
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
        setState(() => _engWordError = null);
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
              onChanged: _onEngWordChanged,
              decoration: InputDecoration(
                labelText: 'İngilizce Kelime',
                border: const OutlineInputBorder(),
                errorText: _engWordError,
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
            AnimatedPressButton(
              onPressed: _saveWord,
              child: const Text('Kelimeyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
