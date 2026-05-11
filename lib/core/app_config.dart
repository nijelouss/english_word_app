import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool get isDemoMode =>
      dotenv.env['DEMO_MODE']?.toLowerCase() == 'true';

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
