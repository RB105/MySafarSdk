import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_draft_store.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/model/remote/profile/order_status_classifier.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart';

/// To'lov muddati o'tgan buyurtmani qayta bron qilish: o'sha yo'nalish va
/// sanalar bo'yicha qidiruv ochiladi, yo'lovchilar formasi esa buyurtmadagi
/// ma'lumotlar bilan to'ldirilgan bo'ladi ([PassengerDraftStore] orqali).
class OrderRebook {
  OrderRebook._();

  /// Server to'lanmagan bronni vaqt o'tgach bekor qilishi mumkin.
  static const String _cancelledStatus = 'cancelled';

  /// To'lov vaqti tugagan (yoki to'lanmay bekor qilingan), lekin parvoz
  /// sanasi hali kelmagan buyurtma.
  static bool canRebook(ConfirmedTicketsModel order) {
    final status = order.orderStatus;
    final book = order.response?.data?.book;
    final bool unpaidExpired = OrderStatusClassifier.isAwaitingPayment(status)
        ? !ElementFormatter.expireStatus(order.createdAt ?? '')
        : status.toLowerCase() == _cancelledStatus &&
            (book?.payedData ?? '').trim().isEmpty;
    if (!unpaidExpired) return false;
    final departure = _firstDeparture(book);
    if (departure == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !departure.isBefore(today) && requestFor(book) != null;
  }

  /// Qidiruv natijalarini ochadi va yo'lovchilar qoralamasini yozadi.
  static void open(BuildContext context, ConfirmedTicketsModel order) {
    final book = order.response?.data?.book;
    final request = requestFor(book);
    if (request == null) return;

    final passengers = passengersFor(book);
    if (passengers.isNotEmpty) {
      final first = book?.passengers?.firstOrNull;
      PassengerDraftStore.write(
        PassengerDraftStore.keyFor(request.adt, request.chd, request.inf),
        PassengerDraft(
          passengers: passengers,
          email: (first?.email ?? '').trim(),
          phone: normalizePhoneDigits(first?.phone ?? ''),
          saveToProfile: const {},
        ),
      );
    }

    ProjectUtils.setRecommendationParams(request);
    Navigator.of(context)
        .pushNamed(RecommendationsTicketPage.routeName, arguments: request);
  }

  /// Buyurtma segmentlaridan qidiruv so'rovi: har bir yo'nalish (direction)
  /// — bitta qidiruv segmenti (birinchi uchishdan oxirgi qo'nishgacha).
  static RecommendationRequestBody? requestFor(Book? book) {
    final legs = _legs(book);
    if (legs.isEmpty) return null;

    final segments = <RecommendationReqBodySegment>[];
    for (final leg in legs) {
      final from = _cityCode(leg.first.dep);
      final to = _cityCode(leg.last.arr);
      final date =
          RecommendationRequestBody.normalizeSegmentDate(leg.first.dep?.date);
      if (from.isEmpty || to.isEmpty || date.isEmpty) return null;
      segments.add(RecommendationReqBodySegment(
        from: _airport(leg.first.dep, from),
        to: _airport(leg.last.arr, to),
        date: date,
      ));
    }

    int count(String age) => (book?.passengers ?? const <Passenger>[])
        .where((p) => (p.age ?? '').toLowerCase() == age)
        .length;
    final adt = count(PassengerConstants.ageAdult);
    if (adt == 0) return null;

    return RecommendationRequestBody(
      adt: adt,
      chd: count(PassengerConstants.ageChild),
      inf: count(PassengerConstants.ageInfant),
      segments: segments,
      klass: _klass(book),
      isDirectOnly: 0,
      flight_Type: RecommendationRequestBody.flightTypeOf(segments),
    );
  }

  /// Yo'lovchilar forma tartibida (kattalar, bolalar, chaqaloqlar) —
  /// `PassengerCubit` yosh toifasini indeks bo'yicha beradi.
  static List<PassengerModel> passengersFor(Book? book) {
    const order = [
      PassengerConstants.ageAdult,
      PassengerConstants.ageChild,
      PassengerConstants.ageInfant,
    ];
    final list = [...?book?.passengers]..sort((a, b) {
        int rank(Passenger p) {
          final i = order.indexOf((p.age ?? '').toLowerCase());
          return i < 0 ? order.length : i;
        }

        return rank(a).compareTo(rank(b));
      });
    return [for (final p in list) _toModel(p)];
  }

  static PassengerModel _toModel(Passenger p) {
    final citizen = (p.citizenship ?? '').trim().toUpperCase();
    final expire = p.document?.expire;
    final model = PassengerModel(
      firstname: PassengerRules.normalizeName(p.name?.first),
      lastname: PassengerRules.normalizeName(p.name?.last),
      middlename: PassengerRules.normalizeName(p.name?.middle),
      age: (p.age ?? PassengerConstants.ageAdult).toLowerCase(),
      birthdate: PassengerRules.toFormDate(p.birthdate),
      docnum: _docnum(p.document),
      docexp: expire == null ? '' : PassengerRules.formatFormDate(expire),
      gender: _gender(p.gender),
      citizen: citizen,
    );
    // Hujjat turi qo'lda kiritishdagi qoida bilan fuqarolikdan olinadi.
    return citizen.isEmpty ? model : model.copyWithCitizen(citizen);
  }

  /// Server raqamni yashirgan bo'lsa ("AA***4567") — bo'sh qoldiriladi,
  /// aks holda noto'g'ri raqam jimgina formaga tushardi.
  static String _docnum(PassengerDocument? doc) {
    for (final raw in [doc?.originalNumber, doc?.num]) {
      final value = (raw ?? '').trim();
      if (value.isEmpty) continue;
      if (value.contains('*')) return '';
      return PassengerRules.normalizeDocnum(value);
    }
    return '';
  }

  static String _gender(String? raw) {
    final g = (raw ?? '').trim().toUpperCase();
    if (g.startsWith('M')) return PassengerConstants.genderMale;
    if (g.startsWith('F') || g.startsWith('W')) {
      return PassengerConstants.genderFemale;
    }
    return '';
  }

  static List<List<ConfirmedTicketSegment>> _legs(Book? book) {
    final legs = <int, List<ConfirmedTicketSegment>>{};
    for (final s
        in book?.flight?.segments ?? const <ConfirmedTicketSegment>[]) {
      legs.putIfAbsent(s.direction ?? 0, () => []).add(s);
    }
    final keys = legs.keys.toList()..sort();
    return [for (final k in keys) legs[k]!];
  }

  static DateTime? _firstDeparture(Book? book) {
    final legs = _legs(book);
    if (legs.isEmpty) return null;
    return RecommendationRequestBody.parseSegmentDate(
        legs.first.first.dep?.date);
  }

  static String _cityCode(ConfirmedTicketArr? point) {
    final city = (point?.city?.code ?? '').trim();
    if (city.isNotEmpty) return city.toUpperCase();
    return (point?.airport?.code ?? '').trim().toUpperCase();
  }

  static AirPortsModel _airport(ConfirmedTicketArr? point, String code) =>
      AirPortsModel(
        cityIataCode: code,
        cityName: point?.city?.title ?? point?.airport?.title ?? code,
        countryIataCode: point?.country?.code ?? '',
        countryName: point?.country?.title ?? '',
      );

  /// Buyurtmadagi klass (e/b/f/w); noma'lum bo'lsa barcha klasslar.
  static String _klass(Book? book) {
    const known = {'e', 'b', 'f', 'w'};
    for (final s
        in book?.flight?.segments ?? const <ConfirmedTicketSegment>[]) {
      for (final p in s.parametersForEachPassenger ?? const []) {
        final code = (p.flightClass?.code ?? '').trim().toLowerCase();
        if (known.contains(code)) return code;
      }
    }
    return 'a';
  }
}
