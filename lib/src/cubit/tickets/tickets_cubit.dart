import 'package:mysafar_sdk/src/core/config/network_request_scope.dart'
    show NetworkCancel;
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/tickets/flight_results_utils.dart';
import 'package:mysafar_sdk/src/model/centrum/get_centrum_recommendation_model.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tickets_state.dart';
part 'tickets_event.dart';

class TicketCubit extends Bloc<TicketEvent, TicketsState> with NetworkCancel {
  TicketCubit(RecommendationRequestBody reqBody, bool isCentrum)
      : super(TicketInitState()) {
    filterReqBody = reqBody;

    on<GetRecommendationsEvent>(_onGetRecommendations);
    on<SendFilterEvent>(_onSendFilter);

    add(GetRecommendationsEvent(reqBody));
  }

  final AviaService _aviaService = AviaService();

  GetRecommendationResModel? overAllData;
  late RecommendationRequestBody filterReqBody;
  bool isFiltered = false;

  // Har bir qidiruvga unik "avlod" raqami: yangi qidiruv boshlansa, eski
  // (parallel davom etayotgan) so'rovlar natijasi UI'ga chiqmasligi uchun.
  int _requestGeneration = 0;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<void> _onGetRecommendations(
    GetRecommendationsEvent event,
    Emitter<TicketsState> emit,
  ) async {
    // Yangi qidiruv — oldingi tarmoq so'rovlarini bekor qilamiz.
    refreshNetworkCancel();
    // Yangi qidiruv avlodi — eski parallel so'rovlar natijasi UI'ga chiqmasin.
    final int generation = ++_requestGeneration;

    emit(TicketLoadingState());
    // Sahifa ichidagi qayta qidiruvlar ham hisoblanadi (router bilan 3 s
    // ichidagi dublikat analitika tomonida tashlanadi).
    AnalyticsService()
        .trackTicketSearchedFor(event.requestBody, source: 'results_page');

    await withNetworkCancel(() async {
      await _runRecommendations(event, emit, generation);
    });
  }

