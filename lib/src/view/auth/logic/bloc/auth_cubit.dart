import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/service/auth_service.dart';
import 'package:mysafar_sdk/src/service/telegram_auth.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with NetworkCancel {
  final AuthService _authService;

  AuthCubit({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        super(const AuthState());

  /// Cubit yopilgandan keyin `emit` chaqirilsa `StateError: Cannot emit new
  /// states after calling close` bo'lardi — foydalanuvchi auth oynasidan
  /// chiqib ketganda async so'rov qaytib kelib holat yozmoqchi bo'ladi
  /// (AppMetrica: 7 kunda 60 ta crash, 48 ta qurilma). Har bir metodda
  /// alohida `isClosed` tekshirish o'rniga bitta joyda to'xtatamiz.
  @override
  void emit(AuthState state) {
    if (isClosed) return;
    super.emit(state);
  }

  /// Telegram tugmasini ko'rsatish sharti.
  static bool get telegramAuthEnabled =>
      MySafarSdk.config.socialAuth?.telegram != null;

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
      final NetworkResponse res = await withNetworkCancel(
        () => _authService.telegramAuth(
          token: idToken,
        ),
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

    final response = await withNetworkCancel(_authService.deleteUser);
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

    final NetworkResponse res = await withNetworkCancel(
      () async => await _authService.sendOtp(phone) as NetworkResponse,
    );
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

    final NetworkResponse res = await withNetworkCancel(
      () async => await _authService.verifyOtp(
        phone: phone,
        token: token,
        otp: otp,
      ) as NetworkResponse,
    );
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

}
