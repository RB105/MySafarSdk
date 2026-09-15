// ignore_for_file: unused_local_variable

import 'dart:async' show unawaited;

import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show ErrorType, NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart' show sdkStorage;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/service/profile/profile_service.dart'
    show ProfileService;
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/booking_create_loading_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_create_states.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart'
    show PassengerConstants;
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';

import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_card_widget.dart'
    show BookingCountryFlag;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';

import '../../model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;

class BookingCreatePage extends StatefulWidget {
  final List<Map<String, dynamic>> passenger;

  /// "Saqlangan yo'lovchilarga qo'shish" yoqilgan yo'lovchilar — bron
  /// muvaffaqiyatli bo'lgach faqat shular profilga saqlanadi.
  final List<Map<String, dynamic>> passengersToSave;
  final FlightPrice? price;
  final String trId;

  const BookingCreatePage({
    super.key,
    required this.passenger,
    this.passengersToSave = const [],
    required this.price,
    required this.trId,
  });

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  /// Booking yaratilgach kiritilgan yo'lovchilarni backend'dagi saqlangan
  /// yo'lovchilar ro'yxatiga (`/create-user-data`) fonda qo'shadi —
  /// AddPassengerPage'dagi bilan bir xil API. Dublikat bo'lmasligi uchun
  /// mavjud ro'yxat `docnum` bo'yicha tekshiriladi.
  ///
  /// Yangi yo'lovchi qo'shilsa `cached_users` tozalanadi va qayta yuklanadi —
  /// keyingi bronlashda "Yo'lovchi tanlash" chiqishi uchun.
  Future<void> _savePassengersInBackground() async {
    if (!MySafarSdk.tokens.isLoggedIn) return;
    if (widget.passengersToSave.isEmpty) return;
    try {
      final service = ProfileService();
      final box = sdkStorage();

      // Mavjud saqlanganlar — dublikatni oldini olish. Avval server; ishlamasa kesh.
      List<dynamic> existing;
      final existingRes = await service.getUserDate();
      if (existingRes is NetworkSuccessResponse) {
        existing = existingRes.data as List? ?? const [];
      } else if (existingRes is NetworkErrorResponse &&
          existingRes.errorType == ErrorType.emptyResponse) {
        existing = const [];
      } else {
        existing = (box.read(UsersDataCubit.cacheKey) as List?) ?? const [];
      }

      final existingDocnums = <String>{
        for (final u in existing)
          if (u is Map && u['docnum'] != null)
            u['docnum'].toString().trim().toUpperCase(),
      };

      var createdAny = false;
      for (final p in widget.passengersToSave) {
        final docnum = (p['docnum'] ?? '').toString().trim();
        if (docnum.isEmpty) continue;
        if (!existingDocnums.add(docnum.toUpperCase())) continue;

        final birthdate = _toApiDate((p['birthdate'] ?? '').toString());
        final docexp = _toApiDate((p['docexp'] ?? '').toString());
        if (birthdate == null || docexp == null) continue;

        final response = await service.createUser(params: {
          'firstname': (p['firstname'] ?? '').toString().trim(),
          'lastname': (p['lastname'] ?? '').toString().trim(),
          'middlename': (p['middlename'] ?? '').toString().trim(),
          'birthdate': birthdate,
          'docnum': docnum,
          'docexp': docexp,
          'gender': (p['gender'] ?? 'M').toString(),
          'citizen': (p['citizen'] ?? '').toString(),
        });
        if (response is NetworkSuccessResponse) createdAny = true;
      }

      // Yangi yozuv bo'lsa eski keshni bekor qilamiz; keyin (kesh yo'q
      // bo'lsa) serverdan qayta yuklaymiz — keyingi bronlashda tugma chiqadi.
      if (createdAny) {
        await UsersDataCubit.clearCache();
      }
      await UsersDataCubit.prefetchIfNeeded();
    } catch (e) {
      // Fon jarayoni — foydalanuvchi oqimiga ta'sir qilmaydi.
      debugPrint('Passenger background save failed: $e');
    }
  }

