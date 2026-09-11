// part of route_search_page.dart — murakkab marshrut ("slojniy marshrut")
// tabining ko'rinish qatlami.

part of 'route_search_page.dart';

/// Rejim tab paneli — oddiy qidiruv / murakkab marshrut.
class _RouteModeTabBar extends StatelessWidget {
  final TabController controller;

  const _RouteModeTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Light (ko'k hero): yarim-shaffof + oq pill. Dark: dark trek + oq pill.
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(14) : Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(40) : Colors.white.withAlpha(55),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        labelColor: brand,
        unselectedLabelColor: Colors.white,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(brand.withAlpha(30)),
        splashBorderRadius: BorderRadius.circular(12),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        labelStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          _tab("simple_route".tr()),
          _tab("multiway".tr()),
        ],
      ),
    );
  }

  Widget _tab(String text) => Tab(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1),
          ),
        ),
      );
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
            icon: Icons.people_outline_rounded,
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
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "route_leg_index"
                      .tr(namedArgs: {"index": "${index + 1}"})
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.42,
                    color: _Web.label,
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
          onTap: onFromTap,
        ),
        const SizedBox(height: 6),
        _WebField(
          label: "to".tr(),
          value: _cityText(leg.to, "choose_to_dir".tr()),
          isPlaceholder: leg.to == null,
          onTap: onToTap,
        ),
        const SizedBox(height: 6),
        _WebField(
          label: "depDate".tr(),
          value: _dateText(leg.date),
          isPlaceholder: leg.date == null,
          icon: Icons.calendar_today_outlined,
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
    return Material(
      color: ProjectTheme.redBgLight.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.close_rounded,
            size: 15,
            color: ProjectTheme.error,
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
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: Center(
              child: Text(
                "add_race".tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : ProjectTheme.brandColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
