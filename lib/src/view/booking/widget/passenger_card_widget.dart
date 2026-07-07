import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_autocompleteInput_field.dart';
import 'package:mysafar_sdk/src/view/booking/widget/gender_button.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/view/booking/widget/save_passenger_information.dart';

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

  String get _passengerTitle {
    if (adultCount > index) {
      return "passenger_adult".tr(namedArgs: {
        "number": "${(adultCount == 1) ? '' : (index + 1)}",
      });
    } else if ((adultCount + childCount) > index && childCount != 0) {
      return "passenger_child".tr(namedArgs: {"number": "${index + 1}"});
    } else {
      return "passenger_infant".tr(namedArgs: {"number": "${index + 1}"});
    }
  }

  IconData get _passengerIcon {
    if (adultCount > index) {
      return Icons.person_rounded;
    } else if ((adultCount + childCount) > index && childCount != 0) {
      return Icons.child_care_rounded;
    } else {
      return Icons.child_friendly_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Saqlangan yo'lovchilardan tanlash
          if (cachedUsers.isNotEmpty) _buildSavedUsersButton(context),

          if (cachedUsers.isNotEmpty) const SizedBox(height: 12),

          // Asosiy karta
          _buildMainCard(context),
        ],
      ),
    );
  }

  Widget _buildSavedUsersButton(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: context.themeProvider.isDark
                  ? Colors.transparent
                  : const Color(0x80C6C7C9),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
          color: context.color.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: GestureDetector(
          onTap: () {
            showPassengerPickerBottomSheet(
              context: context,
              onSelected: onUserSelected,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Image.asset(
                  "assets/img/booking/saved.png",
                  color: context.themeProvider.isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "select_from_saved".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_sharp, size: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.themeProvider.isDark
                ? Colors.transparent
                : const Color(0x80C6C7C9),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
        color: context.color.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ProjectTheme.brandColor,
                        ProjectTheme.accentLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_passengerIcon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _passengerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16, width: double.infinity),

            // Fuqarolik
            _buildCitizenField(context),
            const SizedBox(height: 16),

            // Passport ma'lumotlari
            _buildDocnumField(context),
            const SizedBox(height: 16),

            // Passport amal qilish muddati
            _buildDocexpField(context),
            const SizedBox(height: 16),

            // Ism
            _buildFirstnameField(context),
            const SizedBox(height: 16),

            // Familiya
            _buildLastnameField(context),
            const SizedBox(height: 16),

            // Otasining ismi
            _buildMiddlenameField(context),
            const SizedBox(height: 16),

            // Tug'ilgan sana
            _buildBirthdateField(context),
            const SizedBox(height: 16),

            // Jins
            _buildGenderField(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCitizenField(BuildContext context) {
    final citizenName = passenger.citizen.isNotEmpty
        ? getCountry(passenger.citizen)["name"][dataLang()] ?? ''
        : '';

    return InkWell(
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
    );
  }

  Widget _buildDocnumField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: docnumKey,
      showError: showErrors,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      controller: controller.docnumController,
      label: "passport_data".tr(),
      onChanged: (value) => onFieldChanged('docnum', value),
      validator: (value) {
        if (passenger.docnum.isEmpty) {
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
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.number,
      controller: controller.docexpController,
      label: "passport_validity".tr(),
      hintText: "date_format".tr(),
      onChanged: (value) => onFieldChanged('docexp', value),
      validator: (value) {
        if (passenger.docexp.isEmpty) {
          return "passport_expiry_required".tr();
        }
        return null;
      },
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
      label: "first_name".tr(),
      validator: (value) {
        if (passenger.firstname.isEmpty) {
          return "name_not_entered".tr();
        }
        return null;
      },
      onChanged: (value) => onFieldChanged('firstname', value),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      suggestions: getSuggestions('firstname'),
    );
  }

  Widget _buildLastnameField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: lastnameKey,
      showError: showErrors,
      controller: controller.lastnameController,
      label: "last_name".tr(),
      validator: (value) {
        if (passenger.lastname.isEmpty) {
          return "surname_not_entered".tr();
        }
        return null;
      },
      onChanged: (value) => onFieldChanged('lastname', value),
      suggestions: getSuggestions('lastname'),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildMiddlenameField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: middlenameKey,
      showError: showErrors,
      controller: controller.middlenameController,
      label: "father".tr(),
      validator: (value) => null,
      onChanged: (value) => onFieldChanged('middlename', value),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      suggestions: getSuggestions('middlename'),
    );
  }

  Widget _buildBirthdateField(BuildContext context) {
    return CustomAutocompleteInputField(
      key: birthdateKey,
      inputFormatters: [birthdateFormatter],
      showError: showErrors,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.number,
      controller: controller.birthdateController,
      label: "birth_date".tr(),
      hintText: "date_format".tr(),
      onChanged: (value) => onFieldChanged('birthdate', value),
      validator: (value) {
        if (passenger.birthdate.isEmpty) {
          return "birthdate_required".tr();
        }
        return null;
      },
      suggestions: getSuggestions('birthdate'),
      suffix: IconButton(
        onPressed: onBirthdateCalendarTap,
        icon: const Icon(Icons.calendar_month),
      ),
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "gender".tr(),
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          key: genderKey,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.themeProvider.isDark
                ? const Color(0xff838383).withAlpha(85)
                : const Color(0xffC6C7C9).withAlpha(35),
          ),
          child: Row(
            children: [
              GenderButton(
                label: "male".tr(),
                value: PassengerConstants.genderMale,
                isSelected: passenger.gender == PassengerConstants.genderMale,
                onPressed: () => onFieldChanged('gender', PassengerConstants.genderMale),
              ),
              const SizedBox(width: 8),
              GenderButton(
                label: "female".tr(),
                value: PassengerConstants.genderFemale,
                isSelected: passenger.gender == PassengerConstants.genderFemale,
                onPressed: () => onFieldChanged('gender', PassengerConstants.genderFemale),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