  Future<void> _runRecommendations(
    GetRecommendationsEvent event,
    Emitter<TicketsState> emit,
    int generation,
  ) async {
    final params = event.requestBody.toJson();

    // Firebase SDK'dan olib tashlangan — endpoint ro'yxati Hive keshi yoki
    // koddagi zaxira ro'yxatdan olinadi, tarmoq sinxronizatsiyasi yo'q.

    // Manbalar (endpoint) ro'yxati Firestore'dan (Hive keshi orqali) keladi;
    // bo'lmasa koddagi 3 ta zaxira endpoint ishlatiladi.
    // Har biriga parallel so'rov: birinchi kelgani UI'ga darhol chiqadi,
    // keyingilari ro'yxatga qo'shiladi (merge). Qolgan manbalar kutilayotganda
    // ro'yxat ostida loading ko'rsatiladi (`isLoadingMore`).
    final List<String> endpoints =
        RemoteConfigService.instance.recommendationEndpoints;
    final int totalSources = endpoints.length;
    int completedCount = 0;
    GetRecommendationResModel? accumulated;
    bool anyShown = false;
    NetworkErrorResponse? lastError;
    // Manba umuman javob bera olmagan (timeout, ulanish, 5xx) oxirgi xato —
    // bunda "reys yo'q" deyish noto'g'ri bo'ladi, qayta urinish kerak.
    NetworkErrorResponse? lastTransientError;
    // Kamida bitta manba "bu yo'nalish/sanada reys yo'q" deb javob berdi.
    // Bu — xato emas, yo'nalish haqidagi haqiqiy javob (pastdagi yakuniy
    // tanlovga qarang: [resolveNoResultsOutcome]).
    bool anyEmpty = false;

    bool isStale() => isClosed || generation != _requestGeneration;

    // Jamlangan natijani emit qiladi; hali tugamagan manbalar bo'lsa ro'yxat
    // ostida loading chiqishi uchun `isLoadingMore: true` beradi.
    void emitProgress() {
      if (isStale() || accumulated == null) return;
      emit(TicketSuccessState(
        accumulated!,
        isLoadingMore: completedCount < totalSources,
      ));
    }

    // Bitta manbaga so'rov + kalit/token xatosida qayta urinish. Yakuniy
    // javobni (muvaffaqiyat yoki xato) qaytaradi.
    Future<NetworkResponse> fetchWithRetry(String endPoint) async {
      int retryCount = 0;
      while (true) {
        NetworkResponse response;
        try {
          response = await _aviaService.getRecommendations(
            params: params,
            endPoint: endPoint,
          );
        } catch (e) {
          response = NetworkErrorResponse(error: e.toString());
        }

        if (isStale()) return response;

        if (response is NetworkErrorResponse) {
          final errorMessage = response.error is Map<String, dynamic>
              ? (response.error['ru'] ?? response.error['message'] ?? '')
                  .toString()
                  .toLowerCase()
              : response.error.toString().toLowerCase();

          final bool isKeyError = errorMessage.contains('kalit') ||
              errorMessage.contains('ключ') ||
              errorMessage.contains('key') ||
              errorMessage.contains('token') ||
              errorMessage.contains('unauthorized') ||
              errorMessage.contains('401');

          if (isKeyError && retryCount < _maxRetries) {
            retryCount++;
            debugPrint(
                "TicketCubit: Key error ($endPoint), retrying... ($retryCount/$_maxRetries)");
            await Future.delayed(_retryDelay);
            if (isStale()) return response;
            continue;
          }
        }

        return response;
      }
    }

    // Bitta manbani to'liq qayta ishlaydi: javob kelgach hisobni oshiradi,
    // muvaffaqiyat bo'lsa ro'yxatga qo'shadi va UI'ni yangilaydi. Xato bo'lsa —
    // jim (faqat haqiqiy xatoni saqlaymiz, kerak bo'lsa oxirida chiqadi).
    Future<void> runSource(String endPoint) async {
      final response = await fetchWithRetry(endPoint);
      if (isStale()) return;

      completedCount++;

      if (response is NetworkSuccessResponse) {
        final model = response.data as GetRecommendationResModel;

        // Birinchi muvaffaqiyatli javob — bazaviy; keyingilari ro'yxatga
        // qo'shiladi. Merge har doim YANGI obyekt qaytaradi (Equatable
        // keyingi emit'larni sezishi uchun).
        accumulated = accumulated == null
            ? model
            : _mergeRecommendations(accumulated!, model);
        overAllData = accumulated;

        // DIQQAT: natijadagi aviakompaniyalar so'rovga (`filterReqBody`)
        // YOZILMAYDI. Ilgari hammasi "tanlangan" deb `filter_airlines`ga
        // qo'shilardi va keyingi qidiruvlar (sana lentasi, qayta qidirish)
        // faqat oldingi natijadagi kompaniyalarni so'rardi — birinchi safar
        // sekin/xato bergan manbaning reyslari qaytib kelmasdi. Filtr sheet'i
        // aviakompaniyalar ro'yxatini `overAllData`dan oladi.

        anyShown = true;
      } else if (response is NetworkErrorResponse) {
        if (response.errorType == ErrorType.emptyResponse) {
          // Manba muvaffaqiyatli javob berdi, lekin bu yo'nalish/sanada reys
          // yo'q. Bu xato emas — "bilet topilmadi" holati.
          anyEmpty = true;
        } else {
          // Qisman xato — userga ko'rsatilmaydi. Faqat saqlaymiz; hech qaysi
          // manba javob bermasa, oxirida chiqaramiz.
          lastError = response;
          if (isTransientSearchError(response.errorType)) {
            lastTransientError = response;
          }
        }
      }

      // Har bir manba tugagach UI yangilanadi: natija bo'lsa ro'yxat +
      // (qolganlar kutilsa) ostida loading; oxirgi manba tugaganda loading
      // o'chadi. Xato bo'lganda ham loading shunchaki to'xtaydi (xato chiqmaydi).
      emitProgress();
    }

    // Tarmoq xatolari `fetchWithRetry` ichida `NetworkErrorResponse`ga
    // aylantiriladi; bu yerga faqat kutilmagan istisnolar (parse/cast va h.k.)
    // tushadi — ularni ham "bo'sh natija" emas, xato deb ko'rsatamiz.
    Object? unexpectedError;

    // Barcha manbalarga birdan (parallel) so'rov.
    try {
      await Future.wait(endpoints.map(runSource));
    } catch (e) {
      unexpectedError = e;
      debugPrint("TicketCubit GetRecommendations error: $e");
    }

    if (isStale()) return;

    if (anyShown) {
      final body = event.requestBody;
      AnalyticsService().trackSearchResults(
        count: accumulated?.recommedations?.flights.length ?? 0,
        passengers: body.adt + body.chd + body.inf,
      );
    }

    // Hech qaysi manba reys bermadi — endi (faqat shu holatda) xato yoki bo'sh
    // holatni ko'rsatamiz (tartib: [resolveNoResultsOutcome]).
    if (!anyShown) {
      switch (resolveNoResultsOutcome(
        anyEmpty: anyEmpty,
        hasError: lastError != null,
        hasTransientError: lastTransientError != null,
        hasUnexpectedError: unexpectedError != null,
      )) {
        case TicketNoResultsOutcome.empty:
          AnalyticsService().trackSearchResults(count: 0);
          emit(const TicketEmptyState());
        case TicketNoResultsOutcome.error:
          // Vaqtinchalik xato bo'lsa o'shani ko'rsatamiz — dialog sarlavhasi
          // ("Ulanishda muammo" / "Server xatosi") aynan shunga mos.
          final error = lastTransientError ?? lastError!;
          AnalyticsService().trackSearchFailed(
            errorType: error.errorType?.name,
            passengers: event.requestBody.adt +
                event.requestBody.chd +
                event.requestBody.inf,
          );
          emit(TicketErrorState(error.getError(), errorType: error.errorType));
        case TicketNoResultsOutcome.unexpectedError:
          AnalyticsService().trackSearchFailed(errorType: 'unexpected');
          emit(TicketErrorState("error_other".tr()));
      }
    }
  }

