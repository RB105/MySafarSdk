import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/service/account_service.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({bool? needGetProfile}) : super(ProfileState()) {
    if (needGetProfile ?? false) {
      getProfileData();
    }
  }

  final ProfileService _profileService = ProfileService();
  final AccountService _accountService = AccountService();
  final ProfileCache _cache = ProfileCache();

  /// Foydalanuvchi login qilganmi — access token mavjud va bo'sh emasmi.
  /// Token yo'q bo'lsa profilni serverdan yangilashga umuman urinmaymiz.
  bool get _isLoggedIn => MySafarSdk.tokens.isLoggedIn;

  /// Profilni yuklaydi.
  ///
  /// Odatda profil **doim keshdan** olinadi — server so'rovi yubormaydi.
  /// Faqat [forceRefresh] `true` bo'lganda (MyID'dan o'tgach yoki profil
  /// sahifasida qo'lda yangilash bosilganda) serverdan qayta olinib, kesh
  /// to'liq yangilanadi. Kesh bo'sh bo'lsa (birinchi kirish) ham serverdan
  /// olinadi.
  Future<NetworkResponse> getProfileData({bool forceRefresh = false}) async {
    // Login qilinmagan (access_token yo'q) — keshdagi (ehtimol oldingi
    // foydalanuvchi) profilni umuman o'qib/ko'rsatmaymiz va serverga bormaymiz.
    // Keshni ham tozalaymiz — logout'dan keyin PII qolib ketmasin.
    if (!_isLoggedIn) {
      await _cache.clear();
      emit(state.copyWith(profileInfoStatus: ActionStatus.isInitial));
      return NetworkErrorResponse(
        error: 'unauthorized',
        errorType: ErrorType.unAuthorized_401,
      );
    }

    final cachedData = _cache.read();
    ProfileModel? cachedProfile;
    if (cachedData != null) {
      try {
        cachedProfile = ProfileModel.fromJson(cachedData);
        _bindAnalyticsUser(cachedProfile);
        emit(state.copyWith(
          profileInfoStatus: ActionStatus.isSuccess,
          profileModel: cachedProfile,
        ));
      } catch (e) {
        debugPrint("❌ Cache read error: $e");
      }
    } else {
      emit(state.copyWith(profileInfoStatus: ActionStatus.isLoading));
    }

    // Keshda profil bor va majburiy yangilash so'ralmagan bo'lsa — serverga
    // umuman bormaymiz, keshdagi profilni qaytaramiz.
    if (!forceRefresh && cachedProfile != null) {
      return NetworkSuccessResponse(data: cachedProfile);
    }

    final NetworkResponse res = await _profileService.getProfileData();
    if (isClosed) return res;

    if (res is NetworkSuccessResponse) {
      final profile = res.data;
      _bindAnalyticsUser(profile);

      emit(state.copyWith(
        profileInfoStatus: ActionStatus.isSuccess,
        updateProfileStatus: ActionStatus.isInitial,
        profileModel: profile,
      ));

      try {
        await _cache.write(profile.toJson());
      } catch (e) {
        debugPrint("❌ Cache write error: $e");
      }

      return NetworkSuccessResponse(data: profile);
    } else {
      emit(state.copyWith(
        profileInfoStatus: ActionStatus.isError,
        updateProfileStatus: ActionStatus.isInitial,
        profileInfoError: (res as NetworkErrorResponse).errorType?.name,
      ));
      return res;
    }
  }


  Future<void> updateProfileData(ProfileModel profileModel) async {
    emit(state.copyWith(updateProfileStatus: ActionStatus.isLoading));

    final res = await _accountService.updateProfile(profileModel.toFormData());
    if (isClosed) return;

    if (res is NetworkSuccessResponse) {
      emit(state.copyWith(updateProfileStatus: ActionStatus.isSuccess));
      showToastMessage('profile_success_update'.tr());

      try {
        await _cache.write(profileModel.toJson());
      } catch (e) {
        debugPrint("❌ Cache update error: $e");
      }

      if (!isClosed) {
        // Tahrirdan keyin serverdan yangilab olamiz (sessiya bayrog'iga qaramay).
        getProfileData(forceRefresh: true);
      }
    } else {
      if (isClosed) return;
      emit(state.copyWith(
        updateProfileStatus: ActionStatus.isError,
        updateProfileError: res.toString(),
      ));
      showToastMessage((res as NetworkErrorResponse).errorType?.name ?? '');
    }
  }

  Future<void> clearCache() async {
    await _cache.clear();
  }

  /// Analitika eventlarini backend account ID'siga (kanonik `profile_id`)
  /// bog'laydi. Profil har yuklanganda (cache + server) chaqiriladi, shu bilan
  /// har app sessiyasida profil ID qayta o'rnatiladi.
  void _bindAnalyticsUser(ProfileModel? profile) {
    final id = profile?.id;
    if (id == null) return;
    AnalyticsService().setUser(userId: id.toString());
  }
}
