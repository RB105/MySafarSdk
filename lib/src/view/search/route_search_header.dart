// ignore_for_file: deprecated_member_use, unused_element
// part of route_search_page.dart — private widgets

part of 'route_search_page.dart';

/// mysafar.uz mobil ko'rinishidan olingan dizayn tokenlari.
///
/// Bu ekran webdagi yo'nalish qidiruv sahifasining (`/uz?from=..&to=..`)
/// mobil versiyasini takrorlaydi, shu sababli ranglar va o'lchamlar
/// to'g'ridan-to'g'ri web CSS'idan ko'chirilgan va atay [ProjectTheme]
/// tokenlari bilan almashtirilmagan — aks holda "bir xil" ko'rinish buziladi.
class _Web {
  const _Web._();

  /// Sahifa foni (`#f4f7fc`) — maydonlar foni ham shu rang.
  static const pageBg = Color(0xFFF4F7FC);
  static const fieldBg = Color(0xFFF4F7FC);
  static const fieldBgPressed = Color(0xFFEEF2F9);

  /// Tugmalar.
  static const gold = Color(0xFFFFA600);
  static const goldPressed = Color(0xFFE0940F);
  static const blue = Color(0xFF0F3DEA);

  /// Matn ranglari.
  static const label = Color(0xFF98A2B3);
  static const value = Color(0xFF0B1830);
  static const placeholder = Color(0xFF9AA5B5);
  static const toggleText = Color(0xFF15233D);
  static const sectionTitle = Color(0xFF0C1B38);

  /// Switch.
  static const switchOn = Color(0xFF15A05A);
  static const switchOff = Color(0xFFE4E4E4);

  /// Yordamchi fonlar.
  static const pillBg = Color(0xFFEEF3FF);
  static const iconBoxBg = Color(0xFFEAF1FF);

  /// Karta soyasi: `0 12px 30px rgba(8,28,90,.14)`.
  static const cardShadow = [
    BoxShadow(
      color: Color(0x24081C5A),
      blurRadius: 30,
      offset: Offset(0, 12),
    ),
  ];

  /// Oltin tugma soyasi: `0 10px 22px rgba(255,166,0,.3)`.
  static const goldShadow = [
    BoxShadow(
      color: Color(0x4DFFA600),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];
}

/// Doiraviy "orqaga" tugmasi. Webda bu joyda logo va menyu turadi — ilovada
/// esa sahifa push bilan ochilgani uchun qaytish tugmasi kerak.
class _HeroBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? ProjectTheme.cardColorDark : Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: isDark ? ProjectTheme.textColorDark : _Web.toggleText,
          ),
        ),
      ),
    );
  }
}

/// Web hero'sidagi oq qidiruv kartasi: qayerdan/qayerga + almashtirish
/// tugmasi + sana/yo'lovchilar katakchalari.
///
/// Webdagi tuzilish: `rounded-[18px] bg-white p-2` konteyner ichida
/// `flex-col gap-1.5` (from/to) va `mt-1.5 grid grid-cols-2 gap-1.5`
/// (sana/yo'lovchilar).
class _WebSearchCard extends StatelessWidget {
  final AirPortsModel from;
  final AirPortsModel to;
  final String dateText;
  final bool dateIsPlaceholder;
  final String paxText;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final VoidCallback onDateTap;
  final VoidCallback onPaxTap;

  const _WebSearchCard({
    required this.from,
    required this.to,
    required this.dateText,
    required this.dateIsPlaceholder,
    required this.paxText,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.onDateTap,
    required this.onPaxTap,
  });

