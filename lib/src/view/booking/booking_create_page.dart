// ignore_for_file: unused_local_variable

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/booking_create_loading_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_create_states.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';

import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/dashedline.dart';
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';

import '../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;

class BookingCreatePage extends StatefulWidget {
  final List<Map<String, dynamic>> passenger;
  final FlightPrice? price;
  final String trId;

  const BookingCreatePage({
    super.key,
    required this.passenger,
    required this.price,
    required this.trId,
  });

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  bool isChek = false;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingcreateCubit(),
      child: BlocConsumer<BookingcreateCubit, BookingcreateStates>(
          listener: (context, state) {
        if (state is BookingcreateLoadingState) {
          LoadingDialog.show(context);
        } else if (state is BookingcreateSuccessState) {
          LoadingDialog.dismiss(context);
          ProjectUtils.setCalendarEventByLastSearch();
          _handleBookingCreated(context, state.data);
        } else if (state is BookingcreateErrorState) {
          LoadingDialog.dismiss(context);
          ResponseState.errorState(state.error, context);
        }
      }, builder: (context, state) {
        return Scaffold(
            appBar: _modernAppBar(context, title: "data_confirmation".tr()),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _contactInfoCard(context),
                _buildSectionHeader(context, "passenger_data_title"),
                _passengersCard(context),
                const SizedBox(height: 12),
                _agreementRow(context),
                const SizedBox(height: 8),
              ],
            ),
            bottomNavigationBar: NextButtonWidget(
              nextTittle: "continue_purchase",
              analyticsId: 'booking_create_continue',
              isLoading: false,
              onPressed: isChek
                  ? () {
                      if (state is! BookingcreateLoadingState) {
                        context.read<BookingcreateCubit>().createBooking(
                            context: context,
                            email: widget.passenger[0]["email"],
                            tid: widget.trId,
                            firstName: "${widget.passenger[0]["firstname"]}",
                            passenger: widget.passenger,
                            phoneNumber: widget.passenger[0]["phone"]);
                      }
                    }
                  : null,
              showButton: true,
              passenger: widget.passenger.length,
              price: widget.price,
            ));
      }),
    );
  }

  Future<void> _handleBookingCreated(
      BuildContext context, BookingCreateModel data) async {
    final double? oldPrice = _oldPriceForCurrency(data.currency);
    final double? newPrice = _parseAmount(data.amount);


    final bool priceIncreased = oldPrice != null &&
        oldPrice > 0 &&
        newPrice != null &&
        newPrice > oldPrice;

    if (priceIncreased) {
      final bool confirmed = await ProjectDialogs.showPriceIncreasedConfirm(
        context,
        oldPrice: oldPrice,
        newPrice: newPrice,
        currencyLabel: _currencyLabel(data.currency),
      );
      if (!confirmed || !context.mounted) return;
    }

    _openPaymentPage(context, data);
  }

  void _openPaymentPage(BuildContext context, BookingCreateModel data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmPage(
          passengerNumber: widget.passenger.length,
          bookingCreateModel: data,
          price: widget.price,
        ),
      ),
    );
  }

  double? _oldPriceForCurrency(int? currencyCode) {
    final price = widget.price;
    if (price == null) return null;
    final String? raw = switch (currencyCode) {
      643 => price.rub?.amount,
      840 => price.usd?.amount,
      _ => price.uzs?.amount,
    };
    return _parseAmount(raw);
  }

  String _currencyLabel(int? code) => switch (code) {
        643 => 'RUB',
        840 => 'USD',
        _ => 'UZS',
      };

  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final str = value.toString().trim().replaceAll(' ', '');
    return double.tryParse(str) ?? double.tryParse(str.replaceAll(',', ''));
  }

  PreferredSizeWidget _modernAppBar(BuildContext context,
      {required String title, VoidCallback? onBack}) {
    final isDark = context.themeProvider.isDark;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: context.color.primaryContainer,
      leadingWidth: 56,
      leading: Center(
        child: Material(
          color:
              isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? const Color(0xff3A3A3A) : const Color(0xffEAEBEE),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ProjectTheme.brandColor, ProjectTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            key.tr(),
            style: context.textTheme.bodyLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.themeProvider.isDark
                ? Colors.black.withAlpha(40)
                : const Color(0x80C6C7C9),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      );

  Widget _avatarChip(IconData icon) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ProjectTheme.brandColor, ProjectTheme.accentLight],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      );

  Widget _contactInfoCard(BuildContext context) {
    final muted = context.themeProvider.isDark
        ? const Color(0xffCCCFD3)
        : const Color(0xff8E8E92);
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _avatarChip(Icons.contacts_rounded),
              const SizedBox(width: 10),
              Text(
                "contact_info_title".tr(),
                style: context.textTheme.bodyLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _contactRow(context, Icons.alternate_email_rounded, "email".tr(),
              "${widget.passenger[0]["email"]}", muted),
          const SizedBox(height: 14),
          _contactRow(context, Icons.phone_rounded, "phone_number_label".tr(),
              "+${widget.passenger[0]["phone"]}", muted),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String label,
      String value, Color muted) {
    final brand = ProjectTheme.brandColor;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: brand.withAlpha(context.themeProvider.isDark ? 45 : 20),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: brand, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: "packages/mysafar_sdk/Gilroy", fontSize: 12, color: muted)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passengersCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(context),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.passenger.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              PassengerContainer(passenger: widget.passenger[index]),
              if (index != widget.passenger.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: DashedLine(color: Color(0xffDBDCDF)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _agreementRow(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => isChek = !isChek),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isChek
                ? brand.withAlpha(isDark ? 38 : 16)
                : context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isChek
                  ? brand.withAlpha(120)
                  : context.color.outline.withAlpha(120),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isChek
                      ? LinearGradient(
                          colors: [brand, ProjectTheme.accentLight])
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isChek
                      ? null
                      : Border.all(color: context.color.outline, width: 2),
                ),
                child: isChek
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, WebViewScreen.routName,
                        arguments: "https://mysafar.uz/privacy");
                  },
                  child: Text(
                    "Oferta shartlariga roziman. Ma’lumotlar to’g’riligini tasdiqlayman.",
                    softWrap: true,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerContainer extends StatelessWidget {
  final Map<String, dynamic> passenger;

  const PassengerContainer({
    super.key,
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;
    TextStyle labelStyle;
    if (brightness == Brightness.dark) {
      labelStyle = TextStyle(
        fontSize: 12,
        overflow: TextOverflow.ellipsis,
        color: Color(0xffCCCFD3),
      );
    } else {
      labelStyle = const TextStyle(
        fontSize: 12,
        overflow: TextOverflow.ellipsis,
        color: Color(0xff8E8E92),
      );
    }

    TextStyle? valueStyle = context.textTheme.bodyLarge
        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
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
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${passenger["firstname"] ?? ''} ${passenger["lastname"] ?? ''}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${"citizenship".tr()}:", style: labelStyle),
                    Text(
                        getCountry(passenger["citizen"] ?? "")["name"][dataLang()],
                        style: valueStyle),
                    const SizedBox(height: 12),
                    Text("${"birth_date".tr()}:", style: labelStyle),
                    Text(passenger["birthdate"] ?? '-', style: valueStyle),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${"passport_number".tr()}:", style: labelStyle),
                    Text(passenger["docnum"] ?? '-', style: valueStyle),
                    const SizedBox(height: 12),
                    Text("${"passport_validity".tr()}:", style: labelStyle),
                    Text(passenger["docexp"] ?? '-', style: valueStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
