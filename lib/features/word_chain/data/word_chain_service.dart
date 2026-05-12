import 'package:english_word_app/database/database_helper.dart';
import 'package:english_word_app/features/word_chain/data/gemini_service.dart';
import 'package:english_word_app/features/word_chain/data/image_storage_service.dart';
import 'package:english_word_app/features/word_chain/models/story.dart';

class WordChainService {
  final _gemini = GeminiService();
  final _imageStorage = ImageStorageService();

  Future<Story?> generate({
    required List<int> wordIds,
    required List<String> wordNames,
    required String displayMode,
  }) async {
    // 1. Gemini'den metin + image_prompt al — exception'lar üste taşınır
    final result = await _gemini.generateStory(wordNames, displayMode);
    if (result == null) return null;

    final englishStory = result['english_story'];
    final imagePrompt = result['image_prompt'];
    if (englishStory == null || imagePrompt == null) return null;

    // 2. Görseli indir ve kaydet (başarısız olsa hikayeye devam et)
    String? imagePath;
    try {
      imagePath = await _imageStorage.downloadAndSave(imagePrompt);
    } catch (_) {
      imagePath = null;
    }

    // 3. Story nesnesini oluştur
    final story = Story(
      contentEN: englishStory,
      contentTR: result['turkish_story'],
      imagePath: imagePath,
      wordList: wordNames.join(', '),
      wordIDs: wordIds.toString(),
      displayMode: displayMode,
      createdAt: DateTime.now().toIso8601String(),
    );

    // 4. DB'ye kaydet
    final saved = await DatabaseHelper.instance.insertStory(story);
    if (!saved) return null;

    return story;
  }
}
