import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show ErrorType;
import 'package:mysafar_sdk/src/core/enum/currency.dart' show AppCurrency;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/cubit/tickets/tickets_cubit.dart'
    show TicketCubit, TicketNoResultsOutcome;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FilterAirLineItemsModel, FlightPrice, FluffyRub, FluffyUzs;

/// Qidiruv natijalari bo'yicha tuzatishlar: narxni o'qish/valyuta zaxirasi,
/// `filter_airlines` faqat foydalanuvchi tanlovida yuborilishi va
/// "bilet topilmadi" / xato holatini tanlash.
void main() {
  group('FlightPrice.fromJson', () {
    test('RUB/USD bloklari kelmasa null qoladi ("0" emas)', () {
      final price = FlightPrice.fromJson({
        'UZS': {'amount': '2 751 009'},
      });
      expect(price.rub, isNull);
      expect(price.usd, isNull);
      expect(price.uzs?.amount, '2 751 009');
    });

    test('bloklar kelsa o\'qiladi', () {
      final price = FlightPrice.fromJson({
        'UZS': {'amount': 2751009},
        'USD': {'amount': 215.5},
        'RUB': {'amount': '19 870'},
      });
      expect(price.uzs?.amount, '2751009');
      expect(price.usd?.amount, '215.5');
      expect(price.rub?.amount, '19 870');
    });
  });

  group('CurrencyProvider.resolveElementPrice', () {
    FlightPrice price({String? uzs, String? usd, String? rub}) => FlightPrice(
          uzs: FluffyUzs(amount: uzs),
          usd: usd == null ? null : FluffyRub(amount: usd),
          rub: rub == null ? null : FluffyRub(amount: rub),
        );

    test('bo\'shliqli UZS summasi to\'g\'ri o\'qiladi', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009'), AppCurrency.uzs);
      expect(r, isNotNull);
      expect(r!.value, 2751009);
      expect(r.raw, '2 751 009');
      expect(r.currency, AppCurrency.uzs);
    });

    test('NBSP va ingichka bo\'shliqlar ham o\'qiladi', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009'), AppCurrency.uzs);
      expect(r?.value, 2751009);
    });

    test('tanlangan valyuta bloki bo\'lsa o\'sha ishlatiladi', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009', usd: '215.5'), AppCurrency.usd);
      expect(r?.value, 215.5);
      expect(r?.currency, AppCurrency.usd);
    });

    test('USD bloki yo\'q — UZS summasi UZS belgisi bilan', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009'), AppCurrency.usd);
      expect(r?.value, 2751009);
      expect(r?.currency, AppCurrency.uzs);
    });

    test('RUB summasi "0" — UZS summasiga qaytadi', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009', rub: '0'), AppCurrency.rub);
      expect(r?.value, 2751009);
      expect(r?.currency, AppCurrency.uzs);
    });

    test('"null" matnli summa yaroqsiz hisoblanadi', () {
      final r = CurrencyProvider.resolveElementPrice(
          price(uzs: '2 751 009', usd: 'null'), AppCurrency.usd);
      expect(r?.currency, AppCurrency.uzs);
    });

    test('hech qanday summa yo\'q — null', () {
      expect(
          CurrencyProvider.resolveElementPrice(
              price(uzs: '0'), AppCurrency.usd),
          isNull);
      expect(CurrencyProvider.resolveElementPrice(null, AppCurrency.uzs),
          isNull);
    });
  });

  group('RecommendationRequestBody filter_airlines', () {
    RecommendationRequestBody body() =>
        RecommendationRequestBody(adt: 1, chd: 0, inf: 0);

    final items = [
      FilterAirLineItemsModel(id: 1, code: 'HY', title: 'Uzbekistan Airways'),
      FilterAirLineItemsModel(id: 2, code: 'TK', title: 'Turkish Airlines'),
    ];

    test('standart holatda bo\'sh ro\'yxat yuboriladi', () {
      expect(body().toJson()['filter_airlines'], isEmpty);
    });

    test('natijadagi aviakompaniyalar so\'rovni filtrlamaydi', () {
      final b = body()..setFilterAirlinesFromItems(items);
      expect(b.filterAirlines, hasLength(2));
      expect(b.hasAirlineFilter, isFalse);
      expect(b.toJson()['filter_airlines'], isEmpty);
    });

    test('faqat foydalanuvchi tanlagan kompaniyalar yuboriladi', () {
      final b = body()..setFilterAirlinesFromItems(items);
      b.filterAirlines!.firstWhere((a) => a.code == 'TK').isChosed = true;
      expect(b.hasAirlineFilter, isTrue);
      expect(b.toJson()['filter_airlines'], ['TK']);
    });

    test('ro\'yxat yangilansa foydalanuvchi tanlovi saqlanadi', () {
      final b = body()..setFilterAirlinesFromItems(items);
      b.filterAirlines!.firstWhere((a) => a.code == 'HY').isChosed = true;
      b.setFilterAirlinesFromItems([
        ...items,
        FilterAirLineItemsModel(id: 3, code: 'SU', title: 'Aeroflot'),
      ]);
      expect(b.toJson()['filter_airlines'], ['HY']);
    });

    test('standart filtrlar aviakompaniya tanlovini tozalaydi', () {
      final b = body()..setFilterAirlinesFromItems(items);
      b.filterAirlines!.first.isChosed = true;
      b.setDefaultFilterParams();
      expect(b.toJson()['filter_airlines'], isEmpty);
    });
  });

  group('TicketCubit.resolveNoResultsOutcome', () {
    TicketNoResultsOutcome resolve({
      bool anyEmpty = false,
      bool hasError = false,
      bool hasTransientError = false,
      bool hasUnexpectedError = false,
    }) =>
        TicketCubit.resolveNoResultsOutcome(
          anyEmpty: anyEmpty,
          hasError: hasError || hasTransientError,
          hasTransientError: hasTransientError,
          hasUnexpectedError: hasUnexpectedError,
        );

    test('bir manba bo\'sh, boshqasi timeout — xato (qayta urinish)', () {
      expect(resolve(anyEmpty: true, hasTransientError: true),
          TicketNoResultsOutcome.error);
    });

    test('bir manba bo\'sh, boshqasi biznes/4xx xato — "topilmadi"', () {
      expect(resolve(anyEmpty: true, hasError: true),
          TicketNoResultsOutcome.empty);
    });

    test('barcha manbalar bo\'sh — "topilmadi"', () {
      expect(resolve(anyEmpty: true), TicketNoResultsOutcome.empty);
    });

    test('faqat xatolar — xato', () {
      expect(resolve(hasError: true), TicketNoResultsOutcome.error);
      expect(resolve(hasTransientError: true), TicketNoResultsOutcome.error);
    });

    test('kutilmagan istisno — umumiy xato', () {
      expect(resolve(hasUnexpectedError: true),
          TicketNoResultsOutcome.unexpectedError);
    });

    test('hech narsa yo\'q — "topilmadi"', () {
      expect(resolve(), TicketNoResultsOutcome.empty);
    });
  });

  group('TicketCubit.isTransientSearchError', () {
    test('timeout, ulanish va 5xx — vaqtinchalik', () {
      for (final type in [
        ErrorType.connectTimeout,
        ErrorType.receiveTimeout,
        ErrorType.sendTimeout,
        ErrorType.connectionError,
        ErrorType.dio_error,
        ErrorType.internalServer_500,
        ErrorType.badGateway_502,
        ErrorType.serviceUnavailable_503,
        ErrorType.gatewayTimeout_504,
        ErrorType.serverError_5xx,
      ]) {
        expect(TicketCubit.isTransientSearchError(type), isTrue,
            reason: '$type');
      }
    });

    test('4xx, bo\'sh javob va noma\'lum — vaqtinchalik emas', () {
      for (final type in [
        null,
        ErrorType.badResponse_400,
        ErrorType.unAuthorized_401,
        ErrorType.forbidden_403,
        ErrorType.notFound_404,
        ErrorType.conflict_409,
        ErrorType.emptyResponse,
        ErrorType.other,
      ]) {
        expect(TicketCubit.isTransientSearchError(type), isFalse,
            reason: '$type');
      }
    });
  });
}
