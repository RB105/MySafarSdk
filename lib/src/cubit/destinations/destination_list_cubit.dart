import 'package:mysafar_sdk/src/model/remote/destination/destination_list_model.dart';
import 'package:mysafar_sdk/src/service/fornex/fornex_repository.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'destination_list_state.dart';

/// "Yo'nalishlar" tabi ro'yxati — `POST /v1/destination/list` dan sahifalab yuklaydi.
class DestinationListCubit extends Cubit<DestinationListState> {
  DestinationListCubit({this.pageSize = 10})
      : super(DestinationListLoadingState()) {
    loadNext();
  }

  final int pageSize;
  final FornexRepository _repo = FornexRepository();

  final List<DestinationListItem> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _busy = false;

  Future<void> loadNext() async {
    if (_busy || !_hasMore) return;
    _busy = true;
    if (_items.isEmpty) {
      emit(DestinationListLoadingState());
    } else {
      emit(DestinationListSuccessState(
        List.unmodifiable(_items),
        hasMore: _hasMore,
        loadingMore: true,
      ));
    }

    final response = await _repo.getDestinationList(
      page: _page + 1,
      pageSize: pageSize,
    );
    _busy = false;
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      final result = response.data as DestinationListPageResult;
      _page += 1;
      _items.addAll(result.items);
      _hasMore = result.hasNext && result.items.isNotEmpty;
      emit(DestinationListSuccessState(
        List.unmodifiable(_items),
        hasMore: _hasMore,
        loadingMore: false,
      ));
    } else if (_items.isEmpty) {
      emit(DestinationListErrorState());
    } else {
      emit(DestinationListSuccessState(
        List.unmodifiable(_items),
        hasMore: _hasMore,
        loadingMore: false,
      ));
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    _busy = false;
    await loadNext();
  }
}
