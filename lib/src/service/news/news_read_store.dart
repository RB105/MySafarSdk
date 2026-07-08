import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';
import 'package:mysafar_sdk/src/service/news/news_repository.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

/// Qaysi yangiliklar o'qilganini qurilmada saqlaydi (per-device).
///
/// News Firestore'da barcha uchun umumiy, ammo "o'qildi" holati har bir
/// foydalanuvchining o'z qurilmasida lokal (GetStorage) saqlanadi.
class NewsReadStore {
  NewsReadStore._();
  static final NewsReadStore instance = NewsReadStore._();
  factory NewsReadStore() => instance;

  static const String _key = 'read_news_ids';
  final GetStorage _storage = sdkStorage();

  /// Bell ikonkasidagi o'qilmagan soni — global kuzatiladi (badge shu orqali
  /// yangilanadi).
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Set<String> get readIds {
    final raw = _storage.read(_key);
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return <String>{};
  }

  bool isRead(String id) => readIds.contains(id);

  Future<void> markRead(String id) async {
    final ids = readIds..add(id);
    await _storage.write(_key, ids.toList());
  }

  Future<void> markAllRead(Iterable<String> newsIds) async {
    final ids = readIds..addAll(newsIds);
    await _storage.write(_key, ids.toList());
  }

  /// Berilgan ro'yxatga qarab o'qilmagan sonini qayta hisoblaydi.
  void recompute(List<NewsModel> news) {
    final read = readIds;
    unreadCount.value = news.where((n) => !read.contains(n.id)).length;
  }

  /// Home ekrani uchun: Firestore'dan o'qib, o'qilmagan sonini yangilaydi.
  /// Firestore hali yoqilmagan bo'lsa — xato yutiladi, badge 0 bo'lib qoladi.
  Future<void> refreshUnreadCount() async {
    try {
      final news = await NewsRepository().getNews();
      recompute(news);
    } catch (_) {
      // e'tiborsiz
    }
  }
}
