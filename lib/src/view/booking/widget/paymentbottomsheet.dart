import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/view/booking/widget/country_search_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/humo_uzkard_widget.dart';

import '../../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;

void showPaymentCardBottomSheet(
    BuildContext context, String trId, String cardType, FlightPrice? price) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.color.primaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
            top: Platform.isAndroid,
            bottom: Platform.isAndroid,
            child: PaymentCardBottomSheet(
              trId: trId,
              cardType: cardType,
              price: price,
            ),
          ));
}

String reverseMonthYear(String input) {
  if (input.contains('/')) {
    final parts = input.split('/');
    if (parts.length == 2) {
      return parts[1] + parts[0];
    }
  }
  return input;
}

TextEditingController otpController = TextEditingController();
final FocusNode focusNode = FocusNode();
ValueNotifier<int> timerNotifier = ValueNotifier<int>(59);
Timer? timer;
bool timerStarted = false;

void showPaymentOtpBottomSheet(
    {required BuildContext context,
    required final Map<String, dynamic> data,
    required final Map<String, dynamic> params,
    required FlightPrice? price}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.color.primaryContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      top: Platform.isAndroid,
      bottom: Platform.isAndroid,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, __) =>
            OtpPaymentBottomSheet(data: data, params: params, sum: price),
      ),
    ),
  );
}

Future<Map<String, dynamic>?> showCitySearchPicker(BuildContext context) async {
  if (Platform.isIOS) {
    return await showCupertinoSheet<Map<String, dynamic>>(
        context: context,
        builder: (context) => MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: SearchCountryWidget(),
            ));
  }

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SearchCountryWidget(),
  );
}
