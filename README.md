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

### Foydalanuvchi ma'lumotlari (email, kartalar) — ixtiyoriy

Host oz userining email, myid malumoti va kartalarini init ga berishi mumkin.
Hech narsa bermasa SDK odatdagidek ishlaydi:

```dart
await MySafarSdk.init(
  config: ...,
  userData: MySafarUserData(
    email: 'user@example.com',
    // myid malumot — bersa "Ozimning malumotim" chiqadi
    identification: MySafarUserIdentification(
      firstName: 'VALI',
      lastName: 'ALIYEV',
      middleName: 'VALIYEVICH',
      birthDate: '15.03.1990', // yoki 1990-03-15
      passSeries: 'AA1234567',
      passSeriesMask: 'AA*******',
      passExpiry: '15.03.2030',
      pinfl: '30103901234567',
      pinflMask: '30103********',
      address: 'Toshkent sh.',
      isResident: true,
    ),
    uzsCards: [
      MySafarUzsCard(
        cardNumber: '8600123412341234', // 16 raqam
        expire: '2812',                 // YYMM (12/2028)
        cardMask: '8600 **** **** 1234', // ixtiyoriy — berilmasa raqamdan hosil qilinadi
        owner: 'ALIYEV VALI',           // ixtiyoriy
        balance: 1250000,               // ixtiyoriy, somda (tiyinda emas)
        cardLogoUrl: 'https://.../uzcard.svg', // ixtiyoriy, toliq URL (.svg / .png)
      ),
    ],
    foreignCards: [
      MySafarForeignCard(
        cardToken: '...',               // host processing tokeni
        cardMask: '4276 **** **** 1234',
        owner: 'ALIYEV VALI',           // ixtiyoriy
        currency: 'USD',                // ISO 4217, default USD
      ),
    ],
  ),
);

// Karta qoshildi / balans ozgardi / boshqa user kirdi:
MySafarSdk.updateUserData(MySafarUserData(...));
// Host'dan chiqildi:
MySafarSdk.clearUserData();
```

- `identification` bersa yolovchi formasida "Ozimning malumotim" chiqadi.
  Ozi toldirilmaydi — user korib tasdiqlasa shunda yoziladi.
- Karta malumotlari faqat xotirada turadi — diskka, keshga, analytics'ga
  yozilmaydi; `toString()` karta raqamini maskalaydi.
- Yaroqsiz kartalar (16 raqamsiz, `YYMM` bolmagan muddat, bo'sh token) jim
  tashlab yuboriladi — init yiqilmaydi.
- `MySafarEmbed.email` berilmasa `userData.email` ishlatiladi.

### Saqlangan UZS karta bilan to'lov (`card_token`) — ixtiyoriy

"Chipta uchun to'lov" sahifasida **HUMO / Uzcard** tanlanganda, host
`uzsCards` va `onCreateCardToken` bergan bo'lsa, kartalar ro'yxati (bottom
sheet) ochiladi:

- **Karta tanlansa** — SDK bron to'lovini boshlaydi, `card_token` yaratadi va
  to'lov sahifasini `...?trid=...&billing_id=...&card_token=...` bilan ochadi
  (karta avtomatik to'ldiriladi, foydalanuvchi faqat SMS kodni kiritadi).
- **"Boshqa karta"** — avvalgidek oddiy to'lov sahifasi (karta qo'lda kiritiladi).
- `uzsCards` bo'sh bo'lsa — sheet chiqmaydi, oqim o'zgarmaydi.

Token "Unired → MySafar card_token" hujjati bo'yicha yaratiladi:

- plaintext JSON: `{"card_number","expire" (YYMM),"tr_id","iat"}` — `tr_id`
  to'lov URL'idagi `trid` dan olinadi, `iat` — hozirgi Unix vaqt (token 10
  daqiqa amal qiladi);
- AES-256-GCM, 12 baytli tasodifiy IV, AAD yo'q;
- `card_token = base64url(IV ‖ CIPHERTEXT ‖ TAG)`, padding'siz;
- faqat `https://` to'lov URL'iga qo'shiladi.

Kalitni (64 belgili hex, MySafar beradi) config orqali bering. Kalitni kodga
yoki repoga yozmang — host maxfiy sozlamasidan (`.env` va h.k.) o'qing:

```dart
await MySafarSdk.init(
  config: MySafarConfig(
    ...,
    cardTokenSecret: env['MYSAFAR_CARD_TOKEN_SECRET'],
  ),
);
```

Debug'da `cardTokenSecret` bo'sh bo'lsa `env.json` dagi
`MYSAFAR_CARD_TOKEN_SECRET` ishlatiladi. Debug konsolida
`[MySafar card_token] payload / token / url` qatorlari chiqadi (release'da
yozilmaydi).

Token serverda yaratilishi kerak bo'lsa `callbacks.onCreateCardToken` bering —
u `cardTokenSecret` dan ustun:

```dart
callbacks: MySafarCallbacks(
  onCreateCardToken: (request) => myBackend.createMySafarCardToken(
    cardNumber: request.card.cardNumberDigits,
    expire: request.card.expire, // YYMM
    trId: request.trId,          // URL'dagi trid
  ), // null / xato → sahifa oddiy rejimda ochiladi
),
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
Kalit nomlari Unired `.env` bilan bir xil: `MYSAFAR_BASE_URL`, `MYSAFAR_SKOTE_BASE_URL`,
`MYSAFAR_PARTNER_TOKEN`, `MYSAFAR_APP_NAME`.

```bash
cd example
cp env.json.example env.json   # bir marta — MYSAFAR_* (+ ixtiyoriy USER_PHONE / USER_EMAIL)
flutter run --dart-define-from-file=env.json                          # to'liq app
flutter run -t lib/main_embed.dart --dart-define-from-file=env.json   # embed
```

**Debug to'ldirish.** Faqat debug build'da `MySafarSdk.init` host bo'sh qoldirgan
`baseUrl`, `skoteBaseUrl`, `partnerToken`, `appName` maydonlarini shu `MYSAFAR_*`
dart-define qiymatlaridan to'ldiradi (host bergan qiymat doim ustun). Release/profile
build'da hech narsa to'ldirilmaydi — barcha ma'lumot host `init`ga bergan config'dan
keladi. Repo public: token kodga yoki git'ga yozilmaydi.

Yoki alohida:

```bash
flutter run --dart-define=MYSAFAR_PARTNER_TOKEN=xxx
flutter run -t lib/main_embed.dart --dart-define=MYSAFAR_PARTNER_TOKEN=xxx
```

## Test

```bash
flutter analyze && flutter test
```
