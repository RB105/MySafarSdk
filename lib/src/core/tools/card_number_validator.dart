/// Karta raqamini kiritishdagi xatolarni (bir raqam noto'g'ri terilgan,
/// o'rni almashib ketgan) ilovaning o'zida ushlab qolish uchun tekshirgich.
///
/// Asosi — **Luhn (mod 10)** algoritmi: bank kartalari raqamining oxirgi
/// raqami nazorat raqami bo'lib, u qolgan raqamlardan hisoblanadi
/// (ISO/IEC 7812). Shu sababli raqamning "mavjud bo'lishi mumkin"ligini
/// serverga bormasdan aniqlash mumkin.
///
/// Diqqat: Luhn faqat raqamning **matematik jihatdan to'g'ri** ekanini
/// aytadi — bunday karta bank tizimida bor-yo'qligini yoki hisobda pul
/// borligini bildirmaydi. Buni faqat server/protsessing tekshiradi.
class CardNumberValidator {
  const CardNumberValidator._();

  /// ISO/IEC 7812 bo'yicha karta raqami uzunligi chegaralari.
  static const int minLength = 13;
  static const int maxLength = 19;

  /// Raqam bo'lmagan barcha belgilarni (probel, tire) olib tashlaydi.
  static String digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Uzunlik joyidami (13–19 raqam).
  static bool hasValidLength(String value) {
    final length = digitsOf(value).length;
    return length >= minLength && length <= maxLength;
  }

  /// Luhn (mod 10) tekshiruvi.
  ///
  /// Raqamlar **o'ngdan chapga** sanaladi: toq o'rindagilar (1-, 3-, 5- …)
  /// o'zgarmaydi, juft o'rindagilar (2-, 4-, 6- …) ikkiga ko'paytiriladi va
  /// natija 9 dan katta bo'lsa undan 9 ayiriladi. Barcha raqamlar yig'indisi
  /// 10 ga qoldiqsiz bo'linsa — raqam to'g'ri terilgan.
  ///
  /// Masalan `4111 1111 1111 1111` → yig'indi 30 → to'g'ri;
  /// oxirgi raqami almashtirilgan `…1112` → yig'indi 31 → xato.
  static bool passesLuhn(String value) {
    final digits = digitsOf(value);
    if (digits.length < 2) return false;

    int sum = 0;
    for (int i = 0; i < digits.length; i++) {
      // '0' ning kodi 48 — digitsOf faqat raqam qoldirgani uchun xavfsiz.
      int digit = digits.codeUnitAt(digits.length - 1 - i) - 48;
      if (i.isOdd) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return sum % 10 == 0;
  }

  /// Raqam to'liq yaroqlimi: uzunligi ham, nazorat raqami (Luhn) ham to'g'ri.
  static bool isValid(String value) =>
      hasValidLength(value) && passesLuhn(value);
}
