import 'package:english_word_app/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:english_word_app/core/exceptions.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/features/word_chain/data/word_chain_service.dart';
import 'package:english_word_app/features/word_chain/screens/story_result_screen.dart';

class WordSelectionScreen extends StatefulWidget {
  final int userId;
  const WordSelectionScreen({super.key, required this.userId});

  @override
  State<WordSelectionScreen> createState() => _WordSelectionScreenState();
}

class _WordSelectionScreenState extends State<WordSelectionScreen> {
  List<Map<String, dynamic>> _words = [];
  final Set<int> _selectedIds = {};
  String _displayMode = 'EN+TR';
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await DatabaseHelper.instance.getLearnedWords();
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  Future<void> _generateStory() async {
    setState(() => _isGenerating = true);

    // await'ten önce yakala — async gap'ten sonra context güvensiz
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final selectedWords = _words
        .where((w) => _selectedIds.contains(w['WordID'] as int))
        .toList();
    final wordIds = selectedWords.map((w) => w['WordID'] as int).toList();
    final wordNames = selectedWords.map((w) => w['EngWordName'] as String).toList();

    try {
      final story = await WordChainService().generate(
        wordIds: wordIds,
        wordNames: wordNames,
        displayMode: _displayMode,
      );

      if (story == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Hikaye oluşturulamadı, tekrar deneyin')),
        );
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => StoryResultScreen(story: story),
        ),
      );

    } on GeminiException catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Hikaye oluşturulamadı, tekrar deneyin')),
      );
    } on ImageDownloadException catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Görsel indirilemedi ama hikaye kaydedildi')),
      );
    } on NetworkException catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İnternet bağlantınızı kontrol edin')),
      );
    } on TimeoutAppException catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('İstek zaman aşımına uğradı')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Beklenmeyen bir hata oluştu')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Seç'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(userId: widget.userId),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButton<String>(
                    value: _displayMode,
                    onChanged: (val) => setState(() => _displayMode = val!),
                    items: ['EN', 'TR', 'EN+TR'].map((mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode)),
                    ).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _words.length,
                    itemBuilder: (context, index) {
                      final word = _words[index];
                      final id = word['WordID'] as int;

                      return CheckboxListTile(
                        value: _selectedIds.contains(id),
                        onChanged: (val) {
                          setState(() {
                            if (_selectedIds.contains(id)) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          });
                        },
                        title: Text(word['EngWordName']),
                        subtitle: Text(word['TurWordName']),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGenerating
                          ? null
                          : _selectedIds.length >= 3 && _selectedIds.length <= 7
                              ? _generateStory
                              : null,
                      child: _isGenerating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hikaye Oluştur'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
