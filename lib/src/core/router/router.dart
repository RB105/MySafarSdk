import 'package:flutter/cupertino.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart'
    show PopDestinationsModel;
import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/ban_register/ban_register_page.dart';
import 'package:mysafar_sdk/src/view/ban_register/uz_ban_register.dart';
import 'package:mysafar_sdk/src/view/booking/ticket_pdf_page.dart';
import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart'
    show ProfileModel;
import 'package:mysafar_sdk/src/view/auth/pages/auth_page.dart';
import 'package:mysafar_sdk/src/view/booking/ticketed_booking_search_page.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';
import 'package:mysafar_sdk/src/view/destinations/destination_details_page.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart';
import 'package:mysafar_sdk/src/view/destinations/destinations_info_map_page.dart';
import 'package:mysafar_sdk/src/view/main/pages/main_input_page.dart';
import 'package:mysafar_sdk/src/view/main/pages/notification_page.dart';
import 'package:mysafar_sdk/src/view/main/pages/news_detail_page.dart';
import 'package:mysafar_sdk/src/model/remote/news/news_model.dart' show NewsModel;
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';
import 'package:mysafar_sdk/src/view/profile/pages/add_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_applications/view/my_applications_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/my_contracts_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_data_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/ofd_cheques_page.dart'
    show OFDChequesPage;
import 'package:mysafar_sdk/src/view/profile/pages/identification_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/personal_information_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/settings_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/support_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/updated_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/edit_profile_page.dart';
import 'package:mysafar_sdk/src/view/profile/profile_page.dart';
import 'package:flutter/material.dart'
    show MaterialPageRoute, Route, RouteSettings, Widget;
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart';
import 'package:mysafar_sdk/src/view/visa/myid_verification_page.dart';
import 'package:mysafar_sdk/src/view/visa/ordering_visa_card_page.dart';

class RouterGenerator {
  //Singletone
  static final RouterGenerator generator = RouterGenerator._init();

  static RouterGenerator get router => generator;

  RouterGenerator._init();

  // generator
  Route onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case BottomNavBarPage.routeName:
        return _navigate(
            BottomNavBarPage(
                pageIndex:
                    settings.arguments is int ? settings.arguments as int : 0),
            settings);

      case DestinationDetailsPage.routeName:
        return _navigateWithArgument<PopDestinationsModel>(
          settings,
          (args) => DestinationDetailsPage(destination: args),
        );

      case MainPage.routeName:
        return _pageRouteNavigate(MainPage(), settings);
      case MainInputPage.routeName:
        if (settings.arguments is Map) {
          final args = settings.arguments as Map;
          return _navigate(
              MainInputPage(
                isSmart: args['isSmart'] ?? false,
                nearbyAirport: args['nearbyAirport'],
              ),
              settings);
        }
        return _navigate(
            MainInputPage(isSmart: settings.arguments as bool? ?? false),
            settings);

      case NotificationPage.routeName:
        return _navigate(NotificationPage(), settings);
      case NewsDetailPage.routeName:
        return _navigateWithArgument<NewsModel>(
          settings,
          (args) => NewsDetailPage(news: args),
        );
      case RecommendationsTicketPage.routeName:
        return _navigateWithArgument<RecommendationRequestBody>(
          settings,
          (args) => RecommendationsTicketPage(requestBody: args),
        );

