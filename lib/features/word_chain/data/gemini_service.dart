import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:english_word_app/core/app_config.dart';
import 'package:english_word_app/core/exceptions.dart';

class GeminiService {
  static const _modelName = 'gemini-2.0-flash-lite';

  Future<Map<String, String?>?> generateStory(
    List<String> words,
    String displayMode, {
    bool? demoMode,
  }) async {
    final useDemo = demoMode ?? AppConfig.isDemoMode;

    if (useDemo) {
      try {
        final jsonStr =
            await rootBundle.loadString('assets/demo/demo_story.json');
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return {
          'english_story': json['english_story'] as String?,
          'turkish_story': json['turkish_story'] as String?,
          'image_prompt': json['image_prompt'] as String?,
        };
      } catch (_) {
        throw GeminiException('Demo içerik yüklenemedi');
      }
    }

    late final GenerateContentResponse response;
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
      final prompt = _buildPrompt(words, displayMode);
      response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw TimeoutAppException('Gemini isteği zaman aşımına uğradı');
    } catch (e) {
      throw NetworkException('Gemini bağlantı hatası: $e');
    }

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw GeminiException('Boş yanıt alındı');
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return {
        'english_story': json['english_story'] as String?,
        'turkish_story': json['turkish_story'] as String?,
        'image_prompt': json['image_prompt'] as String?,
      };
    } on FormatException {
      throw GeminiException('Geçersiz yanıt formatı');
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
