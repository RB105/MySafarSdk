import 'package:mysafar_sdk/src/core/tools/project_assets.dart';

class PaymentType {
  final String id;
  final String imagePath;

  /// Ixtiyoriy ikkinchi logo — bitta karta ikki tizimni bildirsa (masalan
  /// MYSAFARPAY: UzCard + Humo) yonma-yon ko'rsatiladi.
  final String? secondaryImagePath;
  final String? cardName;
  final String? subtitle;

  /// Firebase'dan (admin panel) kelgan logotip havolasi. Bo'sh bo'lmasa —
  /// lokal [imagePath] o'rniga shu rasm ko'rsatiladi.
  final String? imageUrl;

  const PaymentType({
    required this.id,
    required this.imagePath,
    this.secondaryImagePath,
    this.cardName,
    this.subtitle,
    this.imageUrl,
  });
}

class PaymentConstants {
  PaymentConstants._();

  static const String uzcard = 'UZCARD';
  static const String humo = 'HUMO';
  static const String paygine = 'PAYGINE';
  static const String visa = 'VISA';
  static const String click = 'CLICK';
  static const String payme = 'PAYME';

  /// UzCard/Humo to'lovi endi server orqali (MYSAFARPAY) amalga oshiriladi:
  /// karta ma'lumotlari web formada kiritiladi (Visa kabi).
  static const String mysafarpay = 'MYSAFARPAY';

  static const int paymentTimeLimitSeconds = 1800;

  /// Endpoint javob bermaganda ko'rsatiladigan zaxira faol turlar.
  static const List<String> fallbackActiveNames = [mysafarpay, paygine, visa];

  /// API'dan kelgan to'lov turi nomini ([Result.name] — masalan "MYSAFARPAY",
  /// "PayMe") ilovadagi statik rasm va nomga bog'laydi. Katta-kichik harfga
  /// bog'liq emas. Noma'lum (yoki rasm yo'q) tur uchun `null` — bunday tur
  /// ro'yxatda ko'rsatilmaydi.
  static PaymentType? paymentTypeByName(String? name) {
    switch ((name ?? '').toUpperCase()) {
      case mysafarpay:
        // MYSAFARPAY — bitta to'lov turi, lekin UzCard va Humo'da ishlaydi;
        // shuning uchun ikkala logo bitta kartada yonma-yon ko'rsatiladi.
        return const PaymentType(
          id: mysafarpay,
          imagePath: ProjectAssets.bookingHumologo,
          secondaryImagePath: ProjectAssets.bookingUzkardlogo,
          cardName: 'HUMO / Uzcard',
          subtitle: 'Barcha kartalar',
        );
      case payme:
        return const PaymentType(
          id: payme,
          imagePath: ProjectAssets.bookingPaymelogo,
          subtitle: "Payme orqali to'lash",
        );
      case paygine:
        return const PaymentType(
          id: paygine,
          imagePath: ProjectAssets.bookingRuflag,
          cardName: 'Rossiya kartalari',
          subtitle: 'Mir, Visa, Mastercard',
        );
      case click:
        return const PaymentType(
          id: click,
          imagePath: ProjectAssets.bookingClicklogo,
          cardName: '',
          subtitle: "Click orqali to'lash",
        );
      case visa:
        return const PaymentType(
          id: visa,
          imagePath: ProjectAssets.bookingVisa,
          cardName: 'Visa kartalari',
          subtitle: 'Xalqaro kartalar',
        );
      default:
        return null;
    }
  }

  /// Local karta turimi tekshirish
  static bool isLocalCard(String type) {
    return type == uzcard || type == humo;
  }
}

