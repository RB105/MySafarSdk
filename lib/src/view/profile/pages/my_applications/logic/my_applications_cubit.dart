import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import '../service/my_application_model.dart';
import '../service/my_applications_service.dart';

part 'my_applications_state.dart';

class MyApplicationsCubit extends Cubit<MyApplicationsState> {
  MyApplicationsCubit() : super(MyApplicationsInitState());

  final MyApplicationsService _service = MyApplicationsService();

  /// In-memory cache. Ilovadan chiqib kirgunga qadar saqlanadi.
  static List<MyApplicationModel>? _cache;
  static String? _cacheKey;

  /// Logout / hisobni almashtirishda chaqirilsin — eski foydalanuvchi
  /// ma'lumotlari yangi sessiyaga o'tib ketmasligi uchun.
  static void clearCache() {
    _cache = null;
    _cacheKey = null;
  }

  Future<void> loadApplications(String pinfl, {bool force = false}) async {
    if (!force && _cacheKey == pinfl && _cache != null) {
      emit(MyApplicationsSuccessState(_cache!));
      return;
    }

    emit(MyApplicationsLoadingState());
    final response = await _service.getMyApplications(pinfl: pinfl);
    if (isClosed) return;

    if (response is NetworkSuccessResponse<List<MyApplicationModel>>) {
      _cache = response.data;
      _cacheKey = pinfl;
      emit(MyApplicationsSuccessState(response.data));
    } else if (response is NetworkErrorResponse) {
      emit(MyApplicationsErrorState(response.getError()));
    } else {
      emit(MyApplicationsInitState());
    }
  }
}
