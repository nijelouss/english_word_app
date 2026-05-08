// backend_interface.dart

abstract class IBackendService {
  
  // Story 1: Kullanıcı Kayıt
  // Arkadaşın UI'dan email ve şifre yollayacak, sen başarılıysa true, değilse false döneceksin.
  Future<bool> registerUser(String email, String password);
  
  // Story 1: Kullanıcı Giriş
  Future<bool> loginUser(String email, String password);

  // Story 2: Kelime Ekleme
  // Arkadaşın kelimeyi, çevirisini ve resim yolunu yollayacak.
  Future<bool> addWord(String engWord, String turWord, String imagePath);

  // Story 3: Sınav Modülü (Leitner Algoritması)
  // Arkadaşın "Bana bugünün test kelimelerini ver" diyecek, sen liste döneceksin.
  Future<List<Map<String, dynamic>>> getTodayQuizWords();

  // Story 3: Cevap Kontrolü
  // Kullanıcı kelimeyi doğru/yanlış bildiğinde UI bu fonksiyonu çağırıp sana sonucu iletecek.
  // Sen de 6 sefer algoritmasına göre veritabanında tarihi güncelleyeceksin.
  Future<void> updateWordProgress(int wordId, bool isCorrect);

  // Story 5: Analiz
  // Başarı grafiği için yüzde dönecek fonksiyon.
  Future<double> getSuccessRate();
}