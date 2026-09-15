import 'dart:async';
import 'dart:io' show Platform;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoAlertDialog,
        CupertinoButton,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData,
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
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/core/widgets/search_city_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/theme_options_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/ticket_tariffs_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/verify_otp_widget.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/view/auth/pages/auth_page.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart'
    show TicketInfoPage;
import 'package:syncfusion_flutter_datepicker/datepicker.dart'
    show PickerDateRange;
import 'package:url_launcher/url_launcher.dart'
    show LaunchMode, canLaunchUrl, launchUrl;

import 'formatters.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show ErrorType;

/// Xato dialogida foydalanuvchi tanlagan amal.
enum ErrorDialogAction {
  retry,
  close,
}

/// Xatoning foydalanuvchiga ko'rsatiladigan turi — sarlavha va izoh shunga
/// qarab tanlanadi. [ErrorType] (dio/HTTP kodlari) shu guruhlarga jamlanadi.
enum ErrorDialogKind {
  network,
  server,
  generic;

  static ErrorDialogKind fromErrorType(ErrorType? type) {
    switch (type) {
      case ErrorType.connectTimeout:
      case ErrorType.receiveTimeout:
      case ErrorType.sendTimeout:
      case ErrorType.connectionError:
      case ErrorType.dio_error:
        return ErrorDialogKind.network;
      case ErrorType.internalServer_500:
      case ErrorType.badGateway_502:
      case ErrorType.serviceUnavailable_503:
      case ErrorType.gatewayTimeout_504:
      // Ro'yxatda yo'q 5xx (505, Cloudflare 520–527) ham server xatosi.
      case ErrorType.serverError_5xx:
        return ErrorDialogKind.server;
      default:
        return ErrorDialogKind.generic;
    }
  }

  String get title => switch (this) {
        ErrorDialogKind.network => "connection_error_title".tr(),
        ErrorDialogKind.server => "server_error_title".tr(),
        ErrorDialogKind.generic => "error_generic_title".tr(),
      };

  String get fallbackMessage => switch (this) {
        ErrorDialogKind.network => "connection_error_message".tr(),
        ErrorDialogKind.server => "server_error_message".tr(),
        ErrorDialogKind.generic => "error_generic_message".tr(),
      };

  String get icon => switch (this) {
        ErrorDialogKind.network => Assets.iconsDialogNetworkIcon,
        ErrorDialogKind.server => Assets.iconsDialogServerIcon,
        ErrorDialogKind.generic => Assets.iconsDialogErrorIcon,
      };

  SdkDialogTone get tone => switch (this) {
        ErrorDialogKind.network => SdkDialogTone.warning,
        ErrorDialogKind.server ||
        ErrorDialogKind.generic =>
          SdkDialogTone.error,
      };
}

class ProjectDialogs {
  static BuildContext? _dialogContext;

  /// type is for DateRangePickerSelectionMode
  static Future<PickerDateRange?> showCalendartPicker(
      BuildContext context,
      int type,
      PickerDateRange? selectedDates,
      final AirPortsModel? fromDir,
      final AirPortsModel? toDir) {
    return showSdkFullHeightSheet<PickerDateRange?>(
      context: context,
      builder: (context, controller) => DateCalendarWidget(
        type: type,
        params: selectedDates,
        fromDir: fromDir,
        toDir: toDir,
        scrollController: controller,
      ),
    );
  }

  static Future<Map<String, dynamic>?> showPassengerCountPicker(
      BuildContext context, Map<String, dynamic>? params) {
    return showSdkFullHeightSheet<Map<String, dynamic>?>(
      context: context,
      builder: (context, controller) => PassengerCountWidget(
        params: params ?? {},
        scrollController: controller,
      ),
    );
  }

