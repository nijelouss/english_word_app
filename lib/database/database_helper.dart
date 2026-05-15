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
      version: 4,
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
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE Users (
        UserID         INTEGER PRIMARY KEY AUTOINCREMENT,
        UserName       TEXT    NOT NULL,
        Email          TEXT    NOT NULL UNIQUE,
        PasswordHash   TEXT    NOT NULL,
        DailyWordLimit INTEGER          DEFAULT 10,
        CreatedAt      TEXT    NOT NULL DEFAULT (datetime('now'))
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

  // ─────────────────────────────────────────────
  // KULLANICI İŞLEMLERİ
  // ─────────────────────────────────────────────

  Future<bool> registerUser(String email, String password) async {
    try {
      final db = await instance.database;
      await db.insert(
        'Users',
        {
          'UserName': email.split('@').first,
          'Email': email,
          'PasswordHash': _hashPassword(email, password),
        },
        // Aynı email ile ikinci kayıt denemesinde exception yerine false dön.
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
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
        ORDER BY w.NextReviewDate ASC
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
        ORDER BY w.CreatedAt ASC
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
