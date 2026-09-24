import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/generated/assets.dart';

/// Yo'lovchilar soni va tarif (klass) tanlash sheet'i — joy qidirish va
/// kalendar oynalari bilan bir xil uslub: markazlangan sarlavha, chapda
/// yopish, tekis ro'yxat + ingichka ajratgichlar, pastda bitta brend tugma.
/// Natija `{"adt","chd","inf","klass"}` map ko'rinishida qaytariladi (eski
/// shartnoma saqlangan).
class PassengerCountWidget extends StatefulWidget {
  final Map<String, dynamic> params;

  /// Sheet'ning `DraggableScrollableSheet` controller'i — ro'yxat eng tepada
  /// bo'lganda pastga tortib yopish shu orqali ishlaydi.
  final ScrollController? scrollController;

  const PassengerCountWidget({
    super.key,
    required this.params,
    this.scrollController,
  });

  @override
  State<PassengerCountWidget> createState() => _PassengerCountWidgetState();
}

class _PassengerCountWidgetState extends State<PassengerCountWidget> {
  int adt = 1;
  int chd = 0;
  int inf = 0;
  String klass = 'a';

  /// Ro'yxat surilganda sarlavha ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  static const double _hPadding = 16;
  static const int _maxPassengers = 9;

  static const _klassOptions = [
    ('e', 'klass_e'),
    ('b', 'klass_b'),
    ('f', 'klass_f'),
    ('w', 'klass_w'),
    ('a', 'klass_a'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.params.isNotEmpty) {
      adt = widget.params['adt'] ?? 1;
      chd = widget.params['chd'] ?? 0;
      inf = widget.params['inf'] ?? 0;
      klass = widget.params['klass'] ?? 'a';
    }
    // Chaqaloqlar kattalardan ko'p bo'lishi mumkin emas (har bir chaqaloq
    // bitta kattaning tizzasida) — eski/noto'g'ri params kelsa ham to'g'rilanadi.
    if (adt < 1) adt = 1;
    if (inf > adt) inf = adt;
  }

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  bool get isMax => adt + chd + inf >= _maxPassengers;

  /// Chaqaloq qo'shish mumkinmi: umumiy limit + chaqaloqlar ≤ kattalar.
  bool get _canAddInfant => !isMax && inf < adt;

  /// Kattalar kamaytirilganda chaqaloqlar soni ham kattalarga tenglashtiriladi.
  void _removeAdult() {
    adt--;
    if (inf > adt) inf = adt;
  }

  bool get _isDefault => adt == 1 && chd == 0 && inf == 0 && klass == 'a';

