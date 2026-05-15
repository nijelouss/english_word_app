import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/game/wordle_engine.dart';

class WordleScreen extends StatefulWidget {
  final int userId;

  const WordleScreen({super.key, required this.userId});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> {
  String _targetWord = '';
  bool _isLoading = true;
  bool _isGameOver = false;
  int _currentAttempt = 0;

  final List<String> _guesses = List.filled(6, '');
  final List<List<LetterMatch>> _results = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWord();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWord() async {
    final word = await DatabaseHelper.instance.getRandomFiveLetterWord(widget.userId);
    if (!mounted) return;
    if (word == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce 5 harfli kelime eklemelisin')),
      );
      Navigator.pop(context);
      return;
    }
    setState(() {
      _targetWord = word.toUpperCase();
      _isLoading = false;
    });
  }

  void _submitGuess() {
    if (_isGameOver) return;

    final guess = _controller.text.trim().toUpperCase();
    if (guess.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 5 harfli bir kelime girin')),
      );
      return;
    }

    final result = checkWordleGuess(guess, _targetWord);
    final bool won = guess == _targetWord;
    final bool lost = !won && _currentAttempt >= 5;

    setState(() {
      _guesses[_currentAttempt] = guess;
      _results.add(result);
      _controller.clear();
      if (won || lost) {
        _isGameOver = true;
      } else {
        _currentAttempt++;
      }
    });

    if (won || lost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultDialog(won: won);
      });
    }
  }

  void _showResultDialog({required bool won}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(won ? 'Tebrikler!' : 'Oyun Bitti'),
        content: Text(
          won
              ? '${_currentAttempt + 1}. denemede bildin!'
              : 'Doğru kelime: $_targetWord',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetGame();
            },
            child: const Text('Tekrar Oyna'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _isLoading = true;
      _currentAttempt = 0;
      _isGameOver = false;
      _guesses.fillRange(0, 6, '');
      _results.clear();
      _controller.clear();
    });
    _loadWord();
  }

  Color _getCellColor(int row, int col) {
    final cs = Theme.of(context).colorScheme;
    if (row >= _results.length) return cs.surface;
    switch (_results[row][col]) {
      case LetterMatch.correct:
        return cs.primary;
      case LetterMatch.present:
        return cs.tertiary;
      case LetterMatch.absent:
        return cs.surfaceContainerHighest;
    }
  }

  Color _getCellTextColor(int row, int col) {
    final cs = Theme.of(context).colorScheme;
    if (row >= _results.length) return cs.onSurface;
    switch (_results[row][col]) {
      case LetterMatch.correct:
        return cs.onPrimary;
      case LetterMatch.present:
        return cs.onTertiary;
      case LetterMatch.absent:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      final row = index ~/ 5;
                      final col = index % 5;

                      String letter = '';
                      if (_guesses[row].isNotEmpty) {
                        letter = _guesses[row][col];
                      } else if (row == _currentAttempt && !_isGameOver) {
                        final typed = _controller.text.toUpperCase();
                        if (col < typed.length) letter = typed[col];
                      }

                      final isSubmitted = row < _results.length;
                      final bgColor = _getCellColor(row, col);
                      final textColor = _getCellTextColor(row, col);
                      final borderColor = row == _currentAttempt && !_isGameOver
                          ? cs.primary
                          : cs.outline;

                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: isSubmitted ? null : Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          letter,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (!_isGameOver) ...[
                    TextField(
                      controller: _controller,
                      maxLength: 5,
                      decoration: const InputDecoration(
                        labelText: 'Tahmininizi yazın',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submitGuess(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitGuess,
                      child: const Text('Tahmin Et'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
