import 'dart:async' show Zone, runZoned;

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBase;

/// Zone orqali joriy [CancelToken] ni uzatadi — servis imzolarini
/// o'zgartirmasdan [RequestConfig] so'rovlariga cancel ulash uchun.
class NetworkRequestScope {
  NetworkRequestScope._();

  static const Symbol _key = #mysafarNetworkCancelToken;

  /// Joriy zonadagi cancel token (yo'q bo'lsa `null`).
  static CancelToken? get current =>
      Zone.current[_key] as CancelToken?;

  /// [body] ni berilgan token bilan zonada bajaradi.
  static Future<T> run<T>(
    CancelToken token,
    Future<T> Function() body,
  ) {
    return runZoned(body, zoneValues: {_key: token});
  }
}

/// [Cubit]/[Bloc] yopilganda (yoki yangi so'rov avlodida) tarmoq
/// so'rovlarini bekor qilish uchun mixin.
///
/// Misol:
/// ```dart
/// class FooCubit extends Cubit<FooState> with NetworkCancel {
///   Future<void> load() => withNetworkCancel(() => _service.fetch());
/// }
/// ```
mixin NetworkCancel<S> on BlocBase<S> {
  CancelToken _networkCancelToken = CancelToken();

  /// Joriy (yoki yangi) cancel token.
  CancelToken get networkCancelToken {
    if (_networkCancelToken.isCancelled) {
      _networkCancelToken = CancelToken();
    }
    return _networkCancelToken;
  }

  /// Oldingi so'rovlarni bekor qilib yangi token ochadi
  /// (masalan, yangi qidiruv avlodi).
  void refreshNetworkCancel() {
    if (!_networkCancelToken.isCancelled) {
      _networkCancelToken.cancel('superseded');
    }
    _networkCancelToken = CancelToken();
  }

  /// Servis chaqiriqlarini shu bloc/cubit tokeni bilan o'raydi.
  Future<R> withNetworkCancel<R>(Future<R> Function() body) {
    return NetworkRequestScope.run(networkCancelToken, body);
  }

  @override
  Future<void> close() {
    if (!_networkCancelToken.isCancelled) {
      _networkCancelToken.cancel('closed');
    }
    return super.close();
  }
}
