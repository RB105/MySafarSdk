import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_option_sheet.dart'
    show SdkRadioMark;
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';

/// Fuqarolik (davlat) tanlash oynasi — "Qayerdan? / Qayerga?" joy qidirish
/// oynasi bilan bir xil uslub: yopish tugmasi va sarlavha, konturli qidiruv
/// maydoni, bayroqli ro'yxat. Tanlangan davlat ro'yxat boshida belgilanadi.
///
/// Natija — `countryCodes`dagi davlat xaritasi (`code`, `name`, ...).
class SearchCountryWidget extends StatefulWidget {
  const SearchCountryWidget({
    super.key,
    this.selectedCode,
    this.scrollController,
  });

  /// Joriy tanlangan davlat kodi (masalan `UZ`) — belgilanadi.
  final String? selectedCode;

  /// To'liq balandlikdagi sheet controller'i — ro'yxat tepada turganda
  /// pastga tortib yopish shu orqali ishlaydi.
  final ScrollController? scrollController;

  @override
  State<SearchCountryWidget> createState() => _SearchCountryWidgetState();
}

class _SearchCountryWidgetState extends State<SearchCountryWidget> {
  static const double _hPadding = 16;

  final TextEditingController _controller = TextEditingController();

  /// Ro'yxat surilganda qidiruv maydoni ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  late List<Map<String, dynamic>> _sorted;
  List<Map<String, dynamic>> _filtered = const [];
  String _lang = '';

  String get _selectedCode => (widget.selectedCode ?? '').toUpperCase();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = dataLang();
    if (lang == _lang) return;
    _lang = lang;
    // Tanlangan davlat birinchi, qolgani joriy tildagi nom bo'yicha.
    _sorted = [...countryCodes]..sort((a, b) {
        final aSel = a["code"] == _selectedCode;
        final bSel = b["code"] == _selectedCode;
        if (aSel != bSel) return aSel ? -1 : 1;
        return _name(a).toLowerCase().compareTo(_name(b).toLowerCase());
      });
    _applyFilter(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  String _name(Map<String, dynamic> country) =>
      (country["name"]?[_lang] ?? country["name"]?["en"] ?? '').toString();

  /// Apostrof turlari (ʻ ‘ ’ `) bir xil qidirilsin: "Oʻzbekiston" = "O'zbekiston".
  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r"[ʻʼ‘’`´]"), "'").trim();

  void _applyFilter(String query) {
    final q = _normalize(query);
    if (q.isEmpty) {
      _filtered = _sorted;
      return;
    }
    // Qidiruv barcha tillardagi nom va kod bo'yicha; nom so'rov bilan
    // boshlanadiganlar yuqorida.
    final starts = <Map<String, dynamic>>[];
    final contains = <Map<String, dynamic>>[];
    for (final country in _sorted) {
      final names = [
        ...((country["name"] as Map?)?.values ?? const []),
      ].map((n) => _normalize(n.toString()));
      final code = (country["code"] ?? '').toString().toLowerCase();
      if (code == q || names.any((n) => n.startsWith(q))) {
        starts.add(country);
      } else if (names.any((n) => n.contains(q))) {
        contains.add(country);
      }
    }
    _filtered = [...starts, ...contains];
  }

  void _onChanged(String value) => setState(() => _applyFilter(value));

  void _onSelected(Map<String, dynamic> country) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(country);
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

  Color get _hintColor => context.isDarkMode
      ? ProjectTheme.disabledTextDark
      : ProjectTheme.disabledTextLight;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(_hPadding, 12, _hPadding, 12),
            child: _buildSearchField(),
          ),
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
              child: _filtered.isEmpty
                  ? ListView(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmpty()],
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        _hPadding - 8,
                        4,
                        _hPadding - 8,
                        context.bottomPadding + 24,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final country = _filtered[index];
                        return _CountryTile(
                          code: (country["code"] ?? '').toString(),
                          name: _name(country),
                          selected: country["code"] == _selectedCode,
                          titleStyle: _titleStyle,
                          onTap: () => _onSelected(country),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                "citizenship".tr(),
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
                icon: _svg(Assets.iconsPlaceCloseIcon, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _borderColor, width: 1),
    );

    return TextField(
      controller: _controller,
      // Klaviatura darhol ochiladi — tanlangach forma keyingi maydonga
      // klaviaturani yopmasdan o'tadi.
      autofocus: true,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: _textColor,
      style: _titleStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintText: "search_country".tr(),
        hintStyle: _titleStyle.copyWith(color: _hintColor),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: _svg(Assets.iconsSearchMagniferIcon,
              size: 20, color: _secondaryColor),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
              icon:
                  _svg(Assets.iconsPlaceClearIcon, size: 20, color: _hintColor),
            );
          },
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: _textColor, width: 1.5),
        ),
      ),
      onChanged: _onChanged,
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 48, _hPadding, 0),
      child: Column(
        children: [
          _svg(Assets.iconsPlaceEmptySearchIcon, size: 40, color: _hintColor),
          const SizedBox(height: 12),
          Text(
            "country_not_found".tr(),
            textAlign: TextAlign.center,
            style: _titleStyle.copyWith(color: _secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _svg(String asset, {double size = 24, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? _textColor, BlendMode.srcIn),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.code,
    required this.name,
    required this.selected,
    required this.titleStyle,
    required this.onTap,
  });

  final String code;
  final String name;
  final bool selected;
  final TextStyle titleStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : ProjectTheme.brandColor.withValues(alpha: 0.07))
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.asset(
                    'packages/mysafar_sdk/assets/img/flags/${code.toLowerCase()}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 12),
                const SdkRadioMark(selected: true, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
