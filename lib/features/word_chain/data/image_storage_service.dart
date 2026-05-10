import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class ImageStorageService {
  static const _timeout = Duration(seconds: 10);

  Future<String?> downloadAndSave(String imagePrompt) async {
    try {
      final encoded = Uri.encodeComponent(imagePrompt);
      final url = Uri.parse(
        'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&safe=true',
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveToGallery(String filePath) async {
    try {
      await Gal.putImage(filePath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
