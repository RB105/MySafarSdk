// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
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
    show showCitySearchPicker;
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
    _scrollController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

        return Scaffold(
          appBar: _buildAppBar(context),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SupportWidget(),
                  const SizedBox(height: 16),
                  _buildContactForm(context, state),
                  _buildSectionHeader(context, 'passenger_data',
                      trailing:
                          _totalPassengers > 1 ? '$_totalPassengers' : null),
                  _buildPassengersList(context, state),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomButton(context),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, PassengerState state) {
    if (state is PassengerLoaded) {
      if (_emailController.text.isEmpty && state.email.isNotEmpty) {
        _emailController.text = state.email;
      }
      if (_phoneController.text.isEmpty && state.phone.isNotEmpty) {
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
      String phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (phoneDigits.startsWith('998')) {
        phoneDigits = phoneDigits.substring(3);
      }
      if (phoneDigits.isNotEmpty) {
        _phoneController.text = _phoneFormatter.maskText(phoneDigits);
      }
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final segs = widget.element.segments ?? const [];
    final dir0 = widget.element.getSegmentsByDirection(0);
    final origin = segs.isNotEmpty
        ? (segs.first.dep.city?.title ??
            segs.first.dep.airport?.code ??
            '')
        : '';
    final dest = dir0.isNotEmpty
        ? (dir0.last.arr.city?.title ?? dir0.last.arr.airport?.code ?? '')
        : (segs.isNotEmpty ? (segs.last.arr.city?.title ?? '') : '');
    final muted = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: context.color.primaryContainer,
      leadingWidth: 56,
      leading: Center(
        child: Material(
          color: isDark
              ? Colors.white.withAlpha(20)
              : Colors.black.withAlpha(10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'booking'.tr(),
            style: context.textTheme.bodyLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (origin.isNotEmpty && dest.isNotEmpty) ...[
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontSize: 11.5, color: muted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.flight_takeoff_rounded,
                      size: 12, color: ProjectTheme.brandColor),
                ),
                Flexible(
                  child: Text(
                    dest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall
                        ?.copyWith(fontSize: 11.5, color: muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? const Color(0xff3A3A3A)
              : const Color(0xffEAEBEE),
        ),
      ),
    );
  }

  /// Bo'lim sarlavhasi — nozik gradient aksent chiziq + nom + (ixtiyoriy)
  /// son badge.
  Widget _buildSectionHeader(BuildContext context, String key,
      {String? trailing}) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [brand, ProjectTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            key.tr(),
            style: context.textTheme.bodyLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: brand.withAlpha(isDark ? 55 : 22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailing,
                style: TextStyle(
                  color: brand,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactForm(BuildContext context, PassengerLoaded state) {
    final cubit = context.read<PassengerCubit>();

    return ContactFormWidget(
      emailController: _emailController,
      phoneController: _phoneController,
      showErrors: state.showErrors,
      selectedCountry: _selectedCountry,
      emailSuggestions: _cachedSuggestions('email'),
      phoneSuggestions: _cachedSuggestions('phone'),
      phoneFormatter: _phoneFormatter,
      onEmailChanged: (value) => cubit.updateEmail(value),
      onPhoneChanged: () => _updatePhoneNumber(cubit),
      onCountrySelected: (code) => _updateMask(code, cubit),
      emailKey: _emailKey,
      phoneKey: _phoneKey,
    );
  }

  Widget _buildPassengersList(BuildContext context, PassengerLoaded state) {
    final cubit = context.read<PassengerCubit>();

    return ListView.builder(
      itemCount: _totalPassengers,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (_, index) => RepaintBoundary(
        child: PassengerCardWidget(
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
          onCitizenTap: () => _showCitizenPicker(index, cubit),
          onDocexpCalendarTap: () => _showDocexpDatePicker(index, cubit),
          onBirthdateCalendarTap: () => _showBirthdateDatePicker(index, cubit),
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
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return NextButtonWidget(
      nextTittle: 'continue_purchase',
      analyticsId: 'booking_passenger_continue',
      onPressed: () => context.read<PassengerCubit>().validateAndSave(),
      passenger: _totalPassengers,
      showButton: true,
      price: widget.element.price,
    );
  }

  void _updatePhoneNumber(PassengerCubit cubit) {
    final unmaskedText = _phoneFormatter.getUnmaskedText();
    final phone = '${_countryCode.dialCode}$unmaskedText';
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
      _phoneController.text = _phoneFormatter.maskText(unmaskedText);
    }

    setState(() {
      _countryCode = code;
      _selectedCountry = code;
    });

    _updatePhoneNumber(cubit);
  }

  void _updateControllersFromUser(int index, dynamic user) {
    final controller = _passengerControllers[index];
    controller.firstnameController.text = user.firstname?.toUpperCase() ?? '';
    controller.lastnameController.text = user.lastname?.toUpperCase() ?? '';
    controller.middlenameController.text = user.middlename?.toUpperCase() ?? '';
    controller.birthdateController.text = user.birthdate ?? '';
    controller.docexpController.text = user.docexp ?? '';
    controller.docnumController.text = user.docnum ?? '';
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
  }

  void _showDocexpDatePicker(int index, PassengerCubit cubit) {
    PassengerDatePicker.show(
      context: context,
      controller: _passengerControllers[index].docexpController,
      isFutureOnly: true,
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
    await Future.delayed(const Duration(milliseconds: 100));
    final fieldContext = key.currentContext;
    if (fieldContext == null) return;

    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final offset = (position.dy - 100).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
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
