import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart';

// States
abstract class UpdateProfileState {}

class UpdateProfileInitial extends UpdateProfileState {}

class UpdateProfileLoading extends UpdateProfileState {}

class UpdateProfileSuccess extends UpdateProfileState {
  final ProfileModel profileModel;
  UpdateProfileSuccess(this.profileModel);
}

class UpdateProfileError extends UpdateProfileState {
  final String error;
  UpdateProfileError(this.error);
}

// Cubit
class UpdateProfileCubit extends Cubit<UpdateProfileState> {
  UpdateProfileCubit() : super(UpdateProfileInitial());

  final ProfileService _profileService = ProfileService();
  final ProfileCache _cache = ProfileCache();

  Future<void> updateProfile(ProfileModel profileModel) async {
    emit(UpdateProfileLoading());

    final response = await _profileService.updateProfileData(profileModel);
    if (isClosed) return;

    if (response is NetworkSuccessResponse) {
      final updatedProfile = response.data as ProfileModel;
      try {
        await _cache.write(updatedProfile.toJson());
      } catch (e) {
        debugPrint("❌ Cache update error: $e");
      }

      if (isClosed) return;
      showToastMessage('profile_success_update'.tr());
      emit(UpdateProfileSuccess(updatedProfile));
    } else if (response is NetworkErrorResponse) {
      emit(UpdateProfileError(response.getError()));
    }
  }
}
