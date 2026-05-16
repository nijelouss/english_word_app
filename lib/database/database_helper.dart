import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:english_word_app/features/word_chain/models/story.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Anahtar = doğru cevap verilen andaki LeitnerLevel.
  // Değer   = bir sonraki testin kaç gün sonra yapılacağı.
  // Level 6 doğru → kelime öğrenildi (IsLearned=1); 365 gün kayıt amaçlı saklanır.
  static const Map<int, int> _reviewIntervals = {
    1: 1,    // 1. başarılı biliş  → 1 gün sonra
    2: 7,    // 2. başarılı biliş  → 1 hafta sonra
    3: 30,   // 3. başarılı biliş  → 1 ay sonra
    4: 90,   // 4. başarılı biliş  → 3 ay sonra
    5: 180,  // 5. başarılı biliş  → 6 ay sonra
    6: 365,  // 6. başarılı biliş  → öğrenildi; 1 yıl kayıt olarak saklanır
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kelime_oyunu.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Yabancı anahtar kısıtlamalarını SQLite düzeyinde aktif hale getirir.
  // SQLite'da bu özellik varsayılan olarak kapalıdır ve her bağlantıda açılması gerekir.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createFoldersTable(db);
    await _createWordsTable(db);
    await _createWordSamplesTable(db);
    await _createStoriesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE Words ADD COLUMN IsLearned INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE Users ADD COLUMN DailyWordLimit INTEGER DEFAULT 10',
      );
      await db.execute(
        'ALTER TABLE Words ADD COLUMN Picture TEXT',
      );
    }
  if (oldVersion < 4) {
    await _createStoriesTable(db);
  }
  if (oldVersion < 5) {
    await db.execute('ALTER TABLE Users ADD COLUMN SecurityQuestion TEXT');
    await db.execute('ALTER TABLE Users ADD COLUMN SecurityAnswer TEXT');
  }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE Users (
        UserID         INTEGER PRIMARY KEY AUTOINCREMENT,
        UserName       TEXT    NOT NULL,
        Email          TEXT    NOT NULL UNIQUE,
        PasswordHash   TEXT    NOT NULL,
        DailyWordLimit INTEGER          DEFAULT 10,
        CreatedAt        TEXT    NOT NULL DEFAULT (datetime('now')),
        SecurityQuestion TEXT,
        SecurityAnswer   TEXT
      )
    ''');
  }

  Future<void> _createFoldersTable(Database db) async {
    await db.execute('''
      CREATE TABLE Folders (
        FolderID   INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID     INTEGER NOT NULL,
        FolderName TEXT    NOT NULL,
        CreatedAt  TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createWordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE Words (
        WordID           INTEGER PRIMARY KEY AUTOINCREMENT,
        FolderID         INTEGER NOT NULL,
        EngWordName      TEXT    NOT NULL,
        TurWordName      TEXT    NOT NULL,
        LeitnerLevel     INTEGER NOT NULL DEFAULT 1
                                 CHECK (LeitnerLevel BETWEEN 1 AND 6),
        IsLearned        INTEGER NOT NULL DEFAULT 0,
        Picture          TEXT,
        NextReviewDate   TEXT    NOT NULL DEFAULT (date('now')),
        LastReviewedDate TEXT,
        CreatedAt        TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (FolderID) REFERENCES Folders(FolderID) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createWordSamplesTable(Database db) async {
    await db.execute('''
      CREATE TABLE WordSamples (
        WordSampleID INTEGER PRIMARY KEY AUTOINCREMENT,
        WordID       INTEGER NOT NULL,
        EngSample    TEXT,
        TurSample    TEXT,
        FOREIGN KEY (WordID) REFERENCES Words(WordID) ON DELETE CASCADE
      )
    ''');
  }
   Future<void> _createStoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE Stories (
        StoryID     INTEGER PRIMARY KEY AUTOINCREMENT,
        ContentEN   TEXT    NOT NULL,
        ContentTR   TEXT,
        ImagePath   TEXT,
        WordList    TEXT    NOT NULL,
        WordIDs     TEXT    NOT NULL,
        DisplayMode TEXT    NOT NULL DEFAULT 'both',
        CreatedAt   TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  // ─────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────

  // Email'i salt olarak kullanarak SHA-256 hash üretir.
  // Aynı şifre farklı hesaplarda farklı hash verir; rainbow table saldırılarını engeller.
  String _hashPassword(String email, String password) {
    final saltedInput = '$email:$password';
    final bytes = utf8.encode(saltedInput);
    return sha256.convert(bytes).toString();
  }

  String _hashAnswer(String answer) {
    final bytes = utf8.encode(answer.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  // ── Seed veri ────────────────────────────────────────────────────────────

  static const List<Map<String, String>> _seedWords = [
    {'eng': 'apple',    'tur': 'elma'},
    {'eng': 'water',    'tur': 'su'},
    {'eng': 'bread',    'tur': 'ekmek'},
    {'eng': 'milk',     'tur': 'süt'},
    {'eng': 'sugar',    'tur': 'şeker'},
    {'eng': 'house',    'tur': 'ev'},
    {'eng': 'table',    'tur': 'masa'},
    {'eng': 'chair',    'tur': 'sandalye'},
    {'eng': 'door',     'tur': 'kapı'},
    {'eng': 'window',   'tur': 'pencere'},
    {'eng': 'book',     'tur': 'kitap'},
    {'eng': 'pen',      'tur': 'kalem'},
    {'eng': 'paper',    'tur': 'kağıt'},
    {'eng': 'phone',    'tur': 'telefon'},
    {'eng': 'computer', 'tur': 'bilgisayar'},
    {'eng': 'car',      'tur': 'araba'},
    {'eng': 'train',    'tur': 'tren'},
    {'eng': 'plane',    'tur': 'uçak'},
    {'eng': 'road',     'tur': 'yol'},
    {'eng': 'bridge',   'tur': 'köprü'},
    {'eng': 'sun',      'tur': 'güneş'},
    {'eng': 'moon',     'tur': 'ay'},
    {'eng': 'star',     'tur': 'yıldız'},
    {'eng': 'cloud',    'tur': 'bulut'},
    {'eng': 'rain',     'tur': 'yağmur'},
    {'eng': 'tree',     'tur': 'ağaç'},
    {'eng': 'flower',   'tur': 'çiçek'},
    {'eng': 'grass',    'tur': 'çimen'},
    {'eng': 'river',    'tur': 'nehir'},
    {'eng': 'mountain', 'tur': 'dağ'},
    {'eng': 'happy',    'tur': 'mutlu'},
    {'eng': 'sad',      'tur': 'üzgün'},
    {'eng': 'angry',    'tur': 'kızgın'},
    {'eng': 'tired',    'tur': 'yorgun'},
    {'eng': 'busy',     'tur': 'meşgul'},
    {'eng': 'smile',    'tur': 'gülümseme'},
    {'eng': 'laugh',    'tur': 'gülmek'},
    {'eng': 'sleep',    'tur': 'uyumak'},
    {'eng': 'dream',    'tur': 'rüya'},
    {'eng': 'read',     'tur': 'okumak'},
    {'eng': 'write',    'tur': 'yazmak'},
    {'eng': 'run',      'tur': 'koşmak'},
    {'eng': 'walk',     'tur': 'yürümek'},
    {'eng': 'eat',      'tur': 'yemek'},
    {'eng': 'drink',    'tur': 'içmek'},
    {'eng': 'night',    'tur': 'gece'},
    {'eng': 'day',      'tur': 'gün'},
    {'eng': 'year',     'tur': 'yıl'},
    {'eng': 'month',    'tur': 'ay'},
    {'eng': 'week',     'tur': 'hafta'},
  ];

  Future<int> _getOrCreateGeneralFolder(Database db, int userId) async {
    final existing = await db.query(
      'Folders',
      columns: ['FolderID'],
      where: 'UserID = ? AND FolderName = ?',
      whereArgs: [userId, 'Genel'],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['FolderID'] as int;
    return db.insert('Folders', {'UserID': userId, 'FolderName': 'Genel'});
  }

  Future<void> _insertSeedWords(int userId) async {
    final db    = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final folderId = await _getOrCreateGeneralFolder(db, userId);

    final batch = db.batch();
    for (final word in _seedWords) {
      batch.insert('Words', {
        'FolderID':      folderId,
        'EngWordName':   word['eng'],
        'TurWordName':   word['tur'],
        'LeitnerLevel':  1,
        'IsLearned':     0,
        'NextReviewDate': today,
      });
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────
  // KULLANICI İŞLEMLERİ
  // ─────────────────────────────────────────────

  Future<bool> registerUser(String email, String password) async {
    try {
      final db = await instance.database;
      final newUserId = await db.insert(
        'Users',
        {
          'UserName': email.split('@').first,
          'Email': email,
          'PasswordHash': _hashPassword(email, password),
        },
        // Aynı email ile ikinci kayıt denemesinde exception yerine false dön.
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _insertSeedWords(newUserId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerUserWithSecurityQuestion(
    String email,
    String password,
    String securityQuestion,
    String securityAnswer,
  ) async {
    try {
      final db = await instance.database;
      final newUserId = await db.insert(
        'Users',
        {
          'UserName': email.split('@').first,
          'Email': email,
          'PasswordHash': _hashPassword(email, password),
          'SecurityQuestion': securityQuestion,
          'SecurityAnswer': _hashAnswer(securityAnswer),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _insertSeedWords(newUserId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSecurityQuestion(String userName) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['SecurityQuestion'],
        where: 'UserName = ?',
        whereArgs: [userName],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['SecurityQuestion'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifySecurityAnswer(String userName, String securityAnswer) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['SecurityAnswer'],
        where: 'UserName = ?',
        whereArgs: [userName],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final storedHash = rows.first['SecurityAnswer'] as String?;
      if (storedHash == null) return false;
      return storedHash == _hashAnswer(securityAnswer);
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(String userName, String newPassword) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['Email'],
        where: 'UserName = ?',
        whereArgs: [userName],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final email = rows.first['Email'] as String;
      await db.update(
        'Users',
        {'PasswordHash': _hashPassword(email, newPassword)},
        where: 'UserName = ?',
        whereArgs: [userName],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Eski şifreyi doğrulayarak yeni şifre kaydeder.
  /// Eski şifre yanlışsa [false] döner.
  Future<bool> updatePassword(
      int userId, String oldPassword, String newPassword) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['Email', 'PasswordHash'],
        where: 'UserID = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final email        = rows.first['Email'] as String;
      final storedHash   = rows.first['PasswordHash'] as String;
      if (storedHash != _hashPassword(email, oldPassword)) return false;
      await db.update(
        'Users',
        {'PasswordHash': _hashPassword(email, newPassword)},
        where: 'UserID = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Kullanıcıya ait tüm Folders (→ Words → WordSamples CASCADE) ve
  /// Stories tablosunu siler. Users tablosuna dokunulmaz.
  Future<bool> resetUserData(int userId) async {
    try {
      final db = await instance.database;
      await db.transaction((txn) async {
        await txn.delete('Stories');
        await txn.delete(
          'Folders',
          where: 'UserID = ?',
          whereArgs: [userId],
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Başarılı girişte [UserID] döner, hatalı kimlik bilgisinde [null] döner.
  Future<int?> loginUser(String email, String password) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['UserID'],
        // Parametreli sorgu: sqflite whereArgs her zaman escape eder → SQL Injection yok.
        where: 'Email = ? AND PasswordHash = ?',
        whereArgs: [email, _hashPassword(email, password)],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['UserID'] as int;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // KLASÖR İŞLEMLERİ
  // ─────────────────────────────────────────────

  Future<bool> createFolder(int userId, String folderName) async {
    try {
      final db = await instance.database;
      await db.insert('Folders', {
        'UserID': userId,
        'FolderName': folderName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFolders(int userId) async {
    try {
      final db = await instance.database;
      return await db.query(
        'Folders',
        where: 'UserID = ?',
        whereArgs: [userId],
        orderBy: 'CreatedAt DESC',
      );
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // KELİME İŞLEMLERİ
  // ─────────────────────────────────────────────

  /// Kullanıcıya ait kelimeler arasında aynı İngilizce kelime var mı kontrol eder.
  /// Karşılaştırma büyük/küçük harf duyarsızdır (LOWER).
  Future<bool> wordExists(int userId, String engWord) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT COUNT(*) AS Cnt
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID             = ?
          AND  LOWER(w.EngWordName) = LOWER(?)
        ''',
        [userId, engWord.trim()],
      );
      if (rows.isEmpty) return false;
      return ((rows.first['Cnt'] as num?)?.toInt() ?? 0) > 0;
    } catch (_) {
      return false;
    }
  }

  /// Words ve (varsa) WordSamples kayıtlarını tek bir transaction içinde ekler.
  /// Transaction sayesinde Words eklendikten sonra WordSamples eklenirken hata çıkarsa
  /// her iki kayıt da geri alınır; veritabanı tutarsız kalmaz.
  Future<bool> addWord(
    int folderId,
    String engWord,
    String turWord, {
    String? engSample,
    String? turSample,
  }) async {
    try {
      final db = await instance.database;
      await db.transaction((txn) async {
        final wordId = await txn.insert('Words', {
          'FolderID': folderId,
          'EngWordName': engWord,
          'TurWordName': turWord,
          'LeitnerLevel': 1,
        });

        if (engSample != null || turSample != null) {
          await txn.insert('WordSamples', {
            'WordID': wordId,
            'EngSample': engSample,
            'TurSample': turSample,
          });
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Klasördeki kelimeleri örnek cümleleriyle birlikte getirir.
  /// WordSamples ile LEFT JOIN yapılır; örnek cümlesi olmayan kelimeler de listeye girer.
  Future<List<Map<String, dynamic>>> getWordsByFolder(int folderId) async {
    try {
      final db = await instance.database;
      return await db.rawQuery(
        '''
        SELECT
          w.WordID,
          w.EngWordName,
          w.TurWordName,
          w.LeitnerLevel,
          w.NextReviewDate,
          w.LastReviewedDate,
          w.CreatedAt,
          ws.EngSample,
          ws.TurSample
        FROM  Words       w
        LEFT JOIN WordSamples ws ON ws.WordID = w.WordID
        WHERE w.FolderID = ?
        ORDER BY w.CreatedAt DESC
        ''',
        [folderId],
      );
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // LEİTNER ALGORİTMASI
  // ─────────────────────────────────────────────

  /// Günlük quiz listesini iki gruptan oluşturur:
  ///   1. Vadesi gelmiş kelimeler (daha önce görülmüş, NextReviewDate <= bugün).
  ///   2. Kullanıcının [DailyWordLimit] değeri kadar hiç görülmemiş yeni kelime.
  /// IsLearned = 1 olanlar her iki gruptan da kesinlikle dışlanır.
  Future<List<Map<String, dynamic>>> getDailyQuizWords(int userId) async {
    try {
      final db    = await instance.database;
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Kullanıcının günlük yeni kelime limitini oku (yoksa varsayılan 10).
      final userRow = await db.query(
        'Users',
        columns: ['DailyWordLimit'],
        where: 'UserID = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final dailyLimit =
          userRow.isEmpty ? 10 : ((userRow.first['DailyWordLimit'] as int?) ?? 10);

      // 1. Grup: vadesi gelmiş, daha önce en az bir kez görülmüş kelimeler.
      final dueWords = await db.rawQuery(
        '''
        SELECT w.WordID, w.EngWordName, w.TurWordName,
               w.LeitnerLevel, w.IsLearned, w.NextReviewDate, w.LastReviewedDate,
               ws.EngSample
        FROM   Words   w
        INNER JOIN Folders      f  ON f.FolderID  = w.FolderID
        LEFT  JOIN WordSamples  ws ON ws.WordID    = w.WordID
        WHERE  f.UserID           = ?
          AND  w.IsLearned        = 0
          AND  w.LastReviewedDate IS NOT NULL
          AND  w.NextReviewDate   <= ?
        ORDER BY w.NextReviewDate ASC, w.LeitnerLevel ASC, w.WordID ASC
        ''',
        [userId, today],
      );

      // 2. Grup: hiç görülmemiş yeni kelimeler, günlük limite kadar.
      final newWords = await db.rawQuery(
        '''
        SELECT w.WordID, w.EngWordName, w.TurWordName,
               w.LeitnerLevel, w.IsLearned, w.NextReviewDate, w.LastReviewedDate,
               ws.EngSample
        FROM   Words   w
        INNER JOIN Folders      f  ON f.FolderID  = w.FolderID
        LEFT  JOIN WordSamples  ws ON ws.WordID    = w.WordID
        WHERE  f.UserID           = ?
          AND  w.IsLearned        = 0
          AND  w.LastReviewedDate IS NULL
        ORDER BY w.CreatedAt ASC, w.WordID ASC
        LIMIT ?
        ''',
        [userId, dailyLimit],
      );

      return [...dueWords, ...newWords];
    } catch (_) {
      return [];
    }
  }

  /// Kullanıcının cevabına göre kelimenin Leitner seviyesini günceller.
  ///
  /// * [isCorrect] == false → hangi seviyede olursa olsun Level 1'e sıfırla, yarın tekrar sor.
  /// * [isCorrect] == true  →
  ///     - Level 1-5: seviye +1, _reviewIntervals[currentLevel] gün sonrasına planla.
  ///     - Level 6   : IsLearned=1 (bilinen soru havuzu); NextReviewDate 1 yıl sonraya kayıt olarak atanır.
  Future<bool> updateWordLevel(int wordId, bool isCorrect) async {
    try {
      final db = await instance.database;
      final today    = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      if (!isCorrect) {
        // Sıfırlama kuralı: herhangi bir seviyede yanlış → Level 1, yarın tekrar.
        final nextDate =
            today.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
        await db.update(
          'Words',
          {
            'LeitnerLevel': 1,
            'IsLearned': 0,
            'NextReviewDate': nextDate,
            'LastReviewedDate': todayStr,
          },
          where: 'WordID = ?',
          whereArgs: [wordId],
        );
        return true;
      }

      // Doğru cevap: mevcut seviyeyi oku
      final rows = await db.query(
        'Words',
        columns: ['LeitnerLevel'],
        where: 'WordID = ?',
        whereArgs: [wordId],
        limit: 1,
      );
      if (rows.isEmpty) return false;

      final currentLevel = rows.first['LeitnerLevel'] as int;
      final intervalDays = _reviewIntervals[currentLevel]!;
      final nextDate =
          today.add(Duration(days: intervalDays)).toIso8601String().substring(0, 10);

      if (currentLevel >= 6) {
        // 6. ve son başarılı biliş: kelime öğrenildi, sınav havuzundan çıkar.
        await db.update(
          'Words',
          {
            'IsLearned': 1,
            'NextReviewDate': nextDate,   // 365 gün → kayıt amaçlı, sorguya girmez
            'LastReviewedDate': todayStr,
          },
          where: 'WordID = ?',
          whereArgs: [wordId],
        );
      } else {
        // Level 1-5: seviye +1, bir sonraki tarihi planla.
        await db.update(
          'Words',
          {
            'LeitnerLevel': currentLevel + 1,
            'NextReviewDate': nextDate,
            'LastReviewedDate': todayStr,
          },
          where: 'WordID = ?',
          whereArgs: [wordId],
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // WORDLE
  // ─────────────────────────────────────────────

  /// Kullanıcının kelime havuzundan tam 5 harfli rastgele bir İngilizce kelime döner.
  /// Uygun kelime yoksa [null] döner.
  Future<String?> getRandomFiveLetterWord(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT w.EngWordName
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID              = ?
          AND  length(w.EngWordName) = 5
        ORDER BY RANDOM()
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) return null;
      return rows.first['EngWordName'] as String;
    } catch (_) {
      return null;
    }
  }

  /// Wordle için sadece [IsLearned = 1] olan, tam 5 harfli,
  /// kullanıcıya ait rastgele bir kelime döner. Yoksa [null] döner.
  Future<String?> getLearnedWordForWordle(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT w.EngWordName
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID              = ?
          AND  w.IsLearned           = 1
          AND  length(w.EngWordName) = 5
        ORDER BY RANDOM()
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) return null;
      return rows.first['EngWordName'] as String;
    } catch (_) {
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getLearnedWords() async {
    try {
      final db = await instance.database;
      return await db.rawQuery(
        '''
        SELECT w.WordID, w.EngWordName, w.TurWordName
        FROM   Words w
        WHERE  w.IsLearned = 1
        ORDER BY w.EngWordName ASC
        ''',
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllWordsByUser(int userId) async {
    try {
      final db = await instance.database;
      return await db.rawQuery(
        '''
        SELECT w.WordID, w.EngWordName, w.TurWordName, w.IsLearned
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID = ?
        ORDER BY w.EngWordName ASC
        ''',
        [userId],
      );
    } catch (_) {
      return [];
    }
  }
  // ─────────────────────────────────────────────
  // ANALİZ
  // ─────────────────────────────────────────────

   Future<List<Map<String, dynamic>>> getFolderStats(int userId) async {
    try {
    final db = await instance.database;
    return await db.rawQuery( 
    '''
    SELECT
      f.FolderName,
      COUNT(w.WordID)                                    AS TotalWords,
      SUM(CASE WHEN w.IsLearned = 1 THEN 1 ELSE 0 END)  AS LearnedWords
    FROM Folders f
    LEFT JOIN Words w ON w.FolderID = f.FolderID
    WHERE f.UserID = ?
    GROUP BY f.FolderID, f.FolderName
    ORDER BY f.FolderName ASC
    ''',
    [userId],
    );
  } catch (_) {
    return [];
  }
  }

  Future<Map<String, int>> getHomeStats(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          COUNT(w.WordID)                                          AS TotalWords,
          SUM(CASE WHEN w.LeitnerLevel >= 2 THEN 1 ELSE 0 END)   AS ActiveWords,
          SUM(CASE WHEN w.IsLearned = 1 THEN 1 ELSE 0 END)       AS LearnedWords
        FROM Folders f
        LEFT JOIN Words w ON w.FolderID = f.FolderID
        WHERE f.UserID = ?
        ''',
        [userId],
      );
      if (rows.isEmpty) return {'total': 0, 'active': 0, 'learned': 0};
      final r = rows.first;
      return {
        'total': (r['TotalWords'] as int? ?? 0),
        'active': (r['ActiveWords'] as int? ?? 0),
        'learned': (r['LearnedWords'] as int? ?? 0),
      };
    } catch (_) {
      return {'total': 0, 'active': 0, 'learned': 0};
    }
  }

  /// Her Leitner kutusundaki kelime sayısını döner: {1: 25, 2: 10, ...}
  /// IsLearned=1 olan kelimeler de LeitnerLevel=6'da yer alır.
  Future<Map<int, int>> getWordCountByLevel(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT w.LeitnerLevel, COUNT(*) AS Cnt
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID = ?
        GROUP  BY w.LeitnerLevel
        ''',
        [userId],
      );
      final Map<int, int> result = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      for (final row in rows) {
        final level = row['LeitnerLevel'] as int;
        result[level] = row['Cnt'] as int? ?? 0;
      }
      return result;
    } catch (_) {
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    }
  }

  /// Son [days] günde öğrenilen (IsLearned=1 olan) kelime sayısını,
  /// günlük olarak [en eskiden → en yeniye] döner.
  /// Eksik günler 0 ile doldurulur.
  Future<List<int>> getLearnedWordsLastNDays(int userId, int days) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT date(w.LastReviewedDate) AS d, COUNT(*) AS Cnt
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID    = ?
          AND  w.IsLearned = 1
          AND  w.LastReviewedDate >= date('now', ? || ' days')
        GROUP  BY d
        ORDER  BY d ASC
        ''',
        [userId, '-$days'],
      );

      final Map<String, int> byDate = {};
      for (final row in rows) {
        byDate[row['d'] as String] = row['Cnt'] as int? ?? 0;
      }

      final today = DateTime.now();
      return List.generate(days, (i) {
        final date = today.subtract(Duration(days: days - 1 - i));
        final key = date.toIso8601String().substring(0, 10);
        return byDate[key] ?? 0;
      });
    } catch (_) {
      return List.filled(days, 0);
    }
  }

  /// Üst üste kaç gündür en az 1 kelime gözden geçirildiğini döner.
  /// Bugün veya dün ile başlamayan seriler 0 sayılır.
  Future<int> getCurrentStreak(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.rawQuery(
        '''
        SELECT DISTINCT date(w.LastReviewedDate) AS d
        FROM   Words   w
        INNER JOIN Folders f ON f.FolderID = w.FolderID
        WHERE  f.UserID              = ?
          AND  w.LastReviewedDate IS NOT NULL
        ORDER  BY d DESC
        ''',
        [userId],
      );

      if (rows.isEmpty) return 0;

      final today = DateTime.now();
      final todayStr =
          today.toIso8601String().substring(0, 10);
      final yesterdayStr =
          today.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      final dates = rows.map((r) => r['d'] as String).toList();

      // Seri bugün veya dünden başlamalı
      if (dates.first != todayStr && dates.first != yesterdayStr) return 0;

      int streak = 1;
      for (int i = 1; i < dates.length; i++) {
        final prev = DateTime.parse(dates[i - 1]);
        final curr = DateTime.parse(dates[i]);
        if (prev.difference(curr).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> insertStory(Story story) async {
    try {
      final db = await instance.database;
      await db.insert('Stories', story.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Story>> getStories() async {
    try {
      final db = await instance.database;
      final rows = await db.query('Stories', orderBy: 'CreatedAt DESC');
      return rows.map((row) => Story.fromMap(row)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteStory(int id) async {
    try {
      final db = await instance.database;
      await db.delete('Stories', where: 'StoryID = ?', whereArgs: [id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // AYARLAR
  // ─────────────────────────────────────────────

  Future<int> getDailyNewWordCount(int userId) async {
    try {
      final db = await instance.database;
      final rows = await db.query(
        'Users',
        columns: ['DailyWordLimit'],
        where: 'UserID = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) return 10;
      return (rows.first['DailyWordLimit'] as int?) ?? 10;
    } catch (_) {
      return 10;
    }
  }

  Future<bool> setDailyNewWordCount(int userId, int count) async {
    try {
      final db = await instance.database;
      await db.update(
        'Users',
        {'DailyWordLimit': count},
        where: 'UserID = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
