import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/save_passenger_information.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

/// Ism/familiya/otasini ismi maydonlarida raqam va bo'sh joy kiritilishini
/// bloklaydi (aviabilet hujjatidagi yozuvga mos).
final List<TextInputFormatter> passengerNameInputFormatters = [
  FilteringTextInputFormatter.deny(RegExp(r'[\d\s]')),
];

String? _validateBookingDate(String? value, {required String emptyMessage}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return emptyMessage;
  if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(trimmed)) {
    return 'invalid_date_format'.tr();
  }
  try {
    DateFormat('dd.MM.yyyy').parseStrict(trimmed);
  } catch (_) {
    return 'invalid_date_format'.tr();
  }
  return null;
}

String? _validateRequired(String value, String message) =>
    value.trim().isEmpty ? message : null;

/// Bitta yo'lovchi formasi: tezkor to'ldirish (skaner / saqlangan
/// yo'lovchi), "Shaxsiy ma'lumotlar" va "Hujjat" kartalari.
///
/// Maydonlar pasportdagi tartibda, yorliqlar doim tepada; xatolar faqat
/// "Davom etish" bosilgandan keyin ko'rsatiladi.
class PassengerCardWidget extends StatelessWidget {
  final PassengerModel passenger;
  final PassengerController controller;
  final bool showErrors;
  final List<dynamic> cachedUsers;
  final List<String> Function(String key) getSuggestions;
  final Function(String field, String value) onFieldChanged;
  final Function(UsersModel) onUserSelected;
  /// Host myid bersa "Ozimning malumotim" chiqadi
  final VoidCallback? onMyDataTap;
  final VoidCallback onCitizenTap;
  final VoidCallback onDocexpCalendarTap;
  final VoidCallback onBirthdateCalendarTap;
  final VoidCallback onNextField;
  final VoidCallback onScanTap;
  final MaskTextInputFormatter docexpFormatter;
  final MaskTextInputFormatter birthdateFormatter;

  // GlobalKeys
  final GlobalKey citizenKey;
  final GlobalKey docnumKey;
  final GlobalKey docexpKey;
  final GlobalKey firstnameKey;
  final GlobalKey lastnameKey;
  final GlobalKey middlenameKey;
  final GlobalKey birthdateKey;
  final GlobalKey genderKey;

  const PassengerCardWidget({
    super.key,
    required this.passenger,
    required this.controller,
    required this.showErrors,
    required this.cachedUsers,
    required this.getSuggestions,
    required this.onFieldChanged,
    required this.onUserSelected,
    this.onMyDataTap,
    required this.onCitizenTap,
    required this.onDocexpCalendarTap,
    required this.onBirthdateCalendarTap,
    required this.onNextField,
    required this.onScanTap,
    required this.docexpFormatter,
    required this.birthdateFormatter,
    required this.citizenKey,
    required this.docnumKey,
    required this.docexpKey,
    required this.firstnameKey,
    required this.lastnameKey,
    required this.middlenameKey,
    required this.birthdateKey,
    required this.genderKey,
  });

