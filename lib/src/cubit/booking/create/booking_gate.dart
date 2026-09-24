import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show
        ErrorType,
        NetworkErrorResponse,
        NetworkResponse,
        NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightPrice;

// ─────────────────────────────────────────────────────────────────────────
//  Bron oldidan reysni qayta tekshirish (№36)
//
//  "Bron qilish" bosilganda yo'lovchi sahifasi darhol ochiladi, reys
//  tekshiruvi (`getFlightInfo`) esa fonda davom etadi. Bron yaratishdan
//  oldin natija kutiladi va [BookingGate.decide] qaror qiladi:
//  davom etish / narx o'zgardi (tasdiq kerak) / reys yaroqsiz.
// ─────────────────────────────────────────────────────────────────────────

/// Fondagi reys tekshiruvi natijasi.
sealed class FlightValidationResult {
  const FlightValidationResult();
}

/// Reys tasdiqlandi — [element] yangi id (bron tokeni) va narx bilan.
final class FlightValidationPassed extends FlightValidationResult {
  const FlightValidationPassed(this.element);
  final FlightElement element;
}

/// Reys tekshiruvdan o'tmadi (sotuvda yo'q, tarmoq xatosi va h.k.).
final class FlightValidationFailed extends FlightValidationResult {
  const FlightValidationFailed({this.message, this.errorType});

  /// Server / tarmoq xabari (bo'sh bo'lsa dialog o'z matnini qo'yadi).
  final String? message;
  final ErrorType? errorType;
}

/// Hali tugamagan (yoki tugagan) tekshiruv — yo'lovchi sahifasiga beriladi.
///
/// [result] hech qachon xato (exception) bilan tugamaydi — har qanday xato
/// [FlightValidationFailed] ga aylanadi.
class FlightValidation {
  FlightValidation._(this.flightId, this.keep, this.result, this._fetch);

  /// Tekshirilayotgan reys id'si (qayta urinish shu bilan).
  final String flightId;

  /// Tekshiruv paytida foydalanuvchi boshqa tarif tanlagan bo'lsa — muvaffaqiyatli
  /// natija o'rniga shu element ishlatiladi (tanlov eski element bilan
  /// almashtirilmaydi, ticket_info'dagi poyga tuzatishi bilan bir xil).
  final FlightElement? keep;

  final Future<FlightValidationResult> result;

  final Future<NetworkResponse> Function(String id)? _fetch;

  /// Tayyor so'rov ([response]) natijasini [FlightValidationResult] ga
  /// o'giradi.
  factory FlightValidation.fromResponse(
    String flightId,
    Future<NetworkResponse> response, {
    FlightElement? keep,
    Future<NetworkResponse> Function(String id)? fetch,
  }) {
    final result = response.then<FlightValidationResult>(
      (r) => resultOf(r, keep: keep),
      onError: (Object e) {
        debugPrint('MySafarSdk: reys tekshiruvi xatosi ($e)');
        return const FlightValidationFailed();
      },
    );
    return FlightValidation._(flightId, keep, result, fetch);
  }

  /// Shu tekshiruvning tarif tanlangan varianti — muvaffaqiyatli natijada
  /// [element] qaytadi, xato esa o'zgarmaydi.
  FlightValidation keeping(FlightElement element) {
    final mapped = result.then<FlightValidationResult>((r) =>
        r is FlightValidationPassed ? FlightValidationPassed(element) : r);
    return FlightValidation._(flightId, element, mapped, _fetch);
  }

  /// Qayta urinish mumkinmi (so'rov funksiyasi berilgan bo'lsa).
  bool get canRetry => _fetch != null && flightId.isNotEmpty;

  /// Xuddi shu reysni qaytadan tekshiradi.
  FlightValidation retry() {
    final fetch = _fetch;
    if (fetch == null) return this;
    return FlightValidation.fromResponse(flightId, fetch(flightId),
        keep: keep, fetch: fetch);
  }

  /// `getFlightInfo` javobi → natija.
  static FlightValidationResult resultOf(NetworkResponse response,
      {FlightElement? keep}) {
    if (response is NetworkSuccessResponse && response.data is FlightElement) {
      return FlightValidationPassed(keep ?? response.data as FlightElement);
    }
    if (response is NetworkErrorResponse) {
      return FlightValidationFailed(
        message: response.getError(),
        errorType: response.errorType,
      );
    }
    return const FlightValidationFailed();
  }
}

/// Bron oldidan qaror.
sealed class BookingGateDecision {
  const BookingGateDecision();
}

/// Bron qilish mumkin — [element] (tasdiqlangan) id va narxi bilan.
final class BookingGateProceed extends BookingGateDecision {
  const BookingGateProceed(this.element);
  final FlightElement element;
}

