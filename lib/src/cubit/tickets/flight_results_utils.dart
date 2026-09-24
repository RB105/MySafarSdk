import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;

/// Qidiruv natijalari bilan ishlovchi sof (UI'siz) yordamchilar: manbalar
/// orasida takroriy reyslarni olib tashlash va qayta hisoblashni keshlash.
class FlightResultsUtils {
  FlightResultsUtils._();

  /// Ikki manbadagi bir xil taklifni aniqlash uchun barqaror kalit.
  ///
  /// Ehtiyotkorlik bilan: faqat HAMMA segmentlari bir xil bo'lgan takliflar
  /// teng hisoblanadi — aviakompaniya, reys raqami, jo'nash/qo'nish aeroporti,
  /// sana va vaqti, tarif kodi (fare basis), xizmat klassi, bagaj va
  /// qaytarish/almashtirish shartlari. Shartlardan biri farq qilsa (masalan
  /// bagajli va bagajsiz tarif) — bu ALOHIDA taklif, birlashtirilmaydi.
  /// Segmentlari bo'lmagan reys uchun `null` (hech narsa bilan birlashmaydi).
  static String? dedupeKey(FlightElement f) {
    final segs = f.segments;
    if (segs == null || segs.isEmpty) return null;
    final b = StringBuffer()
      ..write(f.isBaggage == true ? 'B' : '-')
      ..write(f.isRefund == true ? 'R' : '-')
      ..write('|${f.tariffClass ?? ''}|${f.fareFamilyMarketingName ?? ''}|');
    for (final dir in f.segmentsDirection ?? const <List<int>>[]) {
      b.write('${dir.join(',')};');
    }
    for (final s in segs) {
      b
        ..write('#')
        ..write(s.carrier.code)
        ..write(s.flightNumber)
        ..write('/')
        ..write(s.dep.airport?.code ?? '')
        ..write(s.dep.date ?? '')
        ..write(s.dep.time ?? '')
        ..write('/')
        ..write(s.arr.airport?.code ?? '')
        ..write(s.arr.date ?? '')
        ..write(s.arr.time ?? '')
        ..write('/')
        ..write(s.fareCode)
        ..write('/')
        ..write(s.segmentClass.typeId)
        ..write(s.segmentClass.service)
        ..write('/')
        ..write(s.baggage.piece)
        ..write('x')
        ..write(s.baggage.weight)
        ..write(s.isRefund ? 'R' : '-')
        ..write(s.isChange ? 'C' : '-');
    }
    return b.toString();
  }

  /// [base] reyslari ustiga [extra] reyslarini qo'shadi (YANGI ro'yxat):
  /// • id bo'yicha takrorlar tashlanadi (avvalgidek);
  /// • [dedupeKey] bo'yicha bir xil taklif ikkinchi manbadan kelsa — faqat
  ///   eng arzoni qoladi. Arzonroq bo'lsa, eskisining O'RNIGA qo'yiladi
  ///   (tartib saqlanadi); aks holda yangisi tashlanadi.
  static List<FlightElement> mergeDedupe(
    List<FlightElement> base,
    List<FlightElement> extra,
  ) {
    final result = <FlightElement>[...base];
    final seenIds = <String>{for (final f in base) f.id};
    final indexByKey = <String, int>{};
    for (int i = 0; i < result.length; i++) {
      final key = dedupeKey(result[i]);
      // Bitta manba ichidagi takrorlar bilan ishlamaymiz — birinchisi kalit.
      if (key != null) indexByKey.putIfAbsent(key, () => i);
    }

    for (final flight in extra) {
      if (!seenIds.add(flight.id)) continue;
      final key = dedupeKey(flight);
      final existingIndex = key == null ? null : indexByKey[key];
      if (existingIndex == null) {
        if (key != null) indexByKey[key] = result.length;
        result.add(flight);
        continue;
      }
      if (flight.sortPrice < result[existingIndex].sortPrice) {
        result[existingIndex] = flight;
      }
    }
    return result;
  }

  /// [previous] → [current] o'tishida arzonroq dublikat bilan ALMASHTIRILGAN
  /// reyslar: `yangi id → eski id`. Eski reys yangi ro'yxatda yo'q, yangisi
  /// esa oldin yo'q edi va ikkalasining [dedupeKey] bir xil ([mergeDedupe]
  /// aynan shunday almashtiradi). Karta o'z o'rni va kalitini saqlashi uchun.
  static Map<String, String> replacedIds(
    List<FlightElement> previous,
    List<FlightElement> current,
  ) {
    final currentIds = <String>{for (final f in current) f.id};
    final goneByKey = <String, String>{};
    for (final f in previous) {
      if (currentIds.contains(f.id)) continue;
      final key = dedupeKey(f);
      if (key != null) goneByKey.putIfAbsent(key, () => f.id);
    }
    if (goneByKey.isEmpty) return const <String, String>{};
    final previousIds = <String>{for (final f in previous) f.id};
    final result = <String, String>{};
    for (final f in current) {
      if (previousIds.contains(f.id)) continue;
      final key = dedupeKey(f);
      if (key == null) continue;
      final oldId = goneByKey.remove(key);
      if (oldId != null) result[f.id] = oldId;
    }
    return result;
  }

  /// Dedupe'dan keyin HAQIQATAN yangi reys qo'shildimi: [previous]da id'si
  /// yo'q va eski kartani almashtirmagan reys bormi. Merge har doim yangi
  /// obyekt qaytaradi — shuning uchun obyekt emas, reyslar solishtiriladi
  /// ("Yangi reyslar" tugmasi yangi reys bo'lmasa chiqmasin, №86).
  static bool hasNewFlights(
    List<FlightElement> previous,
    List<FlightElement> current,
  ) {
    final previousIds = <String>{for (final f in previous) f.id};
    final added = [
      for (final f in current)
        if (!previousIds.contains(f.id)) f
    ];
    if (added.isEmpty) return false;
    final replaced = replacedIds(previous, current);
    return added.any((f) => !replaced.containsKey(f.id));
  }

  /// Barqaror saralash (teng kalitlarda kirish tartibi saqlanadi). Har bir
  /// reys kaliti faqat BIR marta hisoblanadi (taqqoslash ichida emas).
  static List<FlightElement> stableSort(
    List<FlightElement> flights,
    double Function(FlightElement) keyOf,
  ) {
    final keys = <double>[for (final f in flights) keyOf(f)];
    final order = List<int>.generate(flights.length, (i) => i);
    order.sort((a, b) {
      final c = keys[a].compareTo(keys[b]);
      return c != 0 ? c : a.compareTo(b);
    });
    return [for (final i in order) flights[i]];
  }
}

/// Oxirgi hisoblangan natijani keshlaydi: kirish ro'yxati AYNAN o'sha obyekt
/// (identical) va [variant] (saralash rejimi, filtr versiyasi) o'zgarmagan
/// bo'lsa — qayta hisoblamaydi. Natijalar sahifasi har rebuild'da (indikator,
/// taymer, valyuta va h.k.) butun ro'yxatni qayta saralab/guruhlamasligi uchun.
class ListResultMemo<T> {
  Object? _source;
  Object? _variant;
  T? _value;
  bool _has = false;

  T get(List<Object?> source, Object? variant, T Function() compute) {
    if (_has && identical(source, _source) && variant == _variant) {
      return _value as T;
    }
    final value = compute();
    _source = source;
    _variant = variant;
    _value = value;
    _has = true;
    return value;
  }
}
