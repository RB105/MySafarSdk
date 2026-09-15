import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/mrz_text_extractor.dart';
import 'package:permission_handler/permission_handler.dart';

enum _ScanDocType { passport, idCard }

/// Pasport/ID MRZ skanerini pastki sheet sifatida ochadi.
/// Muvaffaqiyatda [UsersModel] qaytaradi; yopilsa `null`.
Future<UsersModel?> showMrzScannerBottomSheet(BuildContext context) {
  // Tema jonli: showSdkModalBottomSheet ThemeNotifier tinglaydi.
  return showSdkModalBottomSheet<UsersModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _MrzScannerSheet(),
  );
}

class _MrzScannerSheet extends StatefulWidget {
  const _MrzScannerSheet();

  @override
  State<_MrzScannerSheet> createState() => _MrzScannerSheetState();
}

class _MrzScannerSheetState extends State<_MrzScannerSheet>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  _ScanDocType? _docType;
  bool _hasPermission = false;
  bool _initializing = false;
  bool _isBusy = false;
  bool _isParsed = false;
  bool _isCapturing = false;
  String? _error;
  String? _scanError;
  int _cameraSession = 0;

  /// Chiroq (torch) yoqilganmi.
  bool _torchOn = false;

  /// MRZ o'qildi — ramka yashil bo'lib, qisqa muddatdan so'ng yopiladi.
  bool _found = false;

  /// Ramka ichida yuradigan skaner chizig'i (initState'da yaratiladi —
  /// `late` bo'lsa dispose'da birinchi marta yaratilib xato beradi). Faqat
  /// kamera ko'rinib turganda aylanadi.
  late final AnimationController _scanLine;

  final _accumulatedLines = <String>{};
  Timer? _scanTimeoutTimer;
  static const _scanTimeout = Duration(seconds: 20);

  DateTime _lastProcessAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDebugAt = DateTime.fromMillisecondsSinceEpoch(0);

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    _scanTimeoutTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    _cameraSession++;
    unawaited(_tearDownController(controller));
    unawaited(_textRecognizer.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_docType == null || _isParsed) return;

    if (state == AppLifecycleState.inactive) {
      unawaited(_disposeCamera());
    } else if (state == AppLifecycleState.resumed) {
      if (_hasPermission &&
          _cameraController == null &&
          !_initializing &&
          !_isCapturing) {
        final session = _cameraSession;
        setState(() => _initializing = true);
        unawaited(_initCamera(session));
      }
    }
  }

  Future<void> _tearDownController(CameraController? controller) async {
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    } catch (_) {}
  }

  /// Preview o'chirilgach controller dispose qilinadi (race xatosiz).
  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    if (controller == null) return;

    _cameraSession++;
    _scanLine.stop();
    if (mounted) {
      setState(() => _cameraController = null);
      await WidgetsBinding.instance.endOfFrame;
    }
    await _tearDownController(controller);
  }

  Future<void> _selectDocType(_ScanDocType type) async {
    await _disposeCamera();
    if (!mounted) return;

    final session = _cameraSession;
    setState(() {
      _docType = type;
      _found = false;
      _torchOn = false;
      _initializing = true;
      _error = null;
      _scanError = null;
      _isParsed = false;
      _isBusy = false;
      _accumulatedLines.clear();
    });

    final status = await Permission.camera.request();
    if (!mounted || session != _cameraSession) return;

    if (!status.isGranted) {
      setState(() {
        _hasPermission = false;
        _initializing = false;
      });
      return;
    }

    setState(() => _hasPermission = true);
    await _initCamera(session);
  }

  Future<void> _backToDocPicker() async {
    _scanTimeoutTimer?.cancel();
    await _disposeCamera();
    if (!mounted) return;
    setState(() {
      _docType = null;
      _found = false;
      _torchOn = false;
      _initializing = false;
      _isBusy = false;
      _isParsed = false;
      _error = null;
      _scanError = null;
      _accumulatedLines.clear();
    });
  }

  void _startScanTimeout() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(_scanTimeout, () {
      if (!mounted || _isParsed || _docType == null) return;
      setState(() => _scanError = 'scan_mrz_failed'.tr());
    });
  }

  void _retryScan() {
    setState(() {
      _scanError = null;
      _accumulatedLines.clear();
      _isCapturing = false;
    });
    final controller = _cameraController;
    if (controller != null &&
        controller.value.isInitialized &&
        !controller.value.isStreamingImages) {
      unawaited(controller.startImageStream(_onCameraImage));
    }
    _startScanTimeout();
  }

  Future<void> _initCamera(int session) async {
    try {
      final cameras = await availableCameras();
      if (!mounted || session != _cameraSession) return;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted || session != _cameraSession) {
        await controller.dispose();
        return;
      }

      await controller.startImageStream(_onCameraImage);
      if (!mounted || session != _cameraSession) {
        await _tearDownController(controller);
        return;
      }

      setState(() {
        _cameraController = controller;
        _torchOn = false;
        _initializing = false;
        _error = null;
        _scanError = null;
      });
      unawaited(_scanLine.repeat(reverse: true));
      _startScanTimeout();
    } catch (e) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _initializing = false;
        _error = 'scan_camera_error'.tr();
      });
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    final controller = _cameraController;
    if (_isParsed ||
        _isBusy ||
        _isCapturing ||
        !mounted ||
        _docType == null ||
        controller == null ||
        _scanError != null) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastProcessAt).inMilliseconds < 280) return;
    _lastProcessAt = now;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    _isBusy = true;
    try {
      await _processRecognized(await _textRecognizer.processImage(inputImage));
    } catch (_) {
      // Keyingi kadrda qayta uriniladi.
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _processRecognized(RecognizedText recognized) async {
    final rawLines = <String>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        rawLines.add(line.text);
      }
    }
    if (rawLines.isEmpty) {
      rawLines.addAll(recognized.text.split(RegExp(r'[\r\n]+')));
    }

    MrzTextExtractor.accumulateRawLines(rawLines, _accumulatedLines);

    final expected = _docType == _ScanDocType.passport
        ? MrzExpectedDoc.passport
        : MrzExpectedDoc.idCard;
    final candidates = _accumulatedLines.toList();
    final shouldDebug = kDebugMode &&
        DateTime.now().difference(_lastDebugAt).inMilliseconds >= 1200;
    if (shouldDebug) {
      _lastDebugAt = DateTime.now();
      // ignore: avoid_print
      print(
        '[MRZ] expected=$expected '
        'rawLen=${recognized.text.length} '
        'candidates=${candidates.length}',
      );
    }

    var mrz = MrzTextExtractor.tryExtractFromLines(
      candidates,
      expected: expected,
    );
    mrz ??= MrzTextExtractor.tryExtract(
      recognized.text,
      expected: expected,
    );

    if (mrz == null) {
      final mismatch = MrzTextExtractor.detectMismatch(
        candidates,
        expected: expected,
      );
      if (mismatch != null && mounted) {
        _scanTimeoutTimer?.cancel();
        setState(() {
          _scanError = mismatch == MrzExpectedDoc.passport
              ? 'scan_wrong_doc_passport'.tr()
              : 'scan_wrong_doc_id'.tr();
        });
        if (kDebugMode) {
          print('[MRZ] mismatch: expected=$expected found=$mismatch');
        }
        return;
      }
      if (shouldDebug) {
        MrzTextExtractor.debugWhyFailed(
          candidates,
          expected: expected,
        );
      }
      return;
    }
    if (kDebugMode) {
      print(
        '[MRZ] OK → ${mrz.surnames} ${mrz.givenNames} '
        'doc=${mrz.documentNumber} type=${mrz.documentType}',
      );
    }
    if (!mounted || _isParsed) return;

    _scanTimeoutTimer?.cancel();
    _isParsed = true;
    final active = _cameraController;
    if (active != null && active.value.isStreamingImages) {
      await active.stopImageStream();
    }
    if (!mounted) return;

    await _finishWith(UsersModel.fromScan(mrz));
  }

  /// Muvaffaqiyat: ramka yashil, yengil tebranish, so'ng natija qaytadi.
  Future<void> _finishWith(UsersModel user) async {
    if (!mounted) return;
    _scanLine.stop();
    setState(() => _found = true);
    unawaited(HapticFeedback.mediumImpact());
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop(user);
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (_) {
      // Qurilmada chiroq yo'q — jim o'tkazamiz.
    }
  }

  /// Qo'lda suratga olish — live stream ishlamasa aniqroq o'qish uchun.
  Future<void> _captureAndProcess() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isParsed ||
        _isCapturing ||
        _docType == null) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _scanError = null;
    });

    try {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}

      final file = await controller.takePicture();
      final recognized = await _textRecognizer
          .processImage(InputImage.fromFilePath(file.path));

      final expected = _docType == _ScanDocType.passport
          ? MrzExpectedDoc.passport
          : MrzExpectedDoc.idCard;

      final rawLines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          rawLines.add(line.text);
        }
      }

      MrzTextExtractor.accumulateRawLines(rawLines, _accumulatedLines);

      var mrz = MrzTextExtractor.tryExtractFromLines(
        _accumulatedLines.toList(),
        expected: expected,
      );
      mrz ??= MrzTextExtractor.tryExtract(
        recognized.text,
        expected: expected,
      );

      if (mrz != null && mounted && !_isParsed) {
        _scanTimeoutTimer?.cancel();
        _isParsed = true;
        await _finishWith(UsersModel.fromScan(mrz));
        return;
      }

      if (mounted) {
        setState(() => _scanError = 'scan_mrz_not_found'.tr());
        if (!_isParsed) {
          await controller.startImageStream(_onCameraImage);
          _startScanTimeout();
        }
      }
    } catch (_) {
      if (mounted && !_isParsed) {
        try {
          await controller.startImageStream(_onCameraImage);
          _startScanTimeout();
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return null;

    final camera = controller.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final deviceOrientation = controller.value.deviceOrientation;
      var rotationCompensation = _orientations[deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    final bytes = _concatenatePlanes(image.planes);
    if (bytes == null) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Uint8List? _concatenatePlanes(List<Plane> planes) {
    if (planes.isEmpty) return null;
    if (planes.length == 1) return planes.first.bytes;

    final total = planes.fold<int>(0, (s, p) => s + p.bytes.length);
    final bytes = Uint8List(total);
    var offset = 0;
    for (final plane in planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return bytes;
  }

  String get _instructionKey => _docType == _ScanDocType.passport
      ? 'scan_passport_instruction'
      : 'scan_id_instruction';

  String get _hintKey =>
      _docType == _ScanDocType.passport ? 'scan_passport_hint' : 'scan_id_hint';

  /// Ramka o'lchami butun kamera maydoniga nisbatan (MRZ zonasi — keng va
  /// past to'rtburchak).
  _MrzOverlayConfig get _overlayConfig => _docType == _ScanDocType.passport
      ? const _MrzOverlayConfig(
          widthFactor: 0.9,
          heightFactor: 0.2,
          centerYFactor: 0.46,
        )
      : const _MrzOverlayConfig(
          widthFactor: 0.9,
          heightFactor: 0.24,
          centerYFactor: 0.46,
        );

  @override
  Widget build(BuildContext context) {
    if (_docType == null) return _buildDocPickerSheet(context);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: screenHeight - topInset - 8,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBody(context),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildScannerTopBar(context),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildScannerBottomBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hujjat turini tanlash ───────────────────────────────────────────

  Widget _buildDocPickerSheet(BuildContext context) {
    final isDark = context.isDarkMode;
    final muted =
        isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF5B6475);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.color.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'document_scanner'.tr(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'scan_choose_document'.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: SvgPicture.asset(
                  Assets.iconsPlaceCloseIcon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _DocTypeScanTile(
                iconAsset: Assets.iconsScanPassportIcon,
                label: 'scan_passport_option'.tr(),
                hint: 'scan_passport_picker_hint'.tr(),
                onTap: () => _selectDocType(_ScanDocType.passport),
              ),
              const SizedBox(height: 10),
              _DocTypeScanTile(
                iconAsset: Assets.iconsScanIdCardIcon,
                label: 'scan_id_card_option'.tr(),
                hint: 'scan_id_picker_hint'.tr(),
                onTap: () => _selectDocType(_ScanDocType.idCard),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: Row(
            children: [
              SvgPicture.asset(
                Assets.iconsBookingInfoIcon,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'scan_tip'.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
      ],
    );
  }

  // ── Skaner: yuqori va pastki panellar ───────────────────────────────

  Widget _buildScannerTopBar(BuildContext context) {
    final controller = _cameraController;
    final bool canTorch = controller != null && controller.value.isInitialized;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Color(0x00000000)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
        child: Row(
          children: [
            _GlassIconButton(
              iconAsset: Assets.iconsScanBackIcon,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: _backToDocPicker,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'document_scanner'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (_docType == _ScanDocType.passport
                            ? 'scan_passport_option'
                            : 'scan_id_card_option')
                        .tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (canTorch)
              _GlassIconButton(
                iconAsset: _torchOn
                    ? Assets.iconsScanFlashIcon
                    : Assets.iconsScanFlashOffIcon,
                active: _torchOn,
                onTap: _toggleTorch,
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerBottomBar(BuildContext context) {
    final controller = _cameraController;
    final bool cameraReady = controller != null &&
        controller.value.isInitialized &&
        _hasPermission &&
        _error == null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xCC000000)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_scanError != null)
                _buildScanErrorBanner(context)
              else if (cameraReady)
                Text(
                  _hintKey.tr(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              if (cameraReady) ...[
                const SizedBox(height: 18),
                _ShutterButton(
                  busy: _isCapturing,
                  enabled: !_isCapturing && !_isParsed,
                  onTap: _captureAndProcess,
                ),
                const SizedBox(height: 8),
                Text(
                  'scan_take_photo'.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanErrorBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ProjectTheme.error.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                Assets.iconsBookingAlertIcon,
                width: 18,
                height: 18,
                colorFilter:
                    const ColorFilter.mode(Color(0xFFFF8A80), BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _scanError!,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: _retryScan,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(
                'scan_retry'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kamera maydoni ──────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }

    if (!_hasPermission) {
      return _buildCenteredState(
        context,
        iconAsset: Assets.iconsScanFrameIcon,
        message: 'allow_camera'.tr(),
        actionLabel: 'allow_camera'.tr(),
        onAction: () async {
          if (_docType == null) return;
          final status = await Permission.camera.request();
          if (status.isGranted) {
            setState(() {
              _hasPermission = true;
              _initializing = true;
            });
            await _initCamera(_cameraSession);
          } else {
            await openAppSettings();
          }
        },
      );
    }

    if (_error != null) {
      return _buildCenteredState(
        context,
        iconAsset: Assets.iconsBookingAlertIcon,
        message: _error!,
        actionLabel: 'scan_retry'.tr(),
        onAction: () async {
          if (_docType == null) return;
          setState(() {
            _error = null;
            _initializing = true;
          });
          await _initCamera(_cameraSession);
        },
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }

    final config = _overlayConfig;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frame = config.rectFor(size);
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildFullScreenCameraPreview(controller),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _scanLine,
                builder: (context, _) => CustomPaint(
                  painter: _MrzOverlayPainter(
                    config: config,
                    frameColor: _found ? ProjectTheme.success : Colors.white,
                    lineColor: ProjectTheme.brandColor,
                    scanProgress: _scanLine.value,
                    showScanLine: !_found && _scanError == null,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: size.height - frame.top + 14,
              child: Text(
                _instructionKey.tr(),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: frame.bottom + 14,
              child: Center(child: _StatusPill(found: _found)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCenteredState(
    BuildContext context, {
    required String iconAsset,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconAsset,
                width: 32,
                height: 32,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ProjectTheme.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenCameraPreview(CameraController controller) {
    return LayoutBuilder(
      key: ValueKey(controller),
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return CameraPreview(controller);
        }

        var previewWidth = previewSize.height;
        var previewHeight = previewSize.width;
        final screenRatio = constraints.maxWidth / constraints.maxHeight;
        final previewRatio = previewWidth / previewHeight;

        if (previewRatio > screenRatio) {
          previewHeight = constraints.maxHeight;
          previewWidth = previewHeight * previewRatio;
        } else {
          previewWidth = constraints.maxWidth;
          previewHeight = previewWidth / previewRatio;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: previewWidth,
            maxHeight: previewHeight,
            child: SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

/// Hujjat turi kartasi — ikonka, nom, MRZ izohi va strelka.
class _DocTypeScanTile extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const _DocTypeScanTile({
    required this.iconAsset,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final muted =
        isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF5B6475);

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(
                  iconAsset,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : brand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                Assets.iconsBookingChevronRightIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kamera ustidagi yarim shaffof dumaloq tugma.
class _GlassIconButton extends StatelessWidget {
  final String iconAsset;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;

  const _GlassIconButton({
    required this.iconAsset,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: active
          ? Colors.white.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                active ? Colors.black : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Ramka ostidagi holat: "Kod qidirilmoqda…" (pulsatsiyali nuqta) yoki
/// "Tayyor!" (yashil belgi).
class _StatusPill extends StatefulWidget {
  final bool found;

  const _StatusPill({required this.found});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool found = widget.found;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:
            found ? ProjectTheme.success : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: found ? 0 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (found)
            SvgPicture.asset(
              Assets.iconsScanTickIcon,
              width: 16,
              height: 16,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
          else
            FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ProjectTheme.brandColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            (found ? 'scan_found' : 'scan_searching').tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Katta dumaloq "suratga olish" tugmasi (kamera ilovalaridagidek).
class _ShutterButton extends StatefulWidget {
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'scan_take_photo'.tr(),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.lightImpact();
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: widget.enabled || widget.busy ? 1 : 0.4),
              ),
              alignment: Alignment.center,
              child: widget.busy
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ProjectTheme.brandColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _MrzOverlayConfig {
  final double widthFactor;
  final double heightFactor;
  final double centerYFactor;

  const _MrzOverlayConfig({
    required this.widthFactor,
    required this.heightFactor,
    required this.centerYFactor,
  });

  Rect rectFor(Size size) => Rect.fromCenter(
        center: Offset(size.width / 2, size.height * centerYFactor),
        width: size.width * widthFactor,
        height: size.height * heightFactor,
      );
}

/// Ramka tashqarisini xiralashtiradi, burchak qavslarini va ramka ichida
/// yuradigan skaner chizig'ini chizadi.
class _MrzOverlayPainter extends CustomPainter {
  final _MrzOverlayConfig config;
  final Color frameColor;
  final Color lineColor;
  final double scanProgress;
  final bool showScanLine;

  _MrzOverlayPainter({
    required this.config,
    required this.frameColor,
    required this.lineColor,
    required this.scanProgress,
    required this.showScanLine,
  });

  static const double _radius = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = config.rectFor(size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0x9E000000));

    // Ingichka ramka.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = frameColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Burchak qavslari.
    final corner = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 26.0;
    const r = _radius;
    void bracket(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx + sx * (r + len), o.dy)
        ..lineTo(o.dx + sx * r, o.dy)
        ..arcToPoint(
          Offset(o.dx, o.dy + sy * r),
          radius: const Radius.circular(r),
          clockwise: sx * sy < 0,
        )
        ..lineTo(o.dx, o.dy + sy * (r + len));
      canvas.drawPath(path, corner);
    }

    bracket(rect.topLeft, 1, 1);
    bracket(rect.topRight, -1, 1);
    bracket(rect.bottomLeft, 1, -1);
    bracket(rect.bottomRight, -1, -1);

    if (!showScanLine) return;

    // Yuradigan skaner chizig'i va uning ortidagi yumshoq nur.
    final inset = rect.deflate(10);
    final y = inset.top + inset.height * scanProgress;
    canvas.save();
    canvas.clipRRect(rrect);
    final glowRect = Rect.fromLTRB(inset.left, y - 26, inset.right, y);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0),
            lineColor.withValues(alpha: 0.28),
          ],
        ).createShader(glowRect),
    );
    final lineRect = Rect.fromLTRB(inset.left, y - 1.5, inset.right, y + 1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            lineColor.withValues(alpha: 0),
            lineColor,
            Colors.white,
            lineColor,
            lineColor.withValues(alpha: 0),
          ],
          stops: const [0, 0.2, 0.5, 0.8, 1],
        ).createShader(lineRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MrzOverlayPainter oldDelegate) =>
      oldDelegate.frameColor != frameColor ||
      oldDelegate.scanProgress != scanProgress ||
      oldDelegate.showScanLine != showScanLine ||
      oldDelegate.config != config;
}
