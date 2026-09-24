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

### Foydalanuvchi ma'lumotlari (email, kartalar, xaridor) — ixtiyoriy

Host o'z user'ining emaili va kartalarini `init`ga berishi mumkin. Hech narsa
berilmasa (yoki ro'yxatlar bo'sh bo'lsa) SDK odatdagidek ishlaydi. So'mdagi
kartalar va boshqa valyutadagi kartalar alohida ro'yxatda qabul qilinadi:

```dart
await MySafarSdk.init(
  config: ...,
  userData: MySafarUserData(
    email: 'user@example.com',
    // Xaridor ma'lumotlari (hammasi ixtiyoriy) — bron formasida birinchi
    // katta yoshli yo'lovchi shular bilan oldindan to'ldiriladi:
    firstName: 'VALI',                  // pasportdagidek lotincha
    lastName: 'ALIYEV',
    birthDate: DateTime(1990, 3, 12),
    gender: MySafarGender.male,
    citizenship: 'UZ',                  // ISO 3166-1 alpha-2
    documentNumber: 'AA1234567',
    documentExpiry: DateTime(2031, 1, 1),
    uzsCards: [
      MySafarUzsCard(
        cardNumber: '8600123412341234', // 16 raqam
        expire: '2812',                 // YYMM (12/2028)
        cardMask: '8600 **** **** 1234', // ixtiyoriy — berilmasa raqamdan hosil qilinadi
        owner: 'ALIYEV VALI',           // ixtiyoriy
        balance: 1250000,               // ixtiyoriy, so'mda (tiyinda emas)
        cardLogoUrl: 'https://.../uzcard.svg', // ixtiyoriy, to'liq URL (.svg / .png)
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

// Karta qo'shildi / balans o'zgardi / boshqa user kirdi:
MySafarSdk.updateUserData(MySafarUserData(...));
// Host'dan chiqildi:
MySafarSdk.clearUserData();
```

- Karta ma'lumotlari faqat xotirada turadi — diskka, keshga, analytics'ga
  yozilmaydi; `toString()` karta raqamini maskalaydi.
- Yaroqsiz kartalar (16 raqamsiz, `YYMM` bo'lmagan muddat, bo'sh token) jim
  tashlab yuboriladi — init yiqilmaydi.
- `MySafarEmbed.email` berilmasa `userData.email` ishlatiladi.
- Xaridor maydonlari (ism, familiya, tug'ilgan sana, jins, fuqarolik, hujjat)
  faqat formadagi BO'SH maydonlarni to'ldiradi — foydalanuvchi o'zgartira
  oladi. Ular ham faqat xotirada turadi, `toString()` da ko'rsatilmaydi.
  Noto'g'ri fuqarolik kodi (2 harfli bo'lmasa) jim tashlanadi.
- `clearUserData()` bron formasining xotiradagi qoralamasini ham o'chiradi.

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
> `MySafarApp`/`MySafarEmbed` instance ishlaydi. Host embed'ni ikki marta
> ochsa (tugma ikki marta bosildi), ikkinchi nusxa hech narsa qurmaydi va
> o'z route'ini yopadi — foydalanuvchi birinchisida qoladi. Jim ro'yxatdan
> o'tish (`ensureRegistered`) ham bir vaqtda bitta so'rov yuboradi.

### Ekran yo'nalishi

`MySafarSdk.init()` host ilovaning yo'nalishiga TEGMAYDI. Portret faqat SDK
ekranda turganda qulflanadi (`MySafarEmbed` ochilganda / `MySafarApp`).
Embed yopilganda SDK host siyosatini tiklaydi:

- `MySafarConfig.hostOrientations` berilgan bo'lsa — aynan shu ro'yxat;
- berilmasa — bo'sh ro'yxat, ya'ni Info.plist / AndroidManifest'dagi default.

Host yo'nalishni kodda (`SystemChrome.setPreferredOrientations`) o'rnatsa,
o'sha qiymatni `hostOrientations` ga bering:

```dart
MySafarConfig(
  ...
  hostOrientations: const [DeviceOrientation.portraitUp],
)
```

### Foydalanuvchi almashishi va chiqish

- `ensureRegistered` / `MySafarEmbed(phoneNumber:)` ga BOSHQA raqam kelsa,
  oldingi foydalanuvchining barcha SDK ma'lumoti o'chiriladi: tokenlar,
  saqlangan yo'lovchilar, avtoto'ldirish ro'yxatlari, bron qoralamasi, so'nggi
  qidiruvlar, profil/biletlar keshi, analytics profil ID. Host yangi user uchun
  `updateUserData` chaqirmagan bo'lsa, xotiradagi karta/xaridor ma'lumotlari
  ham o'chadi.
- Host'dan chiqilganda `MySafarSdk.clearUserData()` chaqiring — yuqoridagilar
  hammasi (SDK sessiyasi bilan birga) tozalanadi.
- SDK ichidagi "Chiqish" / "Hisobni o'chirish" ham xuddi shunday tozalaydi.
- Pasport raqami, amal muddati va tug'ilgan kun avtoto'ldirish uchun diskka
  yozilmaydi (faqat ism, email, telefon eslab qolinadi).

### Sessiya (token yangilash)

Access token 401 bersa SDK refresh qiladi. Tarmoq uzilishi / server xatosida
tokenlar saqlanadi va keyingi so'rovda qayta uriniladi. Server refresh'ni rad
etsa (400/401/403) tokenlar o'chiriladi va — `ensureRegistered` bilan kirilgan
bo'lsa — SDK jim qayta ro'yxatdan o'tadi (60 s ichida ko'pi bilan bir marta).
Tiklab bo'lmasa `callbacks.onAuthRequired` chaqiriladi.

### Hive

SDK host'ning Hive sozlamasiga tegmaydi: `Hive.init` chaqirilmaydi, SDK
box'lari alohida papkada (`<documents>/mysafar_sdk`) va `mysafar_` prefiksli
nomlar bilan ochiladi — host'ning `profile_cache` kabi box'lari bilan
to'qnashmaydi. Eski (prefikssiz) SDK kesh fayllari o'chirilmaydi — ular
qayta yuklanadi.

### iOS: CocoaPods va ruxsatlar (majburiy)

SDK `permission_handler` orqali kamera (pasport skaneri) va mikrofon (ovozli
qidiruv) ruxsatini so'raydi. CocoaPods ishlatadigan host'da
`permission_handler` default holatda barcha ruxsatlarni O'CHIRIB kompilyatsiya
qiladi — so'rov oynasi chiqmaydi, status darhol `permanentlyDenied`, iOS
Sozlamalarida kamera tugmasi ham bo'lmaydi. Host `ios/Podfile` ning
`post_install` blokiga qo'shing:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',      # pasport skaneri
        'PERMISSION_MICROPHONE=1',  # ovozli (aqlli) qidiruv
        # host o'zi permission_handler bilan boshqa ruxsat so'rasa,
        # o'shalarni ham shu yerga qo'shing (PERMISSION_PHOTOS=1 va h.k.)
      ]
    end
  end
end
```

Keyin `cd ios && pod install`. (Swift Package Manager bilan ulangan
build'larda bu kerak emas.) SDK joylashuvni `location` paketi, galereyani
`image_picker` orqali oladi — ular uchun `PERMISSION_*` kerak emas.

`Info.plist` usage-description'lari (bo'lmasa iOS ruxsat so'ralganda ilovani
yopadi):

| Kalit | Nima uchun |
|---|---|
| `NSCameraUsageDescription` | Pasport/ID skaneri |
| `NSMicrophoneUsageDescription` | Ovozli qidiruv |
| `NSPhotoLibraryUsageDescription` | Hujjat/profil rasmini galereyadan tanlash |
| `NSLocationWhenInUseUsageDescription` | Yaqin aeroport / yo'nalish takliflari |
| `NSCalendarsUsageDescription` | Chiptani kalendarga qo'shish |

## Host app zimmasida qoladiganlar

- **Firebase** — kerak bo'lsa `Firebase.initializeApp` hostda (Firestore
  remote-config, news, payment-types, Google auth shunga bog'liq; bo'lmasa
  kesh/fallback rejimida ishlaydi).
- **Push (FCM)** — token `callbacks.getPushToken` orqali beriladi.
- **Analytics** — `MySafarAnalytics` implementatsiyasi (masalan AppMetrica).
- **Deep-link tinglash** (app_links) va **in-app review/update**.
- Chiptani ulashish `share_plus` (`>=7.2.2 <14.0.0`) orqali — host o'z
  versiyasini qotirgan bo'lsa ham diapazon ichida mos keladi; qo'shimcha
  sozlash kerak emas.
- Android manifest: INTERNET/LOCATION/CAMERA/RECORD_AUDIO ruxsatlari va Google
  Maps API key; iOS: Info.plist usage-description'lar (namuna: `example/`).
- minSdk **26**.

## Analytics eventlari

SDK eventlarni host bergan `MySafarAnalytics.logEvent` orqali `mysafarsdk_`
prefiksi bilan yuboradi. Har bir eventda `app_version`, `app_build`,
`timestamp` bor.

| Event | Qachon | Asosiy atributlar |
|---|---|---|
| `screen_view` | Har bir sahifa (`PageRoute`) ochilganda yoki unga qaytilganda; navbar tablari almashganda (`tab_home`, `tab_orders`, `tab_destinations`, `tab_profile`). Ekran o'zgarmasa takror yuborilmaydi (SDK qayta ochilganda birinchi ekran albatta yoziladi); dialog/bottom sheet ekran hisoblanmaydi | `screen` (route nomi, masalan `/bookingConfirm`) |
| `ticket_searched` | Qidiruv natijalari sahifasi ochildi (3 s ichidagi takror tashlanadi) | `from`, `to`, `passengers`, `round_trip`, `class`, `source` |
| `results_shown` / `no_results` | Qidiruv yakunlandi (hamma manba xato bersa `no_results` + `reason: error`) | `count`, `from`, `to`, `passengers`, `round_trip`, `reason`, `error_type` |
| `flight_selected` | Natijadan reys tanlandi | `source`, `from`, `to`, `airline`, `amount`, `currency` |
| `passenger_form_started` | Yo'lovchi ma'lumotlari sahifasi ochildi | `source` |
| `passenger_form_completed` | Yo'lovchi formasi to'ldirilib bron so'rovi yuborildi (bitta forma sessiyasida bir marta) | `source`, `passengers` |
| `booking_created` / `booking_failed` | Bron yaratildi / yaratilmadi | `tid`, `billing_number`, `passengers`, `amount`, `currency` / `message` |
| `payment_started` | "To'lash" bosildi | `tr_id`, `payment_method`, `amount`, `currency` |
| `transaction_paid` / `payment_failed` | To'lov natijasi (+ `trackRevenue`) | `tr_id`, `billing_number`, `amount`, `currency` / `message`, `payment_method` |
| `button_tap` | Muhim tugmalar (filtr, qayta qidirish, `ticket_share` va h.k.) | `screen`, `button` |
| `api_error` | API xatosi | `screen`, `endpoint`, `method`, `status_code`, `error_type`, `message` |
| `user_registered` / `user_logged_in` | Ro'yxatdan o'tish / kirish. Jim `web_register` — faqat backend yangi hisob deganda `user_registered`, aks holda `user_logged_in` | `method` |

Profil ID (`setUserId`) — faqat backend account ID (JWT `user_id` / profil
`id`); telefon raqami hech qachon profil ID bo'lmaydi.

Kanonik voronka: `ticket_searched → results_shown → flight_selected →
passenger_form_started → passenger_form_completed → booking_created →
payment_started → transaction_paid`.

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
