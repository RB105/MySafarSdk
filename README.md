# mysafar_sdk

MySafar sayohat (aviabilet) oqimlarini boshqa Flutter ilovalarga embed qilish
uchun SDK: avia qidiruv/booking, to'lov, visa/ban-check, destinations, news,
profile (MyID identifikatsiya bilan).

Ichki arxitektura: `lib/src` (`core` / `cubit` / `model` / `service` / `view`).
Tashqi chegara — `lib/mysafar_sdk.dart` orqali export qilinadigan `src/api/*`.

## Ulash

`publish_to: none` — pub.dev emas. Host `pubspec.yaml`:

```yaml
dependencies:
  mysafar_sdk:
    path: ../MySafarSdk          # lokal
    # yoki git:
    # git:
    #   url: https://github.com/<org>/MySafarSdk.git
    #   ref: <tag-yoki-branch>
```

## Ishlatish

```dart
import 'package:mysafar_sdk/mysafar_sdk.dart';

Future<void> main() async {
  await MySafarSdk.init(
    config: const MySafarConfig(
      baseUrl: 'https://api.mysafar.ru',
      skoteBaseUrl: 'https://cms.mysafar.uz/api',
      partnerToken: '...',
      // appMetricaApiKey: '...',  // berilsa SDK AppMetrica'ni o'zi yoqadi
      // myId: MySafarMyIdConfig(...),
      // socialAuth: MySafarSocialAuthConfig(telegram: ...),
    ),
    // tokenStore: o'z storage'ingiz (ixtiyoriy)
    // analytics: o'z MySafarAnalytics adapteringiz (ixtiyoriy;
    //            appMetricaApiKey bo'lmasa default no-op)
    // callbacks: MySafarCallbacks(
    //   onAuthRequired: ...,
    //   onLoggedIn: ...,
    //   onLoggedOut: ...,
    //   onRequestReview: ...,
    // ),
  );

  runApp(const MySafarApp()); // to'liq app rejimi
}
```

### Embed (host ichida modul)

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => MySafarEmbed(
      // Ixtiyoriy: /auth/web-register — bir marta jim ro'yxat.
      // Raqam o'zgarsa qayta register; email berilsa profilga yoziladi.
      phoneNumber: '998901234567',
      email: 'user@example.com',
      // Host joriy tili (saqlanmaydi). null → startLocale / saqlangan / uz.
      locale: Localizations.localeOf(context),
    ),
  ),
);
```

Yoki host o'zi register qiladi: `await MySafarSdk.ensureRegistered(phone, email: ...)`.

Embed ochilganda SDK portrait'ni qulflaydi; yopilganda orientation'lar tiklanadi.

### Config (embed uchun foydali)

```dart
MySafarConfig(
  baseUrl: '...',
  skoteBaseUrl: '...',
  partnerToken: '...',
  appName: 'Unired Travel',       // UI brendi ("MySafar" o'rniga)
  themeMode: ThemeMode.dark,      // null → system
  brandColor: Color(0xFF0057BE),  // null → default
  enableFullProfile: false,       // true → to'liq profil (ariza/sozlama/chiqish)
  enableShowcaseTour: false,      // default o'chiq (embed uchun)
  enableVersionGate: false,       // default o'chiq (versiya siyosati hostniki)
  startLocale: Locale('ru'),
  saveLocale: true,               // SDK o'z storage'ida; hostga tegmaydi
  support: MySafarSupportConfig(
    phone: '+998 ...',
    telegramUrl: 'https://t.me/...',
  ),
  bottomBarStyle: MySafarBottomBarStyle(...),
  homeHeaderStyle: MySafarHomeHeaderStyle(
    logoAssetPath: 'assets/logo.svg',
    title: 'UNIRED',
    description: 'bilan parvoz qiling',
  ),
)
```

> `enableServicesTab` maydoni saqlangan, lekin pastki nav barda endi
> qo'llanmaydi (o'rniga "Yo'nalishlar").

### Orqaga qaytish (embed)

Bosh ekranda host'ga qaytish tugmasi bor. Tizim back (Android tugma / gesture,
iOS chetdan surish):

1. SDK ichki stack → pop  
2. Non-home tab (Orders / Destinations / Profile) → Main  
3. Main da ikki marta → host ekrani  

**Android 16+ da tizim back ishlashi uchun host manifest sozlamasi shart** —
pastdagi «Android back» bo'limiga qarang.

### Deep-link

Host tinglaydi va uzatadi:

```dart
MySafarSdk.handleLink(uri); // masalan https://mysafar.uz/payment?billing_id=...
```

> **Cheklov:** global navigator key tufayli bir vaqtda faqat bitta
> `MySafarApp` / `MySafarEmbed` instance ishlaydi.

## Host app zimmasida

- **Firebase** — kerak bo'lsa `Firebase.initializeApp` hostda (Firestore
  remote-config, news, payment-types, Google auth shunga bog'liq; bo'lmasa
  kesh/fallback).
- **Analytics** — `appMetricaApiKey` yoki o'z `MySafarAnalytics` adapteri.
- **Deep-link** tinglash (`app_links` va h.k.) + `MySafarSdk.handleLink`.
- **In-app review** — `callbacks.onRequestReview` (host `in_app_review`).
- Android: INTERNET / LOCATION / CAMERA / RECORD_AUDIO, Google Maps API key.
- iOS: Info.plist usage-description'lar (namuna: `example/`).
- **minSdk 26**.

### Android back (majburiy — Android 16+)

`MySafarEmbed` nested `MaterialApp` ishlatadi. Android 16 (API 36) +
`targetSdk` 36+ da predictive back default yoqiladi — tizim back Flutter'ga
kelmaydi va Activity yopilib ketishi mumkin.

SDK host `AndroidManifest.xml`ini o'zgartira olmaydi. **Har bir host** asosiy
`Activity`ga (yoki `application`ga) qo'yishi shart:

```xml
<activity
    android:name=".MainActivity"
    android:enableOnBackInvokedCallback="false"
    ...>
```

Namuna: `example/android/app/src/main/AndroidManifest.xml`.

- **iOS** — kerak emas.
- Flag bo'lmasa: eski Android (masalan 12) da odatda ishlaydi; **16+** da
  tizim back appdan chiqishi mumkin.
- Manifest o'zgargach **to'liq qayta build** (hot reload yetmaydi).

## Example

Local secretlar `env.json` orqali (`gitignore`; template: `env.json.example`).

```bash
cd example
cp env.json.example env.json   # PARTNER_TOKEN / USER_PHONE / USER_EMAIL
flutter run --dart-define-from-file=env.json                          # to'liq app
flutter run -t lib/main_embed.dart --dart-define-from-file=env.json   # embed
```

## Test

```bash
flutter analyze && flutter test
```
