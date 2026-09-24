import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/config/connectivity_banner.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart'
    show Result;
import 'package:mysafar_sdk/src/service/payment/payment_type_repository.dart';
import 'package:mysafar_sdk/src/service/pdf/pdf_download_service.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';
import 'package:open_filex/open_filex.dart' show ResultType;
import 'package:webview_flutter/webview_flutter.dart'
    show WebResourceErrorType;

void main() {
  group('WebViewScreen.isConnectionError (№48)', () {
    test('asosiy sahifadagi tarmoq xatolari — o\'z xato ko\'rinishi', () {
      // Android: host lookup / connect / io / timeout.
      for (final code in [-2, -6, -7, -8]) {
        expect(
          WebViewScreen.isConnectionError(
              errorCode: code, isForMainFrame: true, url: 'https://pay.uz'),
          isTrue,
          reason: '$code',
        );
      }
      // iOS: internet yo'q, taymaut, host topilmadi.
      for (final code in [-1009, -1001, -1003]) {
        expect(
          WebViewScreen.isConnectionError(
              errorCode: code, isForMainFrame: true, url: 'https://pay.uz'),
          isTrue,
          reason: '$code',
        );
      }
      expect(
        WebViewScreen.isConnectionError(
          errorCode: 0,
          isForMainFrame: true,
          errorType: WebResourceErrorType.hostLookup,
        ),
        isTrue,
      );
    });

    test('iframe, bekor qilingan navigatsiya va ilova sxemalari — yo\'q', () {
      expect(
        WebViewScreen.isConnectionError(
            errorCode: -2, isForMainFrame: false, url: 'https://acs.bank'),
        isFalse,
      );
      expect(
        WebViewScreen.isConnectionError(
            errorCode: -2, isForMainFrame: null, url: 'https://acs.bank'),
        isFalse,
      );
      // iOS NSURLErrorCancelled (redirect paytida odatiy).
      expect(
        WebViewScreen.isConnectionError(
            errorCode: -999, isForMainFrame: true, url: 'https://pay.uz'),
        isFalse,
      );
      // Android unsupported scheme — ilova tashqarida ochiladi.
      expect(
        WebViewScreen.isConnectionError(
            errorCode: -10, isForMainFrame: true, url: 'payme://pay?id=1'),
        isFalse,
      );
      expect(
        WebViewScreen.isConnectionError(
            errorCode: -2, isForMainFrame: true, url: 'click://pay'),
        isFalse,
      );
    });
  });

  group('PdfDownloadService (№30)', () {
    test('ochish natijasi: ko\'ruvchi yo\'q — noViewer, jim emas', () {
      final ok = PdfDownloadService.resultFromOpen(
          ResultType.done, 'done', '/tmp/a.pdf');
      expect(ok.isSuccess, isTrue);

      for (final type in [
        ResultType.noAppToOpen,
        ResultType.error,
        ResultType.permissionDenied,
      ]) {
        final r =
            PdfDownloadService.resultFromOpen(type, 'x', '/tmp/a.pdf');
        expect(r.isSuccess, isFalse, reason: '$type');
        expect(r.noViewer, isTrue, reason: '$type');
        expect(r.filePath, '/tmp/a.pdf');
      }

      final missing = PdfDownloadService.resultFromOpen(
          ResultType.fileNotFound, 'nf', '/tmp/a.pdf');
      expect(missing.isSuccess, isFalse);
      expect(missing.noViewer, isFalse);
    });

    test('fayl nomi xavfsiz qilinadi', () {
      expect(PdfDownloadService.safeFileNameForTest('12345'), '12345');
      expect(PdfDownloadService.safeFileNameForTest('a/b c:d'), 'a_b_c_d');
      expect(PdfDownloadService.safeFileNameForTest('  '), 'ticket');
    });
  });

  group('SdkConnectivityBanner.isOffline (№48)', () {
    test('faqat none — offline; bo\'sh — noma\'lum (online)', () {
      expect(SdkConnectivityBanner.isOffline([ConnectivityResult.none]),
          isTrue);
      expect(
          SdkConnectivityBanner.isOffline(
              [ConnectivityResult.none, ConnectivityResult.wifi]),
          isFalse);
      expect(SdkConnectivityBanner.isOffline([ConnectivityResult.mobile]),
          isFalse);
      expect(SdkConnectivityBanner.isOffline(const []), isFalse);
    });
  });

  group('PaymentTypeRepository (№38)', () {
    test('server natijasi config\'ga o\'giriladi, bo\'sh nomlar tashlanadi',
        () {
      final configs = PaymentTypeRepository.configsFromServer([
        Result(id: 1, name: 'payme', isActive: true),
        Result(id: 2, name: ' Click ', isActive: false),
        Result(id: 3, name: '', isActive: true),
        Result(id: 4, name: null, isActive: true),
        Result(id: 5, name: 'VISA'),
      ]);
      expect(configs.map((c) => c.name), ['PAYME', 'CLICK', 'VISA']);
      expect(configs.map((c) => c.isActive), [true, false, false]);
    });

    test('sessiya keshi boshida "yangi" emas', () {
      PaymentTypeRepository.resetForTest();
      expect(PaymentTypeRepository.isFresh, isFalse);
    });
  });
}
