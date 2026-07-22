import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_autocompleteInput_field.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/view/booking/widget/save_passenger_information.dart';

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

/// Yo'lovchi kartasi widgeti
class PassengerCardWidget extends StatelessWidget {
  final int index;
  final int adultCount;
  final int childCount;
  final PassengerModel passenger;
  final PassengerController controller;
  final bool showErrors;
  final List<dynamic> cachedUsers;
  final List<String> Function(String key) getSuggestions;
  final Function(String field, String value) onFieldChanged;
  final Function(UsersModel) onUserSelected;
  final VoidCallback onCitizenTap;
  final VoidCallback onDocexpCalendarTap;
  final VoidCallback onBirthdateCalendarTap;
  final VoidCallback onNextField;
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
    required this.index,
    required this.adultCount,
    required this.childCount,
    required this.passenger,
    required this.controller,
    required this.showErrors,
    required this.cachedUsers,
    required this.getSuggestions,
    required this.onFieldChanged,
    required this.onUserSelected,
    required this.onCitizenTap,
    required this.onDocexpCalendarTap,
    required this.onBirthdateCalendarTap,
    required this.onNextField,
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

  /// "1-yo'lovchi" — maketdagi tartib raqamli sarlavha.
  String get _passengerTitle =>
      "passenger_number".tr(namedArgs: {"number": "${index + 1}"});

  /// Sarlavha ostidagi yosh chegarasi izohi.
  String get _passengerAgeNote {
    if (adultCount > index) return "above_12".tr();
    if ((adultCount + childCount) > index && childCount != 0) {
      return "between_2_12".tr();
    }
    return "under_2".tr();
  }

  @override
  Widget build(BuildContext context) {
    // Karta o'rami tashqarida (yo'lovchilar ro'yxati bitta kartaga
    // joylashtiradi) — bu widget faqat bitta yo'lovchi blokini chizadi.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _passengerTitle,
          style: context.textTheme.bodyLarge
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          _passengerAgeNote,
          style: context.textTheme.headlineSmall?.copyWith(fontSize: 13.5),
        ),
        const SizedBox(height: 14),
        if (cachedUsers.isNotEmpty) ...[
          _buildActionButtons(context),
          const SizedBox(height: 16),
        ],

