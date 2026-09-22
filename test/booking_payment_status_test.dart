import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/cubit/booking/confirm/booking_confirm_states.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_payment_status.dart';

Map<String, dynamic> _ticketData(
  String sign, {
  String? callback,
  String? receipt,
  bool priceChanged = false,
  num total = 1206994,
}) =>
    {
      if (callback != null) 'callback_status': callback,
      'data': {
        'book': {
          'order': {
            'status': {'sign': sign, 'title': sign},
            'billing_number': 125357974025,
            'price': {
              'UZS': {'amount': total}
            },
          },
          'tickets': [
            {
              'provider': {'currency': 'UZS'},
              'documents': {'ticket_receipt': receipt},
            }
          ],
          'is_price_changed': priceChanged,
          'is_search_price_changed': false,
          'agent_mode_prices': {'total_amount_for_active_agent_mode': total},
        }
      },
    };

BookingPaymentStatus _status(BookingPaymentState state) =>
    BookingPaymentStatus(state: state, sign: state.name);

void main() {
  group('BookingPaymentStatus.stateOf', () {
    test('to\'langan holatlar', () {
      for (final s in [
        'Paid',
        'Ticketed',
        'ticketed',
        'PartiallyTicketed',
        'TicketedWaitingPNR',
        'partly_ticketed_waiting_pnr',
      ]) {
        expect(BookingPaymentStatus.stateOf(s), BookingPaymentState.paid,
            reason: s);
      }
    });

    test('Booked — to\'lanmagan, Cancelled — muvaffaqiyatsiz', () {
      expect(BookingPaymentStatus.stateOf('Booked'), BookingPaymentState.unpaid);
      expect(
          BookingPaymentStatus.stateOf('CANCELED'), BookingPaymentState.failed);
      expect(
          BookingPaymentStatus.stateOf('Cancelled'), BookingPaymentState.failed);
    });

    test('noma\'lum / bo\'sh / AwaitPayment — pending', () {
      expect(BookingPaymentStatus.stateOf('AwaitPayment'),
          BookingPaymentState.pending);
      expect(BookingPaymentStatus.stateOf(''), BookingPaymentState.pending);
      expect(BookingPaymentStatus.stateOf(null), BookingPaymentState.pending);
    });
  });

  group('BookingPaymentStatus.fromTicketData', () {
    test('Ticketed — chipta havolasi, billing va valyuta bilan', () {
      final status = BookingPaymentStatus.fromTicketData(
          _ticketData('Ticketed', receipt: 'https://x.uz/eticket.pdf'));
      expect(status.isPaid, isTrue);
      expect(status.ticketReceiptUrl, 'https://x.uz/eticket.pdf');
      expect(status.billingNumber, '125357974025');
      expect(status.currency, 'UZS');
      expect(status.changedTotal, isNull);
      expect(status.ticketPdfArguments?['data']['book'], isNotNull);
    });

    test('callback_status to\'langan desa, order hali Booked bo\'lsa ham', () {
      final status = BookingPaymentStatus.fromTicketData(
          _ticketData('Booked', callback: 'Ticketed'));
      expect(status.state, BookingPaymentState.paid);
    });

    test('Booked — to\'lanmagan', () {
      final status = BookingPaymentStatus.fromTicketData(_ticketData('Booked'));
      expect(status.state, BookingPaymentState.unpaid);
      expect(status.sign, 'Booked');
    });

    test('narx o\'zgargani faqat bayroq bo\'lsa olinadi', () {
      final status = BookingPaymentStatus.fromTicketData(
          _ticketData('Booked', priceChanged: true, total: 1300000));
      expect(status.changedTotal, 1300000);
    });

    test('shakli boshqacha javob yiqitmaydi — pending', () {
      for (final json in [
        null,
        'error',
        <dynamic>[],
        <String, dynamic>{},
        {'data': 'x'},
        {
          'data': {
            'book': {'order': 'x', 'tickets': 'y'}
          }
        },
      ]) {
        final status = BookingPaymentStatus.fromTicketData(json);
        expect(status.state, BookingPaymentState.pending, reason: '$json');
        expect(status.isPaid, isFalse);
      }
    });

    test('haqiqiy namuna (respons_data.json)', () {
      final raw = jsonDecode(
          File('lib/src/view/booking/respons_data.json').readAsStringSync());
      final record = (raw['result'] as List).first as Map<String, dynamic>;

      // Hamkor javobi: order.status.sign = Booked.
      final partner = BookingPaymentStatus.fromTicketData(record['response']);
      expect(partner.state, BookingPaymentState.unpaid);
      expect(partner.ticketReceiptUrl, contains('eticket_125357974025'));
      expect(partner.currency, 'UZS');

      // Buyurtma yozuvi: callback_status = Cancelled ustun.
      final order = BookingPaymentStatus.fromTicketData(record);
      expect(order.state, BookingPaymentState.failed);
    });
  });

  group('BookingDisplayAmount.resolve', () {
    test('bron summasi va valyutasi (qidiruv narxi emas)', () {
      final r = BookingDisplayAmount.resolve(
        bookingAmount: 1243204,
        bookingCurrency: 'RUB',
      );
      expect(r?.amount, 1243204);
      expect(r?.currency, 'RUB');
    });

    test('summa matn ko\'rinishida ham o\'qiladi', () {
      final r = BookingDisplayAmount.resolve(
        bookingAmount: '1 243 204',
        bookingCurrency: 'UZS',
      );
      expect(r?.amount, 1243204);
    });

    test('backend narx o\'zgarganini bildirsa — yangi jami summa', () {
      final r = BookingDisplayAmount.resolve(
        bookingAmount: 1000000,
        bookingCurrency: 'UZS',
        ticketData: BookingPaymentStatus.fromTicketData(
            _ticketData('Booked', priceChanged: true, total: 1300000)),
      );
      expect(r?.amount, 1300000);
      expect(r?.currency, 'UZS');
    });

    test('bayroq bor, lekin summa bir xil — bron summasi', () {
      final r = BookingDisplayAmount.resolve(
        bookingAmount: 1300000,
        bookingCurrency: 'RUB',
        ticketData: BookingPaymentStatus.fromTicketData(
            _ticketData('Booked', priceChanged: true, total: 1300000)),
      );
      expect(r?.currency, 'RUB');
    });

    test('summa yoki valyuta noma\'lum — null (sahifa narxi ishlatiladi)', () {
      expect(
          BookingDisplayAmount.resolve(bookingAmount: null, bookingCurrency: 'UZS'),
          isNull);
      expect(
          BookingDisplayAmount.resolve(bookingAmount: 1000, bookingCurrency: null),
          isNull);
      expect(
          BookingDisplayAmount.resolve(bookingAmount: 0, bookingCurrency: 'UZS'),
          isNull);
    });
  });

  group('BookingCreateModel', () {
    test('valyuta kodi → belgi', () {
      expect(BookingCreateModel.currencyLabelFor(860), 'UZS');
      expect(BookingCreateModel.currencyLabelFor(643), 'RUB');
      expect(BookingCreateModel.currencyLabelFor(840), 'USD');
      expect(BookingCreateModel.currencyLabelFor(null), isNull);
      expect(BookingCreateModel.currencyLabelFor(999), isNull);
    });

    test('fromJson: matn valyuta, billing_id yo\'q', () {
      final model = BookingCreateModel.fromJson({
        'tr_id': 'abc',
        'amount': 1243204,
        'currency': '643',
      });
      expect(model.currencyLabel, 'RUB');
      expect(model.billingId, isNull);
      expect(model.trId, 'abc');
    });
  });

  group('BookingConfirmCubit.pollPaymentStatus', () {
    const tick = Duration(milliseconds: 1);
    final delays = List<Duration>.filled(6, tick)..[0] = Duration.zero;

    Future<({BookingPaymentState state, BookingPaymentStatus? status})> poll(
      List<BookingPaymentStatus?> responses, {
      Duration grace = const Duration(milliseconds: 3),
    }) {
      var i = 0;
      return BookingConfirmCubit.pollPaymentStatus(
        fetch: () async =>
            responses[i < responses.length ? i++ : responses.length - 1],
        delays: delays,
        unpaidGrace: grace,
      );
    }

    test('to\'langan — darhol', () async {
      var calls = 0;
      final result = await BookingConfirmCubit.pollPaymentStatus(
        fetch: () async {
          calls++;
          return _status(BookingPaymentState.paid);
        },
        delays: delays,
      );
      expect(result.state, BookingPaymentState.paid);
      expect(calls, 1);
    });

    test('avval Booked, keyin Ticketed — to\'langan', () async {
      final result = await poll([
        _status(BookingPaymentState.unpaid),
        _status(BookingPaymentState.paid),
      ]);
      expect(result.state, BookingPaymentState.paid);
    });

    test('Booked darhol "to\'lanmagan" emas — grace o\'tgach', () async {
      var calls = 0;
      final result = await BookingConfirmCubit.pollPaymentStatus(
        fetch: () async {
          calls++;
          return _status(BookingPaymentState.unpaid);
        },
        delays: delays,
        unpaidGrace: const Duration(milliseconds: 3),
      );
      expect(result.state, BookingPaymentState.unpaid);
      // 0, 1, 2, 3 ms — to'rtinchi so'rovda grace tugaydi.
      expect(calls, 4);
    });

    test('bekor qilingan — darhol muvaffaqiyatsiz', () async {
      final result = await poll([_status(BookingPaymentState.failed)]);
      expect(result.state, BookingPaymentState.failed);
    });

    test('tarmoq xatolari / AwaitPayment — pending', () async {
      expect((await poll([null])).state, BookingPaymentState.pending);
      expect((await poll([_status(BookingPaymentState.pending)])).state,
          BookingPaymentState.pending);
    });

    test('grace yetmasa ham oxirgi javob Booked — to\'lanmagan', () async {
      final result = await poll(
        [_status(BookingPaymentState.unpaid)],
        grace: const Duration(hours: 1),
      );
      expect(result.state, BookingPaymentState.unpaid);
    });

    test('bekor qilinsa (cubit yopildi) so\'rov yuborilmaydi', () async {
      var calls = 0;
      final result = await BookingConfirmCubit.pollPaymentStatus(
        fetch: () async {
          calls++;
          return null;
        },
        delays: delays,
        isCancelled: () => true,
      );
      expect(calls, 0);
      expect(result.state, BookingPaymentState.pending);
    });
  });
}
