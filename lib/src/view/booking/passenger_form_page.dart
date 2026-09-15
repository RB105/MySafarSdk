// Creator: Ravshanov Anzor
// Created: 14.09.2026

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/widgets/main_button_widget.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/stable_keyboard_insets.dart';
import 'package:mysafar_sdk/src/core/widgets/switch_button_widget.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/passenger/passenger_storage_service.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFieldError, BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/passenger_card_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_date_picker.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart'
    show showCitySearchPicker;
import 'package:mysafar_sdk/src/view/booking/widget/scan_page.dart'
    show showDocumentScanner;
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;

/// [PassengerFormPage] natijasi — to'ldirilgan yo'lovchi va uni saqlangan
/// yo'lovchilarga qo'shish kerakmi.
class PassengerFormResult {
  final PassengerModel passenger;
  final bool saveToProfile;

  const PassengerFormResult({
    required this.passenger,
    required this.saveToProfile,
  });
}

/// Bitta yo'lovchi ma'lumotlarini to'ldirish sahifasi.
///
/// Bron sahifasida har bir yo'lovchi ixcham slot ko'rinishida turadi; slot
/// bosilganda shu sahifa ochiladi va "Davom etish" bosilganda to'ldirilgan
/// model [PassengerFormResult] sifatida qaytariladi.
class PassengerFormPage extends StatefulWidget {
  static const routeName = '/passengerForm';

  final PassengerModel initial;
  final int index;
  final int adultCount;
  final int childCount;
  final bool initialSaveToProfile;

  const PassengerFormPage({
    super.key,
    required this.initial,
    required this.index,
    required this.adultCount,
    required this.childCount,
    this.initialSaveToProfile = false,
  });

  @override
  State<PassengerFormPage> createState() => _PassengerFormPageState();
}

class _PassengerFormPageState extends State<PassengerFormPage> {
  final _scrollController = ScrollController();
  final _controller = PassengerController();
  final _storage = PassengerStorageService();

