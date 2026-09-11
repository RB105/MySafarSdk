# mysafar_sdk

MySafar sayohat (aviabilet) oqimlarini boshqa Flutter ilovalarga embed qilish
uchun SDK: avia qidiruv/booking, to'lov, visa/ban-check, destinations, news,
profile (MyID identifikatsiya bilan).

MySafar app kodidan ajratib olingan (`lib/src` — arxitektura o'sha:
`core/cubit/model/service/view`). Tashqi chegara — `lib/mysafar_sdk.dart`
export qiladigan `src/api/*`.

## Ishlatish

```dart
import 'package:mysafar_sdk/mysafar_sdk.dart';

Future<void> main() async {
  await MySafarSdk.init(
    config: const MySafarConfig(
      baseUrl: 'https://api.mysafar.ru',
      skoteBaseUrl: 'https://cms.mysafar.uz/api',
      partnerToken: '...',              // partner-token auth uchun
      // myId: MySafarMyIdConfig(...),  // MyID identifikatsiya (ixtiyoriy)
      // socialAuth: MySafarSocialAuthConfig(...), // Google/Telegram (ixtiyoriy)
      // enableFirestoreConfig: true,   // host Firebase init qilgan bo'lsa
    ),
    // tokenStore: o'z secure-storage implementatsiyangiz (ixtiyoriy)
    // analytics: AppMetrica/Firebase adapter (ixtiyoriy, default no-op)
    // callbacks: MySafarCallbacks(getPushToken: ..., onAuthRequired: ...),
  );

  runApp(const MySafarApp()); // to'liq app rejimi
}
```

Host app ichida modul sifatida:

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const MySafarEmbed(
      // Ixtiyoriy: host user'ini telefon raqami bilan bir marta jim
      // ro'yxatdan o'tkazadi (/auth/web-register). Raqam o'zgarsa qayta
      // ro'yxatdan o'tadi. email berilsa profilga ham yoziladi.
      phoneNumber: '998901234567',
      email: 'user@example.com',
    ),
  ),
);
```

Embed rejimi uchun foydali config maydonlari:

```dart
MySafarConfig(
  ...
  appName: 'Unired Travel',   // UI'dagi "MySafar" brendi o'rniga
  enableServicesTab: false,   // faqat avia oqimi kerak bo'lsa
  enableMultiSearch: true,    // default: murakkab marshrut tabi ko'rinadi
  // enableMultiSearch: false, // faqat oddiy qidiruv (multi tab yashirin)
  // enableShowcaseTour / enableVersionGate default o'chiq
)
```

Embed ichidagi bosh ekranda host'ga qaytish tugmasi chiqadi; Android back ham
avval SDK stack'ini yechib, oxirida host ekraniga qaytadi.

### Android 16 (targetSdk 36) back tugmasi

Android 16 da tizim back'ini faqat `OnBackInvokedDispatcher`ga ro'yxatdan
o'tgan callback ushlaydi — eski `Activity.onBackPressed()` / `KEYCODE_BACK`
fallback'i olib tashlangan. Callback ro'yxatdan o'tmagan bo'lsa tizim back'ni
Flutter'ga umuman uzatmay activity'ni yopadi (foydalanuvchi uchun: "ilova
chiqib ketdi"). Embed ochiq ekan SDK `setFrameworkHandlesBack(true)` da'vosini
o'zi ushlab turadi, lekin host tomonda quyidagilar shart:

- `MainActivity` `io.flutter.embedding.android.FlutterActivity` dan meros
  olsin. `FlutterFragmentActivity` (yoki `FlutterFragment`) callback'ni o'zi
  ro'yxatdan o'tkazmaydi — u AndroidX `OnBackPressedDispatcher`iga tayanadi,
  shuning uchun `androidx.activity:activity` **1.8+** bo'lishi kerak.
- Manifestda `android:enableOnBackInvokedCallback="false"` bo'lmasin.
- `MainActivity` da `onBackPressed()` override qilinmasin — Android 16 da u
  umuman chaqirilmaydi.

Back tugmasi hamon ishlamasa, diagnostikani yoqing:

```dart
MySafarSdk.debugBackLogging = true;   // runApp dan oldin
```

Qurilmada back bosing va `flutter logs` ni ko'ring:

- `MySafarBack: ...` qatorlari **chiqsa** — event Flutter'ga yetib kelyapti,
  muammo navigatsiyada.
- Hech nima **chiqmasa** — event Flutter'ga umuman kelmayapti: Android
  tomonda `OnBackInvokedCallback` ro'yxatdan o'tmagan (yuqoridagi host
  talablarini tekshiring).

Deep-link (masalan `https://mysafar.uz/payment?billing_id=...`) hostda
tinglanadi va SDK'ga uzatiladi: `MySafarSdk.handleLink(uri)`.

> **Cheklov:** global navigator key tufayli bir vaqtda faqat bitta
> `MySafarApp`/`MySafarEmbed` instance ishlaydi.

## Host app zimmasida qoladiganlar

- **Firebase** — kerak bo'lsa `Firebase.initializeApp` hostda (Firestore
  remote-config, news, payment-types, Google auth shunga bog'liq; bo'lmasa
  kesh/fallback rejimida ishlaydi).
- **Push (FCM)** — token `callbacks.getPushToken` orqali beriladi.
- **Analytics** — `MySafarAnalytics` implementatsiyasi (masalan AppMetrica).
- **Deep-link tinglash** (app_links) va **in-app review/update**.
- Android manifest: INTERNET/LOCATION/CAMERA/RECORD_AUDIO ruxsatlari va Google
  Maps API key; iOS: Info.plist usage-description'lar (namuna: `example/`).
- minSdk **26**.

## Example

Local secretlar `env.json` orqali beriladi (`env.json` gitignore'da; template: `env.json.example`).

```bash
cd example
cp env.json.example env.json   # bir marta — PARTNER_TOKEN / USER_PHONE / USER_EMAIL
flutter run --dart-define-from-file=env.json                          # to'liq app
flutter run -t lib/main_embed.dart --dart-define-from-file=env.json   # embed
```

Yoki alohida:

```bash
flutter run --dart-define=PARTNER_TOKEN=xxx
flutter run -t lib/main_embed.dart --dart-define=PARTNER_TOKEN=xxx
```

## Test

```bash
flutter analyze && flutter test
```
