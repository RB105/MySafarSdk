import 'dart:async';

import 'package:mysafar_sdk/src/model/remote/news/news_model.dart';
import 'package:mysafar_sdk/src/service/news/news_read_store.dart';
import 'package:mysafar_sdk/src/service/news/news_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  NewsCubit() : super(const NewsInitState()) {
    getNews();
  }

  final NewsRepository _repository = NewsRepository();
  final NewsReadStore _readStore = NewsReadStore();
  StreamSubscription<List<NewsModel>>? _sub;

  /// Avval Hive keshidan darhol ko'rsatadi, so'ng Firestore real-time oqimiga
  /// ulanadi. News qo'shilsa/tahrirlansa/o'chirilsa — oqim yangi ro'yxat beradi,
  /// UI ham, kesh ham avtomatik yangilanadi.
  ///
  /// Pull-to-refresh / retry ham shu metodni chaqiradi — oqim qayta ulanadi.
  Future<void> getNews() async {
    // 1. Keshda ma'lumot bo'lsa — spinnersiz darhol ko'rsatamiz.
    final cached = _repository.cachedNews();
    if (cached.isNotEmpty) {
      _readStore.recompute(cached);
      emit(NewsSuccessState(cached, _readStore.readIds));
    } else if (state is! NewsSuccessState) {
      emit(const NewsLoadingState());
    }

    // 2. Real-time oqimga (qayta) ulanamiz.
    await _sub?.cancel();
    _sub = _repository.watchNews().listen(
      (news) {
        if (isClosed) return;
        _readStore.recompute(news);
        emit(NewsSuccessState(news, _readStore.readIds));
      },
      onError: (e) {
        debugPrint("NewsCubit : $e");
        if (isClosed) return;
        // Kesh allaqachon ko'rsatilgan bo'lsa, xatoni ko'rsatmaymiz.
        if (state is! NewsSuccessState) emit(const NewsErrorState());
      },
    );
  }

  /// Bitta yangilikni o'qilgan deb belgilaydi.
  Future<void> markAsRead(String id) async {
    final current = state;
    if (current is! NewsSuccessState) return;
    if (current.readIds.contains(id)) return;

    // 1. Lokal (Badge/UI uchun)
    await _readStore.markRead(id);
    if (isClosed) return;
    _readStore.recompute(current.news);
    emit(NewsSuccessState(current.news, _readStore.readIds));

    // 2. Remote (Admin panel uchun read count)
    await _repository.incrementReadCount(id);
  }

  /// Barcha yangiliklarni o'qilgan deb belgilaydi.
  Future<void> markAllRead() async {
    final current = state;
    if (current is! NewsSuccessState) return;

    final allIds = current.news.map((n) => n.id).toList();
    final unreadIds =
        allIds.where((id) => !current.readIds.contains(id)).toList();

    // 1. Lokal
    await _readStore.markAllRead(allIds);
    if (isClosed) return;
    _readStore.recompute(current.news);
    emit(NewsSuccessState(current.news, _readStore.readIds));

    // 2. Remote
    if (unreadIds.isNotEmpty) {
      await _repository.incrementMultipleReadCounts(unreadIds);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