  static const double _fieldGap = 16;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuickFill(context),
        const SizedBox(height: 20),
        _SectionTitle("personal_info".tr()),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _nameField(
                key: lastnameKey,
                field: 'lastname',
                label: "last_name".tr(),
                textController: controller.lastnameController,
                focusNode: controller.lastnameFocus,
                error: "surname_not_entered".tr(),
              ),
              const SizedBox(height: _fieldGap),
              _nameField(
                key: firstnameKey,
                field: 'firstname',
                label: "first_name".tr(),
                textController: controller.firstnameController,
                focusNode: controller.firstnameFocus,
                error: "name_not_entered".tr(),
              ),
              const SizedBox(height: _fieldGap),
              _nameField(
                key: middlenameKey,
                field: 'middlename',
                label: "father".tr(),
                textController: controller.middlenameController,
                focusNode: controller.middlenameFocus,
                optional: true,
              ),
              const SizedBox(height: _fieldGap),
              _dateField(
                context,
                key: birthdateKey,
                field: 'birthdate',
                label: "birth_date".tr(),
                textController: controller.birthdateController,
                focusNode: controller.birthdateFocus,
                formatter: birthdateFormatter,
                emptyMessage: 'birthdate_required'.tr(),
                onCalendarTap: onBirthdateCalendarTap,
              ),
              const SizedBox(height: _fieldGap),
              BookingChoiceField<String>(
                key: genderKey,
                label: "gender".tr(),
                value: passenger.gender,
                options: [
                  (PassengerConstants.genderMale, "male".tr()),
                  (PassengerConstants.genderFemale, "female".tr()),
                ],
                onChanged: (value) {
                  AnalyticsService()
                      .trackButtonTap('gender_select', extra: {'value': value});
                  onFieldChanged('gender', value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle("passenger_document".tr()),
        BookingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCitizenField(context),
              const SizedBox(height: _fieldGap),
              BookingTextField(
                key: docnumKey,
                label: "document_number".tr(),
                hintText: 'AA1234567',
                controller: controller.docnumController,
                focusNode: controller.docnumFocus,
                showError: showErrors,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                validator: (v) =>
                    _validateRequired(v, "passport_data_not_entered".tr()),
                onChanged: (value) => onFieldChanged('docnum', value),
                onSubmitted: onNextField,
                suggestions: getSuggestions('docnum'),
              ),
              const SizedBox(height: _fieldGap),
              _dateField(
                context,
                key: docexpKey,
                field: 'docexp',
                label: "passport_validity".tr(),
                textController: controller.docexpController,
                focusNode: controller.docexpFocus,
                formatter: docexpFormatter,
                emptyMessage: 'passport_expiry_required'.tr(),
                onCalendarTap: onDocexpCalendarTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tezkor toldirish: skaner, myid (bolsa), saqlangan yolovchi
  Widget _buildQuickFill(BuildContext context) {
    final hasSavedPassengers = cachedUsers.isNotEmpty;
    final hasMyData = onMyDataTap != null;

    final scan = _QuickFillCard(
      iconAsset: Assets.iconsScanFrameIcon,
      title: "scan_short".tr(),
      subtitle: "quick_scan_subtitle".tr(),
      compact: hasSavedPassengers || hasMyData,
      onTap: onScanTap,
    );

    final myData = hasMyData
        ? _QuickFillCard(
            iconAsset: Assets.iconsScanIdCardIcon,
            title: "use_my_data_short".tr(),
            subtitle: "quick_my_data_subtitle".tr(),
            compact: true,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onMyDataTap!();
            },
          )
        : null;

    final saved = hasSavedPassengers
        ? _QuickFillCard(
            iconAsset: Assets.iconsScanSavedPassengersIcon,
            title: "select_passenger_short".tr(),
            subtitle: "quick_saved_subtitle".tr(),
            compact: true,
            onTap: () {
              // Sheet yopilganda klaviatura oxirgi maydonga qaytib
              // ochilmasin.
              FocusManager.instance.primaryFocus?.unfocus();
              showPassengerPickerBottomSheet(
                context: context,
                onSelected: onUserSelected,
              );
            },
          )
        : null;

    // Yolovchi tanlash oldida myid tugmasi
    final secondary = <Widget>[
      if (myData != null) myData,
      if (saved != null) saved,
    ];

    if (secondary.isEmpty) return scan;

    // bitta qoshimcha bolsa skaner yoniga
    if (secondary.length == 1) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: scan),
            const SizedBox(width: 10),
            Expanded(child: secondary.first),
          ],
        ),
      );
    }

    // skaner tepada, pastda myid + yolovchi tanlash
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scan,
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: secondary[0]),
              const SizedBox(width: 10),
              Expanded(child: secondary[1]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nameField({
    required GlobalKey key,
    required String field,
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    String? error,
    bool optional = false,
  }) {
    return BookingTextField(
      key: key,
      label: label,
      optional: optional,
      controller: textController,
      focusNode: focusNode,
      showError: showErrors,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: passengerNameInputFormatters,
      validator: error == null ? null : (v) => _validateRequired(v, error),
      onChanged: (value) => onFieldChanged(field, value),
      onSubmitted: onNextField,
      suggestions: getSuggestions(field),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required GlobalKey key,
    required String field,
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    required MaskTextInputFormatter formatter,
    required String emptyMessage,
    required VoidCallback onCalendarTap,
  }) {
    return BookingTextField(
      key: key,
      label: label,
      hintText: "date_format".tr(),
      controller: textController,
      focusNode: focusNode,
      showError: showErrors,
      keyboardType: TextInputType.number,
      inputFormatters: [formatter],
      validator: (v) => _validateBookingDate(v, emptyMessage: emptyMessage),
      onChanged: (value) => onFieldChanged(field, value),
      onSubmitted: onNextField,
      suggestions: getSuggestions(field),
      suffix: IconButton(
        onPressed: onCalendarTap,
        tooltip: label,
        icon: SvgPicture.asset(
          Assets.iconsFormCalendarIcon,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(
            BookingFormStyle.label(context),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildCitizenField(BuildContext context) {
    final String code = passenger.citizen;
    final String citizenName = code.isNotEmpty
        ? (getCountry(code)["name"][dataLang()] ?? '').toString()
        : '';

    return BookingPickerField(
      key: citizenKey,
      label: "citizenship".tr(),
      placeholder: "citizenship".tr(),
      value: citizenName,
      focusNode: controller.citizenFocus,
      chevronAsset: Assets.iconsFormChevronDownIcon,
      errorText:
          showErrors && code.isEmpty ? "citizenship_not_selected".tr() : null,
      leading: code.isEmpty ? null : BookingCountryFlag(code: code),
      onTap: onCitizenTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Tezkor to'ldirish kartasi. [compact] — ikki ustunda (ikonka tepada),
/// aks holda to'liq kenglikda qator (o'ngda strelka).
class _QuickFillCard extends StatelessWidget {
  const _QuickFillCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color accent = isDark ? Colors.white : brand;

    final Widget icon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SvgPicture.asset(
        iconAsset,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
      ),
    );

    final Widget texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: BookingFormStyle.label(context),
          ),
        ),
      ],
    );

    return Material(
      color: context.color.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [icon, const SizedBox(height: 12), texts],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: texts),
                    SvgPicture.asset(
                      Assets.iconsBookingChevronRightIcon,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        BookingFormStyle.hint(context),
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

/// Fuqarolik yonidagi kichik bayroq (asset bo'lmasa hech narsa chizmaydi).
class BookingCountryFlag extends StatelessWidget {
  const BookingCountryFlag({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        'packages/mysafar_sdk/assets/img/flags/${code.toLowerCase()}.png',
        width: 22,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