  /// directionType for Direction title
  ///
  /// 0 - from direction ; 1 - to direction
  static Future<AirPortsModel?> showCitySearchPicker(
      BuildContext context, int directionType) {
    return showSdkFullHeightSheet<AirPortsModel?>(
      context: context,
      builder: (context, controller) => SearchCityWidget(
        directionType: directionType,
        scrollController: controller,
      ),
    );
  }

  static Future showLowcostSheet(
      BuildContext context, FlightElement flightElement) async {
    final parentContext = context;
    showSdkSheetAlert<void>(
      context: context,
      icon: Assets.iconsDialogPlaneIcon,
      tone: SdkDialogTone.warning,
      title: "about_lowcost".tr(),
      showCloseButton: true,
      content: Builder(
        builder: (context) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sdkDialogMutedFill(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "low_cost_airline_info".tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        SdkDialogAction(
          label: "continue_ticket".tr(),
          onTap: (sheetContext) {
            Navigator.of(sheetContext).pop();
            TicketInfoPage.show(parentContext, flightElement);
          },
        ),
        SdkDialogAction(
          label: "done".tr(),
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
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
                context: dialogContext,
                removeTop: true,
                child: VerifyOtpWidget(phone: phone, otpToken: otpToken));
          });
    }
    return await showSdkModalBottomSheet(
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
                context: dialogContext,
                removeTop: true,
                removeBottom: true,
                child: AuthPage(onAuthSuccess: onAuthSuccess));
          });
    }
    return await showSdkModalBottomSheet(
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

    // Material sheet — jonli Theme.of(parent); CupertinoSheet Theme wrap
    // qilmasa light'da fon chalkashardi.
    return await showSdkModalBottomSheet<FlightElement?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TariffPickerWidget(
        tariffs: tariffs,
        id: tid,
      ),
    );
  }

  /// dialog that shows Support Menu
  ///
  /// 0 -> call
  ///
  /// 1 - chat
  ///
  /// 2 - via tg
  static Future<void> showSupportMenu(BuildContext context) async {
    final telegramUrl = MySafarSdk.config.supportTelegramUrl;
    final telegramHandle = Uri.tryParse(telegramUrl)?.pathSegments.firstOrNull;
    final action = await showSdkModalBottomSheet<int?>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) {
          return SdkSheetFrame(
            showCloseButton: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SdkDialogBadge(
                  icon: Assets.iconsDialogSupportIcon,
                  color: SdkDialogTone.info.color(context),
                ),
                const SizedBox(height: 18),
                Text(
                  "support_badge_title".tr(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "support_subtitle".tr(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                _SupportOptionTile(
                  icon: Assets.iconsDialogPhoneIcon,
                  color: ProjectTheme.success,
                  title: "support_via_phone".tr(),
                  subtitle: MySafarSdk.config.supportPhone,
                  onTap: () => Navigator.of(context).pop(0),
                ),
                const SizedBox(height: 10),
                _SupportOptionTile(
                  icon: Assets.iconsTelegramIcon,
                  color: const Color(0xFF229ED9),
                  title: "support_via_tg".tr(),
                  subtitle: telegramHandle == null || telegramHandle.isEmpty
                      ? null
                      : "@$telegramHandle",
                  onTap: () => Navigator.of(context).pop(2),
                ),
              ],
            ),
          );
        });
    if (action != null) {
      switch (action) {
        case 0:
          // MUHIM: `tel:` path'da bo'shliq bo'lmasligi kerak — aks holda URI
          // buziladi va telefon ilovasi ochilmaydi.
          final phone = MySafarSdk.config.supportPhone.replaceAll(' ', '');
          final Uri phoneUri = Uri(scheme: 'tel', path: phone);
          try {
            await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // Terish ilovasi mavjud emas — jim o'tkazamiz.
          }
          break;
        case 2:
          final Uri uri = Uri.parse(MySafarSdk.config.supportTelegramUrl);
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

  static void showUnavailableService(BuildContext context) =>
      showSdkAlert<void>(
        context: context,
        icon: Assets.iconsDialogHourglassIcon,
        title: "service_unavailable".tr(),
        message: "service_soon_available".tr(),
        actions: [SdkDialogAction(label: "understood".tr())],
      );

  static void showLogoutDialog(BuildContext context) => showSdkAlert<void>(
        context: context,
        icon: Assets.iconsDialogLogoutIcon,
        tone: SdkDialogTone.error,
        title: "logout".tr(),
        message: "logout_des".tr(),
        actions: [
          SdkDialogAction(
            label: "logout".tr(),
            variant: SdkDialogButtonVariant.danger,
            onTap: (dialogContext) async {
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
              if (!dialogContext.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  dialogContext, BottomNavBarPage.routeName, (route) => false,
                  arguments: 0);
            },
          ),
          SdkDialogAction(
            label: "cancel".tr(),
            variant: SdkDialogButtonVariant.secondary,
          ),
        ],
      );

  static void showDeleteAccountDialog(BuildContext context) =>
      showSdkAlert<void>(
        context: context,
        icon: Assets.iconsDialogDeleteIcon,
        tone: SdkDialogTone.error,
        title: "delete_account_title".tr(),
        message: "delete_account_subtitle".tr(),
        actions: [
          SdkDialogAction(
            label: "yes_delete".tr(),
            variant: SdkDialogButtonVariant.danger,
            onTap: (dialogContext) async {
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
              if (!dialogContext.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  dialogContext, BottomNavBarPage.routeName, (route) => false,
                  arguments: 0);
            },
          ),
          SdkDialogAction(
            label: "no_cancel".tr(),
            variant: SdkDialogButtonVariant.secondary,
          ),
        ],
      );

  static Future<DateTime?> showAdaptiveDateTimePicker(BuildContext context,
      {DateTime? initialDate}) async {
    DateTime tempDate = initialDate ?? DateTime(2003);

    if (Platform.isIOS) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return await showCupertinoDialog<DateTime>(
        useRootNavigator: false,
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return Theme(
            data: theme,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: theme.brightness,
                primaryColor: ProjectTheme.brandColor,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 20,
                    color: isDark
                        ? ProjectTheme.textColorDark
                        : ProjectTheme.textColorLight,
                  ),
                ),
              ),
              child: CupertinoAlertDialog(
                title: Text(
                  'choice_date'.tr(),
                  style: theme.textTheme.bodyLarge,
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
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'cancel'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(dialogContext, tempDate),
                    child: Text(
                      'choice'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).whenComplete(_afterComplete);
    } else {
      final theme = Theme.of(context);
      return await showDatePicker(
        context: context,
        initialDate: tempDate,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        builder: (ctx, child) {
          return Theme(
            data: theme.copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: ProjectTheme.brandColor,
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
    showSdkModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        context: context,
        builder: (context) => LangOptionsWidget());
  }

  static void showThemeMenu(BuildContext context) {
    showSdkModalBottomSheet(
        useSafeArea: Platform.isAndroid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        context: context,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return ThemeOptionsWidget();
        }).whenComplete(_afterComplete);
  }

  static void showCurrencyMenu(BuildContext context) {
    showSdkModalBottomSheet(
        useSafeArea: Platform.isAndroid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        context: context,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return CurrencyOptionsWidget();
        }).whenComplete(_afterComplete);
  }

  static void changeAmountPrice(
      BuildContext context, double oldCurrency, double newCurrency) {
    showSdkSheetAlert<void>(
      context: context,
      icon: Assets.iconsDialogPriceIcon,
      tone: SdkDialogTone.warning,
      enableDrag: false,
      title: "ticket_price_changed_title".tr(),
      message: "ticket_price_changed_message".tr(namedArgs: {
        "old_price": ElementFormatter.formatAmount(oldCurrency),
        "new_price": ElementFormatter.formatAmount(newCurrency),
      }),
      actions: [
        SdkDialogAction(label: "continue".tr()),
        SdkDialogAction(
          label: "cancel".tr(),
          variant: SdkDialogButtonVariant.secondary,
          onTap: (sheetContext) => Navigator.pushNamedAndRemoveUntil(
              sheetContext, BottomNavBarPage.routeName, (route) => false,
              arguments: 0),
        ),
      ],
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
    final result = await showSdkSheetAlert<bool>(
      context: context,
      icon: Assets.iconsDialogPriceIcon,
      tone: SdkDialogTone.warning,
      isDismissible: false,
      enableDrag: false,
      title: "ticket_price_changed_title".tr(),
      message: "ticket_price_changed_message_currency".tr(namedArgs: {
        "old_price":
            "${ElementFormatter.formatAmount(oldPrice)} $currencyLabel",
        "new_price":
            "${ElementFormatter.formatAmount(newPrice)} $currencyLabel",
      }),
      actions: [
        SdkDialogAction(label: "continue".tr(), value: true),
        SdkDialogAction(
          label: "cancel".tr(),
          value: false,
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
    return result ?? false;
  }

  /// API'dan kelgan xatolarni ko'rsatadi — tarmoq, timeout, 4xx, 5xx va h.k.
  static Future<ErrorDialogAction> showApiErrorDialog(
    BuildContext context, {
    String? message,
    ErrorType? errorType,
    ErrorDialogKind? kind,
    bool showRetry = true,
    String? secondaryLabel,
  }) async {
    final ErrorDialogKind errorKind =
        kind ?? ErrorDialogKind.fromErrorType(errorType);
    final String title = errorKind.title;
    final String rawMessage = message?.trim() ?? '';
    final String body = (rawMessage.isEmpty || rawMessage == title)
        ? errorKind.fallbackMessage
        : rawMessage;
    HapticFeedback.mediumImpact();
    final result = await showSdkAlert<ErrorDialogAction>(
      context: context,
      icon: errorKind.icon,
      tone: errorKind.tone,
      barrierDismissible: false,
      canPop: false,
      title: title,
      message: body,
      actions: [
        if (showRetry)
          SdkDialogAction(
            label: "retry_search".tr(),
            value: ErrorDialogAction.retry,
          ),
        SdkDialogAction(
          label: secondaryLabel ?? "close".tr(),
          value: ErrorDialogAction.close,
          variant: showRetry
              ? SdkDialogButtonVariant.secondary
              : SdkDialogButtonVariant.primary,
        ),
      ],
    );
    return result ?? ErrorDialogAction.close;
  }

  /// Qidiruv natijalari eskirgani (masalan, 5 daqiqa o'tgani) haqida ogohlantirib,
  /// foydalanuvchini qaytadan qidirishga undaydigan dialog.
  ///
  /// Faqat "qayta qidirish" tugmasi bor; tashqarini bossa yopilmaydi. Tugma
  /// bosilganda yopiladi va `true` qaytaradi.
  static Future<bool> showPricesOutdatedDialog(BuildContext context) async {
    final result = await showSdkSheetAlert<bool>(
      context: context,
      icon: Assets.iconsDialogClockIcon,
      tone: SdkDialogTone.warning,
      isDismissible: false,
      enableDrag: false,
      title: "prices_outdated_title".tr(),
      message: "prices_outdated_message".tr(),
      actions: [SdkDialogAction(label: "search_again".tr(), value: true)],
    );
    return result ?? false;
  }

  static void showCustomBottomSheet(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    HapticFeedback.lightImpact();
    showSdkSheetAlert<void>(
      context: context,
      tone: SdkDialogTone.success,
      isDismissible: false,
      enableDrag: false,
      title: "operation_success_title".tr(),
      message: "changes_saved_desc".tr(),
      actions: [
        SdkDialogAction(
          label: "understood".tr(),
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            Navigator.pop(context, true);
            onConfirm();
          },
        ),
      ],
    );
  }

  static void showDeleteDialog(BuildContext context) {
    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: dialogContext.isDarkMode
                ? ProjectTheme.cardColorDark
                : ProjectTheme.cardColorLight,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'packages/mysafar_sdk/assets/img/profile/utyan_cache.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    width: 96,
                    height: 96,
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      width: 96,
                      height: 96,
                      child: Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor:
                              AlwaysStoppedAnimation(ProjectTheme.brandColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "deleting_data".tr(),
                    textAlign: TextAlign.center,
                    style: dialogContext.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void showDeleteConfirmationSheet(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    showSdkSheetAlert<void>(
      context: context,
      icon: Assets.iconsDialogDeleteIcon,
      tone: SdkDialogTone.error,
      title: "delete_info".tr(),
      message: "delete_data_desc".tr(),
      actions: [
        SdkDialogAction(
          label: "yes_delete".tr(),
          variant: SdkDialogButtonVariant.danger,
          onTap: (sheetContext) {
            Navigator.pop(sheetContext);
            onPressed();
          },
        ),
        SdkDialogAction(
          label: "no_cancel".tr(),
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
  }

  static void showAiSearchLoader(BuildContext context) {
    showDialog(
      useRootNavigator: false,
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

  /// Legacy wrapper — iOS-style top banner ([showAppMessage]).
  static void showCustomToast(
    BuildContext context,
    String message, {
    AppMessageType type = AppMessageType.success,
  }) {
    showAppMessage(message, type: type, context: context);
  }

  static void dismissCurrentDialog<T>({T? result}) {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop(result);
      _dialogContext = null;
    }
  }

  static void showUpdateRequiredDialog(BuildContext context) {
    showSdkSheetAlert<void>(
      context: context,
      icon: Assets.iconsDialogUpdateIcon,
      isDismissible: false,
      enableDrag: false,
      message: "update_required_title".tr(),
      onBuild: (sheetContext) => _dialogContext = sheetContext,
      actions: [
        SdkDialogAction(
          label: "update_button_title".tr(),
          onTap: (_) => _openStore(),
        ),
      ],
    ).whenComplete(_afterComplete);
  }

  static void showSuccessSheet(
      {required BuildContext context,
      required String title,
      required String subtitle,
      required void Function()? onPressed}) {
    showSdkSheetAlert<void>(
      context: context,
      tone: SdkDialogTone.success,
      title: title,
      message: subtitle,
      actions: [
        SdkDialogAction(
          label: "understand_close".tr(),
          onTap: (_) => onPressed?.call(),
        ),
      ],
    );
  }

  static void showUpdateOptionalDialog(BuildContext context) {
    showSdkSheetAlert<void>(
      context: context,
      icon: Assets.iconsDialogUpdateIcon,
      enableDrag: false,
      message: "update_optional_title".tr(),
      onBuild: (sheetContext) => _dialogContext = sheetContext,
      actions: [
        SdkDialogAction(
          label: "update_button_title".tr(),
          onTap: (_) => _openStore(),
        ),
        SdkDialogAction(
          label: "update_later".tr(),
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    ).whenComplete(_afterComplete);
  }

  static Future<void> _openStore() async {
    final url =
        Platform.isAndroid ? EndPoints.playStoreUrl : EndPoints.appStoreUrl;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch store URL');
    }
  }

  static void showLoader(BuildContext context) {
    showSdkLoader(context,
            onBuild: (dialogContext) => _dialogContext = dialogContext)
        .whenComplete(_afterComplete);
  }

  static Future<void> _afterComplete() async {
    _dialogContext = null;
  }
}

class _SupportOptionTile extends StatelessWidget {
  const _SupportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final String icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: sdkDialogMutedFill(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SvgPicture.asset(
                Assets.iconsBookingChevronRightIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  context.textTheme.headlineSmall?.color ?? Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
