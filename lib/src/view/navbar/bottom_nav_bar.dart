// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:showcaseview/showcaseview.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/service/deep_link_gateway.dart';
import 'package:mysafar_sdk/src/view/destinations/destinations_list_page.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart';
import 'package:mysafar_sdk/src/view/main/showcase_keys.dart';
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_page.dart';
import 'package:mysafar_sdk/src/view/profile/profile_page.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class BottomNavBarPage extends StatefulWidget {
  final int? pageIndex;

  /// bottom navigation page: HomePage, BookedTicketsPage,
  /// DestinationsListPage (Yo'nalishlar), ProfilePage
  const BottomNavBarPage({super.key, this.pageIndex});

  @override
  State<BottomNavBarPage> createState() => _BottomNavBarPageState();
  static const routeName = '/bottom_nav_bar';

  /// "Buyurtmalar" tabi indeksi.
  static const int ordersTabIndex = 1;

  /// Ichki sahifalardan tab almashtirish so'rovi (masalan bosh sahifadagi
  /// "Hammasi" → Yo'nalishlar tabi). `null` — so'rov yo'q.
  static final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  /// Hozirgi tab indeksi (0-bosh, 1-buyurtmalar, 2-yo'nalishlar, 3-profil).
  /// Embed back handler Main vs boshqa tabni shu orqali biladi.
  static final ValueNotifier<int> currentTabIndex = ValueNotifier<int>(0);

  /// Tablar uchun screen_view nomlari (№19) — tablar bitta route ichida
  /// almashgani uchun navigator observer ularni route nomi orqali ko'rmaydi.
  static const List<String> tabScreenNames = [
    'tab_home',
    'tab_orders',
    'tab_destinations',
    'tab_profile',
  ];

  /// Hozir ko'rinib turgan tab ekran nomi (navigator observer alias'i).
  static String currentScreenName() {
    final index = currentTabIndex.value;
    return index >= 0 && index < tabScreenNames.length
        ? tabScreenNames[index]
        : routeName;
  }

  /// Berilgan indeksdagi tabga o'tishni so'raydi (0-bosh, 1-buyurtmalar,
  /// 2-yo'nalishlar, 3-profil).
  static void switchTo(int index) => tabRequest.value = index;
}

class _BottomNavBarPageState extends State<BottomNavBarPage> {
  int _pageIndex = 0;

  late final List<Widget> _pages = const [
    MainPage(),
    BookedTicketsPage(),
    DestinationsListPage(),
    ProfilePage(),
  ];

  late final List<bool> _loaded = List<bool>.filled(_pages.length, false);

  bool _shouldShowcase = false;
  bool _showcaseStarted = false;
  static const String _showcaseSeenKey = "main_showcase_seen";

