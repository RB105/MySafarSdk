import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/api/user_data.dart' show MySafarUserIdentification;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;

/// Host myid malumotini korsatadi, tasdiqlasa true
Future<bool> showHostIdentificationConfirmSheet({
  required BuildContext context,
  required MySafarUserIdentification identification,
}) async {
  final result = await showSdkSheetAlert<bool>(
    context: context,
    icon: Assets.iconsScanIdCardIcon,
    title: 'data_confirmation'.tr(),
    content: _IdentificationPreview(identification: identification),
    actions: [
      SdkDialogAction(label: 'cancel'.tr(), value: false),
      SdkDialogAction(
        label: 'confirmation'.tr(),
        value: true,
        variant: SdkDialogButtonVariant.primary,
      ),
    ],
  );
  return result == true;
}

/// Host malumotini UsersModel ga otkazadi (forma shuni kutadi)
UsersModel usersModelFromHostIdentification(MySafarUserIdentification id) {
  final doc = (id.passSeries ?? '').trim().toUpperCase().replaceAll(' ', '');
  return UsersModel(
    firstname: id.firstName,
    lastname: id.lastName,
    middlename: id.middleName,
    birthdate: id.normalizedBirthDate,
    docexp: id.normalizedPassExpiry,
    docnum: doc.isEmpty ? null : doc,
    citizen: id.isResident == true ? 'UZ' : null,
    doctype: id.isResident == true ? 'A' : null,
  );
}

class _IdentificationPreview extends StatelessWidget {
  const _IdentificationPreview({required this.identification});

  final MySafarUserIdentification identification;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (_filled(identification.lastName))
        ('last_name'.tr(), identification.lastName!.trim()),
      if (_filled(identification.firstName))
        ('first_name'.tr(), identification.firstName!.trim()),
      if (_filled(identification.middleName))
        ('father'.tr(), identification.middleName!.trim()),
      if (_filled(identification.normalizedBirthDate))
        ('birth_date'.tr(), identification.normalizedBirthDate!),
      if (_filled(identification.displayPassSeries))
        ('document_number'.tr(), identification.displayPassSeries!),
      if (_filled(identification.normalizedPassExpiry))
        ('passport_validity'.tr(), identification.normalizedPassExpiry!),
      if (_filled(identification.displayPinfl))
        ('pinfl'.tr(), identification.displayPinfl!),
      if (_filled(identification.address))
        ('address'.tr(), identification.address!.trim()),
    ];

    if (rows.isEmpty) {
      return Text(
        'fill_passenger_data'.tr(),
        style: context.textTheme.bodyMedium?.copyWith(
          color: BookingFormStyle.label(context),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Row(label: rows[i].$1, value: rows[i].$2),
        ],
      ],
    );
  }

  static bool _filled(String? v) => v != null && v.trim().isNotEmpty;
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BookingFormStyle.label(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
