import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/api/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
    await GetStorage.init('token_store_test');
  });

  group('GetStorageTokenStore', () {
    late GetStorage storage;
    late GetStorageTokenStore store;

    setUp(() async {
      storage = GetStorage('token_store_test');
      await storage.erase();
      store = GetStorageTokenStore(storage: storage);
    });

    test('bo\'sh holatda login qilinmagan', () {
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      expect(store.isLoggedIn, isFalse);
    });

    test('saveTokens ikkala tokenni yozadi va isLoggedIn true bo\'ladi',
        () async {
      await store.saveTokens(access: 'acc-1', refresh: 'ref-1');
      expect(store.accessToken, 'acc-1');
      expect(store.refreshToken, 'ref-1');
      expect(store.isLoggedIn, isTrue);
      // App'ning tarixiy kalitlari bilan mos — MySafar app'dan migratsiyada
      // mavjud sessiyalar saqlanib qoladi.
      expect(storage.read<String>('access_token'), 'acc-1');
      expect(storage.read<String>('refresh_token'), 'ref-1');
    });

    test('saveAccess faqat access tokenni yangilaydi', () async {
      await store.saveTokens(access: 'acc-1', refresh: 'ref-1');
      await store.saveAccess('acc-2');
      expect(store.accessToken, 'acc-2');
      expect(store.refreshToken, 'ref-1');
    });

    test('clear ikkala tokenni o\'chiradi', () async {
      await store.saveTokens(access: 'acc-1', refresh: 'ref-1');
      await store.clear();
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      expect(store.isLoggedIn, isFalse);
    });
  });
}
