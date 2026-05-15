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
  
    List<Map<String, dynamic>> _folderStats = [];
    bool _isLoading = true;

     @override
    void initState() {
      super.initState();
      _loadStats();
      }
      Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getFolderStats(widget.userId);
    if (!mounted) return;
    setState(() { 
      _folderStats = stats;
      _isLoading = false;
    });
  }
  Future<void> _generatePdf() async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final totalWords = _folderStats.fold<int>(0, (sum, s) => sum + (s['TotalWords'] as int? ?? 0));
    final learnedWords = _folderStats.fold<int>(0, (sum, s) => sum + (s['LearnedWords'] as int? ?? 0));
    final percent = totalWords == 0 ? 0.0 : learnedWords / totalWords * 100;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (ctx) => [
          pw.Text('Analiz Raporu', style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 16),
          pw.Text('Genel Özet', style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('Toplam kelime: $totalWords'),
          pw.Text('Öğrenilen kelime: $learnedWords'),
          pw.Text('Genel başarı: %${percent.toStringAsFixed(1)}'),
          pw.SizedBox(height: 24),
          pw.Text('Klasör Bazlı Başarı', style: pw.TextStyle(font: boldFont, fontSize: 16)),
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
  final totalWords = _folderStats.fold<int>(0, (sum, s) => sum + (s['TotalWords'] as int? ?? 0));
  final learnedWords = _folderStats.fold<int>(0, (sum, s) => sum + (s['LearnedWords'] as int? ?? 0));
  final percent = totalWords == 0 ? 0.0 : learnedWords / totalWords * 100;
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
          :SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Genel Özet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Toplam: $totalWords kelime', style: Theme.of(context).textTheme.bodyMedium),
                Text('Öğrenilen: $learnedWords kelime', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('%${percent.toStringAsFixed(1)}', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: percent / 100),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Klasör Bazlı Başarı', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_folderStats.isEmpty)
          const Center(child: Text('Henüz klasör yok.'))
        else
          ..._folderStats.map((stat) {
            final name = stat['FolderName'] as String;
            final total = stat['TotalWords'] as int? ?? 0;
            final learned = stat['LearnedWords'] as int? ?? 0;
            final folderPercent = total == 0 ? 0.0 : learned / total * 100;
            final cs = Theme.of(context).colorScheme;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '%${folderPercent.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$learned / $total kelime öğrenildi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: folderPercent / 100,
                      color: folderPercent >= 70 ? cs.primary : cs.error,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  )
    );
  }
  }



