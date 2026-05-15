import 'package:flutter/material.dart';
import 'package:english_word_app/screens/auth/login_screen.dart';
import 'package:english_word_app/features/word_chain/screens/word_selection_screen.dart';
import 'package:english_word_app/screens/word/add_word_screen.dart';
import 'package:english_word_app/screens/settings/settings_screen.dart';
import 'package:english_word_app/screens/quiz/quiz_screen.dart';
import 'package:english_word_app/screens/wordle/wordle_screen.dart';
import 'package:english_word_app/screens/analysis/analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba, ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          children: [
            // KELİME EKLE KARTINI BURAYA BAĞLADIK
            _buildMenuCard(
              icon: Icons.add_circle_outline,
              title: 'Kelime Ekle',
              description: 'Yeni İngilizce kelime ekle',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddWordScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.quiz_outlined,
              title: 'Günlük Sınav',
              description: 'Bugünün kelimelerini test et',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.games_outlined,
              title: 'Wordle',
              description: 'Öğrendiğin kelimelerle oyna',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WordleScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.auto_stories,
              title: 'Hikaye Oluştur',
              description: 'Kelimelerden AI hikaye üret',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // const kelimesini kaldırıp hatayı sıfırladık
                    builder: (_) => WordSelectionScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.bar_chart,
              title: 'Analiz',
              description: 'Başarı durumun',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalysisScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.settings,
              title: 'Ayarlar',
              description: 'Günlük kelime sayısı',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}