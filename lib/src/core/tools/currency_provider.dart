import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;
import 'package:mysafar_sdk/src/model/remote/avia/top_city_model.dart'
    show TopCityModel;
import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart' show HotTicketPrice;

class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider() {
    loadCurrency();
  }
  final storage = GetStorage();
  static const _key = 'selected_currency';

  AppCurrency _currency = AppCurrency.uzs;

  AppCurrency get currency => _currency;

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

  String getElementPrice(FlightPrice? price) {
    switch (_currency) {
      case AppCurrency.uzs:
        return "${price?.uzs?.amount} ${currency.label}";
      case AppCurrency.rub:
        return price?.rub != null
            ? "${price?.rub?.amount} ${currency.label}"
            : "${price?.uzs?.amount} ${currency.label}";
      case AppCurrency.usd:
        return price?.usd != null
            ? "${price?.usd?.amount} ${currency.label}"
            : "${price?.uzs?.amount} ${currency.label}";
    }
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
