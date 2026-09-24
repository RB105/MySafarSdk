import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

/// Internet yo'qligi haqida yengil xabar (№48): SDK ildizida, ekran
/// tepasida kichik "pill". Bosishlarni to'smaydi (IgnorePointer), faqat
/// ulanish holati o'zgarganda chiqadi:
/// - aloqa uzilsa (qisqa kechikish bilan — Wi-Fi ↔ mobil almashishida
///   miltillamasligi uchun) "Internet aloqasi yo'q";
/// - qaytsa 2 soniya "Internet tiklandi".
class SdkConnectivityBanner extends StatefulWidget {
  const SdkConnectivityBanner({super.key, required this.child});

  final Widget child;

  /// `connectivity_plus` natijasi internet yo'qligini bildiradimi.
  /// Bo'sh ro'yxat — noma'lum, "bor" deb hisoblanadi.
  @visibleForTesting
  static bool isOffline(List<ConnectivityResult> results) =>
      results.isNotEmpty &&
      results.every((r) => r == ConnectivityResult.none);

  @override
  State<SdkConnectivityBanner> createState() => _SdkConnectivityBannerState();
}

enum _BannerState { hidden, offline, restored }

class _SdkConnectivityBannerState extends State<SdkConnectivityBanner> {
  static const Duration _offlineDelay = Duration(milliseconds: 1500);
  static const Duration _restoredVisible = Duration(seconds: 2);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _offline = false;
  _BannerState _banner = _BannerState.hidden;

  /// Widget testlarida platforma plagini yo'q — kuzatuv o'chiriladi.
  static bool get _enabled {
    try {
      return !Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    try {
      final connectivity = Connectivity();
      _subscription = connectivity.onConnectivityChanged.listen(
        _onResults,
        onError: (_) {},
      );
      connectivity.checkConnectivity().then(_onResults).catchError((_) {});
    } catch (_) {
      // Plagin ishlamasa banner shunchaki ko'rinmaydi.
    }
  }

  void _onResults(List<ConnectivityResult> results) {
    if (!mounted) return;
    final offline = SdkConnectivityBanner.isOffline(results);
    if (offline == _offline) return;
    _offline = offline;
    _timer?.cancel();
    if (offline) {
      _timer = Timer(_offlineDelay, () {
        if (mounted && _offline) {
          setState(() => _banner = _BannerState.offline);
        }
      });
    } else if (_banner == _BannerState.offline) {
      setState(() => _banner = _BannerState.restored);
      _timer = Timer(_restoredVisible, () {
        if (mounted && !_offline) {
          setState(() => _banner = _BannerState.hidden);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _banner != _BannerState.hidden;
    final restored = _banner == _BannerState.restored;
    final double top = MediaQuery.paddingOf(context).top + 6;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: top,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1.6),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Semantics(
                    liveRegion: visible,
                    excludeSemantics: !visible,
                    child: Material(
                      color: restored
                          ? const Color(0xFF1E9E5A)
                          : const Color(0xFF2B2F38),
                      borderRadius: BorderRadius.circular(20),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              restored
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_off_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                restored
                                    ? 'connection_restored'.tr()
                                    : 'offline_banner'.tr(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
