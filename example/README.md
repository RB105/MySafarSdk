# mysafar_sdk_example

SDK namuna ilovasi — to'liq app va embed rejimlari.

> Asosiy integratsiya hujjati: repo ildizidagi [README.md](../README.md).
> Android 16+ hostlar uchun **majburiy:**
> `android:enableOnBackInvokedCallback="false"`
> (`android/app/src/main/AndroidManifest.xml` da qo'yilgan).

## Ishga tushirish (embed rejimi)

Maxfiy qiymatlar `env.json` faylidan olinadi (git'ga kirmaydi):

```bash
cd example
cp env.json.example env.json     # bir marta, keyin env.json ichini to'ldiring
flutter run -t lib/main_embed.dart --dart-define-from-file=env.json
```

> `env.json` faqat sof JSON bo'lishi kerak (izoh/qo'shimcha matn qo'shmang) —
> aks holda `--dart-define-from-file` uni o'qiy olmaydi.

To'liq app rejimi uchun:

```bash
flutter run --dart-define-from-file=env.json
```