  @override
  void initState() {
    _pageIndex = (widget.pageIndex ?? 0).clamp(0, _pages.length - 1);
    _loaded[_pageIndex] = true;
    BottomNavBarPage.currentTabIndex.value = _pageIndex;
    super.initState();
    BottomNavBarPage.tabRequest.addListener(_onTabRequest);
    _shouldShowcase = MySafarSdk.config.enableShowcaseTour &&
        _pageIndex == 0 &&
        sdkStorage().read(_showcaseSeenKey) != true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkGateway.consumePendingLink();
    });
  }

  @override
  void dispose() {
    BottomNavBarPage.tabRequest.removeListener(_onTabRequest);
    if (BottomNavBarPage.currentTabIndex.value == _pageIndex) {
      BottomNavBarPage.currentTabIndex.value = 0;
    }
    super.dispose();
  }

  void _setPageIndex(int index) {
    if (_pageIndex == index) return;
    setState(() {
      _pageIndex = index;
      _loaded[index] = true;
    });
    BottomNavBarPage.currentTabIndex.value = index;
    // screen_view faqat navbar tepada bo'lsa; markScreen takrorni tashlaydi
    // va joriy ekran nomini (api_error/button_tap uchun) yangilaydi.
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      NavigationService.markScreen(BottomNavBarPage.currentScreenName());
    }
  }

  void _onTabRequest() {
    final int? index = BottomNavBarPage.tabRequest.value;
    if (index == null) return;
    BottomNavBarPage.tabRequest.value = null;
    if (!mounted || index < 0 || index >= _pages.length) return;
    _setPageIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return ShowCaseWidget(
      enableAutoScroll: true,
      onFinish: () => sdkStorage().write(_showcaseSeenKey, true),
      builder: (showcaseContext) {
        if (_shouldShowcase && !_showcaseStarted) {
          _showcaseStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            sdkStorage().write(_showcaseSeenKey, true);
            ShowCaseWidget.of(showcaseContext).startShowCase([
              HomeShowcaseKeys.notif,
              HomeShowcaseKeys.support,
              HomeShowcaseKeys.search,
              HomeShowcaseKeys.hot,
              HomeShowcaseKeys.tabOrders,
              HomeShowcaseKeys.tabServices,
              HomeShowcaseKeys.tabProfile,
            ]);
          });
        }
        return Scaffold(
          backgroundColor: isDark
              ? ProjectTheme.backgroundDark
              : ProjectTheme.backgroundLight,
          // Kontent shisha panel ostidan o'tadi; tab sahifalari pastki
          // bo'shliqni `MediaQuery.paddingOf(context).bottom` orqali oladi.
          extendBody: true,
          body: IndexedStack(
            index: _pageIndex,
            children: [
              for (int i = 0; i < _pages.length; i++)
                _loaded[i] ? _pages[i] : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, isDark),
        );
      },
    );
  }

  /// iOS "liquid glass" uslubidagi suzuvchi panel — Android va iOS'da bir xil.
  /// Scaffold `extendBody: true` bo'lgani uchun kontent panel ostidan
  /// scroll bo'lib o'tadi va blur orqali ko'rinib turadi.
  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final style = MySafarSdk.config.bottomBarStyle;
    final double radius = style?.borderRadius ?? 40;
    final EdgeInsets padding = style?.padding ?? const EdgeInsets.all(6);
    final double blurSigma = style?.blurSigma ?? 24;
    final double shadowOpacity = isDark
        ? (style?.shadowOpacityDark ?? 0.45)
        : (style?.shadowOpacityLight ?? 0.12);
    final Color tint = isDark
        ? (style?.backgroundColorDark ??
            const Color(0xFF2A2A2E).withOpacity(0.55))
        : (style?.backgroundColorLight ?? Colors.white.withOpacity(0.62));

    final items = <_NavItemData>[
      _NavItemData(
        label: "home".tr(),
        outlineAsset: Assets.iconsNavHomeOutline,
        filledAsset: Assets.iconsNavHomeFilled,
      ),
      _NavItemData(
        label: "orders".tr(),
        outlineAsset: Assets.iconsNavOrdersOutline,
        filledAsset: Assets.iconsNavOrdersFilled,
        showcaseKey: HomeShowcaseKeys.tabOrders,
        showcaseTitle: "showcase_orders_title".tr(),
        showcaseDesc: "showcase_orders_desc".tr(),
      ),
      _NavItemData(
        label: "destinations_tab".tr(),
        outlineAsset: Assets.iconsNavDestinationsOutline,
        filledAsset: Assets.iconsNavDestinationsFilled,
        showcaseKey: HomeShowcaseKeys.tabServices,
        showcaseTitle: "showcase_popular_title".tr(),
        showcaseDesc: "showcase_popular_desc".tr(),
      ),
      _NavItemData(
        label: "profile".tr(),
        outlineAsset: Assets.iconsNavProfileOutline,
        filledAsset: Assets.iconsNavProfileFilled,
        showcaseKey: HomeShowcaseKeys.tabProfile,
        showcaseTitle: "showcase_profile_title".tr(),
        showcaseDesc: "showcase_profile_desc".tr(),
      ),
    ];
    assert(items.length == _pages.length);

    final Color bodyColor =
        isDark ? ProjectTheme.backgroundDark : ProjectTheme.backgroundLight;

    // Region ekranning eng pastki qismini qoplaydi — Android tizim navigatsiya
    // paneli rangi shu yerdan olinadi va sahifa foniga moslashadi.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: bodyColor,
        systemNavigationBarDividerColor: bodyColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: _glassBar(
        items: items,
        isDark: isDark,
        radius: radius,
        padding: padding,
        blurSigma: blurSigma,
        shadowOpacity: shadowOpacity,
        tint: tint,
      ),
    );
  }

  Widget _glassBar({
    required List<_NavItemData> items,
    required bool isDark,
    required double radius,
    required EdgeInsets padding,
    required double blurSigma,
    required double shadowOpacity,
    required Color tint,
  }) {
    final style = MySafarSdk.config.bottomBarStyle;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: CustomPaint(
          // Soya faqat panel TASHQARISIDA chiziladi — aks holda shaffof
          // shisha ortidan qorayib ko'rinadi.
          painter: _OuterShadowPainter(
            radius: radius,
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: style?.shadowBlurRadius ?? 24,
            offset: style?.shadowOffset ?? const Offset(0, 8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              enabled: blurSigma > 0,
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(tint, Colors.white, isDark ? 0.04 : 0.25)!,
                      tint,
                    ],
                  ),
                ),
                child: CustomPaint(
                  foregroundPainter:
                      _GlassRimPainter(radius: radius, isDark: isDark),
                  child: Padding(
                    padding: padding,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double itemWidth =
                            constraints.maxWidth / items.length;
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 420),
                              curve: const Cubic(0.25, 1.1, 0.4, 1.0),
                              left: itemWidth * _pageIndex,
                              width: itemWidth,
                              top: 0,
                              bottom: 0,
                              child: _selectionPill(
                                radius: math.max(0, radius - padding.top),
                                isDark: isDark,
                              ),
                            ),
                            Row(
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  Expanded(
                                    child: _navItem(
                                      index: i,
                                      data: items[i],
                                      isDark: isDark,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tanlangan tab ostidagi suzuvchi shisha "linza".
  Widget _selectionPill({required double radius, required bool isDark}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark
            ? Colors.white.withOpacity(0.14)
            : const Color(0xFF1B2541).withOpacity(0.07),
        border: Border.all(
          width: 0.8,
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.white.withOpacity(0.70),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required _NavItemData data,
    required bool isDark,
  }) {
    final bool selected = _pageIndex == index;
    final Color activeColor = isDark ? Colors.white : const Color(0xFF1B2541);
    final Color unselectedColor = isDark
        ? ProjectTheme.secondaryTextDark.withOpacity(0.75)
        : const Color(0xFF7A849E);
    final Color color = selected ? activeColor : unselectedColor;

    final Widget item = _PressScale(
      onTap: () {
        if (_pageIndex != index) {
          HapticFeedback.selectionClick();
          _setPageIndex(index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              // Tanlangan ikonka biroz kattalashadi (yengil "pop" bilan).
              scale: selected ? 1.18 : 1,
              duration: const Duration(milliseconds: 320),
              curve: selected ? Curves.easeOutBack : Curves.easeOut,
              child: SizedBox(
                width: 24,
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale:
                          Tween<double>(begin: 0.8, end: 1).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SvgPicture.asset(
                    selected ? data.filledAsset : data.outlineAsset,
                    key: ValueKey<bool>(selected),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(
                data.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );

    if (data.showcaseKey == null) return item;

    return Showcase(
      key: data.showcaseKey!,
      title: data.showcaseTitle,
      description: data.showcaseDesc,
      targetBorderRadius: BorderRadius.circular(30),
      targetPadding: const EdgeInsets.all(4),
      tooltipBackgroundColor: ProjectTheme.brandColor,
      textColor: Colors.white,
      child: item,
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.outlineAsset,
    required this.filledAsset,
    this.showcaseKey,
    this.showcaseTitle,
    this.showcaseDesc,
  });

  final String label;
  final String outlineAsset;
  final String filledAsset;
  final GlobalKey? showcaseKey;
  final String? showcaseTitle;
  final String? showcaseDesc;
}

/// Bosilganda elementni biroz kichraytiradi (iOS tab bar "press" hissi).
class _PressScale extends StatefulWidget {
  const _PressScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Shisha panel qirrasidagi yorug' chiziq — tepada yorqin, pastga xiralashadi.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({required this.radius, required this.isDark});

  final double radius;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 1;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.05)]
            : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.35)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          rect, Radius.circular(math.max(0, radius - stroke / 2))),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.isDark != isDark;
}

/// Faqat panel tashqarisiga tushadigan soya.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({
    required this.radius,
    required this.color,
    required this.blurRadius,
    required this.offset,
  });

  final double radius;
  final Color color;
  final double blurRadius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect shape =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final Rect bounds =
        (Offset.zero & size).inflate(blurRadius * 2 + offset.distance);

    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addRRect(shape));
    canvas.drawRRect(
      shape.shift(offset),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, Shadow.convertRadiusToSigma(blurRadius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.blurRadius != blurRadius ||
      oldDelegate.offset != offset;
}
