import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart'
    show TopCityModel;
import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart' show HotTicketPrice;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider() {
    loadCurrency();
  }
  final storage = sdkStorage();
  static const _key = 'selected_currency';

  AppCurrency _currency = AppCurrency.uzs;

  AppCurrency get currency => _currency;

  /// Foydalanuvchi valyutani AYNAN o'zi tanlaganmi (storage'da saqlangan).
  /// `false` — hali standart (UZS); birinchi qidiruvda bir marta so'rash uchun.
  bool get hasSelected => storage.read(_key) != null;

  void loadCurrency() {
    final name = storage.read(_key);
    if (name != null) {
      _currency = AppCurrency.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppCurrency.uzs,
      );
      notifyListeners();
    }
  }

  Future<void> setCurrency(AppCurrency newCurrency) async {
    _currency = newCurrency;
    storage.write(_key, newCurrency.name);
    notifyListeners();
  }

  /// Reys narxi joriy valyutada ("2 751 009 UZS", "385.5 USD"). Tanlangan
  /// valyuta bloki kelmagan (yoki summasi 0) bo'lsa — UZS summasi UZS belgisi
  /// bilan; narx umuman bo'lmasa "—".
  String getElementPrice(FlightPrice? price) {
    final resolved = resolveElementPrice(price, _currency);
    if (resolved == null) return "—";
    return "${resolved.raw} ${resolved.currency.label}";
  }

  /// [price]dan [currency] valyutasidagi summani tanlaydi. Shu valyuta bloki
  /// yo'q yoki summasi yaroqsiz/0 bo'lsa — UZS summasiga qaytadi va natijada
  /// valyuta ham UZS bo'ladi (UZS summasi RUB/USD belgisi bilan chiqmasin).
  /// Hech qaysi summa bo'lmasa `null`.
  static ({String raw, double value, AppCurrency currency})?
      resolveElementPrice(FlightPrice? price, AppCurrency currency) {
    final String? selected = switch (currency) {
      AppCurrency.uzs => price?.uzs?.amount,
      AppCurrency.rub => price?.rub?.amount,
      AppCurrency.usd => price?.usd?.amount,
    };
    final double? selectedValue = ElementFormatter.parsePrice(selected);
    if (selectedValue != null) {
      return (raw: selected!.trim(), value: selectedValue, currency: currency);
    }
    final String? uzs = price?.uzs?.amount;
    final double? uzsValue = ElementFormatter.parsePrice(uzs);
    if (uzsValue != null) {
      return (raw: uzs!.trim(), value: uzsValue, currency: AppCurrency.uzs);
    }
    return null;
  }


  String getPopularCityPrice(TopCityModel element) {
    switch (currency) {
      case AppCurrency.uzs:
        return "${element.formattedPriceUzs} UZS";
      case AppCurrency.usd:
        return "${element.formattedPriceUsd} USD";
      case AppCurrency.rub:
        return "${element.formattedPriceRub} RUB";
    }
  }
  String getHotTicketPrice(HotTicketPrice price) {
    switch (currency) {
      case AppCurrency.uzs:
        return "${price.uzs.amount} UZS";
      case AppCurrency.usd:
        return "${price.usd?.amount} USD";
      case AppCurrency.rub:
        return "${price.rub?.amount} RUB";
    }
  }

  String getPriceWithCurrency(String sum, int currency) {
    String getCurrency() {
      switch (currency) {
        case 860:
          return "UZS";
        case 643:
          return "RUB";
        case 840:
          return "USD";
        default:
          return "UZS";
      }
    }

    return "$sum ${getCurrency()}";
  }
}
