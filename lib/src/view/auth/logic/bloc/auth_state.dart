part of 'auth_cubit.dart';

class AuthState extends Equatable {
  final ActionStatus googleAuthStatus;
  final ActionStatus telegramAuthStatus;
  final ActionStatus loginAuthStatus;
  final ActionStatus verifyStatus;
  final ActionStatus deleteStatus;
  final String otpToken;
  final String deleteError;
  final String authError;
  final String verifyError;

  const AuthState(
      {this.googleAuthStatus = ActionStatus.isInitial,
      this.telegramAuthStatus = ActionStatus.isInitial,
      this.loginAuthStatus = ActionStatus.isInitial,
      this.verifyStatus = ActionStatus.isInitial,
      this.deleteStatus = ActionStatus.isInitial,
      this.deleteError = '',
      this.otpToken = '',
      this.authError = '',
      this.verifyError = ''});

  AuthState copyWith(
      {ActionStatus? googleAuthStatus,
      ActionStatus? telegramAuthStatus,
      ActionStatus? loginAuthStatus,
      ActionStatus? verifyStatus,
      ActionStatus? deleteStatus,
      String? deleteError,
      String? otpToken,
      String? verifyError,
      String? authError}) {
    return AuthState(
        otpToken: otpToken ?? this.otpToken,
        authError: authError ?? this.authError,
        verifyError: verifyError ?? this.verifyError,
        deleteError: deleteError ?? this.deleteError,
        loginAuthStatus: loginAuthStatus ?? this.loginAuthStatus,
        googleAuthStatus: googleAuthStatus ?? this.googleAuthStatus,
        telegramAuthStatus: telegramAuthStatus ?? this.telegramAuthStatus,
        verifyStatus: verifyStatus ?? this.verifyStatus,
        deleteStatus: deleteStatus ?? this.deleteStatus);
  }

  @override
  List<Object?> get props => [
        googleAuthStatus,
        telegramAuthStatus,
        loginAuthStatus,
        verifyStatus,
        deleteStatus,
        otpToken,
        verifyError,
        authError,
        deleteError,
      ];
}