      case TicketInfoPage.routeName:
        return _navigateWithArgument<FlightElement>(
          settings,
          (args) => TicketInfoPage(flightElement: args),
        );
      case IdentificationPage.routeName:
        return _navigate(IdentificationPage(), settings);
      case SupportPage.routeName:
        return _navigate(SupportPage(), settings);
      case SettingsPage.routeName:
        return _navigate(SettingsPage(), settings);
      case PersonalInformationPage.routeName:
        return _navigateWithArgument<ProfileModel>(
          settings,
          (args) => PersonalInformationPage(profileData: args),
        );
      case BookedTicketsPage.routeName:
        return _navigate(BookedTicketsPage(), settings);
      case TicketedBookingSearchPage.routeName:
        return _navigate(
            TicketedBookingSearchPage(
              billingId: settings.arguments as String?,
            ),
            settings);
      case WebViewScreen.routName:
        return _navigateWithArgument<String>(
          settings,
          (args) => WebViewScreen(url: args),
        );
      case OFDChequesPage.routeName:
        return _navigate(OFDChequesPage(), settings);
      case MyApplicationsPage.routeName:
        return _navigate(const MyApplicationsPage(), settings);
      case MyContractsPage.routeName:
        return _navigateWithArgument<String>(
          settings,
          (args) => MyContractsPage(pinfl: args),
        );
      case ProfilePage.routeName:
        return _navigate(
            ProfilePage(profileData: settings.arguments as ProfileModel?),
            settings);
      case EditProfilePage.routeName:
        return _navigateWithArgument<ProfileModel>(
          settings,
          (args) => EditProfilePage(profileModel: args),
        );
      case MyDataPage.routeName:
        return _navigate(
            MyDataPage(profileModel: settings.arguments as ProfileModel?),
            settings);
      case AddPassengerPage.routeName:
        return _navigate(AddPassengerPage(), settings);
      case UpdatedPassengerPage.routeName:
        return _navigateWithArgument<UsersModel>(
          settings,
          (args) => UpdatedPassengerPage(usersModel: args),
        );
      case DestinationInfoMapWidget.routeName:
        return _navigateWithArgument<PopDestinationsModel>(
          settings,
          (args) => DestinationInfoMapWidget(destinationsModel: args),
        );
      case AuthPage.routeName:
        return _navigate(AuthPage(), settings);
      case TicketPdfPage.routeName:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return _navigate(TicketPdfPage(data: args), settings);
        }
        return _fallbackRoute(settings);
      case BanRegisterPage.routName:
        return _navigate(BanRegisterPage(), settings);
      case UzBanRegisterPage.routName:
        return _navigate(UzBanRegisterPage(), settings);
      case OrderingVisaCardPage.routName:
        return _navigate(OrderingVisaCardPage(), settings);
      case MyIdVerificationPage.routName:
        return _navigate(const MyIdVerificationPage(), settings);

      default:
        if (settings.name != null) {
          final name = settings.name!;
          // Handle Flutter's native deep link routing for /payment
          // Flutter engine calls pushRoute(fullUrl) on warm-start intent
          if (name.contains('mysafar.uz/payment') || name.startsWith('/payment')) {
            final uri = Uri.tryParse(
              name.startsWith('http') ? name : 'https://mysafar.uz$name',
            );
            final billingId = uri?.queryParameters['billing_id'];
            debugPrint('Router: payment deep link → billingId=$billingId');
            return _navigate(
                TicketedBookingSearchPage(billingId: billingId), settings);
          }
          if (name.contains('tgAuthResult') ||
              name.contains('tg.dev') ||
              name == '/') {
            return PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
                return const SizedBox.shrink();
              },
            );
          }
        }
        return _pageRouteNavigate(BottomNavBarPage(), settings);
    }
  }

  /// navigation method
  PageRoute _navigate(Widget page, [RouteSettings? settings]) {
    // if (Platform.isIOS) {
    //   return CupertinoPageRoute(
    //     builder: (context) => page,
    //   );
    // }
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
    );
  }

  PageRoute _pageRouteNavigate(Widget page, [RouteSettings? settings]) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
      );

  Route _navigateWithArgument<T>(
    RouteSettings settings,
    Widget Function(T args) builder,
  ) {
    final args = settings.arguments;
    if (args is T) {
      return _navigate(builder(args), settings);
    }
    return _fallbackRoute(settings);
  }

  Route _fallbackRoute([RouteSettings? settings]) =>
      _pageRouteNavigate(BottomNavBarPage(), settings);
}
