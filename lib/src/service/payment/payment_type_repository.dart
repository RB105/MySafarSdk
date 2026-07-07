import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_cache.dart';

/// Firestore `payment_types` — to'lov turlarini o'qiydi va Hive'ga keshlaydi.
///
/// News singari: har olishда kesh yangilanadi. Admin panelda tur qo'shilsa/
/// o'zgartirilsa/o'chirilsa — keyingi yuklashда ilova yangi ma'lumotni oladi va
/// kesh ustma-ust turadi. Server javob bermasa — kesh (yoki lokal zaxira)
/// ishlatiladi.
class PaymentTypeRepository {
  static const String collectionName = 'payment_types';

  // Getter — field emas: Firebase init qilinmagan hostda konstruktorda
  // yiqilmaslik uchun instance'ga faqat guard'dan o'tgach murojaat qilinadi.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final PaymentTypeCache _cache = PaymentTypeCache();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Keshdagi to'lov turlari — darhol ko'rsatish uchun (offline/tez).
  List<PaymentTypeConfig> cached() => _cache.load();

  /// Firestore'dan bir marta o'qiydi, `order` bo'yicha saralaydi va keshni
  /// yangilaydi. Xatolik bo'lsa exception qaytaradi (chaqiruvchi fallback qiladi).
  Future<List<PaymentTypeConfig>> fetch() async {
    // Firebase yo'q — network xatosi kabi exception; chaqiruvchi kesh/lokal
    // zaxiraga o'tadi (mavjud fallback yo'li o'zgarmaydi).
    if (!MySafarSdk.isFirebaseAvailable) {
      throw StateError('Firebase is not initialized in the host app');
    }
    final snap = await _collection.get();
    final list = _mapAndSort(snap.docs);
    // Bo'sh natija keshni buzmasin — faqat ma'lumot bo'lsa yozamiz.
    if (list.isNotEmpty) await _cache.save(list);
    return list;
  }

  /// Real-time oqim — har o'zgarishда yangi ro'yxat + kesh yangilanishi.
  Stream<List<PaymentTypeConfig>> watch() {
    if (!MySafarSdk.isFirebaseAvailable) return Stream.value(cached());
    return _collection.snapshots().map((snap) {
      final list = _mapAndSort(snap.docs);
      if (list.isNotEmpty) _cache.save(list);
      return list;
    });
  }

  List<PaymentTypeConfig> _mapAndSort(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map(PaymentTypeConfig.fromDoc).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
