import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/widgets/booking_create_loading_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_create_states.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_gate.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_passenger_saver.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_draft_store.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightPrice;
import 'package:mysafar_sdk/src/service/payment/payment_type_repository.dart';
import 'package:mysafar_sdk/src/view/booking/booking_confirm_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_progress_page.dart';

/// Bron yaratish uchun ma'lumotlar.
class BookingCreateRequest {
  const BookingCreateRequest({
    required this.passengers,
    this.passengersToSave = const [],
    required this.trId,
    required this.price,
    this.flight,
  });

  final List<Map<String, dynamic>> passengers;

  /// "Saqlangan yo'lovchilarga qo'shish" yoqilgan yo'lovchilar — bron
  /// muvaffaqiyatli bo'lgach faqat shular profilga saqlanadi.
  final List<Map<String, dynamic>> passengersToSave;
  final String trId;
  final FlightPrice? price;

  /// Tanlangan reys — to'lov sahifasidagi "nima uchun to'lanmoqda" kartasi
  /// uchun (№23).
  final FlightElement? flight;
}

/// [BookingCreateFlow.start] natijasi.
enum BookingCreateOutcome {
  /// Bron yaratildi va to'lov sahifasi ochildi (u yopilgach qaytadi).
  opened,

  /// Bron yaratilmadi — xato dialogi ko'rsatildi.
  failed,

  /// Bron yaratildi, lekin foydalanuvchi oshgan narxni rad etdi (yoki oqim
  /// allaqachon ketmoqda edi).
  cancelled,
}

/// Bron yaratish oqimi (№22) — ilgari alohida "Ma'lumotlarni tasdiqlash"
/// sahifasida edi, endi yo'lovchi sahifasidagi tugmadan
/// to'g'ridan-to'g'ri ishlatiladi:
///  • bron yuklanish sahifasi ([BookingProgressPage], to'liq ekran; orqaga
///    qaytib bo'lmaydi, har qanday chiqishda yopiladi);
///  • [BookingcreateCubit] — so'rov va analitika (booking_created / failed);
///  • muvaffaqiyatda: qoralama bekor ([PassengerDraftStore.markBooked]),
///    kalendar eslatmasi, yo'lovchilarni kechiktirib profilga saqlash,
///    narx oshgan bo'lsa tasdiq dialogi va to'lov sahifasi;
///  • xatoda: TID bilan xato dialogi.
class BookingCreateFlow {
  BookingCreateFlow();

  /// To'lov sahifasi ochilgach yo'lovchilarni saqlashni boshlash kechikishi
  /// (№41) — to'lov usullari va sahifa yuklanishi bilan tarmoq talashmasin.
  static const Duration passengerSaveDelay = Duration(seconds: 3);

  final BookingcreateCubit _cubit = BookingcreateCubit();
  bool _running = false;

  /// Oqim ketmoqdami (ikki marta bosishdan himoya).
  bool get isRunning => _running;

  /// To'lov usullarini oldindan (fonda) keshlaydi — to'lov sahifasi
  /// ochilganda ro'yxat darhol chiqadi (№38).
  static void prefetchPaymentTypes() =>
      unawaited(PaymentTypeRepository.prefetch());

  /// Bronni yaratadi va muvaffaqiyatda to'lov sahifasini ochadi. Reys
  /// tekshiruvi paytida ochilgan [LoadingDialog] bo'lsa — u yopilib, o'rniga
  /// to'liq ekran [BookingProgressPage] ochiladi.
  Future<BookingCreateOutcome> start(
      BuildContext context, BookingCreateRequest request) async {
    if (_running || _cubit.isClosed || request.passengers.isEmpty) {
      return BookingCreateOutcome.cancelled;
    }
    _running = true;
    AnalyticsService().trackPassengerFormCompleted(
      passengers: request.passengers.length,
      source: 'form_submit',
    );
    try {
      // Reys tekshiruvidan qolgan yuklanish oynasi (bo'lsa) yopiladi — u
      // tepadagi route'ni pop qiladi, shuning uchun progress sahifasidan
      // OLDIN yopilishi shart.
      LoadingDialog.dismiss(context);
      BookingProgressPage.show(context);
      final contact = request.passengers.first;
      await _cubit.createBooking(
        context: context,
        email: "${contact["email"] ?? ''}",
        tid: request.trId,
        firstName: "${contact["firstname"]}",
        passenger: request.passengers,
        // Backend +siz (998...) kutadi; profil/UI da bo'lishi mumkin
        // bo'lgan "+" ni olib tashlaymiz.
        phoneNumber: normalizePhoneDigits("${contact["phone"] ?? ''}"),
      );
      final state = _cubit.state;

      if (state is BookingcreateSuccessState) {
        // Bron yaratildi — yo'lovchi qoralamasi keyingi bronga o'tmasin.
        PassengerDraftStore.markBooked();
        ProjectUtils.setCalendarEventByLastSearch();
        // Kiritilgan yo'lovchilarni fonda "Ma'lumotlarim"ga saqlaymiz —
        // to'lov sahifasi ochilib bo'lgach, kechiktirib (№41): to'lov
        // sahifasi yuklanishini sekinlashtirmaydi, xatosi ham jim o'tadi.
        // Taymer sahifa holatiga bog'liq emas — saqlash yo'qolmaydi.
        final toSave = request.passengersToSave;
        Timer(passengerSaveDelay,
            () => unawaited(BookingPassengerSaver.saveInBackground(toSave)));
      }

      // Progress sahifasi har qanday keyingi dialog/navigatsiyadan oldin
      // yopiladi (context'ga bog'liq emas — sahifa yopilgan bo'lsa ham).
      BookingProgressPage.dismiss();
      if (!context.mounted) return BookingCreateOutcome.failed;

      if (state is! BookingcreateSuccessState) {
        // Bronlash xatosida TID ko'rsatiladi — foydalanuvchi nusxalab
        // qo'llab-quvvatga yuborishi mumkin (mobile ilova bilan bir xil).
        ResponseState.errorState(
          state is BookingcreateErrorState ? state.error : 'error_other'.tr(),
          context,
          copyableId: request.trId,
        );
        return BookingCreateOutcome.failed;
      }

      final data = state.data;
      final increase = BookingGate.bookedPriceIncrease(
          request.price, data.amount, data.currency);
      if (increase != null) {
        final confirmed = await ProjectDialogs.showPriceIncreasedConfirm(
          context,
          oldPrice: increase.oldPrice,
          newPrice: increase.newPrice,
          currencyLabel: increase.currencyLabel,
        );
        if (!confirmed || !context.mounted) {
          return BookingCreateOutcome.cancelled;
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmPage(
            passengerNumber: request.passengers.length,
            bookingCreateModel: data,
            price: request.price,
            flight: request.flight,
          ),
          settings: const RouteSettings(name: BookingConfirmPage.routeName),
        ),
      );
      return BookingCreateOutcome.opened;
    } finally {
      // Istisno (exception) yo'lida ham progress sahifasi osilib qolmasin.
      BookingProgressPage.dismiss();
      _running = false;
    }
  }

  void dispose() {
    _cubit.close();
  }
}
