import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';

class QuizScreen extends StatefulWidget {
  final int userId;

  const QuizScreen({super.key, required this.userId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _words = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isRevealed = false;
  int _correctCount = 0;
  int _incorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await DatabaseHelper.instance.getDailyQuizWords(widget.userId);
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Quiz'),
        bottom: _words.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _words.isEmpty ? 0 : _currentIndex / _words.length,
                ),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_words.isEmpty) {
      return const Center(child: Text('Bugün çalışacak kelime yok.'));
    }
    return _buildCard(_words[_currentIndex]);
  }

  Future<void> _nextWord(int wordId, bool isCorrect) async {
    await DatabaseHelper.instance.updateWordLevel(wordId, isCorrect);

    if (isCorrect) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    if (_currentIndex + 1 >= _words.length) {
      if (!mounted) return;
      _showResults();
      return;
    }

    setState(() {
      _currentIndex++;
      _isRevealed = false;
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Toplam: ${_words.length} kelime'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$_correctCount',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text('Bildi'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_incorrectCount',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const Text('Bilemedi'),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> word) {
    final wordId = word['WordID'] as int;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_currentIndex + 1} / ${_words.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            word['EngWordName'] as String,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          if (_isRevealed) ...[
            Text(
              word['TurWordName'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (word['EngSample'] != null)
              Text(
                word['EngSample'] as String,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
          ],
          const SizedBox(height: 32),
          if (!_isRevealed)
            ElevatedButton(
              onPressed: () => setState(() => _isRevealed = true),
              child: const Text('Göster'),
            ),
          if (_isRevealed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _nextWord(wordId, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Bilemedi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _nextWord(wordId, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Bildi'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