/// Narx o'zgardi — foydalanuvchi eski → yangi narxni ko'rib tasdiqlashi kerak.
final class BookingGatePriceChanged extends BookingGateDecision {
  const BookingGatePriceChanged({
    required this.element,
    required this.oldPrice,
    required this.newPrice,
    required this.currencyLabel,
  });

  final FlightElement element;
  final double oldPrice;
  final double newPrice;
  final String currencyLabel;
}

/// Reys tekshiruvdan o'tmadi — bron qilinmaydi.
final class BookingGateFailed extends BookingGateDecision {
  const BookingGateFailed(this.failure);
  final FlightValidationFailed failure;
}

class BookingGate {
  BookingGate._();

  /// Narxlar farqi shundan kichik bo'lsa o'zgarmagan hisoblanadi (yaxlitlash).
  static const double _epsilon = 0.5;

  /// [shown] — foydalanuvchiga ko'rsatilgan reys (narxi shu bo'yicha
  /// ko'rilgan), [result] — fondagi tekshiruv natijasi, [currency] — joriy
  /// valyuta (narx shu valyutada taqqoslanadi va dialogda ko'rsatiladi).
  static BookingGateDecision decide({
    required FlightElement shown,
    required FlightValidationResult result,
    required AppCurrency currency,
  }) {
    switch (result) {
      case FlightValidationFailed():
        return BookingGateFailed(result);
      case FlightValidationPassed(:final element):
        final change = priceChange(shown.price, element.price, currency);
        if (change == null) return BookingGateProceed(element);
        return BookingGatePriceChanged(
          element: element,
          oldPrice: change.oldPrice,
          newPrice: change.newPrice,
          currencyLabel: change.currencyLabel,
        );
    }
  }

  /// Ikki narx [currency] da (yo'q bo'lsa UZS da) farq qilsa — eski/yangi
  /// qiymatlar, aks holda (yoki taqqoslab bo'lmasa) `null`.
  static ({double oldPrice, double newPrice, String currencyLabel})?
      priceChange(
          FlightPrice? oldPrice, FlightPrice? newPrice, AppCurrency currency) {
    var before = CurrencyProvider.resolveElementPrice(oldPrice, currency);
    var after = CurrencyProvider.resolveElementPrice(newPrice, currency);
    if (before == null || after == null) return null;
    // Biri tanlangan valyutada, ikkinchisi UZS ga qaytgan bo'lsa — ikkalasini
    // ham UZS da taqqoslaymiz.
    if (before.currency != after.currency) {
      before = CurrencyProvider.resolveElementPrice(oldPrice, AppCurrency.uzs);
      after = CurrencyProvider.resolveElementPrice(newPrice, AppCurrency.uzs);
      if (before == null ||
          after == null ||
          before.currency != after.currency) {
        return null;
      }
    }
    if ((before.value - after.value).abs() < _epsilon) return null;
    return (
      oldPrice: before.value,
      newPrice: after.value,
      currencyLabel: after.currency.label,
    );
  }

  // ── Bron yaratilgach narx oshgani (BookingCreateModel) ────────────────

  /// Bron javobidagi summa ([bookedAmount], [bookedCurrency] — ISO kod:
  /// 643 RUB, 840 USD, boshqasi UZS) ko'rsatilgan narxdan ([shown]) oshganmi.
  /// Oshgan bo'lsa eski/yangi qiymatlar, aks holda `null`.
  static ({double oldPrice, double newPrice, String currencyLabel})?
      bookedPriceIncrease(
          FlightPrice? shown, dynamic bookedAmount, int? bookedCurrency) {
    if (shown == null) return null;
    final String? raw = switch (bookedCurrency) {
      643 => shown.rub?.amount,
      840 => shown.usd?.amount,
      _ => shown.uzs?.amount,
    };
    final double? oldValue = parseAmount(raw);
    final double? newValue = parseAmount(bookedAmount);
    if (oldValue == null || oldValue <= 0 || newValue == null) return null;
    if (newValue <= oldValue) return null;
    return (
      oldPrice: oldValue,
      newPrice: newValue,
      currencyLabel: currencyLabelOf(bookedCurrency),
    );
  }

  static String currencyLabelOf(int? code) => switch (code) {
        643 => 'RUB',
        840 => 'USD',
        _ => 'UZS',
      };

  /// "1 500 000", "1,500,000" yoki son — `double`; yaroqsiz bo'lsa `null`.
  static double? parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim().replaceAll(' ', '');
    return double.tryParse(str) ?? double.tryParse(str.replaceAll(',', ''));
  }
}