        // Maketdagi tartib: familiya → ism → otasining ismi →
        // (tug'ilgan sana + jins) → fuqarolik → hujjat raqami → muddati.
        _buildLastnameField(context),
        const SizedBox(height: 16),
        _buildFirstnameField(context),
        const SizedBox(height: 16),
        _buildMiddlenameField(context),
        const SizedBox(height: 16),
        _buildBirthdateAndGenderRow(context),
        const SizedBox(height: 16),
        _buildCitizenField(context),
        const SizedBox(height: 16),
        _buildDocnumField(context),
        const SizedBox(height: 16),
        _buildDocexpField(context),
      ],
    );
  }

  /// "Yo'lovchi tanlash" — saqlangan yo'lovchilardan tanlash tugmasi.
  /// Saqlangan yo'lovchi bo'lmasa umuman ko'rsatilmaydi.
  Widget _buildActionButtons(BuildContext context) {
    return _ActionPill(
      icon: Icons.people_alt_outlined,
      label: "select_passenger_short".tr(),
      trailing: Icons.keyboard_arrow_down_rounded,
      onTap: () => showPassengerPickerBottomSheet(
        context: context,
        onSelected: onUserSelected,
      ),
    );
  }

  /// Tug'ilgan sana va jins bitta qatorda (maketdagidek).
  Widget _buildBirthdateAndGenderRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildBirthdateField(context)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _buildGenderField(context)),
        ],
      ),
    );
  }

  Widget _buildCitizenField(BuildContext context) {
    final citizenName = passenger.citizen.isNotEmpty
        ? getCountry(passenger.citizen)["name"][dataLang()] ?? ''
        : '';

    return Focus(
      focusNode: controller.citizenFocus,
      child: InkWell(
        key: citizenKey,
        onTap: onCitizenTap,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(width: 1.5, color: context.color.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    citizenName.isNotEmpty ? citizenName : "citizenship".tr(),
                    style: citizenName.isNotEmpty
                        ? context.textTheme.bodyMedium
                        : context.textTheme.headlineSmall?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                  ),
                  Flexible(
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                      color: context.color.outline,
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

  Widget _buildDocnumField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: docnumKey,
      showError: showErrors,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      controller: controller.docnumController,
      focusNode: controller.docnumFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "passport_data".tr(),
      onChanged: (value) => onFieldChanged('docnum', value),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return "passport_data_not_entered".tr();
        }
        return null;
      },
      suggestions: getSuggestions('docnum'),
    );
  }

  Widget _buildDocexpField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: docexpKey,
      showError: showErrors,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.number,
      controller: controller.docexpController,
      focusNode: controller.docexpFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "passport_validity".tr(),
      hintText: "date_format".tr(),
      onChanged: (value) => onFieldChanged('docexp', value),
      validator: (value) => _validateBookingDate(
        value,
        emptyMessage: 'passport_expiry_required'.tr(),
      ),
      suggestions: getSuggestions('docexp'),
      suffix: IconButton(
        onPressed: onDocexpCalendarTap,
        icon: const Icon(Icons.calendar_month),
      ),
      inputFormatters: [docexpFormatter],
    );
  }

  Widget _buildFirstnameField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: firstnameKey,
      showError: showErrors,
      controller: controller.firstnameController,
      focusNode: controller.firstnameFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "first_name".tr(),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return "name_not_entered".tr();
        }
        return null;
      },
      onChanged: (value) => onFieldChanged('firstname', value),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      inputFormatters: passengerNameInputFormatters,
      suggestions: getSuggestions('firstname'),
    );
  }

  Widget _buildLastnameField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: lastnameKey,
      showError: showErrors,
      controller: controller.lastnameController,
      focusNode: controller.lastnameFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "last_name".tr(),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return "surname_not_entered".tr();
        }
        return null;
      },
      onChanged: (value) => onFieldChanged('lastname', value),
      suggestions: getSuggestions('lastname'),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      inputFormatters: passengerNameInputFormatters,
    );
  }

  Widget _buildMiddlenameField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: middlenameKey,
      showError: showErrors,
      controller: controller.middlenameController,
      focusNode: controller.middlenameFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "father".tr(),
      validator: (value) => null,
      onChanged: (value) => onFieldChanged('middlename', value),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      inputFormatters: passengerNameInputFormatters,
      suggestions: getSuggestions('middlename'),
    );
  }

  Widget _buildBirthdateField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: birthdateKey,
      inputFormatters: [birthdateFormatter],
      showError: showErrors,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.number,
      controller: controller.birthdateController,
      focusNode: controller.birthdateFocus,
      onFieldSubmitted: (_) => onNextField(),
      label: "birth_date".tr(),
      hintText: "date_format".tr(),
      onChanged: (value) => onFieldChanged('birthdate', value),
      validator: (value) => _validateBookingDate(
        value,
        emptyMessage: 'birthdate_required'.tr(),
      ),
      suggestions: getSuggestions('birthdate'),
      suffix: IconButton(
        onPressed: onBirthdateCalendarTap,
        icon: const Icon(Icons.calendar_month),
      ),
    );
  }

  /// Jins — tug'ilgan sana yonidagi ikki bo'lakli tanlagich.
  ///
  /// Maketdagidek: butun blok atrofida och kulrang kontur, tanlangan bo'lak
  /// ustida esa ko'k kontur — tashqi tomoni yumaloq, ichki tomoni tekis
  /// (ya'ni ikkala bo'lak orasida to'g'ri vertikal chiziq hosil bo'ladi).
  Widget _buildGenderField(BuildContext context) {
    final bool isMale = passenger.gender == PassengerConstants.genderMale;
    const double radius = 16;

    return SizedBox(
      key: genderKey,
      height: 56,
      child: Stack(
        children: [
          // 1. Umumiy och kontur.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(width: 1.5, color: context.color.outline),
              ),
            ),
          ),
          // 2. Tanlangan yarmi ustidagi ko'k kontur.
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: isMale ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: isMale
                        ? const BorderRadius.horizontal(
                            left: Radius.circular(radius))
                        : const BorderRadius.horizontal(
                            right: Radius.circular(radius)),
                    border: Border.all(
                      width: 2,
                      color: ProjectTheme.brandColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 3. Yozuvlar va bosish sohalari.
          Row(
            children: [
              _GenderSegment(
                label: "male".tr(),
                selected: isMale,
                radius: const BorderRadius.horizontal(
                    left: Radius.circular(radius)),
                onTap: () =>
                    onFieldChanged('gender', PassengerConstants.genderMale),
              ),
              _GenderSegment(
                label: "female".tr(),
                selected: !isMale,
                radius: const BorderRadius.horizontal(
                    right: Radius.circular(radius)),
                onTap: () =>
                    onFieldChanged('gender', PassengerConstants.genderFemale),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ramkali kichik tugma: ikonka + yozuv (+ ixtiyoriy o'ng ikonka).
class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(width: 1.5, color: context.color.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: context.color.onSurface),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 2),
                  Icon(trailing, size: 20, color: context.color.outline),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Jins tanlagichning bitta bo'lagi — foni shaffof, chunki ramkalar Stack'da
/// alohida chiziladi. Bu yerda faqat yozuv va bosish sohasi.
class _GenderSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final BorderRadius radius;
  final VoidCallback onTap;

  const _GenderSegment({
    required this.label,
    required this.selected,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.themeProvider.isDark;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AnalyticsService()
                .trackButtonTap('gender_select', extra: {'value': label});
            onTap();
          },
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: "packages/mysafar_sdk/Gilroy",
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: selected
                    ? ProjectTheme.brandColor
                    : (isDark
                        ? ProjectTheme.secondaryTextDark
                        : ProjectTheme.secondaryTextLight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
