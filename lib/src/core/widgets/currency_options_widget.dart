import 'dart:io';

import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

class CurrencyOptionsWidget extends StatefulWidget {
  const CurrencyOptionsWidget({super.key});

  @override
  State<CurrencyOptionsWidget> createState() => _CurrencyOptionsWidgetState();
}

class _CurrencyOptionsWidgetState extends State<CurrencyOptionsWidget> {
  late AppCurrency currency;
  late CurrencyProvider currencyProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    currencyProvider = Provider.of<CurrencyProvider>(context);
    currency = currencyProvider.currency;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: Platform.isAndroid,
        top: Platform.isAndroid,

        child:DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Padding(
            padding: context.k16verticalPadding,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              /// Header Row
              Padding(
                padding: context.k16horizontalPadding,
                child: Row(
                  children: [
                    Text("rate".tr(), style: context.textTheme.bodyMedium),
                    Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Divider(thickness: 1, color: context.color.outline),
              context.szBoxHeight12,

              /// Options
              Padding(
                padding: context.k16horizontalPadding,
                child: Column(
                  children: [
                    _buildOption("UZS", AppCurrency.uzs),
                    context.szBoxHeight16,
                    _buildOption("RUB", AppCurrency.rub),
                    context.szBoxHeight16,
                    _buildOption("USD", AppCurrency.usd),
                    context.szBoxHeight16,
                  ],
                ),
              ),

              context.szBoxHeight16
            ]))));
  }

  Widget _buildOption(String title, AppCurrency code) {
    return InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          currencyProvider.setCurrency(code);
          Navigator.pop(context);
        },
        child: Row(children: [
          SizedBox(
            width: 24,
            height: 18,
            child: Center(
              child: Image.asset(getFlag(code)),
            ),
          ),
          context.szBoxWidth12,
          Text(title, style: context.textTheme.bodyMedium),
          Spacer(),
          Visibility(
              visible: currency == code,
              replacement: SizedBox.shrink(),
              child: Icon(Icons.check_circle,
                  color:ProjectTheme.success))
        ]));
  }

  String getFlag(AppCurrency code) {
    switch (code) {
      case AppCurrency.uzs:
        return Assets.profileFlagUz;
      case AppCurrency.usd:
        return Assets.profileFlagUs;
      case AppCurrency.rub:
        return Assets.profileFlagRu;
    }
  }
}
