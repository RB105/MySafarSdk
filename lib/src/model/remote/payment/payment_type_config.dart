import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `payment_types` collection'idagi bitta to'lov turining MATN qismi.
///
/// RASM: `imageUrl` bo'sh bo'lmasa — admin panel yuklagan logotip (Storage'dan)
/// ishlatiladi; bo'sh bo'lsa ilova `name` bo'yicha LOKAL asset'dan oladi
/// (`PaymentConstants.paymentTypeByName`).
///
/// `cardName` — KO'P TILLI yorliq (`{uz, ru, en}`). Bo'sh bo'lsa yorliq
/// ko'rsatilmaydi. Eski hujjatlarda oddiy string bo'lishi ham mumkin.
///
/// ```
/// payment_types/<docId>
///   name:     string        — UPPERCASE identifikator (MYSAFARPAY, PAYME, ...)
///   isActive: bool          — faol/yashirin
///   cardName: { uz, ru, en } — ixtiyoriy ko'rsatiladigan yorliq
///   imageUrl: string?       — ixtiyoriy logotip (bo'lsa lokal rasmdan ustun)
///   order:    number?       — ro'yxatdagi tartib
/// ```
class PaymentTypeConfig {
  /// To'lov turi identifikatori (== eski API `name`), UPPERCASE.
  /// To'lovda `transaction_type` sifatida yuboriladi — barqaror bo'lishi shart.
  final String name;
  final bool isActive;
  final Map<String, String> cardName;
  final String imageUrl;
  final int order;

  const PaymentTypeConfig({
    required this.name,
    required this.isActive,
    this.cardName = const {},
    this.imageUrl = '',
    this.order = 0,
  });

  factory PaymentTypeConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return _build(doc.data() ?? const {}, fallbackName: doc.id);
  }

  factory PaymentTypeConfig.fromMap(Map<String, dynamic> map) {
    return _build(map, fallbackName: '');
  }

  static PaymentTypeConfig _build(
    Map<String, dynamic> data, {
    required String fallbackName,
  }) {
    final rawName = (data['name'] ?? data['id'] ?? fallbackName).toString();
    final active = data['isActive'];
    final rawOrder = data['order'];
    return PaymentTypeConfig(
      name: rawName.toUpperCase(),
      isActive: active is bool ? active : true,
      cardName: _localized(data['cardName'] ?? data['label']),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      order: rawOrder is num ? rawOrder.toInt() : 0,
    );
  }

  /// Joriy [lang] tiliga mos yorliq; mos til bo'lmasa ru→uz→en; hech biri
  /// bo'lmasa bo'sh (yorliq ko'rsatilmaydi).
  String cardNameFor(String lang) => _resolve(cardName, lang);

  Map<String, dynamic> toCacheMap() => {
        'name': name,
        'isActive': isActive,
        'cardName': cardName,
        'imageUrl': imageUrl,
        'order': order,
      };

  /// Map (ko'p tilli) yoki string (eski) qiymatni `{lang: text}` ga aylantiradi.
  static Map<String, String> _localized(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return {'uz': raw};
    }
    return const {};
  }

  static String _resolve(Map<String, String> map, String lang) {
    final v = map[lang];
    if (v != null && v.trim().isNotEmpty) return v.trim();
    for (final f in const ['ru', 'uz', 'en']) {
      final fv = map[f];
      if (fv != null && fv.trim().isNotEmpty) return fv.trim();
    }
    for (final fv in map.values) {
      if (fv.trim().isNotEmpty) return fv.trim();
    }
    return '';
  }
}
