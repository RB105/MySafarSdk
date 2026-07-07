import 'package:flutter/widgets.dart';

/// Bosh sahifa + pastki navigatsiya paneli tanishtiruvi (coach marks) uchun
/// umumiy GlobalKey'lar.
///
/// MainPage va BottomNavBarPage bitta [ShowCaseWidget] ostida joylashgani uchun
/// kalitlar shu yerda markazlashtirilgan — shunda ikkala sahifadagi elementlar
/// bitta ketma-ket tanishtiruv oqimida ko'rsatiladi.
class HomeShowcaseKeys {
  HomeShowcaseKeys._();

  // MainPage elementlari
  static final GlobalKey notif = GlobalKey();
  static final GlobalKey support = GlobalKey();
  static final GlobalKey search = GlobalKey();
  static final GlobalKey hot = GlobalKey();
  static final GlobalKey popular = GlobalKey();

  // Pastki panel tab'lari
  static final GlobalKey tabOrders = GlobalKey();
  static final GlobalKey tabServices = GlobalKey();
  static final GlobalKey tabProfile = GlobalKey();
}
