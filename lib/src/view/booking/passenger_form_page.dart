// Creator: Ravshanov Anzor
// Created: 14.09.2026

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/widgets/main_button_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/switch_button_widget.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart';
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/service/passenger/passenger_storage_service.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_card_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_date_picker.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart'
    show showCitySearchPicker;
import 'package:mysafar_sdk/src/view/booking/widget/scan_page.dart'
    show showMrzScannerBottomSheet;
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
  late bool _saveToProfile = widget.initialSaveToProfile;
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

  Future<void> _openDocumentScanner() async {
    final user = await showMrzScannerBottomSheet(context);
    if (!mounted || user == null) return;
    _applyUser(user);
  }

  Future<void> _showCitizenPicker() async {
    final result = await showCitySearchPicker(context);
    if (!mounted || result == null) return;
    setState(() {
      _passenger = _passenger.copyWithCitizen(result['code'] ?? '');
    });
    _controller.docnumFocus.requestFocus();
  }

  void _showDatePicker({required bool isDocexp}) {
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
  void _goToNextEmptyField() {
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
    final current = order.indexWhere((e) => e.$2 == focused);

    for (var i = current + 1; i < order.length; i++) {
      final (field, node) = order[i];
      if (!empty.contains(field)) continue;
      if (field == 'citizen') {
        FocusManager.instance.primaryFocus?.unfocus();
        _showCitizenPicker();
      } else {
        node.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final empty = _passenger.emptyRequiredFields;
    if (empty.isNotEmpty) {
      setState(() => _showErrors = true);
      final key = _keyByField(empty.first);
      if (key != null) _scrollToField(key);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(PassengerCubit.requiredFieldMessage(empty.first)),
          duration: const Duration(seconds: 3),
        ));
      return;
    }

    Navigator.of(context).pop(PassengerFormResult(
      passenger: _passenger.copyWith(
        firstname: _passenger.firstname.trim(),
        lastname: _passenger.lastname.trim(),
        middlename: _passenger.middlename.trim(),
      ),
      saveToProfile: _saveToProfile && !_alreadySaved,
    ));
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
    await Future.delayed(const Duration(milliseconds: 100));
    final fieldContext = key.currentContext;
    if (fieldContext == null || !fieldContext.mounted) return;
    await Scrollable.ensureVisible(
      fieldContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'passenger_data'.tr(),
          style: context.textTheme.bodyLarge
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              BookingCard(
                child: PassengerCardWidget(
                  index: widget.index,
                  adultCount: widget.adultCount,
                  childCount: widget.childCount,
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
                  onBirthdateCalendarTap: () =>
                      _showDatePicker(isDocexp: false),
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
              ),
              if (!_alreadySaved) ...[
                const SizedBox(height: 12),
                BookingCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'add_to_saved_passengers'.tr(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SwitchButtonWidget(
                        value: _saveToProfile,
                        onChanged: (value) =>
                            setState(() => _saveToProfile = value),
                      ),
                    ],
                  ),
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