  void _apply() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .pop({"adt": adt, "chd": chd, "inf": inf, "klass": klass});
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      adt = 1;
      chd = 0;
      inf = 0;
      klass = 'a';
    });
  }

  // ---------------------------------------------------------------------------
  // Colors
  // ---------------------------------------------------------------------------

  Color get _sheetColor => context.isDarkMode
      ? ProjectTheme.cardColorDark
      : ProjectTheme.cardColorLight;

  Color get _textColor => context.isDarkMode
      ? ProjectTheme.textColorDark
      : ProjectTheme.textColorLight;

  Color get _secondaryColor => context.isDarkMode
      ? ProjectTheme.secondaryTextDark
      : ProjectTheme.secondaryTextLight;

  Color get _borderColor =>
      context.isDarkMode ? ProjectTheme.borderDark : ProjectTheme.borderLight;

  TextStyle get _titleStyle => context.textTheme.bodyMedium!.copyWith(
        color: _textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sheetColor,
      body: Column(
        children: [
          _buildHeader(context),
          ValueListenableBuilder<bool>(
            valueListenable: _isScrolled,
            builder: (context, scrolled, _) => AnimatedOpacity(
              opacity: scrolled ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Divider(height: 1, thickness: 1, color: _borderColor),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                if (n.depth == 0) _isScrolled.value = n.metrics.pixels > 0;
                return false;
              },
              child: ListView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(_hPadding, 4, _hPadding, 24),
                children: [
                  _counterRow(
                    title: "above_12".tr(),
                    count: adt,
                    canRemove: adt > 1,
                    onRemove: () => setState(_removeAdult),
                    onAdd: () => setState(() => adt++),
                  ),
                  _divider(),
                  _counterRow(
                    title: "between_2_12".tr(),
                    count: chd,
                    canRemove: chd > 0,
                    onRemove: () => setState(() => chd--),
                    onAdd: () => setState(() => chd++),
                  ),
                  _divider(),
                  _counterRow(
                    title: "under_2".tr(),
                    count: inf,
                    canRemove: inf > 0,
                    canAdd: _canAddInfant,
                    onRemove: () => setState(() => inf--),
                    onAdd: () => setState(() => inf++),
                  ),
                  // Chaqaloqlar kattalar soniga yetganda nega "+" o'chiqligini
                  // tushuntiramiz — xato bron qadamida emas, shu yerda to'siladi.
                  if (inf > 0 && inf >= adt)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "infants_per_adult_hint".tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: _secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "show_age_feedback_subtitle".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: _secondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                  _sectionTitle("klass_tab".tr()),
                  for (int i = 0; i < _klassOptions.length; i++) ...[
                    if (i > 0) _divider(),
                    _klassRow(_klassOptions[i].$1, _klassOptions[i].$2.tr()),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      // Qat'iy balandlik emas — katta shriftda sarlavha kesilmaydi (№32).
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 92),
              child: Text(
                "passenger_count_header".tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: SvgPicture.asset(
                  Assets.iconsPlaceCloseIcon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(_textColor, BlendMode.srcIn),
                ),
              ),
            ),
            // "Qayta" — faqat standart qiymatlardan farq qilganda ko'rinadi.
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isDefault ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: _isDefault,
                  child: TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: ProjectTheme.brandColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(48, 40),
                    ),
                    child: Text(
                      "reset".tr(),
                      maxLines: 1,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.isDarkMode
                            ? ProjectTheme.linkDark
                            : ProjectTheme.brandColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _sheetColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _hPadding,
          12,
          _hPadding,
          12 + context.bottomPadding,
        ),
        child: ConstrainedBox(
          // Katta shriftda matn sig'ishi uchun balandlik qat'iy emas (№32).
          constraints:
              const BoxConstraints(minWidth: double.infinity, minHeight: 52),
          child: ElevatedButton(
            onPressed: _apply,
            style: ProjectTheme.blueButtonStyle.copyWith(
              elevation: const WidgetStatePropertyAll(0),
            ),
            child: Text(
              "apply".tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _divider() => Divider(height: 1, thickness: 1, color: _borderColor);

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Text(
        text,
        style: context.textTheme.labelMedium?.copyWith(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Bitta yo'lovchi turi qatori: yosh oralig'i + -/soni/+ boshqaruvi.
  Widget _counterRow({
    required String title,
    required int count,
    required bool canRemove,
    bool? canAdd,
    required VoidCallback onRemove,
    required VoidCallback onAdd,
  }) {
    return Padding(
      // Tugma bosish maydoni 44 dp bo'lgani uchun vertikal padding kamaygan —
      // qator balandligi avvalgidek qoladi.
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title.trim(), style: _titleStyle)),
          _stepButton(
            icon: Icons.remove_rounded,
            enabled: canRemove,
            onTap: onRemove,
            semanticLabel: "${"a11y_decrease".tr()}: ${title.trim()}",
          ),
          SizedBox(
            width: 44,
            child: Text(
              "$count",
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium?.copyWith(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _stepButton(
            icon: Icons.add_rounded,
            enabled: canAdd ?? !isMax,
            onTap: onAdd,
            semanticLabel: "${"a11y_increase".tr()}: ${title.trim()}",
          ),
        ],
      ),
    );
  }

  /// Hoshiyali dumaloq +/- tugma; o'chiq holatda xiralashadi.
  /// Ko'rinadigan doira 36 dp, bosish maydoni esa 44 dp (≥44 tavsiya).
  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.35,
        child: InkResponse(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          radius: 22,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderColor, width: 1),
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(icon, size: 20, color: _textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Klass qatori: nom + o'ngda brend rangli radio halqa.
  Widget _klassRow(String type, String title) {
    final bool selected = klass == type;
    return InkWell(
      onTap: () {
        if (selected) return;
        HapticFeedback.selectionClick();
        setState(() => klass = type);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.trim(),
                style: _titleStyle.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? ProjectTheme.brandColor : _borderColor,
                  width: selected ? 6.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
