import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/mrz_text_extractor.dart';
import 'package:permission_handler/permission_handler.dart';

enum _ScanDocType { passport, idCard }

/// Pasport/ID MRZ skanerini pastki sheet sifatida ochadi.
/// Muvaffaqiyatda [UsersModel] qaytaradi; yopilsa `null`.
Future<UsersModel?> showMrzScannerBottomSheet(BuildContext context) {
  // Embed'da root navigator host'niki — SDK theme yo'qoladi.
  // Chaqiruvchi context'dan temani oldindan olib sheet ichiga uzatamiz.
  final isDark = context.isDarkMode;
  final sheetTheme = isDark ? ProjectTheme.dark : ProjectTheme.light;
  final sheetColor =
      isDark ? ProjectTheme.backgroundDark : ProjectTheme.cardColorLight;

  return showModalBottomSheet<UsersModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: false,
    backgroundColor: sheetColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => Theme(
      data: sheetTheme,
      child: const _MrzScannerSheet(),
    ),
  );
}

class _MrzScannerSheet extends StatefulWidget {
  const _MrzScannerSheet();

  @override
  State<_MrzScannerSheet> createState() => _MrzScannerSheetState();
}

class _MrzScannerSheetState extends State<_MrzScannerSheet> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  _ScanDocType? _docType;
  bool _hasPermission = false;
  bool _initializing = false;
  bool _isBusy = false;
  bool _isParsed = false;
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
  void dispose() {
    _scanTimeoutTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    _cameraSession++;
    unawaited(_tearDownController(controller));
    unawaited(_textRecognizer.close());
    super.dispose();
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
    });
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
      final recognized = await _textRecognizer.processImage(inputImage);
      for (final line in MrzTextExtractor.extractCandidateLines(recognized.text)) {
        _accumulatedLines.remove(line);
        _accumulatedLines.add(line);
      }
      while (_accumulatedLines.length > 24) {
        _accumulatedLines.remove(_accumulatedLines.first);
      }

      final expected = _docType == _ScanDocType.passport
          ? MrzExpectedDoc.passport
          : MrzExpectedDoc.idCard;
      final candidates = _accumulatedLines.toList();
      final shouldDebug =
          DateTime.now().difference(_lastDebugAt).inMilliseconds >= 1200;
      if (shouldDebug) {
        _lastDebugAt = DateTime.now();
        // ignore: avoid_print
        print(
          '[MRZ] expected=$expected '
          'rawLen=${recognized.text.length} '
          'candidates=${candidates.length} '
          'lens=${candidates.map((e) => e.length).toList()}',
        );
        for (var i = 0; i < candidates.length; i++) {
          // ignore: avoid_print
          print('[MRZ] L$i(${candidates[i].length}): ${candidates[i]}');
        }
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
          // ignore: avoid_print
          print('[MRZ] mismatch: expected=$expected found=$mismatch');
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
      // ignore: avoid_print
      print(
        '[MRZ] OK → ${mrz.surnames} ${mrz.givenNames} '
        'doc=${mrz.documentNumber} type=${mrz.documentType}',
      );
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
    } catch (_) {
      // Keyingi kadrda qayta uriniladi.
    } finally {
      _isBusy = false;
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
        rotationCompensation =
            (sensorOrientation + rotationCompensation) % 360;
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

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  String get _instructionKey => _docType == _ScanDocType.passport
      ? 'scan_passport_instruction'
      : 'scan_id_instruction';

  String get _hintKey =>
      _docType == _ScanDocType.passport ? 'scan_passport_hint' : 'scan_id_hint';

  _MrzOverlayConfig get _overlayConfig =>
      _docType == _ScanDocType.passport
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
    final sheetHeight = screenHeight - topInset - 8;
    final isDark = context.isDarkMode;
    final titleColor =
        isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    return SizedBox(
      height: sheetHeight,
      child: Column(
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
                    'document_scanner'.tr(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_docType == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'scan_choose_document'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontSize: 14,
                  color: secondaryColor,
                ),
              ),
            ),
            Expanded(child: _buildDocTypePicker(context, isDark)),
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
                color: isDark ? const Color(0xFF000000) : const Color(0xFF1A1A1A),
                child: _buildBody(context),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: _scanError != null
                    ? _buildScanErrorBanner(context)
                    : Row(
                        children: [
                          Icon(
                            Icons.crop_free_rounded,
                            size: 18,
                            color: ProjectTheme.brandColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hintKey.tr(),
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanErrorBanner(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF3A2020)
            : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ProjectTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 20, color: ProjectTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scanError!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypePicker(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: _DocTypeCard(
              icon: Icons.menu_book_outlined,
              label: 'scan_passport_option'.tr(),
              subtitle: 'scan_passport_instruction'.tr(),
              isDark: isDark,
              onTap: () => _selectDocType(_ScanDocType.passport),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _DocTypeCard(
              icon: Icons.badge_outlined,
              label: 'scan_id_card_option'.tr(),
              subtitle: 'scan_id_instruction'.tr(),
              isDark: isDark,
              onTap: () => _selectDocType(_ScanDocType.idCard),
            ),
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
        if (_isParsed)
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(child: CircularProgressIndicator()),
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

class _DocTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _DocTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
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
    final cardColor = isDark
        ? ProjectTheme.cardColorDark
        : ProjectTheme.brandColor.withValues(alpha: 0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 1.5, color: borderColor),
            color: cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: ProjectTheme.brandColor),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 13,
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
              ],
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
