class EndPoints {
  // api
  static const String api_v1_token = '/api/v1/token/';
  static const String api_v1_token_refresh = '/api/v1/token/refresh/';
  static const String api_v1_token_verify = '/api/v1/token/verify/';

  static const String egov = '/egov/';

  // auth

  static const String google_auth = '/auth/google-auth';
  static const String telegram_auth = '/auth/telegram-login';
  static const String auth_phone_register = '/auth/phone-register';
  static const String auth_web_register = '/auth/web-register';
  static const String auth_phone_login = '/auth/phone-login';
  static const String auth_send_otp = '/auth/send-otp';
  static const String auth_verify_otp = '/auth/verify-otp';
  static const String auth_set_reg_id = '/auth/set-regid';
  static const String auth_set_password = '/auth/set-password';
  static const String auth_user_delete = '/auth/user-delete';

  // avia
  static const String avia_airports = '/avia/airports';
  static const String avia_recommendatins = '/avia/get-recommendations';
  // get-recommendations uch manbaga bo'lindi — uchchalasiga parallel so'rov ketadi.
  static const String avia_recommendations_centrum =
      '/avia/get-recommendations-centrum';
  static const String avia_recommendations_myagent =
      '/avia/get-recommendations-myagent';
  static const String avia_recommendations_flydubai =
      '/avia/get-recommendations-flydubai';
  static const String centrum_air_recommendatins = '/centrum/find-ticket';
  static const String main_pop_cities = '/main/popcites';
  static const String main_search_history = '/main/search-history'; // hearder
  static const String ticket_price_by_month = '/avia/one-month-ticket-price';
  static const String avia_get_tariff = '/avia/get-flight-tariffs';
  static const String avia_centrum_recommendatins = '/centrum/find-ticket';
  static const String avia_centrum_rec = '/centrum/find-ticket';

  // booking
  static const String avia_booking_create = '/avia/booking-create'; // hearder
  static const String avia_booking_confirm = '/avia/booking-confirm'; // hearder
  static const String avia_booking_status = '/avia/ticket-data'; // hearder
  static const String avia_payment_confirm = '/avia/payment-confirm'; // hearder
  static const String get_card_info = '/avia/card-info'; // hearder

  static const String getPaymentType = '/get-payment-type';
  static const String avia_ticketed_booking_info = '/avia/ticketed-booking-info';

  // account
  static const String profile = '/profile'; // hearder
  static const String updateProfile = '/auth/update-profile'; // hearder
  static const String user_confirmed_tickets =
      '/avia/user-confirmed-tickets'; // hearder
  static const String user_ofd_cheques = '/main/cheques'; // hearder
  static const String get_user_date = '/get-user-data'; // hearder
  static const String create_user_date = '/create-user-data'; // hearder
  static const String delete_user_date = '/delete-user-data'; // hearder
  static const String update_user_date = '/update-user-data'; // hearder
  static const String check_version_platform =
      '/check-version-platform'; // hearder

  // mts
  static const String mts_callback_tranfer = '/mtc/callback/transfer';

  /*
  SKOTE path
  */
  static const hot_tickets = '/hot-recommendations';
  static const destinations = '/destinations';
  static const contacts = '/contacts';
  static const payment_methods = '/payment-methods';
  static const get_quick_recommendations = '/get-quick-recommendations';
  static const ai_search_chat = '/ai-search-chat';

  /*visa */
  static const myIdSession = '/my-id-session/';
  static String myIdUserInfo(String code, String phoneNumber) =>
      '/my-id-user-info/$code/$phoneNumber/';
  static const autopayApplication = '/autopay/application';
  static const autopayContract = '/autopay/contract';
  static const autopayContractFind = '/autopay/contract-find';
  static const autopaySendCardOtp = '/autopay/send-card-otp';
  static const autopayVerifyCardOtp = '/autopay/verify-card-otp';
  static const autopayCardLink = '/autopay/card-link';

  /*centrum*/
  static const centrum_recommendatins = '/centrum/find-ticket';

  /*
  * Deploy
  * */
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=mysafar.uz.mobile';
  static const String appStoreUrl =
      'https://apps.apple.com/uz/app/mysafar/id6748373763';
}
