// Creator: Ravshanov Anzor
// Created: 14.09.2026

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/support/saved_passenger_search.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;

import '../../imports/app_imports.dart';

/// Saqlangan yo'lovchilar ro'yxati — davlat / joy tanlash oynalari bilan bir
/// xil to'liq balandlikdagi sheet: sarlavha, tepada qidiruv, yo'lovchilar.
/// Qator bosilishi bilan yo'lovchi tanlanadi va sheet yopiladi.
void showPassengerPickerBottomSheet({
  required BuildContext context,
  required void Function(UsersModel selectedUser) onSelected,
}) {
  showSdkFullHeightSheet<UsersModel>(
    context: context,
    builder: (sheetContext, controller) => BlocProvider(
      create: (_) => UsersDataCubit(needGetUsers: true),
      child: _SavedPassengersSheet(scrollController: controller),
    ),
  ).then((user) {
    if (user != null) onSelected(user);
  });
}

class _SavedPassengersSheet extends StatefulWidget {
  const _SavedPassengersSheet({required this.scrollController});

  /// To'liq balandlikdagi sheet controller'i — ro'yxat tepada turganda
  /// pastga tortib yopish shu orqali ishlaydi.
  final ScrollController scrollController;

  @override
  State<_SavedPassengersSheet> createState() => _SavedPassengersSheetState();
}

class _SavedPassengersSheetState extends State<_SavedPassengersSheet> {
  static const double _hPadding = 16;

  final TextEditingController _search = TextEditingController();

  /// Ro'yxat surilganda qidiruv maydoni ostida chiziq ko'rsatiladi.
  final ValueNotifier<bool> _isScrolled = ValueNotifier(false);

  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  bool get _isDark => context.isDarkMode;

  Color get _sheetColor =>
      _isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;

  Color get _textColor =>
      _isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight;

  Color get _hintColor =>
      _isDark ? ProjectTheme.disabledTextDark : ProjectTheme.disabledTextLight;

  Color get _borderColor =>
      _isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight;

  TextStyle get _inputStyle => context.textTheme.bodyMedium!.copyWith(
        color: _textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.25,
      );

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _select(UsersModel user) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sheetColor,
      body: Column(
        children: [
          _buildHeader(),
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
              child: BlocBuilder<UsersDataCubit, UsersDataState>(
                builder: (context, state) => _buildContent(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                "saved_passenger_list".tr(),
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
      controller: _search,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.characters,
      textAlignVertical: TextAlignVertical.center,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: _textColor,
      style: _inputStyle,
      onChanged: _onQueryChanged,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        hintText: "saved_passenger_search_hint".tr(),
        hintStyle: _inputStyle.copyWith(color: _hintColor),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: _svg(Assets.iconsSearchMagniferIcon,
              size: 20, color: BookingFormStyle.label(context)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _search.clear();
                  _onQueryChanged('');
                },
                icon: _svg(Assets.iconsPlaceClearIcon,
                    size: 20, color: _hintColor),
              ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: _textColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildContent(UsersDataState state) {
    if (state is UsersDataErrorState) {
      return _message(
        icon: Assets.iconsBookingAlertIcon,
        iconColor: ProjectTheme.error,
        text: state.error,
        action: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ProjectTheme.brandColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => context.read<UsersDataCubit>().fetchFromServer(),
          child: Text("retry_search".tr()),
        ),
      );
    }

    if (state is UsersDataEmptyState ||
        (state is UsersDataSuccessState && state.usersModel.isEmpty)) {
      return _message(
        icon: Assets.iconsProfileUsersIcon,
        iconColor: BookingFormStyle.label(context),
        text: "no_passenger_info".tr(),
      );
    }

    if (state is! UsersDataSuccessState) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(_hPadding - 8, 4, _hPadding - 8, 0),
        children: const [
          _PassengerSkeleton(),
          _PassengerSkeleton(),
          _PassengerSkeleton(),
        ],
      );
    }

    final users = SavedPassengerSearch.filter(state.usersModel, _query);
    if (users.isEmpty) {
      return _message(
        icon: Assets.iconsPlaceEmptySearchIcon,
        iconColor: _hintColor,
        text: "saved_passenger_not_found".tr(),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        _hPadding - 8,
        4,
        _hPadding - 8,
        context.bottomPadding + 24,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => _SavedPassengerTile(
        user: users[index],
        query: _query,
        onTap: () => _select(users[index]),
      ),
    );
  }

  /// Bo'sh / xato / "topilmadi" holati — ro'yxat o'rnida, pastga tortib
  /// yopish ishlashi uchun scroll ichida.
  Widget _message({
    required String icon,
    required Color iconColor,
    required String text,
    Widget? action,
  }) {
    return ListView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(_hPadding, 48, _hPadding, 0),
      children: [
        _svg(icon, size: 40, color: iconColor),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: _inputStyle.copyWith(color: BookingFormStyle.label(context)),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          Center(child: action),
        ],
      ],
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

class _SavedPassengerTile extends StatelessWidget {
  const _SavedPassengerTile({
    required this.user,
    required this.query,
    required this.onTap,
  });

  final UsersModel user;
  final String query;
  final VoidCallback onTap;

  String get _name =>
      "${user.lastname ?? ''} ${user.firstname ?? ''}".trim().toUpperCase();

  String get _initials {
    String first(String? value) {
      final v = (value ?? '').trim();
      return v.isEmpty ? '' : v.substring(0, 1).toUpperCase();
    }

    final initials = '${first(user.lastname)}${first(user.firstname)}';
    return initials.isEmpty ? '?' : initials;
  }

  /// `1990-03-12` → `12.03.1990`; boshqa ko'rinishlar o'zgarmaydi.
  String get _birthdate {
    final raw = (user.birthdate ?? '').trim();
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    return iso == null ? raw : '${iso[3]}.${iso[2]}.${iso[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color accent = isDark ? Colors.white : brand;
    final Color muted = BookingFormStyle.label(context);
    final code = (user.citizen ?? '').trim();
    final country = code.isEmpty
        ? ''
        : (getCountry(code)["name"]?[dataLang()] ?? '').toString();
    final details = [
      if (country.isNotEmpty) country,
      if ((user.docnum ?? '').trim().isNotEmpty) user.docnum!.trim(),
      if (_birthdate.isNotEmpty) _birthdate,
    ].join(' · ');

    final nameStyle = context.textTheme.bodyMedium!.copyWith(
      fontSize: 15.5,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : brand.withValues(alpha: 0.08),
                ),
                child: Text(
                  _initials,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      _highlighted(_name, nameStyle, accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (code.isNotEmpty) ...[
                            _Flag(code: code),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                Assets.iconsBookingChevronRightIcon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  BookingFormStyle.hint(context),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qidiruv so'zi bilan boshlanadigan qismlarni brend rangida ajratadi.
  TextSpan _highlighted(String text, TextStyle style, Color accent) {
    final ranges = SavedPassengerSearch.highlightRanges(text, query);
    if (ranges.isEmpty) return TextSpan(text: text, style: style);
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final (start, end) in ranges) {
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
      ));
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, children: spans);
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: (context.isDarkMode ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.asset(
          'packages/mysafar_sdk/assets/img/flags/${code.toLowerCase()}.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _PassengerSkeleton extends StatelessWidget {
  const _PassengerSkeleton();

  @override
  Widget build(BuildContext context) {
    final Color fill = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE9EDF3);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(160, 14),
              const SizedBox(height: 6),
              bar(110, 11),
            ],
          ),
        ],
      ),
    );
  }
}
