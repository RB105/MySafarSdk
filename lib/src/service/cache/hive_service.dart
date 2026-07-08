import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_cache.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/service/profile/tickets_cache.dart';

/// Hive (Community Edition) ni ishga tushiradi va barcha kesh box'larini ochadi.
///
/// main() da bir marta chaqiriladi. Yangi kesh box qo'shsangiz — shu yerga
/// qo'shing (box ochilmasa `Hive.box(...)` xato beradi).
class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(RemoteConfigService.boxName),
      Hive.openBox(ProfileCache.boxName),
      Hive.openBox(TicketsCache.boxName),
      Hive.openBox(PaymentTypeCache.boxName),
    ]);
  }
}
