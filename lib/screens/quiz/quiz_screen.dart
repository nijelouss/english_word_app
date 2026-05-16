import 'dart:math';
import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/core/animated_press_button.dart';

enum _QuizMode { classic, multipleChoice }

class QuizScreen extends StatefulWidget {
  final int userId;
  const QuizScreen({super.key, required this.userId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ── Mod ────────────────────────────────────────────────────────
  _QuizMode _mode = _QuizMode.multipleChoice;

  // ── Veri ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _words        = [];
  List<Map<String, dynamic>> _allUserWords = [];

  // ── Ortak state ────────────────────────────────────────────────
  int  _currentIndex  = 0;
  bool _isLoading     = true;
  int  _correctCount  = 0;
  int  _incorrectCount = 0;

  // ── Klasik mod state ───────────────────────────────────────────
  bool _isRevealed = false;

  // ── Çoktan seçmeli state ───────────────────────────────────────
  List<String> _mcOptions     = [];
  String?      _selectedAnswer;
  String?      _correctAnswer;
  bool         _isAnswered    = false;

  // ─────────────────────────────────────────────────────────────
  // YÜKLEME
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);

    final quizWords = await DatabaseHelper.instance.getDailyQuizWords(widget.userId);
    final allWords  = await DatabaseHelper.instance.getAllWordsByUser(widget.userId);

    if (!mounted) return;

    // MC için başlangıç seçenekleri önceden hesapla (setState içinde olsun)
    final initialOptions = (_mode == _QuizMode.multipleChoice &&
            quizWords.isNotEmpty &&
            allWords.length >= 4)
        ? _generateMCOptions(quizWords[0], allWords)
        : <String>[];

    setState(() {
      _words            = quizWords;
      _allUserWords     = allWords;
      _currentIndex     = 0;
      _correctCount     = 0;
      _incorrectCount   = 0;
      _isRevealed     = false;
      _selectedAnswer = null;
      _correctAnswer  = initialOptions.isEmpty ? null : quizWords[0]['TurWordName'] as String;
      _isAnswered     = false;
      _mcOptions      = initialOptions;
      _isLoading        = false;
    });

    // Kelime havuzu yetersizse kullanıcıyı klasik moda yönlendir
    if (_mode == _QuizMode.multipleChoice && allWords.length < 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Çoktan seçmeli için en az 4 kelime gerekli, klasik mod kullanın',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _mode = _QuizMode.classic);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MC SEÇENEK ÜRETİMİ (pure, setState yok)
  // ─────────────────────────────────────────────────────────────

  List<String> _generateMCOptions(
    Map<String, dynamic> word,
    List<Map<String, dynamic>> pool,
  ) {
    final correctAnswer = word['TurWordName'] as String;
    final wordId        = word['WordID'] as int;

    final candidates = pool
        .where((w) =>
            (w['WordID'] as int) != wordId &&
            (w['TurWordName'] as String) != correctAnswer)
        .toList();

    if (candidates.length < 3) return [];

    candidates.shuffle(Random());
    final wrong = candidates
        .take(3)
        .map((w) => w['TurWordName'] as String)
        .toList();

    return ([correctAnswer, ...wrong]..shuffle(Random()));
  }

  void _setupMCOptions() {
    if (_currentIndex >= _words.length) return;
    final options =
        _generateMCOptions(_words[_currentIndex], _allUserWords);
    setState(() {
      _mcOptions      = options;
      _selectedAnswer = null;
      _correctAnswer  = options.isEmpty ? null : _words[_currentIndex]['TurWordName'] as String;
      _isAnswered     = false;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // KLASİK MOD — sonraki kelime
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // ÇOKTAN SEÇMELİ MOD — seçenek tıklandı
  // ─────────────────────────────────────────────────────────────

  Future<void> _onMCOptionSelected(String selected) async {
    if (_isAnswered) return;

    final word      = _words[_currentIndex];
    final wordId    = word['WordID'] as int;
    final isCorrect = selected == _correctAnswer;

    setState(() {
      _selectedAnswer = selected;
      _isAnswered     = true;
    });

    await DatabaseHelper.instance.updateWordLevel(wordId, isCorrect);
    if (isCorrect) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    await Future.delayed(Duration(milliseconds: isCorrect ? 1200 : 2000));
    if (!mounted) return;

    if (_currentIndex + 1 >= _words.length) {
      _showResults();
      return;
    }

    setState(() {
      _currentIndex++;
      _isRevealed     = false;
      _selectedAnswer = null;
      _correctAnswer  = null;
      _isAnswered     = false;
    });
    _setupMCOptions();
  }

  // ─────────────────────────────────────────────────────────────
  // SONUÇ DİALOG
  // ─────────────────────────────────────────────────────────────

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
                _resultColumn('$_correctCount', 'Bildi',
                    Theme.of(context).colorScheme.primary),
                _resultColumn('$_incorrectCount', 'Bilemedi',
                    Theme.of(context).colorScheme.error),
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

  Widget _resultColumn(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(color: color),
        ),
        Text(label),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MOD DEĞİŞTİRME
  // ─────────────────────────────────────────────────────────────

  void _onModeChanged(Set<_QuizMode> selection) {
    final newMode = selection.first;
    if (newMode == _mode) return;
    setState(() => _mode = newMode);
    _loadWords(); // kelime listesini tazele, state sıfırla
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük Quiz'),
        bottom: (_words.isEmpty || _isLoading)
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _currentIndex / _words.length,
                ),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildModeSelector(),
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<_QuizMode>(
        segments: const [
          ButtonSegment(
            value: _QuizMode.classic,
            label: Text('Klasik'),
            icon: Icon(Icons.flip_outlined),
          ),
          ButtonSegment(
            value: _QuizMode.multipleChoice,
            label: Text('Çoktan Seçmeli'),
            icon: Icon(Icons.checklist_outlined),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: _onModeChanged,
      ),
    );
  }

  Widget _buildBody() {
    if (_words.isEmpty) {
      return const Center(child: Text('Bugün çalışacak kelime yok.'));
    }
    return SingleChildScrollView(
      child: _mode == _QuizMode.classic
          ? _buildClassicCard(_words[_currentIndex])
          : _buildMCCard(_words[_currentIndex]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // KLASİK KART (mevcut mantık korundu)
  // ─────────────────────────────────────────────────────────────

  Widget _buildClassicCard(Map<String, dynamic> word) {
    final wordId = word['WordID'] as int;
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_currentIndex + 1} / ${_words.length}',
            style: tt.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            word['EngWordName'] as String,
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_isRevealed) ...[
            Text(
              word['TurWordName'] as String,
              style: tt.titleLarge,
            ),
            const SizedBox(height: 8),
            if (word['EngSample'] != null)
              Text(
                word['EngSample'] as String,
                style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
          ],
          const SizedBox(height: 32),
          if (!_isRevealed)
            AnimatedPressButton(
              onPressed: () => setState(() => _isRevealed = true),
              child: const Text('Göster'),
            ),
          if (_isRevealed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedPressButton(
                  onPressed: () => _nextWord(wordId, false),
                  backgroundColor: cs.error,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Bilemedi'),
                    ],
                  ),
                ),
                AnimatedPressButton(
                  onPressed: () => _nextWord(wordId, true),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('Bildi'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ÇOKTAN SEÇMELİ KART
  // ─────────────────────────────────────────────────────────────

  Widget _buildMCCard(Map<String, dynamic> word) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_mcOptions.isEmpty) {
      // Yeterli kelime yoksa klasik moda yönlendir
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(
                'Çoktan seçmeli için yeterli kelime yok.\n'
                'Klasik modu deneyin.',
                textAlign: TextAlign.center,
                style: tt.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_currentIndex + 1} / ${_words.length}',
            style: tt.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            word['EngWordName'] as String,
            style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (word['EngSample'] != null) ...[
            const SizedBox(height: 8),
            Text(
              word['EngSample'] as String,
              style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          ...List.generate(_mcOptions.length, (i) {
            final option = _mcOptions[i];

            Color bgColor;
            Color fgColor;
            IconData? trailingIcon;

            if (!_isAnswered) {
              bgColor = cs.surface;
              fgColor = cs.onSurface;
            } else if (option == _correctAnswer) {
              bgColor     = cs.primaryContainer;
              fgColor     = cs.onPrimaryContainer;
              trailingIcon = Icons.check_circle;
            } else if (option == _selectedAnswer) {
              bgColor     = cs.errorContainer;
              fgColor     = cs.onErrorContainer;
              trailingIcon = Icons.cancel;
            } else {
              bgColor = cs.surface;
              fgColor = cs.onSurface;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isAnswered ? () {} : () => _onMCOptionSelected(option),
                child: Row(
                  children: [
                    Expanded(child: Text(option, style: tt.bodyLarge)),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, size: 20, color: fgColor),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
