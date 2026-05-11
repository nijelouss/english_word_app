import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:english_word_app/core/app_config.dart';
import 'package:english_word_app/core/exceptions.dart';

class ImageStorageService {
  static const _timeout = Duration(seconds: 10);

  Future<String?> downloadAndSave(String imagePrompt, {bool? demoMode}) async {
    final useDemo = demoMode ?? AppConfig.isDemoMode;

    if (useDemo) {
      try {
        final byteData =
            await rootBundle.load('assets/demo/demo_image.png');
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/demo_image.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        return file.path;
      } catch (_) {
        throw ImageDownloadException('Demo görsel yüklenemedi');
      }
    }

    final encoded = Uri.encodeComponent(imagePrompt);
    final url = Uri.parse(
      'https://image.pollinations.ai/prompt/$encoded?width=512&height=512&nologo=true&safe=true',
    );

    late final http.Response response;
    try {
      response = await http.get(url).timeout(_timeout);
    } on TimeoutException {
      throw TimeoutAppException('Görsel indirme zaman aşımına uğradı');
    } on SocketException {
      throw NetworkException('İnternet bağlantısı yok');
    } catch (e) {
      throw NetworkException('Görsel indirme hatası: $e');
    }

    if (response.statusCode != 200) {
      throw ImageDownloadException(
        'HTTP ${response.statusCode}: Görsel indirilemedi',
      );
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      throw ImageDownloadException('Görsel kaydedilemedi: $e');
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
