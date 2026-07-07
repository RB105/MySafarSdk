import 'package:bloc/bloc.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/service/account_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart' show debugPrint;

part 'check_version_state.dart';

class CheckVersionCubit extends Cubit<CheckVersionState> {
  CheckVersionCubit() : super(CheckVersionInitState()) {
    checkVersion();
  }

  final _accountService = AccountService();

  Future<void> checkVersion() async {
    // Versiya siyosati host app'niki — SDK'da faqat aniq yoqilganda tekshiramiz
    // (aks holda embed hostda MySafar'ning majburiy yangilash dialogi chiqadi).
    if (!MySafarSdk.config.enableVersionGate) return;

    final response = await _accountService.checkAppVersion();

    if (isClosed) return;
    try {
      if (response is NetworkSuccessResponse) {
        final bool isUpdate = response.data['is_update'] ?? false;
        final bool isRequired = response.data['is_required'] ?? false;
        if (isUpdate) {
          if (isRequired) {
            emit(VersionUpdateRequiredState());
            return;
          }
          emit(VersionUpdateOptionalState());
          return;
        }
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
