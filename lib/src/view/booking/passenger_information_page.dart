// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;
import 'package:mysafar_sdk/src/core/widgets/county_pick/src/country_code_model.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_state.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;
import 'package:mysafar_sdk/src/view/booking/booking_create_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/contact_form_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_card_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_date_picker.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart'
    show  showCitySearchPicker;
import 'package:mysafar_sdk/src/view/booking/widget/scan_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart';

class PassengerInformationPage extends StatefulWidget {
  final FlightElement element;
  final int adt;
  final int inf;
  final int chd;

  const PassengerInformationPage({
    super.key,
    required this.element,
    required this.adt,
    required this.chd,
    required this.inf,
  });

  static const routeName = '/passengerInformation';

  @override
  State<PassengerInformationPage> createState() =>
      _PassengerInformationPageState();
}

class _PassengerInformationPageState extends State<PassengerInformationPage> {
  late final PassengerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PassengerCubit(
      adultCount: widget.adt,
      childCount: widget.chd,
      infantCount: widget.inf,
      trId: widget.element.id,
      price: widget.element.price,
    )..initialize();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: _PassengerInformationView(
        element: widget.element,
        adt: widget.adt,
        chd: widget.chd,
        inf: widget.inf,
      ),
    );
  }
}

class _PassengerInformationView extends StatefulWidget {
  final FlightElement element;
  final int adt;
  final int inf;
  final int chd;

  const _PassengerInformationView({
    required this.element,
    required this.adt,
    required this.chd,
    required this.inf,
  });

  @override
  State<_PassengerInformationView> createState() =>
      _PassengerInformationViewState();
}

class _PassengerInformationViewState extends State<_PassengerInformationView> {
  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late List<PassengerController> _passengerControllers;

  CountryCode? _selectedCountry;
  CountryCode _countryCode = CountryCode(
    name: 'Uzbekistan',
    code: 'UZ',
    dialCode: '998',
    phone_format: '## ### ## ##',
  );

