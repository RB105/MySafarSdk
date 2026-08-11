# mysafar_sdk_example

A new Flutter project.

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
flutter run --dart-define=PARTNER_TOKEN=xxx
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
