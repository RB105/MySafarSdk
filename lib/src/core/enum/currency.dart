enum AppCurrency { uzs, usd, rub }

extension AppCurrencyExtension on AppCurrency {
  String get symbol {
    switch (this) {
      case AppCurrency.uzs:
        return 'UZS';
      case AppCurrency.usd:
        return 'USD';
      case AppCurrency.rub:
        return 'RUB';
    }
  }

  String get label {
    switch (this) {
      case AppCurrency.uzs:
        return 'UZS';
      case AppCurrency.usd:
        return 'USD';
      case AppCurrency.rub:
        return 'RUB';
    }
  }
}
