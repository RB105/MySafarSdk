// ignore_for_file: deprecated_member_use
part of '../main_page.dart';

/// Asosiy chipta qidiruv formasi — yuqorida ikki tab: **Aviachipta** (qayerdan/
/// qayerga + swap, sana, yo'lovchilar, doimiy "Bilet topish" tugmasi) va
/// **Smart qidiruv** (AI qidiruv). Rasm dizayniga mos oq karta ko'rinishida.
///
/// Bosh sahifaga bevosita joylashtiriladi, shuningdek MainInputPage uni
/// alohida sahifa sifatida o'raydi (notification/deeplink uchun).
///
/// [autoPromptDirections] true bo'lganda (alohida sahifa) forma ochilishi
/// bilan shahar tanlash oynalari ketma-ket avtomatik ochiladi. Bosh sahifaga
/// joylashtirilganda false — foydalanuvchi maydonlarni o'zi bosadi.
class MainSearchForm extends StatefulWidget {
  final bool isSmart;
  final AirPortsModel? nearbyAirport;
  final bool autoPromptDirections;

  /// Bosh sahifadagi Figma dizayni: tab'lar o'rniga to'q sariq (orange) uslub,
  /// "To'g'ri reys" / "Bagaj bilan" toggle'lari va "Bilet izlash" tugmasi.
  /// `false` bo'lganda — eski tab'li (Aviachipta/Smart) forma (MainInputPage).
  final bool homeStyle;

  const MainSearchForm({
    super.key,
    this.isSmart = false,
    this.nearbyAirport,
    this.autoPromptDirections = false,
    this.homeStyle = false,
  });

  @override
  State<MainSearchForm> createState() => _MainSearchFormState();
}

class _MainSearchFormState extends State<MainSearchForm> {
  bool isSmart = false;

  // Yo'riqli (guided) qidiruv oqimidagi qadamlar tartibi:
  // qayerdan → qayerga → sana → yo'lovchilar.
  static const int _stepFrom = 0;
  static const int _stepTo = 1;
  static const int _stepDate = 2;
  static const int _stepPassengers = 3;

  PickerDateRange? pickerDateRange;

  AirPortsModel? fromDir;
  AirPortsModel? toDir;

  int adt = 1;
  int chd = 0;
  int inf = 0;

  String klass = "a";

  // Figma bosh sahifa toggle'lari (faqat homeStyle rejimida ko'rinadi).
  bool directOnly = false; // "To'g'ri reys"
  bool withBaggage = true; // "Bagaj bilan"

  bool get isFilled =>
      pickerDateRange?.startDate != null && fromDir != null && toDir != null;

  /// True when the departure and arrival cities are the same (e.g. TAS -> TAS).
  bool get isSameAirport =>
      fromDir != null &&
      toDir != null &&
      fromDir!.cityIataCode == toDir!.cityIataCode;

  bool _didInitFromDir = false;

  @override
  void initState() {
    super.initState();
    isSmart = widget.isSmart;

    // context / EasyLocalization faqat didChangeDependencies da ishlatiladi.
    if (widget.nearbyAirport != null) {
      fromDir = widget.nearbyAirport;
      _didInitFromDir = true;
    }

    // Alohida sahifada ochilganda (oddiy rejim) — yo'riqli oqim avtomatik
    // ishga tushadi: bo'sh maydonlar ketma-ket (qayerdan → qayerga → sana →
    // yo'lovchilar) ochiladi va hammasi to'lganda o'zi qidiradi. Bosh sahifaga
    // joylashtirilganda ochilmaydi — foydalanuvchi maydonlarni o'zi bosadi.
    if (widget.autoPromptDirections && !widget.isSmart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _runGuidedFlow(_firstEmptyStep());
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default "Qayerdan" = Toshkent (tilga mos). initState da InheritedWidget
    // o'qib bo'lmaydi — shu yerda bir marta o'rnatamiz.
    if (!_didInitFromDir && fromDir == null && widget.nearbyAirport == null) {
      final lang = context.locale.languageCode;
      fromDir = DefaultAirports.tashkent(lang: lang);
      _didInitFromDir = true;
    }
  }

  /// Lokatsiya bo'yicha aniqlangan yaqin aeroport keyinroq (async) kelganda —
  /// foydalanuvchi hali default Toshkentni o'zgartirmagan bo'lsa, yangilanadi.
  @override
  void didUpdateWidget(covariant MainSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nearbyAirport != null &&
        widget.nearbyAirport != oldWidget.nearbyAirport &&
        (fromDir == null || DefaultAirports.isTashkent(fromDir))) {
      setState(() {
        fromDir = widget.nearbyAirport;
        _didInitFromDir = true;
      });
    }
  }

