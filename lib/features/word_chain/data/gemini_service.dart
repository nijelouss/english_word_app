import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const _modelName = 'gemini-2.0-flash-lite';

  Future<Map<String, String?>?> generateStory(
    List<String> words,
    String displayMode,
  ) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = _buildPrompt(words, displayMode);
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      final text = response.text ?? '';

      final json = jsonDecode(text) as Map<String, dynamic>;
      return {
        'english_story': json['english_story'] as String?,
        'turkish_story': json['turkish_story'] as String?,
        'image_prompt': json['image_prompt'] as String?,
      };
    } catch (_) {
      return null;
    }
  }

  String _buildPrompt(List<String> words, String displayMode) {
    final wordList = words.join(', ');
    final needsTurkish = displayMode == 'tr' || displayMode == 'both';

    return '''
You are a language learning assistant. Respond ONLY with valid JSON, no markdown.

Write a short English story (80-120 words) using ALL of these words: $wordList

Rules:
- B1 level vocabulary
- Friendly tone
- Bold each target word like this: **word**
- image_prompt: English only, max 20 words, one scene, add style like "digital illustration"
${needsTurkish ? '- turkish_story: Turkish translation of the English story' : '- Set turkish_story to null'}

Respond with this exact JSON:
{
  "english_story": "...",
  "turkish_story": ${needsTurkish ? '"..."' : 'null'},
  "image_prompt": "..."
}
''';
  }
}