  final _birthdateFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );
  final _docexpFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );

  final _citizenKey = GlobalKey();
  final _docnumKey = GlobalKey();
  final _docexpKey = GlobalKey();
  final _firstnameKey = GlobalKey();
  final _lastnameKey = GlobalKey();
  final _middlenameKey = GlobalKey();
  final _birthdateKey = GlobalKey();
  final _genderKey = GlobalKey();

  late PassengerModel _passenger = widget.initial;

  /// Yangi yo'lovchi uchun default yoqiq; avval to'ldirilgan (va
  /// foydalanuvchi o'chirgan) bo'lsa — o'sha tanlov saqlanadi.
  late bool _saveToProfile =
      widget.initialSaveToProfile || !widget.initial.isValid;
  bool _showErrors = false;

  // Sahifa ochiq turganda saqlangan ma'lumotlar o'zgarmaydi — bir marta
  // o'qib keshlaymiz (har klaviatura bosilishida storage o'qilmasin).
  late final List<dynamic> _cachedUsers = _storage.getCachedUsers();
  final Map<String, List<String>> _suggestionCache = {};

  List<String> _suggestions(String key) =>
      _suggestionCache.putIfAbsent(key, () => _storage.getSuggestions(key));

  static String _normalizeDocnum(String? raw) =>
      (raw ?? '').trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Hujjat raqami saqlangan yo'lovchilarda allaqachon bor bo'lsa, qo'shish
  /// tugmasi ma'nosiz — ko'rsatilmaydi.
  bool get _alreadySaved {
    final doc = _normalizeDocnum(_passenger.docnum);
    if (doc.isEmpty) return false;
    return _cachedUsers.any(
      (u) => u is Map && _normalizeDocnum(u['docnum']?.toString()) == doc,
    );
  }

  @override
  void initState() {
    super.initState();
    _fillControllers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _fillControllers() {
    _controller.firstnameController.text = _passenger.firstname;
    _controller.lastnameController.text = _passenger.lastname;
    _controller.middlenameController.text = _passenger.middlename;
    _controller.birthdateController.text = _passenger.birthdate;
    _controller.docnumController.text = _passenger.docnum;
    _controller.docexpController.text = _passenger.docexp;
  }

  void _updateField(String field, String value) {
    setState(() {
      _passenger = switch (field) {
        'firstname' =>
          _passenger.copyWith(firstname: PassengerCubit.sanitizeName(value)),
        'lastname' =>
          _passenger.copyWith(lastname: PassengerCubit.sanitizeName(value)),
        'middlename' =>
          _passenger.copyWith(middlename: PassengerCubit.sanitizeName(value)),
        'birthdate' => _passenger.copyWith(birthdate: value),
        'docnum' => _passenger.copyWith(docnum: value),
        'docexp' => _passenger.copyWith(docexp: value),
        'gender' => _passenger.copyWith(gender: value),
        _ => _passenger,
      };
    });
  }

  void _applyUser(UsersModel user) {
    setState(() => _passenger = _passenger.copyFromUser(user));
    _fillControllers();
  }

  /// Sheet/sahifa ochishdan oldin fokusni butunlay olib tashlaydi.
  ///
  /// `FocusScope.of(context).unfocus()` oxirgi maydonni route scope'ida eslab
  /// qoladi — sheet yopilganda Flutter o'sha maydonga fokusni qaytaradi va
  /// klaviatura kutilmaganda qayta ochiladi. `primaryFocus.unfocus()` bu
  /// xotirani tozalaydi.
  static void _dismissKeyboard() =>
      FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _openDocumentScanner() async {
    _dismissKeyboard();
    final scan = await showDocumentScanner(context);
    if (!mounted || scan == null) return;
    // Faqat tanilgan maydonlar yoziladi — o'qilmaganlari saqlanib qoladi.
    setState(() => _passenger = _passenger.mergeScan(scan));
    _fillControllers();
  }

  Future<void> _showCitizenPicker() async {
    _dismissKeyboard();
    final result = await showCitySearchPicker(
      context,
      selectedCode: _passenger.citizen,
    );
    if (!mounted || result == null) return;
    setState(() {
      _passenger = _passenger.copyWithCitizen(result['code'] ?? '');
    });
    // Qidiruv klaviaturasi hali ochiq — keyingi bo'sh maydonga darhol fokus
    // berilsa klaviatura yopilib-ochilmaydi. Hujjat to'liq bo'lsa ochilmaydi.
    _focusNextEmptyField(after: 'citizen');
  }

  void _showDatePicker({required bool isDocexp}) {
    _dismissKeyboard();
    PassengerDatePicker.show(
      context: context,
      controller: isDocexp
          ? _controller.docexpController
          : _controller.birthdateController,
      isFutureOnly: isDocexp,
      title: isDocexp ? 'passport_validity'.tr() : 'birth_date'.tr(),
      onDateSelected: (date) => _updateField(
        isDocexp ? 'docexp' : 'birthdate',
        DateFormat('dd.MM.yyyy').format(date),
      ),
    );
  }

  /// Klaviaturadagi "keyingi": joriy maydondan keyingi bo'sh majburiy maydonga
  /// o'tadi; fuqarolik bo'sh bo'lsa tanlagich ochiladi, hammasi to'lsa
  /// klaviatura yopiladi.
  void _goToNextEmptyField() => _focusNextEmptyField();

  /// [after] maydonidan (berilmasa — fokusdagi maydondan) keyingi bo'sh
  /// majburiy maydonga o'tadi.
  void _focusNextEmptyField({String? after}) {
    final order = <(String, FocusNode)>[
      ('lastname', _controller.lastnameFocus),
      ('firstname', _controller.firstnameFocus),
      ('middlename', _controller.middlenameFocus),
      ('birthdate', _controller.birthdateFocus),
      ('citizen', _controller.citizenFocus),
      ('docnum', _controller.docnumFocus),
      ('docexp', _controller.docexpFocus),
    ];
    final empty = _passenger.emptyRequiredFields.toSet();
    final focused = FocusManager.instance.primaryFocus;
    final current = after != null
        ? order.indexWhere((e) => e.$1 == after)
        : order.indexWhere((e) => e.$2 == focused);

    for (var i = current + 1; i < order.length; i++) {
      final (field, node) = order[i];
      if (!empty.contains(field)) continue;
      if (field == 'citizen') {
        _showCitizenPicker();
      } else {
        node.requestFocus();
      }
      return;
    }
    _dismissKeyboard();
  }

  /// Bo'sh maydon bo'lsa — xatolar maydon ostida ko'rsatiladi, birinchi
  /// bo'sh maydonga suriladi va (matn maydoni bo'lsa) fokus beriladi.
  void _submit() {
    final empty = _passenger.emptyRequiredFields;
    if (empty.isNotEmpty) {
      setState(() => _showErrors = true);
      final first = _firstEmptyInFormOrder(empty);
      final node = _focusNodeByField(first);
      // Matn maydoniga o'tilsa klaviatura yopilmaydi — aks holda yopilib,
      // darhol qayta ochiladi.
      if (node == null) _dismissKeyboard();
      final key = _keyByField(first);
      if (key != null) {
        _scrollToField(key).then((_) {
          if (mounted) node?.requestFocus();
        });
      }
      return;
    }

    _dismissKeyboard();
    Navigator.of(context).pop(PassengerFormResult(
      passenger: _passenger.copyWith(
        firstname: _passenger.firstname.trim(),
        lastname: _passenger.lastname.trim(),
        middlename: _passenger.middlename.trim(),
      ),
      saveToProfile: _saveToProfile && !_alreadySaved,
    ));
  }

  /// Model bo'sh maydonlarni o'z tartibida qaytaradi — foydalanuvchi
  /// ekrandagi (yuqoridan pastga) birinchisiga olib boriladi.
  static const List<String> _formOrder = [
    'lastname',
    'firstname',
    'middlename',
    'birthdate',
    'gender',
    'citizen',
    'docnum',
    'docexp',
  ];

  String _firstEmptyInFormOrder(List<String> empty) =>
      _formOrder.firstWhere(empty.contains, orElse: () => empty.first);

  FocusNode? _focusNodeByField(String field) => switch (field) {
        'lastname' => _controller.lastnameFocus,
        'firstname' => _controller.firstnameFocus,
        'middlename' => _controller.middlenameFocus,
        'birthdate' => _controller.birthdateFocus,
        'docnum' => _controller.docnumFocus,
        'docexp' => _controller.docexpFocus,
        _ => null,
      };

  /// "1-yo'lovchi · 12 yoshdan katta" — app bar sarlavhasi ostida.
  String get _passengerSubtitle {
    final number =
        "passenger_number".tr(namedArgs: {"number": "${widget.index + 1}"});
    final String age;
    if (widget.adultCount > widget.index) {
      age = "above_12".tr();
    } else if (widget.adultCount + widget.childCount > widget.index &&
        widget.childCount != 0) {
      age = "between_2_12".tr();
    } else {
      age = "under_2".tr();
    }
    return '$number · $age';
  }

  GlobalKey? _keyByField(String field) => switch (field) {
        'citizen' => _citizenKey,
        'docnum' => _docnumKey,
        'docexp' => _docexpKey,
        'firstname' => _firstnameKey,
        'lastname' => _lastnameKey,
        'middlename' => _middlenameKey,
        'birthdate' => _birthdateKey,
        'gender' => _genderKey,
        _ => null,
      };

  Future<void> _scrollToField(GlobalKey key) async {
    // Xato matnlari [BookingFieldError] da ochilib bo'lsin — aks holda
    // scroll maqsadi animatsiya davomida siljib, oxirida sakraydi.
    await Future.delayed(BookingFieldError.animationDuration);
    final fieldContext = key.currentContext;
    if (fieldContext == null || !fieldContext.mounted) return;
    await Scrollable.ensureVisible(
      fieldContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StableKeyboardInsets(
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'passenger_data'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyLarge
                  ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _passengerSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.headlineSmall?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismissKeyboard,
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PassengerCardWidget(
                passenger: _passenger,
                controller: _controller,
                showErrors: _showErrors,
                cachedUsers: _cachedUsers,
                getSuggestions: _suggestions,
                onFieldChanged: _updateField,
                onUserSelected: _applyUser,
                onScanTap: _openDocumentScanner,
                onCitizenTap: _showCitizenPicker,
                onDocexpCalendarTap: () => _showDatePicker(isDocexp: true),
                onBirthdateCalendarTap: () => _showDatePicker(isDocexp: false),
                onNextField: _goToNextEmptyField,
                docexpFormatter: _docexpFormatter,
                birthdateFormatter: _birthdateFormatter,
                citizenKey: _citizenKey,
                docnumKey: _docnumKey,
                docexpKey: _docexpKey,
                firstnameKey: _firstnameKey,
                lastnameKey: _lastnameKey,
                middlenameKey: _middlenameKey,
                birthdateKey: _birthdateKey,
                genderKey: _genderKey,
              ),
              if (!_alreadySaved) ...[
                const SizedBox(height: 20),
                _SaveToProfileCard(
                  value: _saveToProfile,
                  onChanged: (value) => setState(() => _saveToProfile = value),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: MainButtonWidget(
            title: 'continue'.tr(),
            analyticsId: 'booking_passenger_form_continue',
            onTap: _submit,
          ),
        ),
      ),
    );
  }
}

/// "Saqlangan yo'lovchilarga qo'shish" — ikonka, izoh va switch'li karta.
/// Butun karta bosiladi.
class _SaveToProfileCard extends StatelessWidget {
  const _SaveToProfileCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    return BookingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  Assets.iconsScanBookmarkAddIcon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : brand,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'add_to_saved_passengers'.tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'save_passenger_subtitle'.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: BookingFormStyle.label(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SwitchButtonWidget(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
