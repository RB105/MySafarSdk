import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/passenger/document_scan_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pasport/ID karta skaneri — to'liq ekranli kamera.
///
/// Hech narsa avtomatik aniqlanmaydi: foydalanuvchi hujjat turini tanlaydi
/// (ramka shakli o'zgaradi), suratga oladi yoki galereyadan tanlaydi, rasm
/// `/v1/document/scan`ga yuboriladi va javobdagi ma'lumotlar [UsersModel]
/// sifatida qaytadi (sanalar `dd.MM.yyyy`, tanilmagan maydonlar bo'sh).
/// Yopilsa `null`.
Future<UsersModel?> showDocumentScanner(BuildContext context) {
  // SDK ichki navigatori — embed rejimda host navigatoriga chiqmaydi.
  return Navigator.of(context).push<UsersModel>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _DocumentScannerPage(),
    ),
  );
}

enum _DocType { passport, idCard }

class _DocumentScannerPage extends StatefulWidget {
  const _DocumentScannerPage();

  @override
  State<_DocumentScannerPage> createState() => _DocumentScannerPageState();
}

class _DocumentScannerPageState extends State<_DocumentScannerPage>
    with WidgetsBindingObserver {
  final DocumentScanService _service = DocumentScanService();

  _DocType _docType = _DocType.passport;

  CameraController? _cameraController;
  int _cameraSession = 0;
  bool _hasPermission = true;
  bool _initializing = true;
  String? _cameraError;
  bool _torchOn = false;

  /// Suratga olingan / tanlangan rasm — yuklash va xato paytida kamera
  /// o'rnida ko'rinadi.
  String? _capturedPath;
  bool _capturing = false;
  bool _uploading = false;
  String? _scanError;

  /// Foydalanuvchi fokus uchun bosgan nuqta (viewport koordinatasida) —
  /// qisqa vaqt belgi ko'rsatiladi.
  Offset? _focusIndicator;

  bool get _cameraReady =>
      _cameraController?.value.isInitialized == true && _cameraError == null;

  bool get _busy => _capturing || _uploading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _cameraController;
    _cameraController = null;
    _cameraSession++;
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      unawaited(_disposeCamera());
    } else if (state == AppLifecycleState.resumed &&
        _hasPermission &&
        _cameraController == null &&
        !_initializing) {
      unawaited(_startCamera());
    }
  }

  // ── Kamera ──────────────────────────────────────────────────────────

  Future<void> _startCamera() async {
    final session = ++_cameraSession;
    if (mounted) {
      setState(() {
        _initializing = true;
        _cameraError = null;
      });
    }

    final status = await Permission.camera.request();
    if (!mounted || session != _cameraSession) return;
    if (!status.isGranted) {
      setState(() {
        _hasPermission = false;
        _initializing = false;
      });
      return;
    }
    _hasPermission = true;

    try {
      final cameras = await availableCameras();
      if (!mounted || session != _cameraSession) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted || session != _cameraSession) {
        await controller.dispose();
        return;
      }
      // Hujjat ramka markazida turadi — fokus va ekspozitsiya o'sha nuqtaga
      // sozlanadi, aks holda kamera fonga fokuslab, matn hira chiqadi.
      await _focusAt(controller, _framePoint);
      setState(() {
        _cameraController = controller;
        _initializing = false;
        _torchOn = false;
      });
    } catch (_) {
      if (!mounted || session != _cameraSession) return;
      setState(() {
        _initializing = false;
        _cameraError = 'scan_camera_error'.tr();
      });
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    if (controller == null) return;
    _cameraSession++;
    if (mounted) {
      setState(() {
        _cameraController = null;
        _torchOn = false;
      });
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      await controller.dispose();
    } catch (_) {}
  }

  /// Ramka markazi (kamera koordinatasida 0..1) — [_frameRect] bilan bir xil.
  static const Offset _framePoint = Offset(0.5, 0.52);

  /// Berilgan nuqtaga avtofokus va ekspozitsiya. Qo'llab-quvvatlamaydigan
  /// qurilmada jim o'tkaziladi.
  Future<void> _focusAt(CameraController controller, Offset point) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(point);
    } catch (_) {
      // Fokus nuqtasi qo'llab-quvvatlanmaydi.
    }
    try {
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setExposurePoint(point);
    } catch (_) {
      // Ekspozitsiya nuqtasi qo'llab-quvvatlanmaydi.
    }
  }

  /// Ekranga bosilganda o'sha joyga fokuslaydi va qisqa belgi ko'rsatadi.
  Future<void> _focusOnTap(Offset localPosition, Size viewportSize) async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturedPath != null ||
        viewportSize.isEmpty) {
      return;
    }
    final point = Offset(
      (localPosition.dx / viewportSize.width).clamp(0.0, 1.0),
      (localPosition.dy / viewportSize.height).clamp(0.0, 1.0),
    );
    setState(() => _focusIndicator = localPosition);
    await _focusAt(controller, point);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && _focusIndicator == localPosition) {
      setState(() => _focusIndicator = null);
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } catch (_) {
      // Qurilmada chiroq yo'q.
    }
  }

  // ── Suratga olish / galereya / yuklash ─────────────────────────────

  Future<void> _capture() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _busy) return;

    setState(() {
      _capturing = true;
      _scanError = null;
    });
    try {
      // Suratdan oldin ramka markaziga qayta fokuslaymiz va avtofokus
      // sozlanib bo'lishini kutamiz — shoshilinch olingan kadr hira chiqadi.
      await _focusAt(controller, _framePoint);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final file = await controller.takePicture();
      if (_torchOn) unawaited(_toggleTorch());
      if (!mounted) return;
      _capturing = false;
      await _upload(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _scanError = 'scan_camera_error'.tr();
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2200,
        maxHeight: 2200,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      await _upload(picked.path);
    } catch (_) {
      // Galereyaga ruxsat berilmadi yoki bekor qilindi.
    }
  }

  /// Rasmni backendga yuboradi va javobni qaytaradi — boshqa ish yo'q.
  Future<void> _upload(String path) async {
    setState(() {
      _capturedPath = path;
      _uploading = true;
      _scanError = null;
    });

    final response = await _service.scan(path);
    if (!mounted) return;

    if (response is NetworkSuccessResponse &&
        response.data is DocumentScanResult) {
      final result = response.data as DocumentScanResult;
      if (!result.isEmpty) {
        unawaited(HapticFeedback.mediumImpact());
        Navigator.of(context).pop(result.passenger);
        return;
      }
      setState(() {
        _uploading = false;
        _scanError = 'scan_not_recognized'.tr();
      });
      return;
    }

    final message =
        response is NetworkErrorResponse ? response.getError().trim() : '';
    setState(() {
      _uploading = false;
      _scanError = message.isNotEmpty ? message : 'scan_upload_failed'.tr();
    });
  }

  /// Xatodan keyin qayta suratga olish — jonli kamera qaytadi.
  void _retake() {
    setState(() {
      _capturedPath = null;
      _scanError = null;
    });
    if (_cameraController == null && _hasPermission && !_initializing) {
      unawaited(_startCamera());
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: _buildViewport(context)),
            _buildBottomPanel(context),
          ],
        ),
      ),
    );
  }

  /// Status bar ostida alohida qora panel — kamera ko'rinishi uning ostidan
  /// boshlanadi, tugmalar soat/batareya bilan ustma-ust tushmaydi.
  Widget _buildTopBar(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final showTorch = _cameraReady && _capturedPath == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, topInset + 8, 8, 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _RoundIconButton(
              iconAsset: Assets.iconsPlaceCloseIcon,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                'document_scanner'.tr(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'packages/mysafar_sdk/Gilroy',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showTorch)
              _RoundIconButton(
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

  Widget _buildViewport(BuildContext context) {
    final capturedPath = _capturedPath;
    final controller = _cameraController;

    final Widget background;
    if (capturedPath != null) {
      background = Image.file(
        File(capturedPath),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (!_hasPermission) {
      return _buildCenteredState(
        context,
        iconAsset: Assets.iconsScanFrameIcon,
        message: 'allow_camera'.tr(),
        actionLabel: 'allow_camera'.tr(),
        onAction: () async {
          final status = await Permission.camera.request();
          if (status.isGranted) {
            await _startCamera();
          } else {
            await openAppSettings();
          }
        },
      );
    } else if (_cameraError != null) {
      return _buildCenteredState(
        context,
        iconAsset: Assets.iconsBookingAlertIcon,
        message: _cameraError!,
        actionLabel: 'scan_retry'.tr(),
        onAction: _startCamera,
      );
    } else if (_initializing || controller == null || !_cameraReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    } else {
      background = _CameraCoverPreview(controller: controller);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final frame = _frameRect(size);
          final focusPoint = _focusIndicator;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Bosilgan joyga fokuslash — hujjat ramkadan chetroqda bo'lsa
              // yoki kamera fonni fokuslab qolsa qo'l bilan to'g'rilash.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _focusOnTap(details.localPosition, size),
                child: background,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _DocumentFramePainter(frame: frame),
                ),
              ),
              if (focusPoint != null && capturedPath == null)
                Positioned(
                  left: focusPoint.dx - _focusRingSize / 2,
                  top: focusPoint.dy - _focusRingSize / 2,
                  child: const IgnorePointer(child: _FocusRing()),
                ),
              Positioned(
                left: 24,
                right: 24,
                bottom: size.height - frame.top + 14,
                child: Text(
                  (_docType == _DocType.passport
                          ? 'scan_passport_frame_hint'
                          : 'scan_id_frame_hint')
                      .tr(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: const TextStyle(
                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_uploading)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: _ProcessingCard()),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Ramka: pasport sahifasi ~125×88 mm (1.42), ID karta 85.6×54 mm (1.59).
  Rect _frameRect(Size size) {
    final isPassport = _docType == _DocType.passport;
    final aspect = isPassport ? 1.42 : 1.586;
    var width = size.width * (isPassport ? 0.9 : 0.84);
    var height = width / aspect;
    final maxHeight = size.height * 0.6;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspect;
    }
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.52),
      width: width,
      height: height,
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasCaptured = _capturedPath != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_scanError != null)
            _buildErrorBanner(context)
          else
            _DocTypeSwitch(
              value: _docType,
              enabled: !_busy,
              onChanged: (type) {
                setState(() {
                  _docType = type;
                  _focusIndicator = null;
                });
                // Ramka o'lchami o'zgardi — markazga qayta fokuslaymiz.
                final controller = _cameraController;
                if (controller != null && controller.value.isInitialized) {
                  unawaited(_focusAt(controller, _framePoint));
                }
              },
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _RoundIconButton(
                    iconAsset: Assets.iconsScanGalleryIcon,
                    size: 50,
                    enabled: !_busy,
                    tooltip: 'gallery'.tr(),
                    onTap: _pickFromGallery,
                  ),
                ),
              ),
              _ShutterButton(
                busy: _busy,
                enabled: _cameraReady && !hasCaptured && !_busy,
                onTap: _capture,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'scan_photo_hint'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'packages/mysafar_sdk/Gilroy',
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.iconsBookingAlertIcon,
            width: 20,
            height: 20,
            colorFilter:
                const ColorFilter.mode(Color(0xFFFF8A80), BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _scanError!,
              style: const TextStyle(
                fontFamily: 'packages/mysafar_sdk/Gilroy',
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: _retake,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              'scan_retry'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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
              style: const TextStyle(
                fontFamily: 'packages/mysafar_sdk/Gilroy',
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
}

const double _focusRingSize = 72;

/// Fokus uchun bosilgan joydagi belgi.
class _FocusRing extends StatelessWidget {
  const _FocusRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _focusRingSize,
      height: _focusRingSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Kamera ko'rinishini maydonni to'liq qoplaydigan qilib (cover) chizadi.
class _CameraCoverPreview extends StatelessWidget {
  const _CameraCoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: ValueKey(controller),
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) return CameraPreview(controller);

        // Portret: preview o'lchami landshaft ko'rinishida keladi.
        final previewRatio = previewSize.height / previewSize.width;
        final areaRatio = constraints.maxWidth / constraints.maxHeight;
        double width;
        double height;
        if (previewRatio > areaRatio) {
          height = constraints.maxHeight;
          width = height * previewRatio;
        } else {
          width = constraints.maxWidth;
          height = width / previewRatio;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            maxWidth: width,
            maxHeight: height,
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

/// "Pasport | ID karta" tanlagichi — tanlangan tur ramka shaklini belgilaydi.
class _DocTypeSwitch extends StatelessWidget {
  const _DocTypeSwitch({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final _DocType value;
  final bool enabled;
  final ValueChanged<_DocType> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(_DocType type, String label) {
      final selected = type == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled && !selected
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(type);
                  }
                : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'packages/mysafar_sdk/Gilroy',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.black
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: 42,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            segment(_DocType.passport, 'scan_passport_option'.tr()),
            segment(_DocType.idCard, 'scan_id_card_option'.tr()),
          ],
        ),
      ),
    );
  }
}

/// Yuklash paytida rasm ustidagi kichik karta: spinner + "O'qilmoqda…".
class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'scan_processing'.tr(),
            style: const TextStyle(
              fontFamily: 'packages/mysafar_sdk/Gilroy',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dumaloq yarim shaffof tugma (yopish, chiroq, galereya).
class _RoundIconButton extends StatelessWidget {
  final String iconAsset;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;
  final double size;
  final String? tooltip;

  const _RoundIconButton({
    required this.iconAsset,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: size * 0.5,
                height: size * 0.5,
                colorFilter: ColorFilter.mode(
                  active ? Colors.black : Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Katta dumaloq "suratga olish" tugmasi.
class _ShutterButton extends StatelessWidget {
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'scan_take_photo'.tr(),
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: enabled || busy ? 1 : 0.4),
            ),
            child: busy
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
    );
  }
}

/// Ramka tashqarisini xiralashtiradi va burchak qavslarini chizadi.
class _DocumentFramePainter extends CustomPainter {
  _DocumentFramePainter({required this.frame});

  final Rect frame;

  static const double _radius = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(frame, const Radius.circular(_radius));

    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0x8C000000));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final corner = Paint()
      ..color = Colors.white
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

    bracket(frame.topLeft, 1, 1);
    bracket(frame.topRight, -1, 1);
    bracket(frame.bottomLeft, 1, -1);
    bracket(frame.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _DocumentFramePainter oldDelegate) =>
      oldDelegate.frame != frame;
}
