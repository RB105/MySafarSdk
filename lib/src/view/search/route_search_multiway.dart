// part of route_search_page.dart — murakkab marshrut ("slojniy marshrut")
// tabining ko'rinish qatlami.

part of 'route_search_page.dart';

/// Rejim tab paneli — oddiy qidiruv / murakkab marshrut. Holat
/// [TabController]da (sahifa uning tinglovchisi orqali cubit'ni yangilaydi).
class _RouteModeTabBar extends StatelessWidget {
  final TabController controller;

  const _RouteModeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _SegmentedPill(
        onHero: true,
        height: 40,
        selectedIndex: controller.index,
        onChanged: (i) => controller.index = i,
        items: [
          _SegmentItem(
            "simple_route".tr(),
            outlineIcon: Assets.iconsSearchOneWayOutline,
            filledIcon: Assets.iconsSearchOneWayFilled,
          ),
          _SegmentItem(
            "multiway".tr(),
            outlineIcon: Assets.iconsSearchMultiRouteOutline,
            filledIcon: Assets.iconsSearchMultiRouteFilled,
          ),
        ],
      ),
    );
  }
}

/// Murakkab marshrut kartasi — oddiy qidiruv kartasi bilan bir xil oq karta,
/// ichida yo'nalishlar ro'yxati (maksimum [RouteSearchState.maxLegs] ta),
/// "reys qo'shish" tugmasi va yo'lovchilar katakchasi.
class _MultiRouteCard extends StatelessWidget {
  final List<RouteLeg> legs;
  final String paxText;
  final bool canAdd;
  final bool canRemove;
  final void Function(int index) onFromTap;
  final void Function(int index) onToTap;
  final void Function(int index) onDateTap;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;
  final VoidCallback onPaxTap;

  const _MultiRouteCard({
    required this.legs,
    required this.paxText,
    required this.canAdd,
    required this.canRemove,
    required this.onFromTap,
    required this.onToTap,
    required this.onDateTap,
    required this.onRemove,
    required this.onAdd,
    required this.onPaxTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? ProjectTheme.cardColorDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: ProjectTheme.borderDark) : null,
        boxShadow: isDark ? null : _Web.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < legs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _LegBlock(
              key: ValueKey('leg_$i'),
              index: i,
              leg: legs[i],
              canRemove: canRemove,
              onFromTap: () => onFromTap(i),
              onToTap: () => onToTap(i),
              onDateTap: () => onDateTap(i),
              onRemove: () => onRemove(i),
            ),
          ],
          const SizedBox(height: 10),
          _AddLegButton(enabled: canAdd, onTap: onAdd),
          const SizedBox(height: 6),
          _WebField(
            label: "passengers".tr(),
            value: paxText,
            icon: Assets.iconsSearchPassengersIcon,
            onTap: onPaxTap,
          ),
        ],
      ),
    );
  }
}

class _LegBlock extends StatelessWidget {
  final int index;
  final RouteLeg leg;
  final bool canRemove;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onDateTap;
  final VoidCallback onRemove;

  const _LegBlock({
    super.key,
    required this.index,
    required this.leg,
    required this.canRemove,
    required this.onFromTap,
    required this.onToTap,
    required this.onDateTap,
    required this.onRemove,
  });

  static String _cityText(AirPortsModel? a, String placeholder) {
    if (a == null) return placeholder;
    final name = a.cityName ?? '';
    final code = a.cityIataCode ?? '';
    if (name.isEmpty) return code.isEmpty ? placeholder : code;
    if (code.isEmpty) return name;
    return '$name ($code)';
  }

  static String _dateText(DateTime? d) {
    if (d == null) return "choice_date".tr();
    return "${d.day} ${ElementFormatter.formatMonth(d.month).toLowerCase()}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // O'chirish tugmasining 44 dp bosish maydoni pastki oraliqni
          // o'z ichiga oladi.
          padding:
              EdgeInsets.fromLTRB(4, 0, canRemove ? 0 : 4, canRemove ? 0 : 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "route_leg_index".tr(namedArgs: {"index": "${index + 1}"}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ProjectTheme.textColorDark
                        : _Web.value,
                  ),
                ),
              ),
              if (canRemove) _LegRemoveButton(onTap: onRemove),
            ],
          ),
        ),
        _WebField(
          label: "from".tr(),
          value: _cityText(leg.from, "choose_from_dir".tr()),
          isPlaceholder: leg.from == null,
          icon: Assets.iconsTicketTakeoffIcon,
          onTap: onFromTap,
        ),
        const SizedBox(height: 6),
        _WebField(
          label: "to".tr(),
          value: _cityText(leg.to, "choose_to_dir".tr()),
          isPlaceholder: leg.to == null,
          icon: Assets.iconsTicketLandingIcon,
          onTap: onToTap,
        ),
        const SizedBox(height: 6),
        _WebField(
          label: "depDate".tr(),
          value: _dateText(leg.date),
          isPlaceholder: leg.date == null,
          icon: Assets.iconsSearchCalendarIcon,
          onTap: onDateTap,
        ),
      ],
    );
  }
}

class _LegRemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LegRemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    void handleTap() {
      HapticFeedback.lightImpact();
      onTap();
    }

    // Ko'rinishi 24 dp doira, bosish maydoni 44×44 dp (№32).
    return Semantics(
      button: true,
      label: "delete".tr(),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: _circle(handleTap)),
        ),
      ),
    );
  }

  Widget _circle(VoidCallback handleTap) {
    return Material(
      color: ProjectTheme.redBgLight.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: handleTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: _SvgIcon(
              Assets.iconsSearchCloseIcon,
              size: 14,
              color: ProjectTheme.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddLegButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _AddLegButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : ProjectTheme.brandColor;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: isDark ? Colors.white.withAlpha(14) : _Web.pillBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: ConstrainedBox(
            // Katta shriftda matn sig'ishi uchun balandlik qat'iy emas (№32).
            constraints:
                const BoxConstraints(minWidth: double.infinity, minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SvgIcon(Assets.iconsSearchAddIcon, size: 20, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    // Tarjimada "+" belgisi bor — ikonka uni takrorlamasin.
                    "add_race".tr().replaceFirst(RegExp(r'^\s*\+\s*'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