  /// "Toshkent (TAS)" — web aynan shu formatda ko'rsatadi.
  static String _cityLabel(AirPortsModel a) {
    final name = a.cityName ?? '';
    final code = a.cityIataCode ?? '';
    if (name.isEmpty) return code;
    if (code.isEmpty) return name;
    return '$name ($code)';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? ProjectTheme.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? ProjectTheme.borderDark : const Color(0xFFE7EDF6),
        ),
        boxShadow: _Web.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // from/to — almashtirish tugmasi ikkalasining ustida "suzadi".
          Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WebField(
                    label: "from".tr(),
                    value: _cityLabel(from),
                    onTap: onFromTap,
                    // O'ng tomonda almashtirish tugmasi uchun joy (web: pr-14).
                    rightPadding: 56,
                  ),
                  const SizedBox(height: 6),
                  _WebField(
                    label: "to".tr(),
                    value: _cityLabel(to),
                    onTap: onToTap,
                    rightPadding: 56,
                  ),
                ],
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _WebSwapButton(onTap: onSwap),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Sana / Yo'lovchilar — teng ikki ustun (web: grid-cols-2 gap-1.5).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WebField(
                    label: "product_dates".tr(),
                    value: dateText,
                    isPlaceholder: dateIsPlaceholder,
                    icon: Icons.calendar_today_outlined,
                    onTap: onDateTap,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _WebField(
                    label: "passengers".tr(),
                    value: paxText,
                    icon: Icons.people_outline_rounded,
                    onTap: onPaxTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartaning bitta katakchasi: tepada kichik BOSH HARFLI yorliq, ostida
/// qiymat, ixtiyoriy o'ng ikonka.
///
/// Web: `rounded-[12px] bg-[#f4f7fc] px-3.5 py-2`, yorliq `10.5px/600`
/// uppercase `tracking-[0.04em]`, qiymat `15.5px/600`.
class _WebField extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;
  final IconData? icon;
  final double rightPadding;
  final VoidCallback onTap;

  const _WebField({
    required this.label,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
    this.icon,
    this.rightPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? Colors.white.withAlpha(14) : _Web.fieldBg;
    final Color valueColor = isPlaceholder
        ? _Web.placeholder
        : (isDark ? ProjectTheme.textColorDark : _Web.value);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: isDark ? null : _Web.fieldBgPressed,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 8, rightPadding, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.42,
                        color: _Web.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: _Web.placeholder),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Oltin doiraviy almashtirish tugmasi — oq halqa bilan (web: `h-10 w-10
/// rounded-full border-[3px] border-white bg-mysafar-gold`).
class _WebSwapButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WebSwapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _Web.gold,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? ProjectTheme.cardColorDark : Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4DFFA600),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Oq "hap" shaklidagi filtr kalitlari: `To'g'ri reys` / `Bagajli`.
///
/// Web: `bg-white rounded-full pl-2 pr-3 py-2 gap-1.5`, matn `12.5px/500`.
class _WebTogglePill extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _WebTogglePill({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? ProjectTheme.cardColorDark : Colors.white,
      clipBehavior: Clip.antiAlias,
      // Fon och bo'lgani uchun oq "pill" ajralib turishi kerak.
      // Diqqat: `shape` bilan `borderRadius` ni birga berib bo'lmaydi
      // (Material assert qiladi) — radius shape ichida beriladi.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isDark ? ProjectTheme.borderDark : const Color(0xFFE7EDF6),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WebSwitch(value: value),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? ProjectTheme.textColorDark : _Web.toggleText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Webdagi switch: 48×28 yo'lak, 22×22 oq g'ildirak, yoqilganda yashil.
/// Material [Switch] o'lchamlari mos kelmagani uchun qo'lda chizilgan.
class _WebSwitch extends StatelessWidget {
  final bool value;

  const _WebSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: value ? _Web.switchOn : _Web.switchOff,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Oltin "Bilet izlash" tugmasi — web: `h-12 rounded-[20px] bg-mysafar-gold
/// text-[16px] font-bold shadow-[0_10px_22px_rgba(255,166,0,.3)]`.
class _WebSearchButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _WebSearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled ? _Web.goldShadow : null,
        ),
        child: Material(
          color: _Web.gold,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: _Web.goldPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "home_search_ticket".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web bo'lim sarlavhasi — `text-[19px] font-bold text-[#0c1b38]`.
class _WebSectionTitle extends StatelessWidget {
  final String text;

  const _WebSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: isDark ? ProjectTheme.textColorDark : _Web.sectionTitle,
      ),
    );
  }
}
