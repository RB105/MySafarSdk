import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

class PaymentHelper {
  PaymentHelper._();

  static Future<void> openExternalUrl(String url) async {
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          debugPrint('URL ochib bo\'lmadi: $url');
        }
      }
    } catch (e) {
      debugPrint('URL ochishda xatolik: $e');
    }
  }

  /// To'lov sahifasini ochadi; sahifa yopilganda (foydalanuvchi yopdi)
  /// tugaydi — chaqiruvchi shundan so'ng to'lov holatini tekshiradi.
  static Future<void> openInWebView(BuildContext context, String url) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/paymentWebView'),
        builder: (_) => WebViewScreen(url: url, confirmClose: true),
      ),
    );
  }

  static void navigateToHome(BuildContext context) =>
      _navigateToTab(context, 0);

  /// "Buyurtmalar" tabi — to'langan chipta shu yerda chiqadi.
  static void navigateToOrders(BuildContext context) =>
      _navigateToTab(context, 1);

  static void _navigateToTab(BuildContext context, int tab) {
    // Booking yakunlandi — biletlar keshi bekor qilinadi, keyingi ochilishda
    // serverdan qayta yuklanadi.
    ConfirmedTicketsCubit.clearCache();
    Navigator.pushNamedAndRemoveUntil(
      context,
      BottomNavBarPage.routeName,
      (route) => false,
      arguments: tab,
    );
  }

  static DateTime? parseCreatedAt(String? created) {
    if (created == null || created.isEmpty) return null;

    final formats = [
      null,
      'dd-MM-yyyy HH:mm',
      'dd.MM.yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'yyyy-MM-dd HH:mm:ss',
    ];

    for (final format in formats) {
      try {
        if (format == null) {
          return DateTime.parse(created);
        }
        return DateFormat(format).parseStrict(created);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';

    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

