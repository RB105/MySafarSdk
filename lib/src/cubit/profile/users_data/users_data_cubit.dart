import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';

import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart'
    show ProfileService;
part 'users_data_state.dart';


class UsersDataCubit extends Cubit<UsersDataState> {
  UsersDataCubit({bool? needGetUsers}) : super(UsersDataInitState()) {
   if(needGetUsers??false){
     getFromCacheOrFetch();
   }
  }

  final _profileService = ProfileService();
  final _box = GetStorage();
  final String _cacheKey = "cached_users";

  Future<void> getFromCacheOrFetch() async {
    emit(UsersDataLoadingState());
    final cachedData = _box.read(_cacheKey);
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = cachedData;
        final users = decoded.map((e) => UsersModel.fromJson(e)).toList();
       if(users.isNotEmpty){
         emit(UsersDataSuccessState(users));
       }else{
         emit(UsersDataEmptyState());
       }
        return;
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    await fetchFromServer();
  }


  Future<void> fetchFromServer() async {
    emit(UsersDataLoadingState());
    final response = await _profileService.getUserDate();
    if (isClosed) return;
    if (response is NetworkSuccessResponse) {
      final users = (response.data as List)
          .map((e) => UsersModel.fromJson(e))
          .toList();
      if(users.isNotEmpty){
        _box.write(_cacheKey, users.map((e) => e.toJson()).toList());
        emit(UsersDataSuccessState(users));
      }else{
        emit(UsersDataEmptyState());
      }
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
  void clearCache() {
    _box.remove(_cacheKey);
  }
  Future<void> createUser({required Map<String,dynamic> params}) async {
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
   Future<void> updateUserdata({required Map<String,dynamic> params,required int id}) async {
    emit(UsersDataLoadingState());
    final response = await _profileService.updateUserDate(params: params,id: id);
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
