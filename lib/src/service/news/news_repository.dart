import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';
import 'package:mysafar_sdk/src/service/news/news_cache.dart';

import '../../view/imports/app_imports.dart';

/// Firestore'dagi `news` collection'i bilan ishlash uchun repository.
///
/// News'lar admin panel orqali kiritiladi — ilova faqat o'qiydi.
/// Har safar Firestore'dan yangi ro'yxat kelганда Hive keshi yangilanadi, shu
/// bois news qo'shilsa/tahrirlansa/o'chirilsa kesh doim ustma-ust turadi.
class NewsRepository {
  static const String collectionName = 'news';

  // Getter — field emas: Firebase init qilinmagan hostda konstruktorda
  // yiqilmaslik uchun instance'ga faqat guard'dan o'tgach murojaat qilinadi.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final NewsCache _cache = NewsCache();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Hive keshidagi yangiliklar — Firestore javobidan oldin darhol ko'rsatish
  /// uchun (offline/tez ochilish).
  List<NewsModel> cachedNews() => _cache.load();

  /// Barcha (`isActive != false`) yangiliklarni yangi'dan eski tartibida
  /// bir marta o'qib beradi va keshni yangilaydi.
  Future<List<NewsModel>> getNews() async {
    // Firebase yo'q (host init qilmagan) — kesh bilan kifoyalanamiz.
    if (!MySafarSdk.isFirebaseAvailable) return cachedNews();
    final snapshot =
        await _collection.orderBy('createdAt', descending: true).get();

    final list = snapshot.docs.where(_isActive).map(NewsModel.fromDoc).toList();
    await _cache.save(list);
    return list;
  }

  /// Real-time oqim — news qo'shilsa/o'zgarsa/o'chirilsa darhol yangi ro'yxat
  /// keladi va shu zahoti kesh ham yangilanadi.
  Stream<List<NewsModel>> watchNews() {
    if (!MySafarSdk.isFirebaseAvailable) return Stream.value(cachedNews());
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.where(_isActive).map(NewsModel.fromDoc).toList();
      // Fon rejimida keshni yangilaymiz (stream'ni bloklamaymiz).
      _cache.save(list);
      return list;
    });
  }

  /// Console'da `isActive: false` qo'yilgan hujjatlarni yashiramiz.
  /// Maydon umuman yo'q bo'lsa — ko'rsatamiz.
  bool _isActive(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()?['isActive'];
    return value is bool ? value : true;
  }

  /// Firestore'da o'qilganlar sonini (read count) bittaga oshiradi.
  Future<void> incrementReadCount(String newsId) async {
    if (!MySafarSdk.isFirebaseAvailable) return;
    try {
      await _collection.doc(newsId).update({
        'read': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("NewsRepository.incrementReadCount error: $e");
    }
  }

  /// Bir nechta yangiliklarni o'qilgan deb belgilash (batch).
  Future<void> incrementMultipleReadCounts(Iterable<String> newsIds) async {
    if (newsIds.isEmpty || !MySafarSdk.isFirebaseAvailable) return;
    try {
      final batch = _firestore.batch();
      for (final id in newsIds) {
        batch.update(_collection.doc(id), {
          'read': FieldValue.increment(1),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("NewsRepository.incrementMultipleReadCounts error: $e");
    }
  }
}
