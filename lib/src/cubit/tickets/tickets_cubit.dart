import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/model/centrum/get_centrum_recommendation_model.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart';
import 'package:mysafar_sdk/src/service/avia_service.dart';
import 'package:mysafar_sdk/src/service/config/remote_config_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tickets_state.dart';
part 'tickets_event.dart';

class TicketCubit extends Bloc<TicketEvent, TicketsState> {
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
    // Yangi qidiruv avlodi — eski parallel so'rovlar natijasi UI'ga chiqmasin.
    final int generation = ++_requestGeneration;

    emit(TicketLoadingState());

    final params = event.requestBody.toJson();

    // Har qidiruvdan oldin endpoint ro'yxatini Firestore'dan yangilaymiz —
    // shu bilan admin paneldagi o'zgarish (ilovani qayta ochmasdan) shu
    // qidiruvga ham darrov qo'llanadi. Sekin/oflayn bo'lsa keshdagini
    // ishlataveramiz (timeout).
    try {
      await RemoteConfigService.instance
          .sync()
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
    if (isClosed || generation != _requestGeneration) return;

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

        // Foydalanuvchi qo'lda filter qo'llamagan bo'lsa, filter
        // aviakompaniyalarini jamlangan (manbalar birlashmasi) ro'yxatdan
        // sinxronlaymiz.
        if (!isFiltered) {
          filterReqBody.setFilterAirlinesFromItems(
            accumulated?.filterAirLineItems ?? [],
          );
        }

        anyShown = true;
      } else if (response is NetworkErrorResponse &&
          response.errorType != ErrorType.emptyResponse) {
        // Qisman xato — userga ko'rsatilmaydi. Faqat saqlaymiz; barcha manba
        // xato bo'lsa, oxirida chiqaramiz.
        lastError = response;
      }

      // Har bir manba tugagach UI yangilanadi: natija bo'lsa ro'yxat +
      // (qolganlar kutilsa) ostida loading; oxirgi manba tugaganda loading
      // o'chadi. Xato bo'lganda ham loading shunchaki to'xtaydi (xato chiqmaydi).
      emitProgress();
    }

    // Barcha manbalarga birdan (parallel) so'rov.
    try {
      await Future.wait(endpoints.map(runSource));
    } catch (e) {
      debugPrint("TicketCubit GetRecommendations error: $e");
    }

    if (isStale()) return;

    // Hech qaysi manba reys bermadi — endi (faqat shu holatda) xato yoki bo'sh
    // holatni ko'rsatamiz.
    if (!anyShown) {
      if (lastError != null) {
        emit(TicketErrorState(lastError!.getError()));
      } else {
        emit(TicketEmptyState());
      }
    }
  }

  /// Ikki manba natijasini birlashtiradi: `base` reyslari ustiga `extra`
  /// reyslarini qo'shadi (id bo'yicha takrorlanmaslik bilan). Eski emit'langan
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

    final combinedFlights = <FlightElement>[...baseRec.flights];
    final seenIds = combinedFlights.map((f) => f.id).toSet();
    for (final flight in extraRec.flights) {
      if (seenIds.add(flight.id)) {
        combinedFlights.add(flight);
      }
    }

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
