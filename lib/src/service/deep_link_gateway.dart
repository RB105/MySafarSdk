import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/api/sdk.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/view/booking/ticketed_booking_search_page.dart';

/// Deep-link'lar uchun package-ichki shlyuz. App'dagi `DeepLinkService`
/// (app_links) o'rnini bosadi: link tinglash host app'da qoladi, host
/// `MySafarSdk.handleLink(uri)` orqali shu yerga uzatadi.
class DeepLinkGateway {
  DeepLinkGateway._();

  static String? _pendingBillingId;

  /// Host'dan kelgan link. mysafar.uz/payment linklarini taniydi; navigator
  /// tayyor bo'lsa darhol ochadi, aks holda pending sifatida saqlaydi —
  /// BottomNavBar `consumePendingLink()` bilan keyin ochadi.
  static void handleLink(Uri uri) {
    debugPrint('DeepLinkGateway: handleLink uri=$uri');
    MySafarSdk.analytics.reportAppOpen(uri.toString());

    final host = uri.host;
    if (host != 'mysafar.uz' && host != 'www.mysafar.uz') return;
    if (uri.path != '/payment') return;
    final billingId = uri.queryParameters['billing_id'];
    if (billingId == null || billingId.isEmpty) return;

    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed(
        TicketedBookingSearchPage.routeName,
        arguments: billingId,
      );
    } else {
      debugPrint('DeepLinkGateway: storing pendingBillingId=$billingId');
      _pendingBillingId = billingId;
    }
  }

  /// BottomNavBar initState'dan (addPostFrameCallback bilan) chaqiriladi —
  /// cold-start linklar nav stack qurilgach ochiladi.
  static void consumePendingLink() {
    final id = _pendingBillingId;
    if (id == null) return;
    _pendingBillingId = null;
    debugPrint('DeepLinkGateway: consumePendingLink → billingId=$id');
    NavigationService.navigatorKey.currentState?.pushNamed(
      TicketedBookingSearchPage.routeName,
      arguments: id,
    );
  }
}