  void _setSmart(bool value) {
    if (isSmart == value) return;
    HapticFeedback.selectionClick();
    setState(() => isSmart = value);
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      final tmp = fromDir;
      fromDir = toDir;
      toDir = tmp;
    });
  }

  /// Maydon bosilganda: qidiruv allaqachon to'liq bo'lsa — faqat shu maydonni
  /// tahrirlaymiz (oqim/avto-qidiruv yo'q); aks holda yo'riqli oqimni shu
  /// qadamdan boshlab yuritamiz.
  ///
  /// Bosh sahifa (`homeStyle`): faqat Qayerdan/Qayerga — sana/yo'lovchi
  /// RouteSearchPage da. Ikkalasi tanlansa shu sahifaga o'tamiz.
  void _onFieldTap(int step) {
    HapticFeedback.selectionClick();
    if (widget.homeStyle) {
      _homeFieldTap(step);
      return;
    }
    if (isFilled) {
      _promptStep(step);
    } else {
      _runGuidedFlow(step);
    }
  }

  Future<void> _homeFieldTap(int step) async {
    // Ikkalasi oldindan to'liq bo'lsa — faqat tahrir; sana/yo'lovchi
    // auto-oqimi qayta ochilmaydi.
    final hadBoth = fromDir != null && toDir != null;
    final picked = await _promptStep(step);
    if (!mounted || !picked) return;

    // Qayerdan → keyin avtomatik Qayerga.
    if (step == _stepFrom && toDir == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final toPicked = await _promptStep(_stepTo);
      if (!mounted || !toPicked) return;
    }

    if (fromDir != null && toDir != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RouteSearchPage(
            from: fromDir!,
            to: toDir!,
            // Birinchi marta yo'nalish to'lganda: sana → yo'lovchi.
            autoPromptDatePassengers: !hadBoth,
          ),
        ),
      );
    }
  }

  /// Birinchi bo'sh (to'ldirilmagan) qadamni qaytaradi.
  int _firstEmptyStep() {
    if (fromDir == null) return _stepFrom;
    if (toDir == null) return _stepTo;
    if (pickerDateRange?.startDate == null) return _stepDate;
    return _stepPassengers;
  }

  bool _isStepFilled(int step) {
    switch (step) {
      case _stepFrom:
        return fromDir != null;
      case _stepTo:
        return toDir != null;
      case _stepDate:
        return pickerDateRange?.startDate != null;
      default:
        return false; // yo'lovchilar — har doim so'raladi
    }
  }

  /// Yo'riqli (guided) oqim: [startStep] dan boshlab keyingi BO'SH maydonlarni
  /// ketma-ket ochadi (qayerdan → qayerga → sana → yo'lovchilar) va hammasi
  /// to'lganda "Bilet topish"ni bosmasdan avtomatik qidiradi. Istalgan qadam
  /// bekor qilinsa (null qaytsa) oqim to'xtaydi va avto-qidiruv bo'lmaydi.
  Future<void> _runGuidedFlow(int startStep) async {
    for (int step = startStep; step <= _stepPassengers; step++) {
      // Bosilgan qadamdan keyingilari faqat bo'sh bo'lsa ochiladi.
      if (step != startStep && _isStepFilled(step)) continue;

      // Oldingi oyna yopilish animatsiyasi tugashi uchun qisqa pauza.
      if (step != startStep) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
      }

      final picked = await _promptStep(step);
      if (!mounted) return;
      if (!picked) return; // bekor qilindi
    }

    // Hammasi to'liq — avtomatik qidiruv.
    if (isFilled) _search();
  }

  /// Bitta qadamning tanlash oynasini ochadi. Foydalanuvchi tanlasa `true`,
  /// bekor qilsa (null qaytsa) `false` qaytaradi.
  Future<bool> _promptStep(int step) async {
    switch (step) {
      case _stepFrom:
        final r = await ProjectDialogs.showCitySearchPicker(context, 0);
        if (!mounted || r == null) return false;
        setState(() => fromDir = r);
        return true;
      case _stepTo:
        final r = await ProjectDialogs.showCitySearchPicker(context, 1);
        if (!mounted || r == null) return false;
        setState(() => toDir = r);
        // Non-home: Qayerdan → qayerga tanlandi — RouteSearchPage ga o'tamiz.
        // homeStyle da navigatsiya `_homeFieldTap` ichida (From ham yangilanganda).
        if (!widget.homeStyle && fromDir != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RouteSearchPage(
                from: fromDir!,
                to: r,
                autoPromptDatePassengers: true,
              ),
            ),
          );
          return false; // eski qadam zanjiri (sana/yo'lovchi) ochilmaydi
        }
        return true;
      case _stepDate:
        final r = await ProjectDialogs.showCalendartPicker(
            context, 1, pickerDateRange, fromDir, toDir);
        if (!mounted || r == null) return false;
        setState(() => pickerDateRange = r);
        return true;
      case _stepPassengers:
        final r = await ProjectDialogs.showPassengerCountPicker(
            context, {"adt": adt, "chd": chd, "inf": inf, "klass": klass});
        if (!mounted || r == null) return false;
        setState(() {
          adt = r['adt'] ?? 1;
          chd = r['chd'] ?? 0;
          inf = r['inf'] ?? 0;
          klass = r['klass'] ?? "a";
        });
        return true;
      default:
        return false;
    }
  }

  void _search() {
    HapticFeedback.mediumImpact();
    if (!isFilled) {
      showToastTr("home_fill_search");
      return;
    }
    if (isSameAirport) {
      showToastTr("same_airport_warning");
      return;
    }
    AnalyticsService().trackTicketSearched(
      passengers: adt + chd + inf,
      roundTrip: pickerDateRange?.endDate != null,
      travelClass: klass,
    );
    final params = RecommendationRequestBody(
        adt: adt,
        chd: chd,
        inf: inf,
        segments: _getSegments(),
        isDirectOnly: widget.homeStyle ? (directOnly ? 1 : 0) : 0,
        isBaggage: widget.homeStyle ? withBaggage : null,
        flight_Type: pickerDateRange?.endDate != null ? 1 : 0,
        klass: klass);
    ProjectUtils.setRecommendationParams(params);
    // Oxirgi qidiruvni lokal Hive keshga yozamiz (bosh sahifada ko'rsatiladi).
    RecentSearchCache().add(params);
    Navigator.of(context)
        .pushNamed(RecommendationsTicketPage.routeName, arguments: params);
  }

  @override
  Widget build(BuildContext context) {
    // Bosh sahifa — Figma dizayni (tab'siz, orange uslub, toggle'lar).
    if (widget.homeStyle) return _homeCard(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: context.shadowDown,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tabBar(context),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  // Yo'nalishli surilish + fade: yangi kontent tanlangan tab
                  // tomonidan kirib keladi, eskisi qarama-qarshi tomonga chiqadi.
                  transitionBuilder: (child, animation) {
                    final isSmartChild = child.key == const ValueKey('smart');
                    final isIncoming = isSmartChild == isSmart;
                    final beginDx = isIncoming
                        ? (isSmart ? 0.15 : -0.15)
                        : (isSmart ? -0.15 : 0.15);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(beginDx, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  // Kontent tepadan tekislanadi — balandlik o'zgarganda
                  // AnimatedSize bilan silliq (o'rtaga sakramaydi).
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  child: isSmart
                      ? const KeyedSubtree(
                          key: ValueKey('smart'),
                          child: SmartSearchWidget(),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('avia'),
                          child: _aviaForm(context),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Bosh sahifa (MySafar video) — faqat Qayerdan / Qayerga + circular swap.
  // Sana, yo'lovchi, toggle va "Bilet izlash" RouteSearchPage da.
  // ───────────────────────────────────────────────────────────────────────

  Widget _homeCard(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color glass = isDark
        ? Colors.black.withOpacity(0.28)
        : Colors.white.withOpacity(0.94);
    final Color border = isDark
        ? Colors.white.withOpacity(0.22)
        : Colors.white.withOpacity(0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: _homeFromToBlock(context),
        ),
      ),
    );
  }

  /// Bitta karta ichida From / To + circular orange swap (MySafar home).
  Widget _homeFromToBlock(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color divider = isDark
        ? Colors.white.withOpacity(0.18)
        : const Color(0xFFE6EAF0);
    final Color fieldBg = isDark ? Colors.white : Colors.transparent;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _homeRouteRow(
              context,
              value: fromDir?.cityName,
              placeholder: "from".tr(),
              onTap: () => _onFieldTap(_stepFrom),
              background: fieldBg,
              topRadius: true,
            ),
            Divider(height: 1, thickness: 1, color: divider),
            _homeRouteRow(
              context,
              value: toDir?.cityName,
              placeholder: "to".tr(),
              onTap: () => _onFieldTap(_stepTo),
              background: fieldBg,
              topRadius: false,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: _orangeSwapButton(context, circular: true),
        ),
      ],
    );
  }

  Widget _homeRouteRow(
    BuildContext context, {
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    required Color background,
    required bool topRadius,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final radius = topRadius
        ? const BorderRadius.vertical(top: Radius.circular(23))
        : const BorderRadius.vertical(bottom: Radius.circular(23));
    return Material(
      color: background,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 66, 18),
            child: Text(
              hasValue ? value : placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasValue
                  ? context.textTheme.displayLarge
                      ?.copyWith(color: ProjectTheme.textColorLight)
                  : context.textTheme.headlineLarge
                      ?.copyWith(color: ProjectTheme.secondaryTextLight),
            ),
          ),
        ),
      ),
    );
  }

  /// Orange swap — home'da circular (MySafar video), boshqa joyda rounded square.
  Widget _orangeSwapButton(BuildContext context, {bool circular = false}) {
    final radius = circular ? 23.0 : 14.0;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: ProjectTheme.accentOrange,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _swap,
          child: const Icon(Icons.swap_vert_rounded,
              color: Colors.white, size: 24),
        ),
      ),
    );
  }

  /// Yuqoridagi ikki tab — sirg'aluvchi oq "pill" bilan.
  Widget _tabBar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final tabWidth = c.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment:
                    isSmart ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: context.color.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0A2540),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _tab(
                      context,
                      icon: Icons.flight_rounded,
                      label: "home_tab_avia".tr(),
                      active: !isSmart,
                      onTap: () => _setSmart(false),
                    ),
                  ),
                  Expanded(
                    child: _tab(
                      context,
                      icon: Icons.auto_awesome_rounded,
                      label: "home_tab_smart".tr(),
                      active: isSmart,
                      onTap: () => _setSmart(true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? ProjectTheme.brandColor : context.disabledTextColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Center(
        // Uzun tarjimalar tor ekranda toraymasdan biroz kichrayadi.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: (active
                        ? context.textTheme.displayMedium
                        : context.textTheme.bodyMedium)
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aviaForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Qayerdan / Qayerga — ikki alohida karta; o'rtadagi bo'shliqda
        // markazda suzuvchi almashtirish tugmasi ikkovini bog'lab turadi.
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fieldCard(
                  context,
                  child: _fieldRow(
                    context,
                    icon: Icons.flight_takeoff_rounded,
                    label: "from".tr(),
                    value: fromDir?.cityName,
                    hint: "home_choose_city".tr(),
                    onTap: () => _onFieldTap(_stepFrom),
                  ),
                ),
                const SizedBox(height: 20),
                _fieldCard(
                  context,
                  child: _fieldRow(
                    context,
                    icon: Icons.flight_land_rounded,
                    label: "to".tr(),
                    value: toDir?.cityName,
                    hint: "home_where_to_hint".tr(),
                    onTap: () => _onFieldTap(_stepTo),
                  ),
                ),
              ],
            ),
            // Ikki karta orasidagi bo'shliqda, aynan markazda suzib turadi.
            _swapButton(context),
          ],
        ),
        const SizedBox(height: 10),
        _fieldCard(
          context,
          child: _fieldRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: "product_dates".tr(),
            value: pickerDateRange?.startDate == null ? null : _getDateTitle(),
            hint: "start_end_dates".tr(),
            onTap: () => _onFieldTap(_stepDate),
          ),
        ),
        const SizedBox(height: 10),
        _fieldCard(
          context,
          child: _fieldRow(
            context,
            icon: Icons.person_outline_rounded,
            label: "passengers".tr(),
            value: _getPassengerInfo(),
            hint: "",
            onTap: () => _onFieldTap(_stepPassengers),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ProjectTheme.blueButtonStyle,
            onPressed: _search,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("home_find_ticket".tr()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Maydonni loyiha uslubidagi yumaloq kulrang kartaga o'raydi — chiziq
  /// (divider) o'rniga. Ichidagi InkWell to'lqini karta chetiga qirqiladi.
  Widget _fieldCard(BuildContext context, {required Widget child}) {
    return Material(
      color: context.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _fieldRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ProjectTheme.brandColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? value : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasValue
                        ? context.textTheme.bodyMedium
                        : context.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swapButton(BuildContext context) {
    return Material(
      color: context.color.primaryContainer,
      shape: CircleBorder(
        side: BorderSide(color: ProjectTheme.borderLight, width: 1),
      ),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _swap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.swap_vert_rounded,
            color: ProjectTheme.brandColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  String _getDateTitle() {
    if (pickerDateRange?.endDate != null) {
      return "${ElementFormatter.formatDate(pickerDateRange?.startDate?.formattedDotDate ?? "")} - ${ElementFormatter.formatDate(pickerDateRange?.endDate?.formattedDotDate ?? "")}";
    } else if (pickerDateRange?.startDate != null) {
      return ElementFormatter.formatDate(
          pickerDateRange?.startDate?.formattedDotDate ?? "");
    }
    return "start_end_dates".tr();
  }

  String _getPassengerInfo() {
    String getKlassName() {
      switch (klass) {
        case "a":
          return "klass_a_short".tr();
        case "b":
          return "klass_b".tr();
        case "e":
          return "klass_e".tr();
        case "f":
          return "klass_f".tr();
        case "w":
          return "klass_w".tr();
        default:
          return "";
      }
    }

    return "passengers_details".tr(
        namedArgs: {"count": "${inf + chd + adt}", "klass": getKlassName()});
  }

  /// "1 yo'lovchi, Ekonom" → ("1 yo'lovchi", "Ekonom") — bosh sahifa
  /// kartachasida ikki qatorda ko'rsatish uchun (oxirgi vergul bo'yicha;
  /// vergul bo'lmasa ikkinchi qator yo'q).
  List<RecommendationReqBodySegment> _getSegments() {
    if (pickerDateRange?.endDate != null) {
      return [
        RecommendationReqBodySegment(
            from: fromDir,
            to: toDir,
            date: pickerDateRange?.startDate?.formattedDotDate),
        RecommendationReqBodySegment(
            from: toDir,
            to: fromDir,
            date: pickerDateRange?.endDate?.formattedDotDate)
      ];
    }
    return [
      RecommendationReqBodySegment(
          from: fromDir,
          to: toDir,
          date: pickerDateRange?.startDate?.formattedDotDate)
    ];
  }
}
