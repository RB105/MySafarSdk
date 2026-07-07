import 'package:mysafar_sdk/src/core/config/dio_client.dart'
    show AuthMode, DioClient, TokenManager;
import 'package:mysafar_sdk/src/core/constants/end_points.dart' show EndPoints;
import 'package:dio/dio.dart' show DioException, Options;
import 'package:get_storage/get_storage.dart' show GetStorage;

final class ApiService {
  final GetStorage _db = GetStorage();

  /// token refresh — delegates to the shared, single-flight [TokenManager] so
  /// concurrent 401s never trigger more than one refresh at a time.
  Future<bool> refreshToken() => TokenManager.refresh();

  /// verifies token valid or not with api
  Future<bool> verifyToken() async {
    final access = _db.read('access_token');
    if (access == null || '$access'.isEmpty) return false;

    try {
      final response = await DioClient.main.post(
        EndPoints.api_v1_token_verify,
        data: {'token': access},
        options: Options(extra: {'authMode': AuthMode.none}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return refreshToken();
      }
      return false;
    }
  }
}
