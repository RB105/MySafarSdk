import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/county_pick/src/country_code_model.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_autocompleteInput_field.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_country_picker.dart';

class ContactFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool showErrors;
  final CountryCode? selectedCountry;
  final List<String> emailSuggestions;
  final List<String> phoneSuggestions;
  final MaskTextInputFormatter phoneFormatter;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onPhoneChanged;
  final ValueChanged<CountryCode> onCountrySelected;
  final GlobalKey emailKey;
  final GlobalKey phoneKey;

  const ContactFormWidget({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.showErrors,
    required this.selectedCountry,
    required this.emailSuggestions,
    required this.phoneSuggestions,
    required this.phoneFormatter,
    required this.onEmailChanged,
    required this.onPhoneChanged,
    required this.onCountrySelected,
    required this.emailKey,
    required this.phoneKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
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
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: const Icon(Icons.contacts_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "your_contacts".tr(),
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
            const SizedBox(height: 16),
            CustomAutocompleteInputField(
              key: emailKey,
              showError: showErrors,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.emailAddress,
              controller: emailController,
              label: "email".tr(),
              onChanged: onEmailChanged,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "enter_email_address".tr();
                }
                return null;
              },
              suggestions: emailSuggestions,
            ),
            const SizedBox(height: 16),

            CustomAutocompleteInputField(
              key: phoneKey,
              showError: showErrors,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              controller: phoneController,
              label: "phone".tr(),
              onChanged: (_) => onPhoneChanged(),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return "enter_full_phone_number".tr();
                }
                return null;
              },
              perfex: _buildCountryCodePrefix(context),
              suggestions: phoneSuggestions,
              inputFormatters: [phoneFormatter],
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryCodePrefix(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await Navigator.push<CountryCode>(
          context,
          MaterialPageRoute(builder: (context) => CountryListWidget()),
        );
        if (selected != null) {
          onCountrySelected(selected);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 15, left: 12),
        child: Text("+${selectedCountry?.dialCode ?? '998'}"),
      ),
    );
  }
}

