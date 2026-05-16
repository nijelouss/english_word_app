import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:english_word_app/database/database_helper.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalysisScreen extends StatefulWidget {
  final int userId;
  const AnalysisScreen({super.key, required this.userId});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _folderStats = [];
  int _totalWords = 0;
  int _learnedWords = 0;
  int _streak = 0;
  Map<int, int> _wordsByLevel = {};
  List<int> _weeklyProgress = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final folderStatsFuture =
        DatabaseHelper.instance.getFolderStats(widget.userId);
    final levelsFuture =
        DatabaseHelper.instance.getWordCountByLevel(widget.userId);
    final weeklyFuture =
        DatabaseHelper.instance.getLearnedWordsLastNDays(widget.userId, 7);
    final streakFuture =
        DatabaseHelper.instance.getCurrentStreak(widget.userId);

    final folderStats = await folderStatsFuture;
    final levelData = await levelsFuture;
    final rawWeekly = await weeklyFuture;
    final streak = await streakFuture;

    // sqflite SUM() bazı Android sürümlerinde double döndürebilir;
    // as num? ile güvenli dönüşüm yapılır.
    int total = 0;
    int learned = 0;
    for (final row in folderStats) {
      total   += (row['TotalWords']   as num?)?.toInt() ?? 0;
      learned += (row['LearnedWords'] as num?)?.toInt() ?? 0;
    }

    // Tam 7 elemana normalize et: eksik günleri soldan 0 ile doldur
    final List<int> weekly = rawWeekly.length >= 7
        ? rawWeekly.sublist(rawWeekly.length - 7)
        : [...List.filled(7 - rawWeekly.length, 0), ...rawWeekly];

    if (!mounted) return;
    setState(() {
      _totalWords   = total;
      _learnedWords = learned;
      _folderStats  = folderStats;
      _wordsByLevel = levelData;
      _weeklyProgress = weekly;
      _streak = streak;
      _isLoading = false;
    });
  }

  Future<void> _generatePdf() async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);
    final int progressedForPdf = _wordsByLevel.entries
        .where((e) => e.key >= 2)
        .fold(0, (sum, e) => sum + e.value);
    final percent =
        _totalWords == 0 ? 0.0 : progressedForPdf / _totalWords * 100;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (ctx) => [
          pw.Text('Analiz Raporu',
              style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 16),
          pw.Text('Genel Özet',
              style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('Toplam kelime: $_totalWords',
              style: pw.TextStyle(font: font)),
          pw.Text('Öğrenilen kelime: $_learnedWords',
              style: pw.TextStyle(font: font)),
          pw.Text('Genel başarı: %${percent.toStringAsFixed(1)}',
              style: pw.TextStyle(font: font)),
          pw.Text('Günlük seri: $_streak gün',
              style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 24),
          pw.Text('Klasör Bazlı Başarı',
              style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                _pdfCell('Klasör', boldFont),
                _pdfCell('Toplam', boldFont),
                _pdfCell('Öğrenilen', boldFont),
                _pdfCell('Başarı', boldFont),
              ]),
              ..._folderStats.map((stat) {
                final name = stat['FolderName'] as String;
                final total = stat['TotalWords'] as int? ?? 0;
                final learned = stat['LearnedWords'] as int? ?? 0;
                final fp = total == 0 ? 0.0 : learned / total * 100;
                return pw.TableRow(children: [
                  _pdfCell(name, font),
                  _pdfCell('$total', font),
                  _pdfCell('$learned', font),
                  _pdfCell('%${fp.toStringAsFixed(1)}', font),
                ]);
              }),
            ],
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'analiz_raporu.pdf');
  }

  pw.Widget _pdfCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(font: font)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Level >= 2 = en az bir kez doğru bilinmiş (IsLearned=1 dahil, o da level 6)
    final int progressedWords = _wordsByLevel.entries
        .where((e) => e.key >= 2)
        .fold(0, (sum, e) => sum + e.value);
    final double successRate =
        _totalWords == 0 ? 0.0 : progressedWords / _totalWords * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Raporu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isLoading ? null : _generatePdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Özet Kartları ──────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.book,
                            value: '$_totalWords',
                            label: 'Toplam',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.check_circle,
                            value: '$_learnedWords',
                            label: 'Öğrenilen',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.trending_up,
                            value: '%${successRate.toStringAsFixed(0)}',
                            label: 'Başarı',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            icon: Icons.local_fire_department,
                            value: '$_streak gün',
                            label: 'Seri',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. Leitner Seviye Bar Chart ───────────────────
                  _LevelDistributionChart(data: _wordsByLevel),
                  const SizedBox(height: 16),

                  // ── 3. Haftalık İlerleme Line Chart ──────────────
                  _WeeklyProgressChart(data: _weeklyProgress),
                  const SizedBox(height: 16),

                  // ── 4. Konu/Klasör Bazlı Başarı ───────────────────
                  _FolderProgressList(stats: _folderStats),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ÖZET KART
// ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: cs.primary),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              label,
              style: tt.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// LEITNER SEVİYE BAR CHART
// ─────────────────────────────────────────────────────────

class _LevelDistributionChart extends StatelessWidget {
  final Map<int, int> data;

  const _LevelDistributionChart({required this.data});

  // Kırmızı → turuncu → sarı → açık yeşil → yeşil → mor (zayıftan güçlüye)
  static const _levelColors = [
    Color(0xFFEF5350), // L1
    Color(0xFFFFA726), // L2
    Color(0xFFFFCA28), // L3
    Color(0xFF9CCC65), // L4
    Color(0xFF66BB6A), // L5
    Color(0xFF7E57C2), // L6
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isEmpty = data.isEmpty || data.values.every((v) => v == 0);

    int maxVal = 0;
    for (final v in data.values) {
      if (v > maxVal) maxVal = v;
    }
    final chartMaxY = maxVal == 0 ? 10.0 : (maxVal * 1.3).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seviye Dağılımı', style: tt.titleMedium),
            const SizedBox(height: 16),
            isEmpty
                ? _emptyState(context, Icons.bar_chart)
                : SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barGroups: List.generate(6, (i) {
                          final level = i + 1;
                          final count = data[level] ?? 0;
                          final base  = _levelColors[i];
                          // ignore: deprecated_member_use
                          final light = base.withOpacity(0.55);
                          return BarChartGroupData(
                            x: level,
                            barRods: [
                              BarChartRodData(
                                toY: count.toDouble(),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [base, light],
                                ),
                                width: 24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final count = data[value.toInt()] ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '$count',
                                    style: tt.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'L${value.toInt()}',
                                  style: tt.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                if (value != 0 && value != meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${value.toInt()}',
                                  style: tt.bodySmall,
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            // ignore: deprecated_member_use
                            color: cs.outline.withOpacity(0.2),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: false),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// HAFTALIK İLERLEME LINE CHART
// ─────────────────────────────────────────────────────────

class _WeeklyProgressChart extends StatelessWidget {
  final List<int> data; // 7 eleman, eskiden yeniye

  const _WeeklyProgressChart({required this.data});

  static const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  List<String> _weekLabels() {
    return List.generate(7, (i) {
      final daysAgo = 6 - i;
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      return _days[date.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEmpty = data.every((v) => v == 0);
    final labels = _weekLabels();

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].toDouble()),
    );

    int maxVal = 0;
    for (final v in data) {
      if (v > maxVal) maxVal = v;
    }
    final chartMaxY = maxVal == 0 ? 10.0 : (maxVal * 1.2).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu Hafta', style: tt.titleMedium),
            const SizedBox(height: 16),
            isEmpty
                ? _emptyState(context, Icons.show_chart)
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: chartMaxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: cs.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  // ignore: deprecated_member_use
                                  cs.primary.withOpacity(0.2),
                                  // ignore: deprecated_member_use
                                  cs.primary.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child:
                                      Text(labels[idx], style: tt.bodySmall),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value != 0 && value != meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${value.toInt()}',
                                  style: tt.bodySmall,
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            // ignore: deprecated_member_use
                            color: cs.outline.withOpacity(0.2),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// KONU BAZLI BAŞARI LİSTESİ
// ─────────────────────────────────────────────────────────

class _FolderProgressList extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const _FolderProgressList({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konu Bazlı Başarı', style: tt.titleMedium),
            const SizedBox(height: 12),
            if (stats.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Henüz klasör yok.', style: tt.bodyMedium),
                ),
              )
            else
              ...stats.map((stat) {
                final name = stat['FolderName'] as String;
                final total = stat['TotalWords'] as int? ?? 0;
                final learned = stat['LearnedWords'] as int? ?? 0;
                final progress = total == 0 ? 0.0 : learned / total;

                return Card(
                  elevation: 0,
                  color: cs.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(name, style: tt.titleSmall),
                            ),
                            Text(
                              '$learned / $total',
                              style: tt.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          color: progress >= 0.7 ? cs.primary : cs.error,
                          backgroundColor: cs.surfaceContainerHigh,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// ORTAK BOŞ DURUM WIDGET'I
// ─────────────────────────────────────────────────────────

Widget _emptyState(BuildContext context, IconData icon) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.outline),
          const SizedBox(height: 8),
          Text('Henüz veri yok', style: tt.bodyMedium),
        ],
      ),
    ),
  );
}
