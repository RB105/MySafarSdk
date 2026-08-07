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
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        _initializing = false;
        _error = null;
        _scanError = null;
      });
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

    final user = UsersModel.fromScan(mrz);
    Navigator.of(context).pop(user);
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
        final user = UsersModel.fromScan(mrz);
        Navigator.of(context).pop(user);
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

  _MrzOverlayConfig get _overlayConfig => _docType == _ScanDocType.passport
      ? const _MrzOverlayConfig(
          widthFactor: 0.98,
          heightFactor: 0.28,
          centerYFactor: 0.62,
        )
      : const _MrzOverlayConfig(
          widthFactor: 0.94,
          heightFactor: 0.32,
          centerYFactor: 0.58,
        );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.paddingOf(context).top;
    final scannerSheetHeight = screenHeight - topInset - 8;
    final pickingDoc = _docType == null;
    final isDark = context.isDarkMode;
    final titleColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    final sheet = AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: pickingDoc ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.color.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_docType != null) {
                      _backToDocPicker();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(
                    _docType != null
                        ? Icons.arrow_back_rounded
                        : Icons.close_rounded,
                    color: titleColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    pickingDoc
                        ? 'scan_choose_document'.tr()
                        : 'document_scanner'.tr(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: pickingDoc ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (pickingDoc) ...[
            _buildDocTypePicker(context, isDark),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _instructionKey.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontSize: 13.5,
                  color: secondaryColor,
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color:
                    isDark ? const Color(0xFF000000) : const Color(0xFF1A1A1A),
                child: _buildBody(context),
              ),
            ),
            SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141414)
                      : const Color(0xFF1A1A1A),
                  border: Border(
                    top: BorderSide(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.08 : 0.06),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _scanError != null
                      ? _buildScanErrorBanner(context)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.crop_free_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _hintKey.tr(),
                                    style:
                                        context.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      height: 1.35,
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: (_isCapturing ||
                                        _isParsed ||
                                        _cameraController == null)
                                    ? null
                                    : _captureAndProcess,
                                style: FilledButton.styleFrom(
                                  backgroundColor: ProjectTheme.brandColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: ProjectTheme
                                      .brandColor
                                      .withValues(alpha: 0.35),
                                  disabledForegroundColor:
                                      Colors.white.withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                icon: _isCapturing
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.photo_camera_rounded,
                                        size: 20,
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                      ),
                                label: Text(
                                  'scan_capture'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (pickingDoc) {
      return sheet;
    }
    return SizedBox(height: scannerSheetHeight, child: sheet);
  }

  Widget _buildScanErrorBanner(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2020) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ProjectTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 20, color: ProjectTheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _scanError!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: _retryScan,
                style: TextButton.styleFrom(
                  foregroundColor: ProjectTheme.brandColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('scan_retry'.tr()),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: (_isCapturing || _cameraController == null)
                    ? null
                    : _captureAndProcess,
                style: TextButton.styleFrom(
                  foregroundColor: ProjectTheme.brandColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: Text('scan_capture'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypePicker(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DocTypeScanTile(
            label: 'scan_passport_option'.tr(),
            hint: 'scan_passport_picker_hint'.tr(),
            isDark: isDark,
            docShape: _DocShape.passport,
            onTap: () => _selectDocType(_ScanDocType.passport),
          ),
          const SizedBox(height: 10),
          _DocTypeScanTile(
            label: 'scan_id_card_option'.tr(),
            hint: 'scan_id_picker_hint'.tr(),
            isDark: isDark,
            docShape: _DocShape.idCard,
            onTap: () => _selectDocType(_ScanDocType.idCard),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined,
                  size: 40, color: context.color.outline),
              const SizedBox(height: 16),
              Text(
                'allow_camera'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ProjectTheme.brandColor,
                ),
                onPressed: () async {
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
                child: Text('allow_camera'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: ProjectTheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ProjectTheme.brandColor,
                ),
                onPressed: () async {
                  if (_docType == null) return;
                  setState(() {
                    _error = null;
                    _initializing = true;
                  });
                  await _initCamera(_cameraSession);
                },
                child: Text('scan_retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFullScreenCameraPreview(controller),
        IgnorePointer(
          child: CustomPaint(
            painter: _MrzOverlayPainter(
              config: _overlayConfig,
              color: ProjectTheme.brandColor.withValues(alpha: 0.95),
            ),
          ),
        ),
        if (_isParsed || _isCapturing)
          ColoredBox(
            color: const Color(0x66000000),
            child: Center(
              child: CircularProgressIndicator(
                color: ProjectTheme.brandColor,
              ),
            ),
          ),
      ],
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

enum _DocShape { passport, idCard }

class _DocTypeScanTile extends StatelessWidget {
  final String label;
  final String hint;
  final bool isDark;
  final _DocShape docShape;
  final VoidCallback onTap;

  const _DocTypeScanTile({
    required this.label,
    required this.hint,
    required this.isDark,
    required this.docShape,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;
    final subtitleColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final borderColor =
        isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _DocShapeIcon(shape: docShape, isDark: isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: subtitleColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocShapeIcon extends StatelessWidget {
  final _DocShape shape;
  final bool isDark;

  const _DocShapeIcon({required this.shape, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPassport = shape == _DocShape.passport;
    final w = isPassport ? 28.0 : 36.0;
    final h = isPassport ? 36.0 : 24.0;
    final borderColor =
        isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight;

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ProjectTheme.brandColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isPassport ? 4 : 3),
          border: Border.all(color: borderColor, width: 1.2),
          color: isDark
              ? ProjectTheme.cardColorDark
              : Colors.white.withValues(alpha: 0.9),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: w * 0.85,
            height: h * 0.22,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: ProjectTheme.brandColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1),
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
}

class _MrzOverlayPainter extends CustomPainter {
  final _MrzOverlayConfig config;
  final Color color;

  _MrzOverlayPainter({required this.config, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * config.centerYFactor),
      width: size.width * config.widthFactor,
      height: size.height * config.heightFactor,
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = const Color(0xAA000000));

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _drawCorner(canvas, rect.topLeft, true, true);
    _drawCorner(canvas, rect.topRight, false, true);
    _drawCorner(canvas, rect.bottomLeft, true, false);
    _drawCorner(canvas, rect.bottomRight, false, false);
  }

  void _drawCorner(
    Canvas canvas,
    Offset point,
    bool left,
    bool top,
  ) {
    const len = 22.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (left && top) {
      canvas.drawLine(point, point + const Offset(len, 0), paint);
      canvas.drawLine(point, point + const Offset(0, len), paint);
    } else if (!left && top) {
      canvas.drawLine(point, point + const Offset(-len, 0), paint);
      canvas.drawLine(point, point + const Offset(0, len), paint);
    } else if (left && !top) {
      canvas.drawLine(point, point + const Offset(len, 0), paint);
      canvas.drawLine(point, point + const Offset(0, -len), paint);
    } else {
      canvas.drawLine(point, point + const Offset(-len, 0), paint);
      canvas.drawLine(point, point + const Offset(0, -len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MrzOverlayPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.config != config;
}
