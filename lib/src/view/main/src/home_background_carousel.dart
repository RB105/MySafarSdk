import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// Bosh sahifa header'ining orqa fon rasmi.
///
/// `assets/img/home/backgrounds/` papkasidagi barcha rasmlarni avtomatik topib,
/// har 5 soniyada silliq (cross-fade) almashtirib turadi. Foydalanuvchi shu
/// papkaga xohlagan rasmlarini tashlashi kifoya — kodni o'zgartirmasdan
/// rotatsiyaga qo'shiladi (`flutter pub get` + qayta build kerak).
///
/// Papka bo'sh bo'lsa yoki manifest o'qilmasa — eski `main_bg.png` ko'rsatiladi.
/// Bitta rasm bo'lsa — statik turadi (rotatsiya faqat ≥2 rasmda ishlaydi).
class HomeBackgroundCarousel extends StatefulWidget {
  const HomeBackgroundCarousel({super.key});

  /// Fon rasmlari shu papkadan olinadi.
  static const String dir = 'assets/img/home/backgrounds/';

  /// Rasmlar almashish intervali.
  static const Duration interval = Duration(seconds: 5);

  /// Cross-fade davomiyligi.
  static const Duration fade = Duration(milliseconds: 900);

  @override
  State<HomeBackgroundCarousel> createState() => _HomeBackgroundCarouselState();
}

class _HomeBackgroundCarouselState extends State<HomeBackgroundCarousel> {
  // Manifest butun app sessiyasi davomida bir marta o'qiladi (kesh).
  static Future<List<String>>? _assetsFuture;

  List<String> _images = const [];
  int _index = 0;
  Timer? _timer;
  bool _didPrecache = false;

  @override
  void initState() {
    super.initState();
    _assetsFuture ??= _discoverBackgrounds();
    _assetsFuture!.then((imgs) {
      if (!mounted) return;
      setState(() => _images = imgs);
      _startRotation();
    });
  }

  /// `backgrounds/` papkasidagi rasm asset'larini AssetManifest orqali topadi.
  static Future<List<String>> _discoverBackgrounds() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final imgs = manifest
          .listAssets()
          .where((a) => a.startsWith(HomeBackgroundCarousel.dir))
          .where((a) {
        final l = a.toLowerCase();
        return l.endsWith('.png') ||
            l.endsWith('.jpg') ||
            l.endsWith('.jpeg') ||
            l.endsWith('.webp');
      }).toList()
        ..sort();
      if (imgs.isNotEmpty) return imgs;
    } catch (_) {
      // manifest o'qishda xato — bo'sh qaytaramiz, yashil gradient ko'rinadi.
    }
    return const <String>[];
  }

  /// Rasm topilmaganda (yoki yuklanguncha) — Figma'ga mos yashil gradient.
  static const List<Color> _greenGradient = [
    Color(0xFF8FC3B0),
    Color(0xFF4E8A5A),
    Color(0xFF234E36),
  ];

  void _startRotation() {
    _timer?.cancel();
    if (_images.length < 2) return;
    _timer = Timer.periodic(HomeBackgroundCarousel.interval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _images.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Barcha fon rasmlarini oldindan keshlaymiz — almashuvda "sakrash" bo'lmaydi.
    if (!_didPrecache && _images.isNotEmpty) {
      _didPrecache = true;
      for (final path in _images) {
        precacheImage(AssetImage(path), context).catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rasmlar hali yuklanmagan bo'lsa — brend rangli bo'shliq (bo'sh oq emas).
    final String? current = _images.isEmpty ? null : _images[_index];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _greenGradient,
        ),
      ),
      child: AnimatedSwitcher(
        duration: HomeBackgroundCarousel.fade,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: current == null
            ? const SizedBox.expand(key: ValueKey('bg-empty'))
            : Image.asset(
                current,
                key: ValueKey(current),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}
