import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

/// Bron sahifasidagi kontakt kartasi (email + telefon). Sarlavha kartadan
/// tashqarida — sahifa bo'lim sarlavhasi sifatida chizadi.
class ContactFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool showErrors;
  final List<String> emailSuggestions;
  final ValueChanged<String> onEmailChanged;
  final GlobalKey emailKey;
  final GlobalKey phoneKey;
  final FocusNode emailFocusNode;
  final FocusNode phoneFocusNode;
  final VoidCallback onNextField;

  /// Telefon o'zgarganda — faqat raqamlar (`998901234567`).
  final ValueChanged<String> onPhoneChanged;

  /// Joriy telefon (faqat raqamlar). Validatsiya UI'dagi formatlangan
  /// matndan mustaqil shu qiymat bo'yicha qilinadi.
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
    required this.phoneFocusNode,
    required this.onNextField,
    required this.onPhoneChanged,
    required this.rawPhoneDigits,
  });

  @override
  Widget build(BuildContext context) {
    return BookingCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingTextField(
            key: emailKey,
            label: "email".tr(),
            hintText: 'name@mail.com',
            controller: emailController,
            focusNode: emailFocusNode,
            showError: showErrors,
            keyboardType: TextInputType.emailAddress,
            onChanged: onEmailChanged,
            onSubmitted: onNextField,
            validator: (value) =>
                value.trim().isEmpty ? "enter_email_address".tr() : null,
            suggestions: emailSuggestions,
          ),
          const SizedBox(height: 16),
          // Telefon — UI: +998 90 123 45 67; state: 998901234567.
          BookingTextField(
            key: phoneKey,
            label: "phone".tr(),
            hintText: "+998 90 123 45 67",
            controller: phoneController,
            focusNode: phoneFocusNode,
            showError: showErrors,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: const [InternationalPhoneInputFormatter()],
            onChanged: (value) => onPhoneChanged(normalizePhoneDigits(value)),
            onSubmitted: onNextField,
            validator: (_) => rawPhoneDigits.length < kMinPhoneDigits
                ? "enter_full_phone_number".tr()
                : null,
          ),
          const SizedBox(height: 12),
          const _PhoneOwnerNotice(),
        ],
      ),
    );
  }
}

/// "Telefon raqami yo'lovchining o'ziga tegishli bo'lishi shart" — telefon
/// maydoni ostidagi ixcham izoh (katta ogohlantirish qutisi o'rniga).
class _PhoneOwnerNotice extends StatelessWidget {
  const _PhoneOwnerNotice();

  @override
  Widget build(BuildContext context) {
    final Color muted = BookingFormStyle.label(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SvgPicture.asset(
            Assets.iconsBookingInfoIcon,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "${"contact_phone_warning".tr()}. ${"contact_phone_warning_sub".tr()}.",
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }
}
