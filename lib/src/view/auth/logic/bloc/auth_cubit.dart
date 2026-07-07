import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/service/auth_service.dart';
import 'package:mysafar_sdk/src/service/telegram_auth.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final GoogleSignIn _googleSignIn;
  final AuthService _authService;

  AuthCubit({
    GoogleSignIn? googleSignIn,
    AuthService? authService,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _authService = authService ?? AuthService(),
        super(const AuthState()) {
    // Client ID'lar endi hardcode emas — host `MySafarConfig.socialAuth`
    // orqali beradi. Berilmagan bo'lsa Google tugmasi UI'da ko'rsatilmaydi.
    final google = MySafarSdk.config.socialAuth?.google;
    if (google != null) {
      _googleSignIn.initialize(
        serverClientId: Platform.isAndroid
            ? google.serverClientIdAndroid
            : google.serverClientIdIos,
      );
    }
  }

  /// Google tugmasini ko'rsatish sharti: config berilgan VA host Firebase'ni
  /// init qilgan (kirish oqimi FirebaseAuth orqali o'tadi).
  static bool get googleAuthEnabled =>
      MySafarSdk.config.socialAuth?.google != null &&
      MySafarSdk.isFirebaseAvailable;

  /// Telegram tugmasini ko'rsatish sharti.
  static bool get telegramAuthEnabled =>
      MySafarSdk.config.socialAuth?.telegram != null;

  Future<void> googleSignIn() async {
    emit(state.copyWith(
      googleAuthStatus: ActionStatus.isLoading,
      authError: '',
    ));

    try {
      final account = await _googleSignIn.authenticate();

      final googleAuth = account.authentication;
      final googleIdToken = googleAuth.idToken;
      final credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final NetworkResponse res = await _authService.googleAuth(
        token: googleIdToken!,
        email: account.email,
      );

      if (res is NetworkSuccessResponse) {
        emit(state.copyWith(googleAuthStatus: ActionStatus.isSuccess));
      } else if (res is NetworkErrorResponse) {
        emit(state.copyWith(
          googleAuthStatus: ActionStatus.isError,
          authError: res.errorType?.name.toString(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        googleAuthStatus: ActionStatus.isError,
        authError: e.message ?? 'Unknown Firebase error',
      ));
    } on Exception catch (e) {
      debugPrint("Google Sign in exception: ${e.toString()}");
      emit(state.copyWith(
        googleAuthStatus: ActionStatus.isError,
        authError: e.toString(),
      ));
    }
  }

  Future<void> telegramSignIn() async {
    emit(state.copyWith(
      telegramAuthStatus: ActionStatus.isLoading,
      authError: '',
    ));

    try {
      final idToken = await TelegramLoginService.loginWithTelegram();
      if (idToken == null || idToken.isEmpty) {
        emit(state.copyWith(telegramAuthStatus: ActionStatus.isInitial));
        return;
      }
      final NetworkResponse res = await _authService.telegramAuth(
        token: idToken,
      );

      if (res is NetworkSuccessResponse) {
        emit(state.copyWith(telegramAuthStatus: ActionStatus.isSuccess));
      } else if (res is NetworkErrorResponse) {
        emit(state.copyWith(
          telegramAuthStatus: ActionStatus.isError,
          authError: res.errorType?.name.toString(),
        ));
      }
    } on Exception catch (e) {
      debugPrint("Telegram Sign in exception: ${e.toString()}");
      emit(state.copyWith(
        telegramAuthStatus: ActionStatus.isError,
        authError: e.toString(),
      ));
    }
  }

  Future<void> deleteUser() async {
    emit(state.copyWith(
      deleteStatus: ActionStatus.isLoading,
      deleteError: '',
    ));

    final response = await _authService.deleteUser();
    if (response is NetworkSuccessResponse) {
      emit(state.copyWith(deleteStatus: ActionStatus.isSuccess));
    } else if (response is NetworkErrorResponse) {
      emit(state.copyWith(
        deleteStatus: ActionStatus.isError,
        deleteError: response.getError(),
      ));
    }
  }

  Future<void> sendOtp(String phone) async {
    emit(state.copyWith(
      loginAuthStatus: ActionStatus.isLoading,
      authError: '',
    ));

    final NetworkResponse res = await _authService.sendOtp(phone);
    if (res is NetworkSuccessResponse) {
      emit(state.copyWith(
        loginAuthStatus: ActionStatus.isSuccess,
        otpToken: res.data,
      ));
    } else if (res is NetworkErrorResponse) {
      emit(state.copyWith(
        loginAuthStatus: ActionStatus.isError,
        authError: res.errorType?.name.toString(),
      ));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String token,
    required String otp,
  }) async {
    emit(state.copyWith(
      verifyStatus: ActionStatus.isLoading,
      verifyError: '',
    ));

    final NetworkResponse res =
        await _authService.verifyOtp(phone: phone, token: token, otp: otp);
    if (res is NetworkSuccessResponse) {
      emit(state.copyWith(verifyStatus: ActionStatus.isSuccess));
    } else if (res is NetworkErrorResponse) {
      emit(state.copyWith(
        verifyStatus: ActionStatus.isError,
        verifyError: res.error.toString(),
      ));
    }
  }

  void resetGoogleAuthError() {
    emit(state.copyWith(
      googleAuthStatus: ActionStatus.isInitial,
      telegramAuthStatus: ActionStatus.isInitial,
      authError: '',
    ));
  }

  @override
  Future<void> close() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out errors during disposal.
    }
    return super.close();
  }
}
