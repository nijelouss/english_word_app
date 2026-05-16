import 'package:flutter/material.dart';
import 'package:english_word_app/screens/auth/login_screen.dart';
import 'package:english_word_app/features/word_chain/screens/word_selection_screen.dart';
import 'package:english_word_app/screens/word/add_word_screen.dart';
import 'package:english_word_app/screens/settings/settings_screen.dart';
import 'package:english_word_app/screens/quiz/quiz_screen.dart';
import 'package:english_word_app/screens/wordle/wordle_screen.dart';
import 'package:english_word_app/screens/analysis/analysis_screen.dart';
import 'package:english_word_app/core/page_transitions.dart';
import 'package:english_word_app/database/database_helper.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _totalWords = 0;
  int _activeWords = 0;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getHomeStats(widget.userId);
    if (!mounted) return;
    setState(() {
      _totalWords = stats['total']!;
      _activeWords = stats['active']!;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      SlideFadePageRoute(page: const LoginScreen()),
      (route) => false,
    );
  }

  int get _successRate =>
      _totalWords == 0 ? 0 : ((_activeWords / _totalWords) * 100).round();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          // ── HERO BÖLÜMÜ ──────────────────────────────
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst satır: Merhaba + Çıkış
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merhaba',
                                  style: tt.titleMedium?.copyWith(
                                    color: cs.onPrimary.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.userName,
                                  style: tt.displayMedium?.copyWith(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            color: cs.onPrimary,
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // İstatistik kartı
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.onPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            _statItem(
                              icon: Icons.menu_book_outlined,
                              value: '$_totalWords',
                              label: 'Toplam',
                              onPrimary: cs.onPrimary,
                              tt: tt,
                            ),
                            _verticalDivider(cs.onPrimary),
                            _statItem(
                              icon: Icons.local_fire_department_outlined,
                              value: '$_activeWords',
                              label: 'Aktif',
                              onPrimary: cs.onPrimary,
                              tt: tt,
                            ),
                            _verticalDivider(cs.onPrimary),
                            _statItem(
                              icon: Icons.trending_up,
                              value: '%$_successRate',
                              label: 'İlerleme',
                              onPrimary: cs.onPrimary,
                              tt: tt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── MENÜ KARTLARI ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                children: [
                  _buildMenuCard(
                    icon: Icons.add_circle_outline,
                    title: 'Kelime Ekle',
                    description: 'Yeni İngilizce kelime ekle',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: AddWordScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    icon: Icons.quiz_outlined,
                    title: 'Günlük Sınav',
                    description: 'Bugünün kelimelerini test et',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: QuizScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    icon: Icons.games_outlined,
                    title: 'Wordle',
                    description: 'Öğrendiğin kelimelerle oyna',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: WordleScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    icon: Icons.auto_stories,
                    title: 'Hikaye Oluştur',
                    description: 'Kelimelerden AI hikaye üret',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: WordSelectionScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    icon: Icons.bar_chart,
                    title: 'Analiz',
                    description: 'Başarı durumun',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: AnalysisScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    description: 'Günlük kelime sayısı',
                    onTap: () => Navigator.push(context,
                        SlideFadePageRoute(page: SettingsScreen(userId: widget.userId)))
                        .then((_) => _loadStats()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    required Color onPrimary,
    required TextTheme tt,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: onPrimary),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(Color onPrimary) {
    return Container(
      width: 1,
      height: 48,
      color: onPrimary.withValues(alpha: 0.3),
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
