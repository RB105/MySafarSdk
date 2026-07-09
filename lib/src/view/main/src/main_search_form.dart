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

  @override
  void initState() {
    super.initState();
    isSmart = widget.isSmart;

    if (widget.nearbyAirport != null) {
      fromDir = widget.nearbyAirport;
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

  /// Lokatsiya bo'yicha aniqlangan yaqin aeroport keyinroq (async) kelganda —
  /// foydalanuvchi hali "qayerdan"ni qo'lda o'zgartirmagan bo'lsa, uni
  /// avtomatik to'ldiramiz.
  @override
  void didUpdateWidget(covariant MainSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nearbyAirport != null &&
        widget.nearbyAirport != oldWidget.nearbyAirport &&
        fromDir == null) {
      setState(() => fromDir = widget.nearbyAirport);
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
  void _onFieldTap(int step) {
    HapticFeedback.selectionClick();
    if (isFilled) {
      _promptStep(step);
    } else {
      _runGuidedFlow(step);
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
      showToastMessage("home_fill_search".tr());
      return;
    }
    if (isSameAirport) {
      showToastMessage("same_airport_warning".tr());
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
  // Bosh sahifa (Figma) — orange uslubli qidiruv kartasi
  // ───────────────────────────────────────────────────────────────────────

  Widget _homeCard(BuildContext context) {
    // Frosted (shishasimon) karta — orqa fon rasmi ustida suzadi.
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fromToBlock(context),
              const SizedBox(height: 4),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _miniCell(
                        context,
                        icon: Icons.calendar_today_rounded,
                        value: pickerDateRange?.startDate == null
                            ? null
                            : _getDateTitle(),
                        hint: "home_departure".tr(),
                        onTap: () => _onFieldTap(_stepDate),
                          radius: BorderRadius.only(bottomLeft: Radius.circular(12))
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Builder(builder: (context) {
                        final (paxTitle, paxKlass) = _passengerParts();
                        return _miniCell(
                          context,
                          icon: Icons.people_alt_outlined,
                          value: paxTitle,
                          subtitle: paxKlass,
                          hint: "",
                          onTap: () => _onFieldTap(_stepPassengers),
                            radius: BorderRadius.only(bottomRight: Radius.circular(12))
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _homeToggle(
                      context,
                      label: "home_direct_flight".tr(),
                      value: directOnly,
                      onChanged: (v) => setState(() => directOnly = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _homeToggle(
                      context,
                      label: "home_with_baggage".tr(),
                      value: withBaggage,
                      onChanged: (v) => setState(() => withBaggage = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ProjectTheme.orangeButtonStyle,
                  onPressed: _search,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text("home_search_ticket".tr()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qayerdan / Qayerga — ikkita ALOHIDA oq karta, orasida ochiq bo'shliq;
  /// o'ngda orange kvadrat swap tugmasi ikkovining kesishmasida turadi (Figma).
  Widget _fromToBlock(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bigField(context,
                value: fromDir?.cityName,
                placeholder: "from".tr(),
                onTap: () => _onFieldTap(_stepFrom),
                radius: BorderRadius.vertical(top: Radius.circular(12))
            ),
            const SizedBox(height: 4),
            _bigField(
              context,
              value: toDir?.cityName,
              placeholder: "to".tr(),
              onTap: () => _onFieldTap(_stepTo),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _orangeSwapButton(context),
        ),
      ],
    );
  }

  /// From/To maydoni — alohida oq karta, bitta qator matn (Figma).
  Widget _bigField(BuildContext context,
      {required String? value,
      required String placeholder,
      required VoidCallback onTap,
      BorderRadius? radius}) {
    final hasValue = value != null && value.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 66, 16),
            child: Text(
              hasValue ? value : placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Karta har doim oq — ranglar temaga bog'lanmaydi (dark rejimda
              // theme rangi oq bo'lib, oq kartada ko'rinmay qolardi).
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

  /// Sana / yo'lovchilar kartachasi — oq, chapda matn (ixtiyoriy ikkinchi
  /// qator bilan), o'ngda kulrang ikonka (Figma).
  Widget _miniCell(BuildContext context,
      {required IconData icon,
      required String? value,
      required String hint,
      String? subtitle,
      required VoidCallback onTap,
      BorderRadius? radius}) {
    final hasValue = value != null && value.isNotEmpty;
    final hasSubtitle = hasValue && subtitle != null && subtitle.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasValue ? value : hint,
                        maxLines: hasSubtitle ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        // Oq kartada temadan mustaqil ranglar (dark rejim uchun).
                        style: hasValue
                            ? context.textTheme.displayMedium?.copyWith(
                                fontSize: 15,
                                color: ProjectTheme.textColorLight)
                            : context.textTheme.headlineMedium?.copyWith(
                                color: ProjectTheme.secondaryTextLight),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.headlineSmall?.copyWith(
                              color: ProjectTheme.secondaryTextLight),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: ProjectTheme.secondaryTextLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "To'g'ri reys" / "Bagaj bilan" — yarim shaffof PILL (kapsula) ichida:
  /// chapda switch, o'ngda oq yozuv (Figma).
  Widget _homeToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    onChanged(v);
                  },
                  activeTrackColor: ProjectTheme.switchGreen,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.45),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Orange KVADRAT (yumaloq burchakli) swap tugmasi — Figma bo'yicha.
  Widget _orangeSwapButton(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: ProjectTheme.accentOrange,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
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
  (String, String?) _passengerParts() {
    final full = _getPassengerInfo();
    final idx = full.lastIndexOf(', ');
    if (idx <= 0) return (full, null);
    return (full.substring(0, idx), full.substring(idx + 2));
  }

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
