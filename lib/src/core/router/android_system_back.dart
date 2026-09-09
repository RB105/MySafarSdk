import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;

/// Android 16 (targetSdk 36) da tizim back'ini FAQAT `OnBackInvokedDispatcher`
/// ga ro'yxatdan o'tgan callback oladi — `Activity.onBackPressed()`
/// chaqirilmaydi va `KeyEvent.KEYCODE_BACK` yuborilmaydi.
///
/// Flutter o'z callback'ini faqat `FlutterActivity` ichida ro'yxatdan
/// o'tkazadi. Host app boshqa Activity ishlatsa hech kim ro'yxatdan o'tmaydi
/// va tizim back'ni o'zi ushlab, SDK ekrani ochiq bo'lsa ham task'ni orqa
/// fonga suradi. Bunga Dart tomondan ta'sir qilib bo'lmaydi — shuning uchun
/// SDK'ning Android moduli embed ochiq ekan o'z callback'ini o'zi
/// ro'yxatdan o'tkazadi (`MySafarBackPlugin`).
///
/// Native callback event'ni o'zi qayta ishlamaydi: uni shu yerga uzatadi va
/// bu klass event'ni `flutter/backgesture` kanaliga xuddi engine yuborgandek
/// qayta kiritadi. Shu sababli Flutter'ning odatdagi back mexanizmi —
/// `PopScope`, `didPopRoute`, predictive back animatsiyalari, [MySafarEmbed]
/// ning `SdkEmbedBackHandler`i — o'zgarishsiz ishlaydi.
class AndroidSystemBack {
  const AndroidSystemBack._();

  static const MethodChannel _channel =
      MethodChannel('mysafar_sdk/android_back');

  /// Engine back event'larni shu kanalga yuboradi; biz ham shu yerga
  /// kiritamiz.
  static const String _frameworkBackGestureChannel = 'flutter/backgesture';

  static const MethodCodec _codec = StandardMethodCodec();

  static bool _listening = false;

  /// Native callback ro'yxatdan o'tganmi. `false` bo'lsa SDK Flutter'ning
  /// o'z yo'liga (`setFrameworkHandlesBack`) tayanadi.
  static bool get isActive => _active;
  static bool _active = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Embed ochilganda chaqiriladi. Native tomon ro'yxatdan o'tsa `true`.
  static Future<bool> enable() async {
    if (!_supported) return false;
    if (!_listening) {
      _channel.setMethodCallHandler(_handleNativeBackEvent);
      _listening = true;
    }
    try {
      _active = await _channel.invokeMethod<bool>('enable') ?? false;
    } on MissingPluginException {
      // SDK'ning Android moduli ulanmagan (eski host build'i) — Flutter'ning
      // o'z back yo'li ishlatiladi.
      _active = false;
    } on PlatformException {
      _active = false;
    }
    MySafarSdk.logBack('AndroidSystemBack.enable -> $_active');
    return _active;
  }

  /// Embed yopilganda chaqiriladi — host o'z back siyosatiga qaytadi.
  static Future<void> disable() async {
    if (!_supported) return;
    _active = false;
    try {
      await _channel.invokeMethod<bool>('disable');
    } on MissingPluginException {
      // Yuqoridagi bilan bir xil — e'tiborsiz.
    } on PlatformException {
      // Activity allaqachon yo'q.
    }
    MySafarSdk.logBack('AndroidSystemBack.disable');
  }

  /// Framework'ga xabar kiritish yo'li. Productionda `channelBuffers.push` —
  /// engine back event'larni aynan shu yo'l bilan yetkazadi. Testda
  /// `TestDefaultBinaryMessenger` ga yo'naltiriladi, chunki u
  /// `channelBuffers` ni chetlab o'tadi.
  @visibleForTesting
  static void Function(String channel, ByteData message) dispatchToFramework =
      pushToChannelBuffers;

  /// [dispatchToFramework] ning production qiymati.
  @visibleForTesting
  static void pushToChannelBuffers(String channel, ByteData message) {
    ServicesBinding.instance.channelBuffers.push(
      channel,
      message,
      (ByteData? _) {},
    );
  }

  /// Test uchun: native tomon yuboradigan event'ni qo'lda kiritadi.
  @visibleForTesting
  static Future<void> debugDispatchNativeBackEvent(MethodCall call) =>
      _handleNativeBackEvent(call);

  /// Native'dan kelgan back event'ni framework'ning back kanaliga kiritadi.
  static Future<void> _handleNativeBackEvent(MethodCall call) async {
    MySafarSdk.logBack('native ${call.method}');
    final message = _codec.encodeMethodCall(
      MethodCall(call.method, _normalizeArguments(call.arguments)),
    );
    dispatchToFramework(_frameworkBackGestureChannel, message);
  }

  /// Native tomon `progress` ni `Float` sifatida beradi; framework
  /// `PredictiveBackEvent.fromMap` da `double` kutadi.
  static Object? _normalizeArguments(Object? arguments) {
    if (arguments is! Map) return arguments;
    final touchOffset = arguments['touchOffset'];
    return <String, Object?>{
      'touchOffset': touchOffset is List
          ? touchOffset.map((v) => (v as num).toDouble()).toList()
          : null,
      'progress': (arguments['progress'] as num?)?.toDouble() ?? 0.0,
      'swipeEdge': (arguments['swipeEdge'] as num?)?.toInt() ?? 0,
    };
  }
}