  final _birthdateFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );
  final _docexpFormatter = MaskTextInputFormatter(
    type: MaskAutoCompletionType.lazy,
    mask: '##.##.####',
  );
  final _phoneFormatter = MaskTextInputFormatter(
    filter: {'#': RegExp(r'[0-9]')},
    mask: '## ### ## ##',
    type: MaskAutoCompletionType.lazy,
  );

  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _continueButtonKey = GlobalKey();
  final _emailFocusNode = FocusNode(skipTraversal: true);
  final _phoneFocusNode = FocusNode(skipTraversal: true);
  late List<GlobalKey> _citizenKeys;
  late List<GlobalKey> _docnumKeys;
  late List<GlobalKey> _docexpKeys;
  late List<GlobalKey> _firstnameKeys;
  late List<GlobalKey> _lastnameKeys;
  late List<GlobalKey> _middlenameKeys;
  late List<GlobalKey> _birthdateKeys;
  late List<GlobalKey> _genderKeys;

  int get _totalPassengers => widget.adt + widget.chd + widget.inf;

  bool _isContactControllersFilled = false;
  bool _formFieldFocused = false;

  late final VoidCallback _focusListener;

  // Autocomplete tavsiyalari faqat saqlash xizmati orqali (saqlangan
  // ma'lumotlardan) keladi va sahifa ochiq turganda o'zgarmaydi. Har bir
  // klaviatura bosilishida ListView qayta qurilganda getSuggestions har bir
  // maydon uchun GetStorage.read + List nusxasini bajaradi. Shu sababli bir
  // marta hisoblab, key bo'yicha keshlaymiz.
  final Map<String, List<String>> _suggestionCache = {};

  List<String> _cachedSuggestions(String key) {
    return _suggestionCache.putIfAbsent(
      key,
      () => context.read<PassengerCubit>().getSuggestions(key),
    );
  }

  // Saqlangan telefon raqamlari mamlakat kodi bilan ('998' + 9 raqam) saqlanadi.
  // Taklif ro'yxatida va tanlanganda kodni olib tashlab, joriy mamlakat niqobiga
  // moslab ko'rsatamiz: "998123456789" -> "12 345 67 89". Aks holda niqob butun
  // qatorga qo'llanib "99 812 34 56" kabi noto'g'ri format chiqadi. Mamlakat
  // o'zgarganda kesh tozalanadi (_updateMask).
  List<String>? _phoneSuggestionsCache;

  List<String> _phoneSuggestions() {
    return _phoneSuggestionsCache ??= _buildPhoneSuggestions();
  }

  List<String> _buildPhoneSuggestions() {
    final dialCode = _countryCode.dialCode ?? '998';
    final seen = <String>{};
    final result = <String>[];
    for (final raw in _cachedSuggestions('phone')) {
      var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith(dialCode)) {
        digits = digits.substring(dialCode.length);
      }
      if (digits.isEmpty) continue;
      final masked = _phoneFormatter.maskText(digits);
      if (seen.add(masked)) result.add(masked);
    }
    return result;
  }

  // Saqlangan foydalanuvchilar ham sahifa ochiq turganda o'zgarmaydi —
  // har bir qayta qurishda storage'dan o'qimaslik uchun bir marta keshlanadi.
  List<dynamic>? _cachedUsersList;

  List<dynamic> _cachedUsers() {
    return _cachedUsersList ??= context.read<PassengerCubit>().getCachedUsers();
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeKeys();
    _focusListener = _updateFormFocusState;
    FocusManager.instance.addListener(_focusListener);
    for (final node in _allFormFocusNodes) {
      node.addListener(_updateFormFocusState);
    }
  }

  Iterable<FocusNode> get _allFormFocusNodes sync* {
    yield _emailFocusNode;
    yield _phoneFocusNode;
    for (final controller in _passengerControllers) {
      yield controller.lastnameFocus;
      yield controller.firstnameFocus;
      yield controller.middlenameFocus;
      yield controller.birthdateFocus;
      yield controller.citizenFocus;
      yield controller.docnumFocus;
      yield controller.docexpFocus;
    }
  }

  void _updateFormFocusState() {
    final focused = FocusManager.instance.primaryFocus;
    final hasFormFocus =
        focused != null && _allFormFocusNodes.contains(focused);
    if (hasFormFocus != _formFieldFocused && mounted) {
      setState(() => _formFieldFocused = hasFormFocus);
    }
  }

  void _initializeControllers() {
    _passengerControllers = List.generate(
      _totalPassengers,
      (_) => PassengerController(),
    );
  }

  void _initializeKeys() {
    _citizenKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _docnumKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _docexpKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _firstnameKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _lastnameKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _middlenameKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _birthdateKeys = List.generate(_totalPassengers, (_) => GlobalKey());
    _genderKeys = List.generate(_totalPassengers, (_) => GlobalKey());
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusListener);
    for (final node in _allFormFocusNodes) {
      node.removeListener(_updateFormFocusState);
    }
    _scrollController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    for (final controller in _passengerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PassengerCubit, PassengerState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        if (state is! PassengerLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_isContactControllersFilled) {
          _isContactControllersFilled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateContactControllers(state.email, state.phone);
          });
        }

        // Klavatura balandligi OS dan keladi — tugma aynan shu qiymatda
        // joylashadi, orada bo'sh joy qolmaydi (har qanday qurilmada).
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        final showKeyboardBar = keyboardInset > 0;
        const keyboardBarHeight = 44.0;

        return Scaffold(
          appBar: _buildAppBar(context),
          // Scaffold o'zi insetni "yeb" qo'ymasligi kerak — aks holda
          // Positioned(bottom: inset) ikki marta hisoblanib bo'shliq chiqadi
          // yoki tugma klaviatura orqasida qoladi.
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    16 +
                        (showKeyboardBar
                            ? keyboardBarHeight + keyboardInset
                            : 140),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRouteSummary(context),
                      const SizedBox(height: 12),
                      const SupportWidget(),
                      const SizedBox(height: 12),
                      _buildContactForm(context, state),
                      const SizedBox(height: 12),
                      _buildPassengersList(context, state),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: showKeyboardBar ? keyboardInset : 0,
                child: showKeyboardBar
                    ? _buildKeyboardNextBar(context, state)
                    : _buildBottomButton(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, PassengerState state) {
    if (state is PassengerLoaded) {
      if (_emailController.text.isEmpty && state.email.isNotEmpty) {
        _emailController.text = state.email;
      }
      // Fokusda tahrirlayotganda state'dan qayta yozib qo'ymaymiz.
      if (!_phoneFocusNode.hasFocus &&
          _phoneController.text.isEmpty &&
          state.phone.isNotEmpty) {
        _updateContactControllers('', state.phone);
      }
    } else if (state is PassengerValidationError) {
      _handleValidationError(state);
    } else if (state is PassengerSaved) {
      _navigateToBookingPage(context, state);
    }
  }

  void _handleValidationError(PassengerValidationError state) {
    final key = _getFieldKeyByName(state.passengerIndex, state.fieldName);
    if (key != null) {
      _scrollToField(key);
    }
    _showSnackBar(state.message);
  }

  Future<void> _navigateToBookingPage(
      BuildContext context, PassengerSaved state) async {
    // SDK'da login talab qilinmaydi — sessiyani host boshqaradi (web-register).
    // Token tekshiruvi va auth bottom-sheet olib tashlangan.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingCreatePage(
          passenger: state.passengersJson,
          price: state.price,
          trId: state.trId,
        ),
      ),
    );

    if (!mounted) return;

    context.read<PassengerCubit>().restoreState();
  }

  void _updateContactControllers(String email, String phone) {
    if (email.isNotEmpty) {
      _emailController.text = email;
    }
    if (phone.isNotEmpty) {
      final phoneDigits = _stripDialCodeFromPhone(phone);
      if (phoneDigits.isNotEmpty) {
        _applyPhoneDigitsToController(phoneDigits);
      }
    }
  }

  String _stripDialCodeFromPhone(String phone) {
    var phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final dialCode = _countryCode.dialCode ?? '998';
    if (phoneDigits.startsWith(dialCode)) {
      phoneDigits = phoneDigits.substring(dialCode.length);
    } else if (phoneDigits.startsWith('998')) {
      phoneDigits = phoneDigits.substring(3);
    }
    return phoneDigits;
  }

  /// MaskTextInputFormatter ichki holatini controller bilan sinxron saqlaydi.
  void _applyPhoneDigitsToController(String digits) {
    if (digits.isEmpty) {
      _phoneController.value = const TextEditingValue();
      _phoneFormatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(),
      );
      return;
    }

    _phoneController.value = _phoneFormatter.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: digits),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      ),
      title: Text(
        'booking'.tr(),
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildRouteSummary(BuildContext context) {
    final segs = widget.element.segments ?? const [];
    if (segs.isEmpty) return const SizedBox.shrink();

    final dir0 = widget.element.getSegmentsByDirection(0);
    final origin =
        segs.first.dep.city?.title ?? segs.first.dep.airport?.code ?? '';
    final dest = dir0.isNotEmpty
        ? (dir0.last.arr.city?.title ?? dir0.last.arr.airport?.code ?? '')
        : (segs.last.arr.city?.title ?? '');

    final dir1 = widget.element.getSegmentsByDirection(1);
    final String? depDate = _shortDate(segs.first.dep.date);
    final String? retDate =
        dir1.isNotEmpty ? _shortDate(dir1.first.dep.date) : null;

    final parts = <String>[
      if (depDate != null) retDate != null ? "$depDate - $retDate" : depDate,
      "passengers_count".tr(namedArgs: {"count": "$_totalPassengers"}),
    ];

    return BookingCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz_rounded,
                    size: 18, color: ProjectTheme.brandColor),
              ),
              Flexible(
                child: Text(
                  dest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineSmall?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  String? _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    DateTime? d = DateTime.tryParse(raw);
    if (d == null) {
      final parts = raw.split(RegExp(r'[.\-/]'));
      if (parts.length == 3) {
        final a = int.tryParse(parts[0]);
        final b = int.tryParse(parts[1]);
        final c = int.tryParse(parts[2]);
        if (a != null && b != null && c != null) {
          d = a > 31 ? DateTime(a, b, c) : DateTime(c, b, a);
        }
      }
    }
    if (d == null) return null;
    return "${d.day} ${ElementFormatter.formatMonth(d.month).toLowerCase()}";
  }

  Widget _buildContactForm(BuildContext context, PassengerLoaded state) {
    final cubit = context.read<PassengerCubit>();

    return ContactFormWidget(
      emailController: _emailController,
      phoneController: _phoneController,
      showErrors: state.showErrors,
      selectedCountry: _selectedCountry,
      emailSuggestions: _cachedSuggestions('email'),
      phoneSuggestions: _phoneSuggestions(),
      phoneFormatter: _phoneFormatter,
      onEmailChanged: (value) => cubit.updateEmail(value),
      onPhoneChanged: () => _updatePhoneNumber(cubit),
      onCountrySelected: (code) => _updateMask(code, cubit),
      emailKey: _emailKey,
      phoneKey: _phoneKey,
      emailFocusNode: _emailFocusNode,
      phoneFocusNode: _phoneFocusNode,
      onNextField: _goToNextEmptyField,
    );
  }

  Widget _buildKeyboardNextBar(BuildContext context, PassengerLoaded state) {
    final isDark = context.isDarkMode;
    final cubit = context.read<PassengerCubit>();
    final targets = _fieldTargets(cubit, state);
    final allFilled = !targets.any(_fieldNeedsAttention);

    return Material(
      elevation: 6,
      color: isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color:
                  isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight,
            ),
          ),
        ),
        child: Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: allFilled
                  ? _dismissKeyboardWhenComplete
                  : _goToNextEmptyField,
              child: Text(
                allFilled ? 'continue_purchase'.tr() : 'next'.tr(),
                style: TextStyle(
                  fontFamily: 'packages/mysafar_sdk/Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ProjectTheme.brandColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersList(BuildContext context, PassengerLoaded state) {
    final cubit = context.read<PassengerCubit>();

    return BookingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "passenger_booking_title".tr(),
            style: context.textTheme.bodyLarge
                ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            "passenger_booking_subtitle".tr(),
            style: context.textTheme.headlineSmall?.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < _totalPassengers; index++) ...[
            if (index != 0) ...[
              const SizedBox(height: 20),
              Divider(height: 1, thickness: 1, color: context.color.outline),
              const SizedBox(height: 20),
            ],
            RepaintBoundary(
              child: _buildPassengerCard(context, cubit, state, index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerCard(
    BuildContext context,
    PassengerCubit cubit,
    PassengerLoaded state,
    int index,
  ) {
    return PassengerCardWidget(
      index: index,
      adultCount: widget.adt,
      childCount: widget.chd,
      passenger: state.passengers[index],
      controller: _passengerControllers[index],
      showErrors: state.showErrors,
      cachedUsers: _cachedUsers(),
      getSuggestions: _cachedSuggestions,
      onFieldChanged: (field, value) => _handlePassengerFieldChanged(
        cubit,
        index,
        field,
        value,
      ),
      onUserSelected: (user) {
        cubit.updatePassengerFromUser(index, user);
        _updateControllersFromUser(index, user);
      },
      onScanTap: () => _openMrzScanner(index, cubit),
      onCitizenTap: () => _showCitizenPicker(index, cubit),
      onDocexpCalendarTap: () => _showDocexpDatePicker(index, cubit),
      onBirthdateCalendarTap: () => _showBirthdateDatePicker(index, cubit),
      onNextField: _goToNextEmptyField,
      docexpFormatter: _docexpFormatter,
      birthdateFormatter: _birthdateFormatter,
      citizenKey: _citizenKeys[index],
      docnumKey: _docnumKeys[index],
      docexpKey: _docexpKeys[index],
      firstnameKey: _firstnameKeys[index],
      lastnameKey: _lastnameKeys[index],
      middlenameKey: _middlenameKeys[index],
      birthdateKey: _birthdateKeys[index],
      genderKey: _genderKeys[index],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return KeyedSubtree(
      key: _continueButtonKey,
      child: NextButtonWidget(
        nextTittle: 'continue_purchase',
        analyticsId: 'booking_passenger_continue',
        onPressed: () {
          ////////////////
          // FocusScope.of(context).unfocus();
          context.read<PassengerCubit>().validateAndSave();
        },
        passenger: _totalPassengers,
        showButton: true,
        price: widget.element.price,
      ),
    );
  }

  void _updatePhoneNumber(PassengerCubit cubit) {
    final unmaskedText = _phoneFormatter.getUnmaskedText();
    // Raqam kiritilmagan bo'lsa telefonni bo'sh saqlaymiz. Aks holda phone
    // faqat mamlakat kodidan iborat bo'lib ('998' / '1'), listener uni bo'sh
    // input ichiga qaytadan yozib qo'yardi.
    final phone =
        unmaskedText.isEmpty ? '' : '${_countryCode.dialCode}$unmaskedText';
    cubit.updatePhone(phone);
  }

  void _updateMask(CountryCode code, PassengerCubit cubit) {
    final unmaskedText = _phoneFormatter.getUnmaskedText();
    final maskFromJson = code.phone_format ?? '## ### ## ##';
    final formatterMask = maskFromJson.replaceAll('X', '#');

    _phoneFormatter.updateMask(
      mask: formatterMask,
      filter: {'#': RegExp(r'[0-9]')},
    );

    if (unmaskedText.isNotEmpty) {
      _applyPhoneDigitsToController(unmaskedText);
    }

    setState(() {
      _countryCode = code;
      _selectedCountry = code;
      // Yangi mamlakat kodi/niqobiga mos ravishda qayta hisoblansin.
      _phoneSuggestionsCache = null;
    });

    _updatePhoneNumber(cubit);
  }

  void _updateControllersFromUser(int index, dynamic user) {
    final controller = _passengerControllers[index];
    controller.firstnameController.text =
        PassengerCubit.sanitizeName(user.firstname);
    controller.lastnameController.text =
        PassengerCubit.sanitizeName(user.lastname);
    controller.middlenameController.text =
        PassengerCubit.sanitizeName(user.middlename);
    controller.birthdateController.text = user.birthdate ?? '';
    controller.docexpController.text = user.docexp ?? '';
    controller.docnumController.text = user.docnum ?? '';
  }

  Future<void> _openMrzScanner(int index, PassengerCubit cubit) async {
    final user = await showMrzScannerBottomSheet(context);
    if (!mounted || user == null) return;
    cubit.updatePassengerFromUser(index, user);
    _updateControllersFromUser(index, user);
  }

  void _handlePassengerFieldChanged(
    PassengerCubit cubit,
    int index,
    String field,
    String value,
  ) {
    cubit.updatePassengerField(index, field, value);

    if (field == 'gender' && index == _totalPassengers - 1) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _showCitizenPicker(int index, PassengerCubit cubit) async {
    final result = await showCitySearchPicker(context);
    if (result != null) {
      cubit.updateCitizen(index, result['code'] ?? '');
    }
    if (!mounted) return;
    _passengerControllers[index].citizenFocus.requestFocus();
  }

  void _showDocexpDatePicker(int index, PassengerCubit cubit) {
    PassengerDatePicker.show(
      context: context,
      controller: _passengerControllers[index].docexpController,
      isFutureOnly: true,
      title: 'passport_validity'.tr(),
      onDateSelected: (date) {
        cubit.updatePassengerField(
          index,
          'docexp',
          DateFormat('dd.MM.yyyy').format(date),
        );
      },
    );
  }

  void _showBirthdateDatePicker(int index, PassengerCubit cubit) {
    PassengerDatePicker.show(
      context: context,
      controller: _passengerControllers[index].birthdateController,
      isFutureOnly: false,
      title: 'birth_date'.tr(),
      onDateSelected: (date) {
        cubit.updatePassengerField(
          index,
          'birthdate',
          DateFormat('dd.MM.yyyy').format(date),
        );
      },
    );
  }

  GlobalKey? _getFieldKeyByName(int? index, String? fieldName) {
    if (fieldName == 'email') return _emailKey;
    if (fieldName == 'phone') return _phoneKey;
    if (index == null || fieldName == null) return null;

    return switch (fieldName) {
      'citizen' => _citizenKeys[index],
      'docnum' => _docnumKeys[index],
      'docexp' => _docexpKeys[index],
      'firstname' => _firstnameKeys[index],
      'lastname' => _lastnameKeys[index],
      'middlename' => _middlenameKeys[index],
      'birthdate' => _birthdateKeys[index],
      'gender' => _genderKeys[index],
      _ => null,
    };
  }

  Future<void> _scrollToField(GlobalKey key) async {
    final fieldContext = key.currentContext;
    if (fieldContext == null) return;

    await Scrollable.ensureVisible(
      fieldContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: 0.18,
    );
  }

  Future<void> _scrollToContinueButton() async {
    FocusScope.of(context).unfocus();
    await _scrollToField(_continueButtonKey);
  }

  String? _validateRequired(String value, String emptyMessage) {
    if (value.trim().isEmpty) return emptyMessage;
    return null;
  }

  String? _validateDate(String value, {required String emptyMessage}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return emptyMessage;
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(trimmed)) {
      return 'invalid_date_format'.tr();
    }
    try {
      DateFormat('dd.MM.yyyy').parseStrict(trimmed);
    } catch (_) {
      return 'invalid_date_format'.tr();
    }
    return null;
  }

  bool _fieldNeedsAttention(_BookingFieldTarget target) {
    if (target.isOptional) return false;
    final text = target.getText();
    if (text.trim().isEmpty) return true;
    final error = target.validator?.call(text);
    return error != null && error.isNotEmpty;
  }

  List<_BookingFieldTarget> _fieldTargets(
    PassengerCubit cubit,
    PassengerLoaded state,
  ) {
    final targets = <_BookingFieldTarget>[
      _BookingFieldTarget(
        fieldName: 'email',
        key: _emailKey,
        focusNode: _emailFocusNode,
        getText: () => _emailController.text,
        validator: (v) => _validateRequired(v, 'enter_email_address'.tr()),
      ),
      _BookingFieldTarget(
        fieldName: 'phone',
        key: _phoneKey,
        focusNode: _phoneFocusNode,
        getText: () => _phoneController.text,
        validator: (_) => _phoneFormatter.getUnmaskedText().isEmpty
            ? 'enter_full_phone_number'.tr()
            : null,
      ),
    ];

    for (int index = 0; index < _totalPassengers; index++) {
      final controller = _passengerControllers[index];
      final passenger = state.passengers[index];
      targets.addAll([
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'lastname',
          key: _lastnameKeys[index],
          focusNode: controller.lastnameFocus,
          getText: () => controller.lastnameController.text,
          validator: (v) => _validateRequired(v, 'surname_not_entered'.tr()),
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'firstname',
          key: _firstnameKeys[index],
          focusNode: controller.firstnameFocus,
          getText: () => controller.firstnameController.text,
          validator: (v) => _validateRequired(v, 'name_not_entered'.tr()),
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'middlename',
          key: _middlenameKeys[index],
          focusNode: controller.middlenameFocus,
          isOptional: true,
          getText: () => controller.middlenameController.text,
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'birthdate',
          key: _birthdateKeys[index],
          focusNode: controller.birthdateFocus,
          getText: () => controller.birthdateController.text,
          validator: (v) =>
              _validateDate(v, emptyMessage: 'birthdate_required'.tr()),
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'citizen',
          key: _citizenKeys[index],
          isPicker: true,
          focusNode: controller.citizenFocus,
          getText: () => passenger.citizen,
          validator: (v) =>
              _validateRequired(v, 'citizenship_not_selected'.tr()),
          onPickerTap: () => _showCitizenPicker(index, cubit),
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'docnum',
          key: _docnumKeys[index],
          focusNode: controller.docnumFocus,
          getText: () => controller.docnumController.text,
          validator: (v) =>
              _validateRequired(v, 'passport_data_not_entered'.tr()),
        ),
        _BookingFieldTarget(
          passengerIndex: index,
          fieldName: 'docexp',
          key: _docexpKeys[index],
          focusNode: controller.docexpFocus,
          getText: () => controller.docexpController.text,
          validator: (v) =>
              _validateDate(v, emptyMessage: 'passport_expiry_required'.tr()),
        ),
      ]);
    }

    return targets;
  }

  _BookingFieldTarget? _currentTarget(List<_BookingFieldTarget> targets) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return null;

    for (final target in targets) {
      if (target.focusNode != null && target.focusNode == focused) {
        return target;
      }
    }
    return null;
  }

  Future<void> _goToNextEmptyField() async {
    final cubit = context.read<PassengerCubit>();
    if (cubit.state is! PassengerLoaded) return;

    _updatePhoneNumber(cubit);
    cubit.showErrors();

    final state = cubit.state as PassengerLoaded;
    final targets = _fieldTargets(cubit, state);
    final current = _currentTarget(targets);

    if (current != null && _fieldNeedsAttention(current)) {
      await _activateField(current);
      if (mounted) setState(() {});
      return;
    }

    final nextIndex = current == null ? 0 : targets.indexOf(current) + 1;

    if (nextIndex >= targets.length) {
      final firstIssue = targets.cast<_BookingFieldTarget?>().firstWhere(
            (target) => target != null && _fieldNeedsAttention(target),
            orElse: () => null,
          );
      if (firstIssue != null) {
        await _activateField(firstIssue);
      } else {
        await _scrollToContinueButton();
      }
      if (mounted) setState(() {});
      return;
    }

    await _activateField(targets[nextIndex]);
    if (mounted) setState(() {});
  }

  Future<void> _dismissKeyboardWhenComplete() async {
    FocusScope.of(context).unfocus();
    await _scrollToContinueButton();
  }

  Future<void> _activateField(_BookingFieldTarget target) async {
    if (target.isPicker) {
      // FocusScope.of(context).unfocus();
      await _scrollToField(target.key);
      target.focusNode?.requestFocus();
      target.onPickerTap?.call();
      return;
    }

    await _scrollToField(target.key);
    target.focusNode?.requestFocus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _BookingFieldTarget {
  final int? passengerIndex;
  final String fieldName;
  final GlobalKey key;
  final FocusNode? focusNode;
  final bool isPicker;
  final bool isOptional;
  final VoidCallback? onPickerTap;
  final String Function() getText;
  final String? Function(String value)? validator;

  const _BookingFieldTarget({
    required this.fieldName,
    required this.key,
    required this.getText,
    this.passengerIndex,
    this.focusNode,
    this.isPicker = false,
    this.isOptional = false,
    this.onPickerTap,
    this.validator,
  });
}
