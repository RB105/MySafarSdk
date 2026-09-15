import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';

/// Saqlangan yo'lovchilar bo'yicha qidiruv.
///
/// * familiya, ism, otasining ismi, hujjat raqami, tug'ilgan sana bo'yicha;
/// * bir nechta so'z — har biri mos kelishi kerak ("ali val" → ALIYEV VALI);
/// * kirill ↔ lotin ("алиев" → ALIYEV), apostrof turlari, `kh`/`x`, `zh`/`j`
///   farqi e'tiborga olinmaydi;
/// * hujjat raqami va sanadagi bo'shliq/nuqta/tire e'tiborga olinmaydi;
/// * familiya yoki ism so'rov bilan boshlanganlar ro'yxat boshida.
class SavedPassengerSearch {
  SavedPassengerSearch._();

  static const Map<String, String> _cyrillic = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'е': 'e',
    'ё': 'yo',
    'ж': 'j',
    'з': 'z',
    'и': 'i',
    'й': 'y',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'с': 's',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'х': 'x',
    'ц': 'ts',
    'ч': 'ch',
    'ш': 'sh',
    'щ': 'sh',
    'ъ': '',
    'ы': 'i',
    'ь': '',
    'э': 'e',
    'ю': 'yu',
    'я': 'ya',
    'ў': 'o',
    'қ': 'q',
    'ғ': 'g',
    'ҳ': 'h',
    'ә': 'a',
    'ө': 'o',
    'ү': 'u',
    'ұ': 'u',
    'і': 'i',
    'ң': 'n',
    'ҷ': 'j',
    'ӣ': 'i',
    'ӯ': 'u',
  };

  /// Taqqoslash uchun kanonik ko'rinish: kichik harf, kirill → lotin,
  /// apostrof va diakritikasiz, `kh` → `x`, `zh` → `j`.
  static String normalize(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_cyrillic[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r"[ʻʼ‘’`´']"), '')
        .replaceAll('kh', 'x')
        .replaceAll('zh', 'j')
        // Алиев / Aliyev / yozilayotgan "aliy" — hammasi `ali...`.
        .replaceAll('iy', 'i');
  }

  /// Faqat harf va raqamlar (hujjat raqami, sana uchun).
  static String _compact(String value) =>
      normalize(value).replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// [users] ichidan [query] ga mos kelganlarni, eng mosi birinchi bo'lib
  /// qaytaradi. Bo'sh so'rov — ro'yxat o'zgarmaydi.
  static List<UsersModel> filter(List<UsersModel> users, String query) {
    final tokens = normalize(query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return users;

    final ranked = <({UsersModel user, int score, int index})>[];
    for (int i = 0; i < users.length; i++) {
      final score = _score(users[i], tokens);
      if (score > 0) ranked.add((user: users[i], score: score, index: i));
    }
    ranked.sort(
        (a, b) => b.score != a.score ? b.score - a.score : a.index - b.index);
    return [for (final r in ranked) r.user];
  }

  /// 0 — mos emas. Katta qiymat — yaxshiroq moslik.
  static int _score(UsersModel user, List<String> tokens) {
    final nameWords = [user.lastname, user.firstname, user.middlename]
        .map((w) => normalize(w ?? '').trim())
        .where((w) => w.isNotEmpty)
        .expand((w) => w.split(RegExp(r'[\s-]+')))
        .toList();
    final fullName = nameWords.join(' ');
    final docnum = _compact(user.docnum ?? '');
    final birthdate = _compact(user.birthdate ?? '');

    int total = 0;
    for (final token in tokens) {
      final compactToken = token.replaceAll(RegExp(r'[^a-z0-9]'), '');
      int best = 0;
      for (int w = 0; w < nameWords.length; w++) {
        // Familiya > ism > otasining ismi; aniq moslik > boshlanishi.
        final int score;
        if (nameWords[w] == token) {
          score = switch (w) { 0 => 100, 1 => 95, _ => 55 };
        } else if (nameWords[w].startsWith(token)) {
          score = switch (w) { 0 => 65, 1 => 60, _ => 45 };
        } else {
          continue;
        }
        if (score > best) best = score;
      }
      if (best == 0 && fullName.contains(token)) best = 20;
      if (compactToken.isNotEmpty) {
        if (docnum.isNotEmpty && docnum.startsWith(compactToken)) {
          best = best < 70 ? 70 : best;
        } else if (docnum.contains(compactToken)) {
          best = best < 30 ? 30 : best;
        }
        if (compactToken.length >= 2 && birthdate.contains(compactToken)) {
          best = best < 25 ? 25 : best;
        }
      }
      if (best == 0) return 0;
      total += best;
    }
    return total;
  }

  /// Ko'rsatiladigan [text] ichida [query] so'zlari bilan boshlanadigan
  /// so'z bo'laklarining oralig'i (`start`, `end`) — ajratib ko'rsatish uchun.
  /// Faqat to'g'ridan-to'g'ri (lotin) moslik belgilanadi.
  static List<(int, int)> highlightRanges(String text, String query) {
    final tokens = query
        .toLowerCase()
        .replaceAll(RegExp(r"[ʻʼ‘’`´']"), "'")
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const [];
    final lower = text.toLowerCase().replaceAll(RegExp(r"[ʻʼ‘’`´']"), "'");
    final ranges = <(int, int)>[];
    for (final match in RegExp(r"[^\s-]+").allMatches(lower)) {
      final word = match.group(0)!;
      int longest = 0;
      for (final token in tokens) {
        if (word.startsWith(token) && token.length > longest) {
          longest = token.length;
        }
      }
      if (longest > 0) ranges.add((match.start, match.start + longest));
    }
    return ranges;
  }
}
