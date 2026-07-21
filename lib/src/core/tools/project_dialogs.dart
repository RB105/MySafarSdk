import 'dart:async';
import 'dart:io' show Platform;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoAlertDialog,
        CupertinoButton,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        showCupertinoDialog;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontWeight, HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/service/profile/tickets_cache.dart';
import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/currency_options_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/date_calendar_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/lang_options_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/passenger_count_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/search_city_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/theme_options_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/ticket_filters_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/ticket_tariffs_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/verify_otp_widget.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/view/auth/pages/auth_page.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart' show TicketInfoPage;
import 'package:syncfusion_flutter_datepicker/datepicker.dart'
    show PickerDateRange;
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, canLaunchUrl, launchUrl;

import 'formatters.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class ProjectDialogs {
  static BuildContext? _dialogContext;

  /// type is for DateRangePickerSelectionMode
  static Future<PickerDateRange?> showCalendartPicker(
      BuildContext context,
      int type,
      PickerDateRange? selectedDates,
      final AirPortsModel? fromDir,
      final AirPortsModel? toDir) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet<PickerDateRange?>(
          context: context,
          builder: (context) => MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: DateCalendarWidget(
                  type: type,
                  params: selectedDates,
                  fromDir: fromDir,
                  toDir: toDir,
                ),
              ));
    } else {
      return await showModalBottomSheet<PickerDateRange?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => DateCalendarWidget(
          type: type,
          params: selectedDates,
          fromDir: fromDir,
          toDir: toDir,
        ),
      );
    }
  }

  static Future<Map<String, dynamic>?> showPassengerCountPicker(
      BuildContext context, Map<String, dynamic>? params) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet<Map<String, dynamic>?>(
          context: context,
          builder: (context) => MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: PassengerCountWidget(
                  params: params ?? {},
                ),
              ));
    }
    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => PassengerCountWidget(
        params: params ?? {},
      ),
    );
  }

  /// directionType for Direction title
  ///
  /// 0 - from direction ; 1 - to direction
  static Future<AirPortsModel?> showCitySearchPicker(
      BuildContext context, int directionType) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet<AirPortsModel?>(
          context: context,
          builder: (context) => MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: SearchCityWidget(
                  directionType: directionType,
                ),
              ));
    }

    return await showModalBottomSheet<AirPortsModel?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SearchCityWidget(
        directionType: directionType,
      ),
    );
  }

  static Future<RecommendationRequestBody?> showTicketFilter(
      BuildContext context, RecommendationRequestBody filterBody) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet<RecommendationRequestBody?>(
        context: context,
        builder: (context) => MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: TicketFiltersWidget(params: filterBody)),
      );
    }

    return await showModalBottomSheet<RecommendationRequestBody?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TicketFiltersWidget(params: filterBody),
    );
  }

  static Future showLowcostSheet(
      BuildContext context, FlightElement flightElement) async {
    final parentContext = context;
    showModalBottomSheet(
      backgroundColor: context.color.primaryContainer,
      isScrollControlled: true,
      context: context,
      builder: (sheetContext) => SizedBox(
        height: sheetContext.height * 0.7,
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Padding(
            padding: sheetContext.k16horizontalPadding,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  sheetContext.szBoxHeight16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "lowcost".tr(),
                        style: sheetContext.textTheme.bodyMedium,
                      ),
                      InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => Navigator.of(sheetContext).pop(),
                          child: Icon(Icons.close))
                    ],
                  ),
                  Divider(
                    thickness: 1,
                    color: ProjectTheme.borderLight,
                  ),
                  sheetContext.szBoxHeight16,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "about_lowcost".tr(),
                      style: sheetContext.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    "low_cost_airline_info".tr(),
                    style: sheetContext.textTheme.bodySmall,
                  ),
                  sheetContext.szBoxHeight16,
                  Row(
                    children: [
                      Expanded(
                          child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                            style: ProjectTheme.blueBorderButtonStyle,
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text("done".tr())),
                      )),
                      sheetContext.szBoxWidth12,
                      Expanded(
                          child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                            style: ProjectTheme.blueButtonStyle,
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              TicketInfoPage.show(
                                  parentContext, flightElement);
                            },
                            child: Text("continue_ticket".tr())),
                      )),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future showVerifyOtpSheet(
      BuildContext context, final String phone, final otpToken) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet(
          context: context,
          builder: (dialogContext) {
            _dialogContext = dialogContext;
            return MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: VerifyOtpWidget(phone: phone, otpToken: otpToken));
          });
    }
    return await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return VerifyOtpWidget(phone: phone, otpToken: otpToken);
        });
  }

  static Future showAuthPhoneSheet(
    BuildContext context, {
    VoidCallback? onAuthSuccess,
  }) async {
    if (Platform.isIOS) {
      return await showSdkCupertinoSheet(
          context: context,
          builder: (dialogContext) {
            _dialogContext = dialogContext;
            return MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: AuthPage(onAuthSuccess: onAuthSuccess));
          });
    }
    return await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return AuthPage(onAuthSuccess: onAuthSuccess);
        });
  }

  static Future<FlightElement?> showTariffPicker(
      BuildContext context, List<FlightTariffModel> tariffs, String tid) async {
    if (tariffs.isEmpty) return null;

    if (Platform.isIOS) {
      return await showSdkCupertinoSheet<FlightElement?>(
          context: context,
          builder: (context) => MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: TariffPickerWidget(
                tariffs: tariffs,
                id: tid,
              )));
    }

    return await showModalBottomSheet<FlightElement?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => TariffPickerWidget(
              tariffs: tariffs,
              id: tid,
            ));
  }

  /// dialog that shows Support Menu
  ///
  /// 0 -> call
  ///
  /// 1 - chat
  ///
  /// 2 - via tg
  static Future<void> showSupportMenu(BuildContext context) async {
    final action = await showModalBottomSheet<int?>(
        context: context,
        builder: (context) => SafeArea(
              bottom: Platform.isAndroid,
              child: SizedBox(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: context.color.primaryContainer,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12))),
                    child: Padding(
                      padding: context.k16horizontalPadding
                          .copyWith(bottom: 12.0, top: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text("support_badge_title".tr(),
                                  style: context.textTheme.bodyMedium),
                              Expanded(child: SizedBox.shrink()),
                              InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Icon(Icons.close))
                            ],
                          ),
                          Divider(thickness: 1, color: context.color.outline),
                          Text("support_subtitle".tr(),
                              maxLines: 3,
                              textAlign: TextAlign.start,
                              style: context.textTheme.bodyMedium),
                          context.szBoxHeight12,
                          SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                  style: ProjectTheme.blueButtonStyle,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop(0);
                                  },
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: SvgPicture.asset(
                                              Assets.iconsPhoneCallIcon),
                                        ),
                                        context.szBoxWidth12,
                                        Text("support_via_phone".tr()),
                                      ]))),
                          context.szBoxHeight12,
                          // SizedBox(
                          //     height: 48,
                          //     width: double.infinity,
                          //     child: ElevatedButton(
                          //         style: ProjectTheme.blueButtonStyle,
                          //         onPressed: () => Navigator.of(context).pop(1),
                          //         child: Row(
                          //             mainAxisAlignment: MainAxisAlignment.center,
                          //             children: [
                          //               SizedBox(
                          //                 width: 24,
                          //                 height: 24,
                          //                 child: SvgPicture.asset(
                          //                     ProjectAssets.messageIcon),
                          //               ),
                          //               context.szBoxWidth12,
                          //               Text("Chat orqali bog'lanish"),
                          //             ]))),
                          // context.szBoxHeight12,
                          SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: ElevatedButton(
                                  style: ProjectTheme.blueButtonStyle,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop(2);
                                  },
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: SvgPicture.asset(
                                              Assets.iconsTelegramIcon),
                                        ),
                                        context.szBoxWidth12,
                                        Text("support_via_tg".tr())
                                      ]))),
                          SizedBox(height: 20)
                        ],
                      ),
                    )),
              ),
            ));
    if (action != null) {
      switch (action) {
        case 0:
          // MUHIM: `tel:` path'da bo'shliq bo'lmasligi kerak — aks holda URI
          // buziladi va telefon ilovasi ochilmaydi.
          final Uri phoneUri = Uri(scheme: 'tel', path: "+998555120008");
          try {
            await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Terish ilovasi mavjud emas — jim o'tkazamiz.
          }
          break;
        case 2:
          final Uri uri = Uri.parse("https://t.me/My_Safar_call_center_bot");
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              debugPrint('Brauzerni ham ochib bo\'lmadi.');
            }
          }
          break;
        default:
      }
    }
  }

  static void showUnavailableService(BuildContext context) => showDialog(useRootNavigator: false, 
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black45,
      builder: (context) => Center(
              child: AlertDialog(
            backgroundColor: context.color.primaryContainer,
            title: Text("service_unavailable".tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Lottie.asset(
                    Assets.homeDevProcessAnim,
                    height: 160,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                Text("service_soon_available".tr(),
                    style: context.textTheme.displayMedium),
              ],
            ),
            // actions: [
            //   TextButton(
            //       onPressed: () => Navigator.pop(context),
            //       child:
            //           Text("ok".tr(), style: context.textTheme.displayMedium))
            // ],
          )));

  static void showLogoutDialog(BuildContext context) => showAdaptiveDialog(useRootNavigator: false, 
      context: context,
      builder: (context) => AlertDialog.adaptive(
              backgroundColor: context.color.primaryContainer,
              title:
                  Text("logout".tr(), style: context.theme.textTheme.bodyLarge),
              content: Text("logout_des".tr(),
                  style: context.theme.textTheme.bodyMedium),
              actions: [
                TextButton(
                    onPressed: () async {
                      final box = sdkStorage();
                      final isFirstTime = box.read('isFirstTime');
                      final lang = box.read('lang');

                      await box.erase();
                      // Custom TokenStore ishlatilgan bo'lsa ham tokenlar
                      // aniq tozalanishi uchun (box.erase faqat GetStorage'ni
                      // o'chiradi).
                      await MySafarSdk.tokens.clear();
                      // Hive keshlari (profil + biletlar) — oldingi
                      // foydalanuvchi ma'lumoti qolib ketmasligi uchun tozalaymiz.
                      await ProfileCache().clear();
                      await TicketsCache().clear();
                      // Analytics profil ID'sini tozalaymiz — keyingi
                      // foydalanuvchi eski profil bilan aralashmasligi uchun.
                      AnalyticsService().clearUser();

                      if (isFirstTime != null) {
                        await box.write('isFirstTime', isFirstTime);
                      }
                      if (lang != null) {
                        await box.write('lang', lang);
                      }

                      MySafarSdk.callbacks.onLoggedOut?.call();
                      // ignore: use_build_context_synchronously
                      Navigator.pushNamedAndRemoveUntil(context,
                          BottomNavBarPage.routeName, (route) => false,
                          arguments: 0);
                    },
                    child: Text("yes".tr(),
                        style: context.theme.textTheme.bodyMedium)),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("no".tr(),
                        style: context.theme.textTheme.bodyMedium))
              ]));

  static void showDeleteAccountDialog(BuildContext context) =>
      showAdaptiveDialog(useRootNavigator: false, 
          context: context,
          builder: (context) => AlertDialog(
                  backgroundColor: context.color.primaryContainer,
                  title: Text("delete_account_title".tr(),
                      style: context.theme.textTheme.bodyLarge),
                  content: Text("delete_account_subtitle".tr(),
                      style: context.theme.textTheme.bodyMedium),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          final box = sdkStorage();
                          final isFirstTime = box.read('isFirstTime');
                          final lang = box.read('lang');

                          await box.erase();
                          await MySafarSdk.tokens.clear();
                          await ProfileCache().clear();
                          await TicketsCache().clear();
                          AnalyticsService().clearUser();

                          if (isFirstTime != null) {
                            await box.write('isFirstTime', isFirstTime);
                          }
                          if (lang != null) {
                            await box.write('lang', lang);
                          }

                              MySafarSdk.callbacks.onLoggedOut?.call();
                          // ignore: use_build_context_synchronously
                          Navigator.pushNamedAndRemoveUntil(context,
                              BottomNavBarPage.routeName, (route) => false,
                              arguments: 0);
                        },
                        child: Text("yes".tr(),
                            style: context.theme.textTheme.bodyMedium)),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("no".tr(),
                            style: context.theme.textTheme.bodyMedium))
                  ]));

  static Future<DateTime?> showAdaptiveDateTimePicker(BuildContext context,
      {DateTime? initialDate}) async {
    DateTime tempDate = initialDate ?? DateTime(2003);

    if (Platform.isIOS) {
      return await showCupertinoDialog<DateTime>(useRootNavigator: false, 
        context: context,
        barrierDismissible: true,
        builder: (context) {
          _dialogContext = context;
          return CupertinoAlertDialog(
            title: Text(
              'choice_date'.tr(),
              style: context.theme.textTheme.bodyLarge,
            ),
            content: SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: DateTime(1950),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) => tempDate = newDate,
              ),
            ),
            actions: [
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr(),
                  style: context.theme.textTheme.bodyMedium,
                ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.pop(context, tempDate),
                child: Text(
                  'choice'.tr(),
                  style: context.theme.textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ).whenComplete(_afterComplete);
    } else {
      return await showDatePicker(
        context: context,
        initialDate: tempDate,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: context.theme.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
    }
  }

  static void showLanguageMenu(BuildContext context) {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        backgroundColor: context.color.primaryContainer,
        context: context,
        builder: (context) => LangOptionsWidget());
  }

  static void showThemeMenu(BuildContext context) {
    showModalBottomSheet(
        useSafeArea: Platform.isAndroid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        backgroundColor: context.color.primaryContainer,
        context: context,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return ThemeOptionsWidget();
        }).whenComplete(_afterComplete);
  }

  static void showCurrencyMenu(BuildContext context) {
    showModalBottomSheet(
        useSafeArea: Platform.isAndroid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        backgroundColor: context.color.primaryContainer,
        context: context,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return CurrencyOptionsWidget();
        }).whenComplete(_afterComplete);
  }

  static void changeAmountPrice(
      BuildContext context, double oldCurrency, double newCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Warning icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          "ticket_price_changed_title".tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "ticket_price_changed_message".tr(namedArgs: {
                            "old_price":
                                ElementFormatter.formatAmount(oldCurrency),
                            "new_price":
                                ElementFormatter.formatAmount(newCurrency),
                          }),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        BottomNavBarPage.routeName,
                                        (route) => false,
                                        arguments: 0),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  "cancel".tr(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ProjectTheme.brandColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  "continue".tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ))),
        );
      },
    );
  }

  /// Bilet narxi oshganda ko'rsatiladigan tasdiqlash dialogi.
  ///
  /// Eski va yangi narxni (valyuta belgisi bilan) ko'rsatadi va
  /// foydalanuvchi "davom etish" tugmasini bossa `true`, aks holda
  /// (bekor qilsa yoki yopsa) `false` qaytaradi.
  static Future<bool> showPriceIncreasedConfirm(
    BuildContext context, {
    required double oldPrice,
    required double newPrice,
    required String currencyLabel,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.color.primaryContainer,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "ticket_price_changed_title".tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ticket_price_changed_message_currency".tr(namedArgs: {
                        "old_price":
                            "${ElementFormatter.formatAmount(oldPrice)} $currencyLabel",
                        "new_price":
                            "${ElementFormatter.formatAmount(newPrice)} $currencyLabel",
                      }),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.color.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "cancel".tr(),
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ProjectTheme.brandColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "continue".tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Qidiruv natijalari eskirgani (masalan, 5 daqiqa o'tgani) haqida ogohlantirib,
  /// foydalanuvchini qaytadan qidirishga undaydigan dialog.
  ///
  /// Faqat "qayta qidirish" tugmasi bor; tashqarini bossa yopilmaydi. Tugma
  /// bosilganda yopiladi va `true` qaytaradi.
  static Future<bool> showPricesOutdatedDialog(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.color.primaryContainer,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "prices_outdated_title".tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "prices_outdated_message".tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProjectTheme.brandColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "search_again".tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  static void showCustomBottomSheet(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'packages/mysafar_sdk/assets/img/profile/wallet_congrats.json',
                    repeat: false,
                    fit: BoxFit.contain,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Operatsiya muvaffaqiyatli",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xff27AE60),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "O’zgartirishlar ma’lumotlar omborida muvaffaqiyatli saqlandi.",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        Navigator.pop(context, true);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProjectTheme.brandColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "understood".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showDeleteDialog(BuildContext context) {
    showDialog(useRootNavigator: false, 
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.color.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              "O'chirilmoqda...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Lottie.asset(
              'packages/mysafar_sdk/assets/img/profile/utyan_cache.json',
              repeat: true,
              fit: BoxFit.contain,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.hourglass_empty,
                size: 100,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static void showDeleteConfirmationSheet(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    showModalBottomSheet(
      backgroundColor: context.color.primaryContainer,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Ma'lumotlarni o'chirmoqchimisiz?",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Haqiqatan ham ma'lumotlaringizni o'chirmoqchimisiz? Ma'lumotlaringiz butunlay o'chirib tashlanadi.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProjectTheme.brandColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Yo‘q, bekor qilish",
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onPressed();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Ha, o‘chirish",
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static void showAiSearchLoader(BuildContext context) {
    showDialog(useRootNavigator: false, 
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(50),
      builder: (BuildContext context) {
        _dialogContext = context;
        return Center(
          child: Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Lottie.asset(
              Assets.homeAiStarsSearch,
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    ).whenComplete(
      _afterComplete,
    );
  }

  static void showCustomToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 120,
          left: 24,
          right: 24,
          child: _AnimatedToastWidget(
            message: message,
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  static void dismissCurrentDialog<T>({T? result}) {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop(result);
      _dialogContext = null;
    }
  }

  static void showUpdateRequiredDialog(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        _dialogContext = context;
        return SafeArea(
          bottom: Platform.isAndroid,
          top: Platform.isAndroid,
          child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.color.primaryContainer),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: context.height * 0.2,
                            child: Lottie.asset(
                                Assets.animUpdateAnimation,
                                repeat: false),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              "update_required_title".tr(),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                          context.szBoxHeight16,
                          ElevatedButton(
                              style: ProjectTheme.blueButtonStyle,
                              onPressed: () async {
                                final url = Platform.isAndroid
                                    ? EndPoints.playStoreUrl
                                    : EndPoints.appStoreUrl;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  // Optionally show an error dialog/snackbar
                                  debugPrint('Could not launch store URL');
                                }
                              },
                              child: Text("update_button_title".tr())),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        );
      },
    ).whenComplete(_afterComplete);
  }

  static void showSuccessSheet(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required void Function()? onPressed}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 64),
          child: Container(
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    title,
                    style: context.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProjectTheme.brandColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onPressed,
                      child: Text(
                        "understand_close".tr(),
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showUpdateOptionalDialog(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isDismissible: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        _dialogContext = context;
        return SafeArea(
          bottom: Platform.isAndroid,
          top: Platform.isAndroid,
          child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.color.primaryContainer),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: context.height * 0.2,
                            child: Lottie.asset(
                                Assets.animUpdateAnimation,
                                repeat: false),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              "update_optional_title".tr(),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                          context.szBoxHeight16,
                          ElevatedButton(
                              style: ProjectTheme.blueButtonStyle,
                              onPressed: () async {
                                final url = Platform.isAndroid
                                    ? EndPoints.playStoreUrl
                                    : EndPoints.appStoreUrl;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  // Optionally show an error dialog/snackbar
                                  debugPrint('Could not launch store URL');
                                }
                              },
                              child: Text("update_button_title".tr())),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        );
      },
    ).whenComplete(_afterComplete);
  }

  static void showLoader(BuildContext context) {
    showDialog(useRootNavigator: false, 
        context: context,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return Center(
            child: SizedBox(
                width: 64,
                height: 64,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: context.color.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                    child: const CircularProgressIndicator.adaptive())),
          );
        }).whenComplete(_afterComplete);
  }

  static Future<void> _afterComplete() async {
    _dialogContext = null;
  }
}

class _AnimatedToastWidget extends StatefulWidget {
  final String message;

  const _AnimatedToastWidget({required this.message});

  @override
  State<_AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<_AnimatedToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
              )
            ],
          ),
          child: Text(
            widget.message,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
