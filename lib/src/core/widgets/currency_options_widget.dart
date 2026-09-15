import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkSheetFrame;
import 'package:mysafar_sdk/src/core/widgets/sdk_option_sheet.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

/// Valyuta tanlash sheet'i — kod, to'liq nom va bayroq; izohda narxlar
/// tanlangan valyutada ko'rsatilishi aytiladi (birinchi qidiruvda ham
/// shu sheet ochiladi).
class CurrencyOptionsWidget extends StatelessWidget {
  const CurrencyOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return SdkSheetFrame(
      child: SdkOptionList<AppCurrency>(
        title: "rate".tr(),
        subtitle: "currency_sheet_hint".tr(),
        selected: currencyProvider.currency,
        options: [
          _option(AppCurrency.uzs, "UZS", "currency_uzs_name",
              Assets.profileFlagUz),
          _option(AppCurrency.rub, "RUB", "currency_rub_name",
              Assets.profileFlagRu),
          _option(AppCurrency.usd, "USD", "currency_usd_name",
              Assets.profileFlagUs),
        ],
        onSelected: (currency) {
          currencyProvider.setCurrency(currency);
          Navigator.pop(context);
        },
      ),
    );
  }

  SdkOptionItem<AppCurrency> _option(
    AppCurrency value,
    String code,
    String nameKey,
    String flag,
  ) {
    return SdkOptionItem(
      value: value,
      title: code,
      subtitle: nameKey.tr(),
      leading: SdkRoundFlag(image: Image.asset(flag, fit: BoxFit.cover)),
    );
  }
}