  /// `dd.MM.yyyy` yoki `yyyy-MM-dd` ko'rinishidagi sanani API formatiga
  /// (`yyyy-MM-dd`) keltiradi; noto'g'ri format bo'lsa `null`.
  String? _toApiDate(String raw) {
    final value = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return value;
    if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(value)) {
      final parts = value.split('.');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return null;
  }

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
          // Kiritilgan yo'lovchilarni fonda "Ma'lumotlarim"ga saqlaymiz —
          // to'lov oynasiga o'tishni bloklamaydi, xatosi ham jim o'tadi.
          unawaited(_savePassengersInBackground());
          _handleBookingCreated(context, state.data);
        } else if (state is BookingcreateErrorState) {
          LoadingDialog.dismiss(context);
          // Bronlash xatosida TID ko'rsatiladi — foydalanuvchi nusxalab
          // qo'llab-quvvatga yuborishi mumkin (mobile ilova bilan bir xil).
          ResponseState.errorState(
            state.error,
            context,
            copyableId: widget.trId,
          );
        }
      }, builder: (context, state) {
        return Scaffold(
            appBar: _buildAppBar(context),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _CheckDataNotice(),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: "passenger_data_title".tr(),
                  onChange: () => Navigator.of(context).maybePop(),
                ),
                for (int i = 0; i < widget.passenger.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  PassengerContainer(passenger: widget.passenger[i]),
                ],
                const SizedBox(height: 20),
                _SectionHeader(
                  title: "your_contacts".tr(),
                  onChange: () => Navigator.of(context).maybePop(),
                ),
                _buildContactsCard(context),
                const SizedBox(height: 20),
                _buildOfferCard(context),
              ],
            ),
            bottomNavigationBar: NextButtonWidget(
              nextTittle: "continue_purchase",
              analyticsId: 'booking_create_continue',
              isLoading: false,
              onPressed: () {
                if (state is! BookingcreateLoadingState) {
                  context.read<BookingcreateCubit>().createBooking(
                      context: context,
                      email: widget.passenger[0]["email"],
                      tid: widget.trId,
                      firstName: "${widget.passenger[0]["firstname"]}",
                      passenger: widget.passenger,
                      // Backend +siz (998...) kutadi; profil/UI da
                      // bo'lishi mumkin bo'lgan "+" ni olib tashlaymiz.
                      phoneNumber: normalizePhoneDigits(
                          "${widget.passenger[0]["phone"] ?? ''}"));
                }
              },
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      ),
      title: Text(
        "data_confirmation".tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }

  /// Kontaktlar — email va telefon, ikonkali qatorlar ko'rinishida.
  Widget _buildContactsCard(BuildContext context) {
    final contact = widget.passenger[0];
    return BookingCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _ContactRow(
            iconAsset: Assets.iconsProfileMailIcon,
            label: "email".tr(),
            value: "${contact["email"] ?? ''}",
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            endIndent: 16,
            color: context.color.outline.withValues(alpha: 0.6),
          ),
          _ContactRow(
            iconAsset: Assets.iconsBookingCallIcon,
            label: "phone".tr(),
            value: formatInternationalPhone("${contact["phone"] ?? ''}"),
          ),
        ],
      ),
    );
  }

  /// Oferta — xaridni davom ettirish shartlarga rozilik hisoblanadi; karta
  /// bosilganda oferta matni ochiladi.
  Widget _buildOfferCard(BuildContext context) {
    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, WebViewScreen.routName,
            arguments: "https://mysafar.uz/privacy"),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const _IconChip(
                asset: Assets.iconsProfileDocumentIcon,
                shape: BoxShape.rectangle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "offer_title".tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "offer_accept_by_continue".tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: BookingFormStyle.label(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

/// Bo'lim sarlavhasi; [onChange] berilsa o'ngda "O'zgartirish" havolasi
/// (oldingi — ma'lumot kiritish sahifasiga qaytaradi).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onChange});

  final String title;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final Color link =
        context.isDarkMode ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (onChange != null)
            InkWell(
              onTap: onChange,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  "change".tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: link,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sahifa tepasidagi eslatma: chipta hujjatdagi ma'lumotlar bo'yicha
/// rasmiylashtiriladi — to'lovdan oldin tekshirib chiqish kerak.
class _CheckDataNotice extends StatelessWidget {
  const _CheckDataNotice();

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color accent = isDark ? ProjectTheme.accentLight : brand;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SvgPicture.asset(
              Assets.iconsBookingInfoIcon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "confirm_data_hint".tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kichik tonli ikonka konteyneri (yangi bron UI'dagi bilan bir xil).
class _IconChip extends StatelessWidget {
  const _IconChip({required this.asset, this.shape = BoxShape.circle});

  final String asset;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : brand.withValues(alpha: 0.08),
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(12) : null,
      ),
      child: SvgPicture.asset(
        asset,
        width: 22,
        height: 22,
        colorFilter:
            ColorFilter.mode(isDark ? Colors.white : brand, BlendMode.srcIn),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconChip(asset: iconAsset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: BookingFormStyle.label(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
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

/// Bitta yo'lovchining tasdiqlash kartasi: ism (pasportdagidek), yosh
/// toifasi va jinsi, pastda hujjat ma'lumotlari "yorliq — qiymat" qatorlarida.
class PassengerContainer extends StatelessWidget {
  final Map<String, dynamic> passenger;

  const PassengerContainer({
    super.key,
    required this.passenger,
  });

  String _field(String key) => (passenger[key] ?? '').toString().trim();

  String get _fullName => [
        _field("lastname"),
        _field("firstname"),
        _field("middlename"),
      ].where((part) => part.isNotEmpty).join(' ');

  String get _ageLabel => switch (_field("age")) {
        'chd' => "between_2_12".tr(),
        'inf' => "under_2".tr(),
        _ => "above_12".tr(),
      };

  String get _genderLabel => _field("gender") == PassengerConstants.genderFemale
      ? "female".tr()
      : "male".tr();

  @override
  Widget build(BuildContext context) {
    final String citizenCode = _field("citizen");
    final String citizenName = citizenCode.isEmpty
        ? ''
        : (getCountry(citizenCode)["name"][dataLang()] ?? '').toString();

    return BookingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const _IconChip(asset: Assets.iconsBookingUserIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fullName.isEmpty ? '-' : _fullName.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$_ageLabel · $_genderLabel",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BookingFormStyle.label(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: context.color.outline.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                _InfoRow(
                  label: "citizenship".tr(),
                  value: citizenName,
                  leading: citizenCode.isEmpty
                      ? null
                      : BookingCountryFlag(code: citizenCode),
                ),
                _InfoRow(label: "birth_date".tr(), value: _field("birthdate")),
                _InfoRow(
                    label: "document_number".tr(), value: _field("docnum")),
                _InfoRow(
                  label: "passport_validity".tr(),
                  value: _field("docexp"),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Yorliq — qiymat" qatori: yorliq chapda (xira), qiymat o'ngda (qalin).
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.leading,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Widget? leading;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: BookingFormStyle.label(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (leading != null && value.isNotEmpty) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
