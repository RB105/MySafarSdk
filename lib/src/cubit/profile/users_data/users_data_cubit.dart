import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart'
    show ProfileService;

part 'users_data_state.dart';

/// "Ma'lumotlarim" — saqlangan yo'lovchilar ro'yxati.
///
/// Strategiya:
///  • keshda ma'lumot bo'lsa — faqat keshdan, serverga bormaydi;
///  • kesh bo'sh va login bo'lsa — serverdan olib keshga yozadi;
///  • token yo'q — keshni tozalaydi, so'rov yubormaydi.
///
/// Prefetch: [prefetchIfNeeded] main ochilganda chaqiriladi — bronlash
/// sahifasidagi "Yo'lovchi tanlash" tugmasi uchun `cached_users` ni to'ldiradi.
class UsersDataCubit extends Cubit<UsersDataState> {
  UsersDataCubit({bool? needGetUsers}) : super(UsersDataInitState()) {
    if (needGetUsers ?? false) {
      getFromCacheOrFetch();
    }
  }

  final _profileService = ProfileService();
  static final _box = sdkStorage();
  static const String cacheKey = 'cached_users';

  bool get _isLoggedIn => MySafarSdk.tokens.isLoggedIn;

  /// Keshda yo'lovchilar ro'yxati saqlanganmi (bo'sh list ham "saqlangan").
  static bool get hasCachedData {
    final raw = _box.read(cacheKey);
    return raw is List;
  }

  /// Keshdan o'qiydi; yo'q yoki buzilgan bo'lsa null.
  static List<UsersModel>? readCache() {
    final raw = _box.read(cacheKey);
    if (raw is! List) return null;
    try {
      return raw
          .map((e) => UsersModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('UsersDataCubit.readCache error: $e');
      return null;
    }
  }

  static Future<void> writeCache(List<UsersModel> users) async {
    await _box.write(
      cacheKey,
      users.map((e) => e.toJson()).toList(),
    );
  }

  static Future<void> clearCache() async {
    await _box.remove(cacheKey);
  }

  /// Main / app start: kesh bo'sh va login bo'lsa — fonda yuklab saqlaydi.
  /// UI holatini o'zgartirmaydi (cubit instance kerak emas).
  static Future<void> prefetchIfNeeded() async {
    if (!MySafarSdk.tokens.isLoggedIn) return;
    if (hasCachedData) return;

    try {
      final response = await ProfileService().getUserDate();
      if (response is! NetworkSuccessResponse) return;

      final users = _parseUsers(response.data);
      await writeCache(users);
    } catch (e) {
      debugPrint('UsersDataCubit.prefetchIfNeeded error: $e');
    }
  }

  static List<UsersModel> _parseUsers(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => UsersModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  /// Kesh → UI; kesh yo'q bo'lsa server.
  Future<void> getFromCacheOrFetch({bool forceRefresh = false}) async {
    if (!_isLoggedIn) {
      await clearCache();
      if (!isClosed) emit(UsersDataEmptyState());
      return;
    }

    if (!forceRefresh) {
      final cached = readCache();
      if (cached != null) {
        if (cached.isEmpty) {
          if (!isClosed) emit(UsersDataEmptyState());
        } else {
          if (!isClosed) emit(UsersDataSuccessState(cached));
        }
        return;
      }
    }

    await fetchFromServer();
  }

  Future<void> fetchFromServer() async {
    if (!_isLoggedIn) {
      await clearCache();
      if (!isClosed) emit(UsersDataEmptyState());
      return;
    }

    emit(UsersDataLoadingState());
    final response = await _profileService.getUserDate();
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      final users = _parseUsers(response.data);
      await writeCache(users);
      if (isClosed) return;
      if (users.isNotEmpty) {
        emit(UsersDataSuccessState(users));
      } else {
        emit(UsersDataEmptyState());
      }
    } else if (response is NetworkErrorResponse) {
      if (response.errorType == ErrorType.emptyResponse) {
        await writeCache(const []);
        if (!isClosed) emit(UsersDataEmptyState());
      } else {
        final cached = readCache();
        if (cached != null && cached.isNotEmpty) {
          emit(UsersDataSuccessState(cached));
        } else {
          emit(UsersDataErrorState(
            error: response.getError(),
            errorType: response.errorType,
          ));
        }
      }
    }
  }

  Future<void> createUser({required Map<String, dynamic> params}) async {
    emit(UsersDataLoadingState());
    final response = await _profileService.createUser(params: params);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(UsersDataCreateState());
    } else if (response is NetworkErrorResponse) {
      if (response.errorType == ErrorType.emptyResponse) {
        emit(UsersDataEmptyState());
      } else {
        emit(UsersDataErrorState(
          error: response.getError(),
          errorType: response.errorType,
        ));
      }
    }
  }

  Future<void> updateUserdata({
    required Map<String, dynamic> params,
    required int id,
  }) async {
    emit(UsersDataLoadingState());
    final response =
        await _profileService.updateUserDate(params: params, id: id);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(UsersDataCreateState());
    } else if (response is NetworkErrorResponse) {
      if (response.errorType == ErrorType.emptyResponse) {
        emit(UsersDataEmptyState());
      } else {
        emit(UsersDataErrorState(
          error: response.getError(),
          errorType: response.errorType,
        ));
      }
    }
  }

  Future<void> deleteUserdata({required int id}) async {
    emit(UsersDataLoadingState());
    final response = await _profileService.deleteUserDate(id: id);
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      emit(UsersDataCreateState());
    } else if (response is NetworkErrorResponse) {
      if (response.errorType == ErrorType.emptyResponse) {
        emit(UsersDataEmptyState());
      } else {
        emit(UsersDataErrorState(
          error: response.getError(),
          errorType: response.errorType,
        ));
      }
    }
  }
}
