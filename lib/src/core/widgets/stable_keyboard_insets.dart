import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Klaviatura animatsiyasi paytida sahifa layout'ini barqaror ushlaydi.
///
/// 1) Sahifa yopilayotganda (pop animatsiyasi, iOS swipe, Android predictive
///    back) Flutter fokusni oladi va klaviatura yopila boshlaydi. Inset
///    muzlatilmasa, ketayotgan sahifa har kadrda qayta joylashadi — kontent va
///    tugmalar sakraydi. Bu yerda inset oxirgi qiymatida qoladi: sahifa joyida
///    turadi, klaviatura esa ortidan silliq tushadi.
/// 2) `padding.bottom` doim `viewPadding.bottom` ga teng — klaviatura
///    ochilayotganda/yopilayotganda uning ortidagi pastki tugma ([SafeArea])
///    balandligi o'zgarib, kontentni tebratmaydi.
///
/// Klaviatura ustida turadigan (SafeArea'li) panel bor sahifalarda
/// ishlatmang — u yerda `padding.bottom` klaviatura ochiqligida 0 bo'lishi
/// kerak.
class StableKeyboardInsets extends StatefulWidget {
  const StableKeyboardInsets({super.key, required this.child});

  final Widget child;

  /// [route] yopilayotganmi yoki navigator'da orqaga gesture davom etyaptimi.
  static bool isLeaving(ModalRoute<dynamic>? route) {
    if (route == null) return false;
    return route.animation?.status == AnimationStatus.reverse ||
        (route.navigator?.userGestureInProgress ?? false);
  }

  @override
  State<StableKeyboardInsets> createState() => _StableKeyboardInsetsState();
}

class _StableKeyboardInsetsState extends State<StableKeyboardInsets> {
  ModalRoute<dynamic>? _route;
  ValueListenable<bool>? _gesture;
  double _bottomInset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final gesture = _route?.navigator?.userGestureInProgressNotifier;
    if (!identical(gesture, _gesture)) {
      _gesture?.removeListener(_onGestureChanged);
      _gesture = gesture?..addListener(_onGestureChanged);
    }
  }

  @override
  void dispose() {
    _gesture?.removeListener(_onGestureChanged);
    super.dispose();
  }

  // Gesture bekor qilinsa sahifa qolaveradi — jonli insetga qaytish uchun.
  void _onGestureChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    if (!StableKeyboardInsets.isLeaving(_route)) {
      _bottomInset = data.viewInsets.bottom;
    }
    return MediaQuery(
      data: data.copyWith(
        viewInsets: data.viewInsets.copyWith(bottom: _bottomInset),
        padding: data.padding.copyWith(bottom: data.viewPadding.bottom),
      ),
      child: widget.child,
    );
  }
}
