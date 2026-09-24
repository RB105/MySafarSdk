import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/model/remote/profile/cheque_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/order_status_classifier.dart';
import 'package:mysafar_sdk/src/service/payment/card_token_encoder.dart';
import 'package:mysafar_sdk/src/service/payment/sensitive_log.dart';
import 'package:mysafar_sdk/src/view/profile/src/expire_time_widget.dart';

void main() {
  group('OrderStatusClassifier (№58/№59)', () {
    test('paid family goes to "paid" tab, case/format insensitive', () {
      for (final s in [
        'Paid',
        'Ticketed',
        'ticketed',
        'PartiallyTicketed',
        'TicketedWaitingPNR',
        'ticketed_waiting_pnr',
        'PartlyTicketedWaitingPNR',
      ]) {
        expect(OrderStatusClassifier.isPaid(s), isTrue, reason: s);
      }
      for (final s in [
        'Booked',
        'AwaitPayment',
        'Cancelled',
        'Refunded',
        '',
        null,
        'Unknown',
      ]) {
        expect(OrderStatusClassifier.isPaid(s), isFalse, reason: '$s');
      }
    });

    test('download only when ticket issued AND url present', () {
      const url = 'https://x/ticket.pdf';
      expect(OrderStatusClassifier.canDownloadTicket('Ticketed', url), isTrue);
      expect(OrderStatusClassifier.canDownloadTicket('PartiallyTicketed', url),
          isTrue);
      expect(OrderStatusClassifier.canDownloadTicket('TicketedWaitingPNR', url),
          isTrue);
      expect(OrderStatusClassifier.canDownloadTicket('Ticketed', ''), isFalse);
      expect(OrderStatusClassifier.canDownloadTicket('Ticketed', '  '), isFalse);
      expect(OrderStatusClassifier.canDownloadTicket('Paid', url), isFalse);
      expect(OrderStatusClassifier.canDownloadTicket('Booked', url), isFalse);
    });

    test('paid without ticket is "being issued"', () {
      expect(OrderStatusClassifier.isTicketPending('Paid', ''), isTrue);
      expect(OrderStatusClassifier.isTicketPending('Paid', 'https://x'), isTrue);
      expect(OrderStatusClassifier.isTicketPending('Ticketed', null), isTrue);
      expect(
          OrderStatusClassifier.isTicketPending('Ticketed', 'https://x'), isFalse);
      expect(OrderStatusClassifier.isTicketPending('Booked', ''), isFalse);
    });

    test('awaiting payment', () {
      expect(OrderStatusClassifier.isAwaitingPayment('Booked'), isTrue);
      expect(OrderStatusClassifier.isAwaitingPayment('booked'), isTrue);
      expect(OrderStatusClassifier.isAwaitingPayment('Paid'), isFalse);
    });
  });

  group('CardTokenEncoder.appendQueryParam (№64)', () {
    test('keeps signed query bytes intact', () {
      const url =
          'https://pay.example.uz/p?trid=1%7e2&sign=a|b+c&x=%2F&billing_id=9';
      final out = CardTokenEncoder.appendQueryParam(url, 'card_token', 'tok');
      expect(out, '$url&card_token=tok');
      // Uri.replace would have rewritten it — the reason for this helper.
      final viaUri = Uri.parse(url).replace(queryParameters: {
        ...Uri.parse(url).queryParametersAll,
        'card_token': 'tok',
      }).toString();
      expect(viaUri.startsWith(url), isFalse);
    });

    test('no query / trailing ? / trailing & / fragment', () {
      expect(CardTokenEncoder.appendQueryParam('https://a/p', 'k', 'v'),
          'https://a/p?k=v');
      expect(CardTokenEncoder.appendQueryParam('https://a/p?', 'k', 'v'),
          'https://a/p?k=v');
      expect(CardTokenEncoder.appendQueryParam('https://a/p?x=1&', 'k', 'v'),
          'https://a/p?x=1&k=v');
      expect(CardTokenEncoder.appendQueryParam('https://a/p?x=1#top', 'k', 'v'),
          'https://a/p?x=1&k=v#top');
    });

    test('encodes only the new value', () {
      expect(
          CardTokenEncoder.appendQueryParam('https://a/p?x=|', 'k', 'a b+c/='),
          'https://a/p?x=|&k=a+b%2Bc%2F%3D');
      // base64url token is left as-is.
      expect(CardTokenEncoder.appendQueryParam('https://a/p', 'k', 'Ab-_09'),
          'https://a/p?k=Ab-_09');
    });
  });

  group('ExpireTimeText.remainingSecondsAt (№88)', () {
    final created = DateTime(2026, 1, 1, 12, 0, 0);
    test('computed from createdAt, not decremented', () {
      expect(ExpireTimeText.remainingSecondsAt(created, created), 1800);
      expect(
          ExpireTimeText.remainingSecondsAt(
              created, created.add(const Duration(minutes: 10))),
          1200);
      // App was in background 25 minutes — no lag.
      expect(
          ExpireTimeText.remainingSecondsAt(
              created, created.add(const Duration(minutes: 25, seconds: 1))),
          299);
    });
    test('clamped at zero; null date is expired', () {
      expect(
          ExpireTimeText.remainingSecondsAt(
              created, created.add(const Duration(hours: 2))),
          0);
      expect(ExpireTimeText.remainingSecondsAt(null, created), 0);
    });
  });

  group('ChequeModel safe parsing (№89)', () {
    test('num / string / null amounts and bad dates do not throw', () {
      final c = ChequeModel.fromJson({
        'qr_url': 'https://q',
        'amount': 12500.0,
        'currency': '860',
        'created_at': null,
        'order_number': 123,
        'status': 1,
      });
      expect(c.amount, 12500);
      expect(c.currency, 860);
      expect(c.createdAt, isNull);
      expect(c.orderNumber, '123');
      expect(c.status, isTrue);

      final d = ChequeModel.fromJson({
        'amount': '12 500',
        'created_at': 'not-a-date',
      });
      expect(d.amount, 12500);
      expect(d.currency, 860);
      expect(d.createdAt, isNull);
      expect(d.status, isFalse);
      expect(d.toJson()['created_at'], isNull);
    });

    test('valid date parses', () {
      final c = ChequeModel.fromJson({'created_at': '2026-03-01T10:00:00'});
      expect(c.createdAt, DateTime(2026, 3, 1, 10));
    });

    test('toInt helper', () {
      expect(ChequeModel.toInt(null), isNull);
      expect(ChequeModel.toInt(''), isNull);
      expect(ChequeModel.toInt('abc'), isNull);
      expect(ChequeModel.toInt(double.nan), isNull);
      expect(ChequeModel.toInt(7), 7);
      expect(ChequeModel.toInt(7.6), 8);
      expect(ChequeModel.toInt('1 000'), 1000);
    });
  });

  group('SensitiveLog masking (№63)', () {
    test('maskTail keeps only last 4', () {
      expect(SensitiveLog.maskTail('8600123412345678'), '************5678');
      expect(SensitiveLog.maskTail('12345678'), '********');
      expect(SensitiveLog.maskTail(null), '');
    });
    test('hide keeps only length', () {
      expect(SensitiveLog.hide('2812'), '****');
      expect(SensitiveLog.hide(''), '');
    });
  });
}