  /// Manba umuman javob bera olmagan (qayta urinish yordam berishi mumkin)
  /// xato turlarimi: timeout, ulanish uzilishi, 5xx.
  @visibleForTesting
  static bool isTransientSearchError(ErrorType? type) => switch (type) {
        ErrorType.connectTimeout ||
        ErrorType.receiveTimeout ||
        ErrorType.sendTimeout ||
        ErrorType.connectionError ||
        ErrorType.dio_error ||
        ErrorType.internalServer_500 ||
        ErrorType.badGateway_502 ||
        ErrorType.serviceUnavailable_503 ||
        ErrorType.gatewayTimeout_504 ||
        ErrorType.serverError_5xx =>
          true,
        _ => false,
      };

  /// Hech qaysi manba reys bermaganda qaysi holat ko'rsatilishini tanlaydi.
  /// Tartib muhim:
  ///   1) kamida bitta manba javob bera olmadi (timeout/ulanish/5xx) → xato +
  ///      "Qayta urinish". Boshqa manba "reys yo'q" desa ham — javob bermagan
  ///      manbada reys bo'lishi mumkin, "bilet topilmadi" deyish noto'g'ri;
  ///   2) kamida bitta manba "reys yo'q" dedi → "bilet topilmadi" (boshqa
  ///      manbaning biznes/4xx xatosi bu javobni bekor qilmaydi);
  ///   3) faqat xatolar → xato dialogi;
  ///   4) kutilmagan istisno → umumiy xato;
  ///   5) qolgan hollarda → "bilet topilmadi".
  @visibleForTesting
  static TicketNoResultsOutcome resolveNoResultsOutcome({
    required bool anyEmpty,
    required bool hasError,
    required bool hasTransientError,
    required bool hasUnexpectedError,
  }) {
    if (hasTransientError) return TicketNoResultsOutcome.error;
    if (anyEmpty) return TicketNoResultsOutcome.empty;
    if (hasError) return TicketNoResultsOutcome.error;
    if (hasUnexpectedError) return TicketNoResultsOutcome.unexpectedError;
    return TicketNoResultsOutcome.empty;
  }

  /// Ikki manba natijasini birlashtiradi: `base` reyslari ustiga `extra`
  /// reyslarini qo'shadi (id va bir xil taklif bo'yicha takrorlanmaslik bilan). Eski emit'langan
  /// modelni o'zgartirmaslik va Equatable yangi holatni sezishi uchun har doim
  /// YANGI obyekt qaytaradi.
  GetRecommendationResModel _mergeRecommendations(
    GetRecommendationResModel base,
    GetRecommendationResModel extra,
  ) {
    final baseRec = base.recommedations;
    final extraRec = extra.recommedations;
    if (baseRec == null) return extra;
    if (extraRec == null) return base;

    // id bo'yicha, hamda turli manbalardan kelgan AYNAN bir xil taklif
    // (reyslar, vaqtlar, tarif shartlari) bo'yicha takrorlar olib tashlanadi —
    // faqat eng arzoni qoladi ([FlightResultsUtils.mergeDedupe]).
    final combinedFlights =
        FlightResultsUtils.mergeDedupe(baseRec.flights, extraRec.flights);

    final combinedAirlines = <FilterAirLineItemsModel>[
      ...?base.filterAirLineItems,
    ];
    final seenCodes = combinedAirlines.map((a) => a.code).toSet();
    for (final item
        in extra.filterAirLineItems ?? <FilterAirLineItemsModel>[]) {
      if (seenCodes.add(item.code)) {
        combinedAirlines.add(item);
      }
    }

    return GetRecommendationResModel(
      recommedations: OverAllData(
        search: baseRec.search,
        flights: combinedFlights,
        segmentsComments: baseRec.segmentsComments,
        healthDeclarationText: baseRec.healthDeclarationText,
        predefinedAirlines: baseRec.predefinedAirlines,
        excludedAirlines: baseRec.excludedAirlines,
      ),
      filterAirLineItems: combinedAirlines,
    );
  }

  void _onSendFilter(
    SendFilterEvent event,
    Emitter<TicketsState> emit,
  ) {
    isFiltered = true;
    filterReqBody = event.requestBody;
    ProjectUtils.setRecommendationParams(filterReqBody);
    add(GetRecommendationsEvent(filterReqBody));
  }
}
