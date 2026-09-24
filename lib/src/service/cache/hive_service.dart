import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mysafar_sdk/src/service/avia/recent_search_cache.dart';
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_cache.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/service/profile/tickets_cache.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

/// Hive (Community Edition) kesh box'larini SDK uchun izolyatsiyalangan
/// holda ochadi.
///
/// №94: Hive global singleton — host (masalan Unired) ham Hive ishlatadi.
/// Shu sabab SDK:
///  • `Hive.init` / `Hive.initFlutter` ni CHAQIRMAYDI — host'ning global
///    `homePath`i o'zgarmaydi; box'lar `path:` bilan SDK'ning alohida
///    papkasida (`<documents>/mysafar_sdk`) ochiladi;
///  • box nomlariga `mysafar_` prefiksi qo'shiladi ([physicalName]) — host'da
///    `profile_cache` kabi bir xil nomli box bo'lsa ham to'qnashmaydi.
///
/// Eski (prefikssiz, documents ildizidagi) box fayllari o'chirilmaydi: ular
/// host'ning bir xil nomli fayli bo'lishi mumkin. Keshlar qayta yuklanadi.
///
/// main() da bir marta chaqiriladi. Yangi kesh box qo'shsangiz — shu yerga
/// qo'shing va `Hive.box(HiveService.physicalName(name))` orqali o'qing.
class HiveService {
  HiveService._();

  static const String _prefix = 'mysafar_';
  static const String _subDir = 'mysafar_sdk';

  /// SDK mantiqiy box nomi → Hive'dagi haqiqiy (prefiksli) nom.
  static String physicalName(String logicalName) =>
      logicalName.startsWith(_prefix) ? logicalName : '$_prefix$logicalName';

  /// SDK box'i (ochilgan bo'lishi kerak).
  static Box box(String logicalName) => Hive.box(physicalName(logicalName));

  static Future<void> init() async {
    String? path;
    if (!kIsWeb) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        path = '${docs.path}/$_subDir';
      } catch (e) {
        debugPrint('HiveService: documents papkasi topilmadi: $e');
      }
    }
    await Future.wait([
      for (final name in const [
        RemoteConfigService.boxName,
        ProfileCache.boxName,
        TicketsCache.boxName,
        PaymentTypeCache.boxName,
        RecentSearchCache.boxName,
      ])
        Hive.openBox(physicalName(name), path: path),
    ]);
  }
}
