// ignore_for_file: deprecated_member_use

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:showcaseview/showcaseview.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/deep_link_gateway.dart';
import 'package:mysafar_sdk/src/view/destinations/services_page.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart';
import 'package:mysafar_sdk/src/view/main/showcase_keys.dart';
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_page.dart';
import 'package:mysafar_sdk/src/view/profile/profile_page.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class BottomNavBarPage extends StatefulWidget {
  final int? pageIndex;

  /// bottom navigation page : HomePage , BookedTicketsPage, ServicesPage
  const BottomNavBarPage({super.key, this.pageIndex});

  @override
  State<BottomNavBarPage> createState() => _BottomNavBarPageState();
  static const routeName = '/bottom_nav_bar';
}

class _BottomNavBarPageState extends State<BottomNavBarPage> {
  int _pageIndex = 0;

  // "Xizmatlar" tab'i host config'iga bog'liq — o'chiq bo'lsa sahifa ham,
  // pastki tugma ham qurilmaydi.
  late final bool _servicesEnabled = MySafarSdk.config.enableServicesTab;

  late final List<Widget> _pages = [
    const MainPage(),
    const BookedTicketsPage(),
    if (_servicesEnabled) const ServicesPage(),
    const ProfilePage(),
  ];

  int get _profileIndex => _servicesEnabled ? 3 : 2;

  late final List<bool> _loaded = List<bool>.filled(_pages.length, false);

  bool _shouldShowcase = false;
  bool _showcaseStarted = false;
  static const String _showcaseSeenKey = "main_showcase_seen";

  @override
  void initState() {
    _pageIndex = (widget.pageIndex ?? 0).clamp(0, _pages.length - 1);
    _loaded[_pageIndex] = true;
    super.initState();
    _shouldShowcase = MySafarSdk.config.enableShowcaseTour &&
        _pageIndex == 0 &&
        sdkStorage().read(_showcaseSeenKey) != true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkGateway.consumePendingLink();
    });
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
              if (_servicesEnabled) HomeShowcaseKeys.tabServices,
              HomeShowcaseKeys.tabProfile,
            ]);
          });
        }
        return Scaffold(
          backgroundColor: isDark
              ? ProjectTheme.backgroundDark
              : ProjectTheme.backgroundLight,
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

  /// Figma: chetlardan ajralib suzib turuvchi yumaloq panel — har bir tab
  /// ikonka + doimiy yozuv; aktiv tab ikonkasi oq doira ichida.
  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final style = MySafarSdk.config.bottomBarStyle;
    final shadowOpacity = isDark
        ? (style?.shadowOpacityDark ?? 0.45)
        : (style?.shadowOpacityLight ?? 0.12);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: style?.padding ?? const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark
              ? (style?.backgroundColorDark ?? ProjectTheme.cardColorDark)
              : (style?.backgroundColorLight ?? ProjectTheme.cardColorLight),
          borderRadius: BorderRadius.circular(style?.borderRadius ?? 40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: style?.shadowBlurRadius ?? 24,
              offset: style?.shadowOffset ?? const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                  index: 0,
                  asset: Assets.homeHouseIcon,
                  label: "home".tr(),
                  isDark: isDark),
            ),
            Expanded(
              child: _navItem(
                  index: 1,
                  asset: Assets.homeTicket,
                  label: "orders".tr(),
                  isDark: isDark,
                  showcaseKey: HomeShowcaseKeys.tabOrders,
                  showcaseTitle: "showcase_orders_title".tr(),
                  showcaseDesc: "showcase_orders_desc".tr()),
            ),
            if (_servicesEnabled)
              Expanded(
                child: _navItem(
                    index: 2,
                    asset: Assets.homeHomeService,
                    label: "services".tr(),
                    isDark: isDark,
                    showcaseKey: HomeShowcaseKeys.tabServices,
                    showcaseTitle: "showcase_services_title".tr(),
                    showcaseDesc: "showcase_services_desc".tr()),
              ),
            Expanded(
              child: _navItem(
                  index: _profileIndex,
                  iconData: Icons.person_outline_rounded,
                  label: "profile".tr(),
                  isDark: isDark,
                  showcaseKey: HomeShowcaseKeys.tabProfile,
                  showcaseTitle: "showcase_profile_title".tr(),
                  showcaseDesc: "showcase_profile_desc".tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required bool isDark,
    String? asset,
    IconData? iconData,
    GlobalKey? showcaseKey,
    String? showcaseTitle,
    String? showcaseDesc,
  }) {
    final bool selected = _pageIndex == index;
    // Figma: aktiv — to'q ko'k (navy), passiv — ko'kimtir kulrang.
    final Color activeColor = isDark ? Colors.white : const Color(0xFF1B2541);
    final Color unselectedColor =
        isDark ? ProjectTheme.secondaryTextDark : const Color(0xFF8E99B5);
    final Color color = selected ? activeColor : unselectedColor;

    final Widget item = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_pageIndex != index) {
          HapticFeedback.selectionClick();
          setState(() {
            _pageIndex = index;
            _loaded[index] = true;
          });
        }
      },
      // Aktiv element butunlay (ikonka + yozuv) kulrang pill ichida (Figma).
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? Colors.white.withOpacity(0.10)
                  : const Color(0xFFE4E6EC))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(asset: asset, iconData: iconData, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );

    if (showcaseKey == null) return item;

    return Showcase(
      key: showcaseKey,
      title: showcaseTitle,
      description: showcaseDesc,
      targetBorderRadius: BorderRadius.circular(30),
      targetPadding: const EdgeInsets.all(4),
      tooltipBackgroundColor: ProjectTheme.brandColor,
      textColor: Colors.white,
      child: item,
    );
  }

  Widget _icon({String? asset, IconData? iconData, required Color color}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: asset != null
          ? SvgPicture.asset(
              asset,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          : Icon(iconData, size: 24, color: color),
    );
  }
}
