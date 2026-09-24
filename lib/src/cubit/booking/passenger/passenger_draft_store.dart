import 'package:mysafar_sdk/src/model/local/passenger_model.dart';

/// Bron formasining qoralamasi — foydalanuvchi orqaga qaytib boshqa reys
/// tanlasa ham kiritilgan yo'lovchilar, email va telefon yo'qolmaydi.
///
/// Xavfsizlik: faqat xotirada (in-memory) saqlanadi — pasport ma'lumotlari
/// diskka yozilmaydi. Ilova yopilsa yoki host [clear] chaqirsa
/// (`MySafarSdk.clearUserData`) o'chadi.
///
/// Kalit — yo'lovchilar tarkibi (`adt-chd-inf`): tarkib bir xil bo'lsa
/// boshqa reysga ham qo'llanadi (yosh / pasport qoidalari baribir yangi reys
/// sanalari bo'yicha qayta tekshiriladi).
class PassengerDraftStore {
  PassengerDraftStore._();

  static final Map<String, PassengerDraft> _drafts = {};

  /// Bron yaratilgach oshiriladi — o'sha oqimdagi (eski) cubit yopilganda
  /// qoralamani qayta yozib qo'ymasin: keyingi bron boshqa odam uchun
  /// bo'lishi mumkin.
  static int _generation = 0;

  static int get generation => _generation;

  static String keyFor(int adults, int children, int infants) =>
      '$adults-$children-$infants';

  static PassengerDraft? read(String key) => _drafts[key];

  static void write(String key, PassengerDraft draft, {int? generation}) {
    if (generation != null && generation != _generation) return;
    // Faqat bitta tarkib saqlanadi — eski qoralamalar xotirada to'planmasin.
    _drafts
      ..clear()
      ..[key] = draft;
  }

  static void clear() => _drafts.clear();

  /// Bron muvaffaqiyatli yaratildi — qoralama o'chiriladi va shu oqimdagi
  /// cubit'lar uni qayta yoza olmaydi.
  static void markBooked() {
    _drafts.clear();
    _generation++;
  }
}

class PassengerDraft {
  final List<PassengerModel> passengers;
  final String email;
  final String phone;
  final Set<int> saveToProfile;

  const PassengerDraft({
    required this.passengers,
    required this.email,
    required this.phone,
    required this.saveToProfile,
  });
}
