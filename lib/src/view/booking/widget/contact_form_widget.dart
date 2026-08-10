import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/view/booking/widget/custom_autocompleteInput_field.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

class ContactFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool showErrors;
  final List<String> emailSuggestions;
  final ValueChanged<String> onEmailChanged;
  final GlobalKey emailKey;
  final GlobalKey phoneKey;
  final FocusNode emailFocusNode;
  final VoidCallback onNextField;

  /// Host/profil telefoni (faqat raqamlar). Bo'sh bo'lsa validatsiya xato
  /// ko'rsatiladi — UI'dagi formatlangan matndan mustaqil.
  final String rawPhoneDigits;

  const ContactFormWidget({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.showErrors,
    required this.emailSuggestions,
    required this.onEmailChanged,
    required this.emailKey,
    required this.phoneKey,
    required this.emailFocusNode,
    required this.onNextField,
    required this.rawPhoneDigits,
  });

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "your_contacts".tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const _PhoneOwnerNotice(),
          const SizedBox(height: 14),
          CustomAutocompleteInputField(
            key: emailKey,
            showError: showErrors,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            label: "email".tr(),
            focusNode: emailFocusNode,
            onFieldSubmitted: (_) => onNextField(),
            onChanged: onEmailChanged,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return "enter_email_address".tr();
              }
              return null;
            },
            suggestions: emailSuggestions,
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            child: CustomInputField(
              key: phoneKey,
              showError: showErrors,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.none,
              controller: phoneController,
              label: "phone".tr(),
              readOnly: true,
              keyboardType: TextInputType.phone,
              validator: (_) {
                if (rawPhoneDigits.isEmpty) {
                  return "enter_full_phone_number".tr();
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Telefon raqami yo'lovchining o'ziga tegishli bo'lishi shart" ogohlantirishi.
class _PhoneOwnerNotice extends StatelessWidget {
  const _PhoneOwnerNotice();

  static const Color _amber = Color(0xFFF5A623);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF3D3018) : const Color(0xFFFFF8E6);
    final titleColor = isDark ? const Color(0xFFFFE082) : const Color(0xFF5C4200);
    final subColor =
        isDark ? const Color(0xFFE8C878) : ProjectTheme.secondaryTextLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _amber.withAlpha(isDark ? 70 : 45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: isDark ? const Color(0xFFFFCA28) : _amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "contact_phone_warning".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "contact_phone_warning_sub".tr(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
