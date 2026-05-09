enum LetterMatch { correct, present, absent }

/// Kullanıcının tahminini hedef kelimeyle karşılaştırır ve her harf için
/// bir [LetterMatch] durumu döner.
///
/// Tekrarlayan harf kuralı (standart Wordle):
///   1. Geçiş: doğru pozisyondaki harfler [correct] işaretlenir ve
///      hedef havuzundan düşülür.
///   2. Geçiş: kalan pozisyonlar sırayla kontrol edilir; hedef havuzunda
///      harf kalmışsa [present], yoksa [absent] döner.
///
/// Örnek — hedef "APPLE", tahmin "PUPPY":
///   P[0]=present  U[1]=absent  P[2]=correct  P[3]=absent  Y[4]=absent
List<LetterMatch> checkWordleGuess(String guess, String targetWord) {
  final g = guess.toUpperCase();
  final t = targetWord.toUpperCase();
  final len = t.length;

  final result = List<LetterMatch>.filled(len, LetterMatch.absent);

  // Hedef harflerinin frekans tablosu; her geçişte tüketilir.
  final targetFreq = <String, int>{};
  for (var i = 0; i < len; i++) {
    final ch = t[i];
    targetFreq[ch] = (targetFreq[ch] ?? 0) + 1;
  }

  // 1. Geçiş: tam eşleşmeler (correct)
  for (var i = 0; i < len; i++) {
    if (g[i] == t[i]) {
      result[i] = LetterMatch.correct;
      targetFreq[g[i]] = targetFreq[g[i]]! - 1;
    }
  }

  // 2. Geçiş: yanlış pozisyonda bulunan harfler (present / absent)
  for (var i = 0; i < len; i++) {
    if (result[i] == LetterMatch.correct) continue;

    final ch = g[i];
    if ((targetFreq[ch] ?? 0) > 0) {
      result[i] = LetterMatch.present;
      targetFreq[ch] = targetFreq[ch]! - 1;
    }
    // else: result[i] zaten absent olarak başlatıldı, değişiklik yok.
  }

  return result;
}
