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
  MaterialPageRoute(builder: (_) => const MySafarEmbed()),
);
```

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

```bash
cd example
flutter run --dart-define=PARTNER_TOKEN=xxx           # to'liq app rejimi
flutter run -t lib/main_embed.dart --dart-define=PARTNER_TOKEN=xxx  # embed
```

## Test

```bash
flutter analyze && flutter test
```
