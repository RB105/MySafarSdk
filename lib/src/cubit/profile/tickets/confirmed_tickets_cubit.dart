import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart'
    show ConfirmedTicketsModel;
import 'package:mysafar_sdk/src/service/profile/profile_service.dart'
    show ProfileService;
import 'package:mysafar_sdk/src/service/profile/tickets_cache.dart';
part 'confirmed_tickets_state.dart';

class ConfirmedTicketsCubit extends Cubit<ConfirmedTicketsState> {
  ConfirmedTicketsCubit() : super(ConfirmedTicketsInitState()) {
    getTickets();
  }

  final _profileService = ProfileService();
  final _cache = TicketsCache();

  /// Foydalanuvchi login qilganmi — `access_token` mavjud va bo'sh emasmi.
  /// Token yo'q bo'lsa biletlarni serverdan yangilashga umuman urinmaymiz.
  bool get _isLoggedIn {
    final token = GetStorage().read('access_token');
    return token != null && '$token'.isNotEmpty;
  }

  /// Biletlarni yuklaydi.
  ///
  /// Odatda biletlar **doim keshdan** olinadi — serverga bormaydi. Faqat
  /// [forceRefresh] `true` bo'lganda (booking yaratilgach yoki sahifada qo'lda
  /// yangilashda) serverdan qayta olib, kesh to'liq yangilanadi. Kesh bo'sh
  /// bo'lsa (birinchi kirish) ham serverdan olinadi.
  ///
  /// [silent] — loading holatini ko'rsatmaslik (pull-to-refresh o'z
  /// indikatoriga ega).
  Future<void> getTickets({bool forceRefresh = false, bool silent = false}) async {
    List<ConfirmedTicketsModel>? cached;
    final cachedData = _cache.read();
    if (cachedData != null) {
      try {
        cached = _parse(cachedData);
        if (cached.isEmpty) {
          emit(ConfirmedTicketsEmptyState());
        } else {
          emit(ConfirmedTicketsSuccessState(cached));
        }
      } catch (e) {
        cached = null;
        debugPrint("❌ Tickets cache read error: $e");
      }
    } else if (!silent) {
      emit(ConfirmedTicketsLoadingState());
    }

    // Keshda biletlar bor va majburiy yangilash so'ralmagan bo'lsa — serverga
    // umuman bormaymiz, keshdagi biletlarni ko'rsataveramiz.
    if (!forceRefresh && cached != null) return;

    // Access token yo'q (login qilinmagan) — serverdan yangilashning ma'nosi
    // yo'q. Keshdagini ko'rsatamiz; kesh bo'sh bo'lsa bo'sh holatga o'tamiz.
    if (!_isLoggedIn) {
      if (cached == null) emit(ConfirmedTicketsEmptyState());
      return;
    }

    // Butun server bo'limi try/catch ostida — malformed javob yoki parse xatosi
    // Loading spinnerni osib qo'ymasligi uchun (har doim terminal holatga o'tadi).
    try {
      final response = await _profileService.getTickets();
      if (isClosed) return;

      if (response is NetworkSuccessResponse) {
        final List rawTickets =
            response.data is List ? response.data as List : const [];
        // Avval parse — muvaffaqiyatli bo'lsagina keshga yozamiz (buzuq payload
        // keshga tushmasin).
        final tickets = _parse(rawTickets);
        try {
          _cache.write(rawTickets);
        } catch (e) {
          debugPrint("❌ Tickets cache write error: $e");
        }
        if (tickets.isEmpty) {
          emit(ConfirmedTicketsEmptyState());
        } else {
          emit(ConfirmedTicketsSuccessState(tickets));
        }
      } else if (response is NetworkErrorResponse) {
        if (response.errorType == ErrorType.emptyResponse) {
          // Bo'sh natijani ham keshlaymiz — keyingi kirishda darhol Empty.
          _cache.write(const []);
          emit(ConfirmedTicketsEmptyState());
          return;
        }
        // Keshdan allaqachon ko'rsatgan bo'lsak, tarmoq xatosini bosib o'tmaymiz.
        if (cached == null) {
          emit(ConfirmedTicketsErrorState(
              error: response.getError(), errorType: response.errorType));
        }
      }
    } catch (e) {
      if (isClosed) return;
      debugPrint("❌ Tickets fetch/parse error: $e");
      // Faqat ko'rsatadigan kesh bo'lmaganda xato holatini chiqaramiz.
      if (cached == null) {
        emit(ConfirmedTicketsErrorState(
            error: "error_other".tr(), errorType: ErrorType.other));
      }
    }
  }

  /// Xom JSON ro'yxatini modellarga o'giradi — Map bo'lmagan (null yoki boshqa)
  /// elementlarni o'tkazib yuboradi.
  List<ConfirmedTicketsModel> _parse(List raw) => raw
      .whereType<Map>()
      .map((e) => ConfirmedTicketsModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  /// Booking yaratilgach keshni bekor qiladi — keyingi ochilishda biletlar
  /// serverdan qayta yuklanadi.
  static Future<void> clearCache() => TicketsCache().clear();
}
