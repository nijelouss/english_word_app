import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'backend_interface.dart'; // Arkadaşınla anlaştığınız sözleşme

class DatabaseHelper implements IBackendService {
  // Singleton pattern (Uygulama boyunca tek bir DB bağlantısı açık kalsın diye)
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını kurma ve tabloları yaratma aşaması
  Future<Database> _initDatabase() async {
    // Telefonun belgesel klasörünün yolunu buluyoruz
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "kelime_oyunu.db");

    // Veritabanını aç, eğer yoksa onCreate içindeki tabloları yarat
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // UYGULAMA İLK YÜKLENDİĞİNDE ÇALIŞACAK SQL KODLARI
  Future _onCreate(Database db, int version) async {
    // 1. Kullanıcılar Tablosu
    await db.execute('''
      CREATE TABLE Users (
        UserID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserName TEXT NOT NULL,
        Password TEXT NOT NULL
      )
    ''');

    // 2. Kelimeler Tablosu (Senin belirlediğin yapı)
    await db.execute('''
      CREATE TABLE Words (
        WordID INTEGER PRIMARY KEY AUTOINCREMENT,
        EngWordName TEXT NOT NULL,
        TurWordName TEXT NOT NULL,
        Picture TEXT
      )
    ''');

    // 3. Kelime Örnek Cümleleri ve Seviyeleri Tablosu
    await db.execute('''
      CREATE TABLE WordSamples (
        WordSamplesID INTEGER PRIMARY KEY AUTOINCREMENT,
        WordID INTEGER,
        Samples TEXT,
        FOREIGN KEY (WordID) REFERENCES Words (WordID)
      )
    ''');
  }

  // --- INTERFACE'TEN GELEN FONKSİYONLARIN İÇİNİ DOLDURMA ---

  @override
  Future<bool> addWord(String engWord, String turWord, String imagePath) async {
    try {
      Database db = await instance.database;
      await db.insert('Words', {
        'EngWordName': engWord,
        'TurWordName': turWord,
        'Picture': imagePath,
      });
      return true; 
    } catch (e) {
      print("Kelime eklerken hata çıktı: $e");
      return false;
    }
  }

  // Diğer fonksiyonları (registerUser, getTodayQuizWords vb.) 
  // zamanla buraya ekleyip içlerini SQL sorgularıyla dolduracaksın.
  
  // Interface hatası vermemesi için şimdilik boş tanımlamalar (Dummy data)
  @override
  Future<bool> registerUser(String email, String password) async => true;
  @override
  Future<bool> loginUser(String email, String password) async => true;
  @override
  Future<List<Map<String, dynamic>>> getTodayQuizWords() async => [];
  @override
  Future<void> updateWordProgress(int wordId, bool isCorrect) async {}
  @override
  Future<double> getSuccessRate() async => 0.0;
}