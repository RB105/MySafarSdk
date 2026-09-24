import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/pdf/ticket_pdf_actions.dart';
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_information_page.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

void main() {
  group('funnelEventForPush (№19)', () {
    test('route literals match page routeNames', () {
      expect(AnalyticsService.passengerInfoRoute,
          PassengerInformationPage.routeName);
      expect(
          AnalyticsService.bookingConfirmRoute, BookingConfirmPage.routeName);
    });

    test('passenger page push -> passenger_form_started', () {
      expect(
        AnalyticsService.funnelEventForPush('/passengerInformation', '/x'),
        'passenger_form_started',
      );
    });

    test('passenger page -> confirm -> passenger_form_completed', () {
      expect(
        AnalyticsService.funnelEventForPush(
            '/bookingConfirm', '/passengerInformation'),
        'passenger_form_completed',
      );
    });

    test('other pushes produce nothing', () {
      // "Buyurtmalarim"dan to'lovga — forma to'ldirilmagan.
      expect(
          AnalyticsService.funnelEventForPush(
              '/bookingConfirm', '/bottom_nav_bar'),
          isNull);
      expect(
          AnalyticsService.funnelEventForPush(
              '/passengerForm', '/passengerInformation'),
          isNull);
      expect(AnalyticsService.funnelEventForPush(null, null), isNull);
    });
  });

  group('screen names (№19)', () {
    test('navbar route resolves to visible tab name', () {
      NavigationService.registerScreenAlias(
          BottomNavBarPage.routeName, BottomNavBarPage.currentScreenName);
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: BottomNavBarPage.routeName),
        builder: (_) => const SizedBox(),
      );
      final before = BottomNavBarPage.currentTabIndex.value;
      BottomNavBarPage.currentTabIndex.value = BottomNavBarPage.ordersTabIndex;
      expect(NavigationService.screenNameOf(route), 'tab_orders');
      BottomNavBarPage.currentTabIndex.value = 0;
      expect(NavigationService.screenNameOf(route), 'tab_home');
      BottomNavBarPage.currentTabIndex.value = before;
    });

    test('plain named route keeps its name', () {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/documentScanner'),
        builder: (_) => const SizedBox(),
      );
      expect(NavigationService.screenNameOf(route), '/documentScanner');
    });
  });

  testWidgets('shareOriginOf returns the widget rect (iPad popover)',
      (tester) async {
    late BuildContext buttonContext;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 20),
          child: Builder(builder: (context) {
            buttonContext = context;
            return const SizedBox(width: 40, height: 30);
          }),
        ),
      ),
    ));
    expect(TicketPdfActions.shareOriginOf(buttonContext),
        const Rect.fromLTWH(10, 20, 40, 30));
  });
}
