import 'package:get_storage/get_storage.dart';

/// SDK'ning alohida GetStorage konteyneri.
///
/// Default konteyner ataylab ishlatilmaydi: host app (masalan Unired) ham
/// get_storage'ning default box'idan foydalanadi va kalitlar (`access_token`,
/// `lang`, `isFirstTime`, ...) to'qnashadi. Eng xavflisi — SDK logout'idagi
/// `erase()` host app'ning butun storage'ini o'chirib yuborar edi. Alohida
/// konteyner bilan SDK faqat o'z ma'lumotiga tegadi.
const String kMySafarStorageContainer = 'mysafar_sdk';

GetStorage sdkStorage() => GetStorage(kMySafarStorageContainer);
