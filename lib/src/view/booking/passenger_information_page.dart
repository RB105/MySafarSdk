// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart' show dataLang;
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart'
    show ErrorDialogAction, ProjectDialogs;
import 'package:mysafar_sdk/src/core/widgets/booking_create_loading_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show
        SdkDialogAction,
        SdkDialogButtonVariant,
        SdkDialogTone,
        showSdkSheetAlert;
import 'package:mysafar_sdk/src/core/widgets/stable_keyboard_insets.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/booking/create/booking_gate.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_state.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/local/passenger_model.dart'
    show PassengerModel;
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;
import 'package:mysafar_sdk/src/view/booking/booking_create_flow.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_form_page.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart'
    show WebViewScreen;
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/contact_form_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/flight_details_sheet.dart';
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/route_arc_hero.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart'
    show RecommendationsTicketPage;

/// O'zbekiston telefon kodi — bo'sh telefon maydoniga fokusda qo'yiladi.
const String _kUzPhonePrefix = '998';

class PassengerInformationPage extends StatefulWidget {
  final FlightElement element;
  final int adt;
  final int inf;
  final int chd;

  /// "Bron qilish" bosilganda hali tugamagan reys tekshiruvi (№36). Bron
  /// yaratishdan oldin kutiladi: bron tokeni (trId) va narx tekshirilgan
  /// elementdan olinadi. `null` — reys allaqachon tekshirilgan.
  final FlightValidation? pendingValidation;

  const PassengerInformationPage({
    super.key,
    required this.element,
    required this.adt,
    required this.chd,
    required this.inf,
    this.pendingValidation,
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
      firstFlightDate: _firstFlightDate(widget.element),
      lastFlightDate: _lastFlightDate(widget.element),
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
        pendingValidation: widget.pendingValidation,
        adt: widget.adt,
        chd: widget.chd,
        inf: widget.inf,
      ),
    );
  }
}

class _PassengerInformationView extends StatefulWidget {
  final FlightElement element;
  final FlightValidation? pendingValidation;
  final int adt;
  final int inf;
  final int chd;

  const _PassengerInformationView({
    required this.element,
    this.pendingValidation,
    required this.adt,
    required this.chd,
    required this.inf,
  });

  @override
  State<_PassengerInformationView> createState() =>
      _PassengerInformationViewState();
}

class _PassengerInformationViewState extends State<_PassengerInformationView> {
  /// Joriy reys — fondagi tekshiruvdan so'ng tasdiqlangan element bilan
  /// almashtiriladi (yangi narx pastki panelda ham ko'rinadi).
  late FlightElement _element = widget.element;

  /// Hali kutilmagan reys tekshiruvi (№36); natija qo'llangach `null`.
  late FlightValidation? _pendingValidation = widget.pendingValidation;

  /// Bron yaratish oqimi (№22) — alohida tasdiqlash sahifasi o'rniga shu
  /// sahifadagi tugma bronni yaratadi va to'lov sahifasini ochadi.
  final BookingCreateFlow _bookingFlow = BookingCreateFlow();
  bool _bookingBusy = false;

  final _scrollController = ScrollController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  /// Telefon — faqat raqamlar (`998...`). Profil/hostdan to'ldiriladi,
  /// foydalanuvchi tahrirlashi mumkin. UI formatlangan ko'rinishda.
  String _rawPhoneDigits = '';

  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _continueButtonKey = GlobalKey();
  final _emailFocusNode = FocusNode(skipTraversal: true);
  final _phoneFocusNode = FocusNode(skipTraversal: true);
  late final List<GlobalKey> _passengerSlotKeys =
      List.generate(_totalPassengers, (_) => GlobalKey());

  int get _totalPassengers => widget.adt + widget.chd + widget.inf;

  /// Tugma ostidagi teskari sanoq: 15:00 dan 00:00 gacha. Faqat shu yozuv
  /// qayta quriladi, butun sahifa emas.
  static const Duration _holdDuration = Duration(minutes: 15);
  final ValueNotifier<Duration> _holdLeft = ValueNotifier(_holdDuration);
  Timer? _holdTimer;

  /// Vaqt tugadi — narx/joy eskirgan hisoblanadi: tugma o'chadi va
  /// foydalanuvchi natijalar sahifasiga qaytariladi.
  bool _holdExpired = false;

  void _startHoldCountdown() {
    _holdTimer?.cancel();
    _holdLeft.value = _holdDuration;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = _holdLeft.value - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        _holdLeft.value = Duration.zero;
        timer.cancel();
        _onHoldExpired();
        return;
      }
      _holdLeft.value = left;
    });
  }

  Future<void> _onHoldExpired() async {
    if (!mounted || _holdExpired) return;
    setState(() => _holdExpired = true);

    // Sahifa ustida boshqa ekran (yo'lovchi formasi, varaq, bron/to'lov)
    // bo'lsa — dialog hozir emas, shu sahifaga qaytilgach chiqadi.
    while (mounted && !(ModalRoute.of(context)?.isCurrent ?? true)) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;

    final searchAgain = await ProjectDialogs.showPricesOutdatedDialog(context);
    if (!mounted) return;
    // "Qayta qidirish" — natijalar sahifasiga qaytib, xuddi shu parametrlar
    // bilan yangi so'rov. Aks holda shunchaki natijalarga qaytiladi.
    // Kiritilgan yo'lovchilar qoralamada saqlanib qoladi.
    if (searchAgain && RecommendationsTicketPage.returnAndSearchAgain(context)) {
      return;
    }
    Navigator.of(context).popUntil(
      (r) => r.isFirst || r.settings.name == RecommendationsTicketPage.routeName,
    );
  }

  static String _mmss(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  bool _isContactControllersFilled = false;

  /// Kontakt maydoni fokusdami — faqat pastki panel shunga qarab qayta
  /// quriladi (butun sahifa emas).
  final ValueNotifier<bool> _formFieldFocused = ValueNotifier(false);

  /// Klaviatura ustidagi "Keyingi" paneli. Sahifa yopilayotganda
  /// ([StableKeyboardInsets.isLeaving]) oxirgi holatida qoladi.
  bool _keyboardBarVisible = false;

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

  @override
  void initState() {
    super.initState();
    _focusListener = _updateFormFocusState;
    FocusManager.instance.addListener(_focusListener);
    for (final node in _allFormFocusNodes) {
      node.addListener(_updateFormFocusState);
    }
    _phoneFocusNode.addListener(_onPhoneFocusChanged);
    _passengerCubit = context.read<PassengerCubit>();
    // To'lov usullarini oldindan (fonda) keshlaymiz — bron yaratilgach to'lov
    // sahifasida ro'yxat darhol chiqadi (№38).
    BookingCreateFlow.prefetchPaymentTypes();
    _startHoldCountdown();
  }

  /// Fokus listener'lari sahifa yopilayotganda ham chaqirilishi mumkin —
  /// o'shanda `context.read` xavfli, shuning uchun oldindan olinadi.
  late final PassengerCubit _passengerCubit;

  /// Telefon bo'sh bo'lsa fokusda `+998` o'zi qo'yiladi (asosiy auditoriya);
  /// boshqa davlat kodi uchun o'chirib yozish mumkin. Faqat prefiks qolib
  /// fokus ketsa — maydon yana bo'shatiladi.
  void _onPhoneFocusChanged() {
    if (!mounted) return;
    if (_phoneFocusNode.hasFocus) {
      if (_rawPhoneDigits.isEmpty && _phoneController.text.isEmpty) {
        if (!_shouldPrefixUzPhone()) return;
        const prefix = _kUzPhonePrefix;
        _rawPhoneDigits = prefix;
        _phoneController.value = TextEditingValue(
          text: formatInternationalPhone(prefix),
          selection: TextSelection.collapsed(
              offset: formatInternationalPhone(prefix).length),
        );
        _passengerCubit.updatePhone(prefix);
      }
    } else if (_rawPhoneDigits == _kUzPhonePrefix) {
      _rawPhoneDigits = '';
      _phoneController.clear();
      if (!_passengerCubit.isClosed) _passengerCubit.updatePhone('');
    }
  }

  /// Oldin kiritilgan telefonlar bo'lsa va ularning hech biri `998` bilan
  /// boshlanmasa — foydalanuvchi boshqa davlatdan, prefiks qo'yilmaydi.
  bool _shouldPrefixUzPhone() {
    final previous = _cachedSuggestions('phone')
        .map(normalizePhoneDigits)
        .where((p) => p.isNotEmpty)
        .toList();
    return previous.isEmpty ||
        previous.any((p) => p.startsWith(_kUzPhonePrefix));
  }

  /// Bron sahifasida faqat kontakt maydonlari qoldi — yo'lovchilar alohida
  /// [PassengerFormPage] da to'ldiriladi.
  Iterable<FocusNode> get _allFormFocusNodes sync* {
    yield _emailFocusNode;
    yield _phoneFocusNode;
  }

  void _updateFormFocusState() {
    final focused = FocusManager.instance.primaryFocus;
    final hasFormFocus =
        focused != null && _allFormFocusNodes.contains(focused);
    if (mounted) _formFieldFocused.value = hasFormFocus;
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusListener);
    for (final node in _allFormFocusNodes) {
      node.removeListener(_updateFormFocusState);
    }
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _formFieldFocused.dispose();
    _holdTimer?.cancel();
    _holdLeft.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _bookingFlow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PassengerCubit, PassengerState>(
      listener: _handleStateChanges,
      // Email / telefon har harfda cubit'ga yoziladi — butun sahifa qayta
      // qurilmasin (maydonlar o'z controller'i orqali yangilanadi). Saqlash /
      // xato oraliq holatlarida ham sahifa spinner'ga almashmaydi.
      buildWhen: (previous, current) {
        if (current is! PassengerLoaded) return previous is PassengerInitial;
        if (previous is PassengerLoaded &&
            (previous.email != current.email ||
                previous.phone != current.phone)) {
          return false;
        }
        return true;
      },
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

        return StableKeyboardInsets(
          child: Scaffold(
            appBar: _buildAppBar(context),
            // Klaviatura insetini o'zimiz beramiz (pastki panel shu balandlikda
            // turadi) — Scaffold uni ikkinchi marta hisoblamasin.
            resizeToAvoidBottomInset: false,
            // Pastki panel kontent USTIGA emas, ostiga joylashadi — balandligi
            // (narx + tugma + safe area) qanday bo'lmasin, oxirgi karta
            // yashirinib qolmaydi.
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _dismissKeyboard,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Marshrut — ekran kengligi bo'yicha (yon
                          // to'ldirishsiz), shuning uchun scroll padding'i
                          // faqat pastda; qolgan blok o'zi 16 px oladi.
                          RouteArcHero(
                            element: _element,
                            // Faqat mavjud ma'lumot ko'rsatiladi — so'rov yo'q.
                            onDetails: () => showFlightDetailsSheet(
                              context,
                              _element,
                              passengerCount: _totalPassengers,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 4),
                                _SectionTitle("passenger_data_title".tr()),
                                // Tasdiqlash sahifasi olib tashlangach (№22)
                                // eslatma shu yerda: chipta hujjatdagidek
                                // chiqadi.
                                const _CheckDataNotice(),
                                const SizedBox(height: 10),
                                _buildPassengersList(context, state),
                                const SizedBox(height: 20),
                                _SectionTitle("your_contacts".tr()),
                                _buildContactForm(context, state),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Klaviatura har kadrda o'zgaradi — faqat pastki qism qayta
                // quriladi, butun sahifa emas.
                ValueListenableBuilder<bool>(
                  valueListenable: _formFieldFocused,
                  builder: (context, _, __) => _buildBottomArea(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Klaviatura ochiq va shu sahifadagi kontakt maydoni fokusda bo'lsa —
  /// klaviatura ustida "Keyingi" paneli, aks holda narx + davom etish tugmasi.
  ///
  /// Fokus sharti muhim: yo'lovchi formasidan qaytishda (yoki ustidagi
  /// sahifada yozilayotganda) klaviatura boshqa sahifaniki — panel bu yerda
  /// chiqib, tugma bilan almashinib sakramasin.
  Widget _buildBottomArea(BuildContext context) {
    // Klavatura balandligi OS dan keladi — panel aynan shu qiymatda
    // joylashadi, orada bo'sh joy qolmaydi (har qanday qurilmada).
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (!StableKeyboardInsets.isLeaving(ModalRoute.of(context))) {
      _keyboardBarVisible =
          keyboardInset > 0 && _allFormFocusNodes.any((node) => node.hasFocus);
    }
    if (!_keyboardBarVisible) return _buildBottomButton(context);

    const keyboardBarHeight = 44.0;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SizedBox(
        height: keyboardBarHeight,
        child: _buildKeyboardNextBar(context),
      ),
    );
  }

  /// `FocusScope.of(context).unfocus()` oxirgi maydonni route scope'ida eslab
  /// qoladi — ustidagi sahifa yopilganda Flutter fokusni o'sha maydonga
  /// qaytaradi va klaviatura kutilmaganda ochiladi. `primaryFocus.unfocus()`
  /// bu xotirani tozalaydi.
  static void _dismissKeyboard() =>
      FocusManager.instance.primaryFocus?.unfocus();

  void _handleStateChanges(BuildContext context, PassengerState state) {
    if (state is PassengerLoaded) {
      if (_emailController.text.isEmpty && state.email.isNotEmpty) {
        _emailController.text = state.email;
      }
      if (_rawPhoneDigits.isEmpty && state.phone.isNotEmpty) {
        _updateContactControllers('', state.phone);
      }
    } else if (state is PassengerValidationError) {
      _handleValidationError(state);
    } else if (state is PassengerSaved) {
      _createBooking(state);
    }
  }

  void _handleValidationError(PassengerValidationError state) {
    final key = _getFieldKeyByName(state.passengerIndex, state.fieldName);
    if (key != null) {
      _scrollToField(key);
    }
    // Yo'lovchi maydonlari alohida sahifada — qaysi yo'lovchi va nima xato
    // ekani aniq aytiladi.
    final index = state.passengerIndex;
    _showSnackBar(index != null
        ? "${"passenger_number".tr(namedArgs: {"number": "${index + 1}"})}: "
            "${state.message.isNotEmpty ? state.message : "incomplete_passenger_data".tr()}"
        : state.message);
  }

  /// "Tasdiqlash va bron qilish" (№22): ma'lumotlar tekshirilgach bron shu
  /// yerning o'zida yaratiladi va to'lov sahifasi ochiladi. Avval fondagi
  /// reys tekshiruvi kutiladi (№36).
  Future<void> _createBooking(PassengerSaved saved) async {
    final cubit = _passengerCubit;
    if (_bookingBusy || _bookingFlow.isRunning) return;
    _bookingBusy = true;
    try {
      // Pasport safardan keyin 6 oydan kam amal qilsa — yumshoq ogohlantirish
      // (№72). Bron to'xtatilmaydi, foydalanuvchi tanlaydi.
      if (!await _confirmPassportExpiry(saved, cubit)) {
        if (mounted) cubit.restoreState();
        return;
      }
      if (!mounted) return;
      // SDK'da login talab qilinmaydi — sessiyani host boshqaradi
      // (web-register). Token tekshiruvi va auth bottom-sheet yo'q.
      final canBook = await _awaitFlightValidation(cubit);
      if (!mounted) return;
      if (!canBook) {
        cubit.restoreState();
        return;
      }
      final outcome = await _bookingFlow.start(
        context,
        BookingCreateRequest(
          passengers: saved.passengersJson,
          passengersToSave: saved.passengersToSaveJson,
          // Tekshiruvdan so'ng yangilangan token va narx.
          trId: cubit.trId,
          price: cubit.price,
          flight: _element,
        ),
      );
      if (!mounted) return;
      if (outcome == BookingCreateOutcome.cancelled) {
        LoadingDialog.dismiss(context);
      }
      cubit.restoreState();
    } finally {
      _bookingBusy = false;
    }
  }

  /// Ogohlantirish tasdiqlangan pasportlar (`docnum|docexp`) — har bosishda
  /// qayta so'ralmaydi.
  final Set<String> _expiryAcknowledged = {};

  /// Pasporti oxirgi reysdan keyin 6 oydan kam amal qiladigan yo'lovchilar
  /// bo'lsa ogohlantiradi (№72). `true` — davom etish.
  Future<bool> _confirmPassportExpiry(
      PassengerSaved saved, PassengerCubit cubit) async {
    final numbers = <String>[];
    final keys = <String>[];
    for (int i = 0; i < saved.passengersJson.length; i++) {
      final p = PassengerModel.fromJson(saved.passengersJson[i]);
      final key = '${p.docnum}|${p.docexp}';
      if (_expiryAcknowledged.contains(key)) continue;
      if (!PassengerRules.passportExpiresSoon(p.docexp,
          lastFlight: cubit.lastFlightDate)) {
        continue;
      }
      numbers.add('${i + 1}');
      keys.add(key);
    }
    if (numbers.isEmpty) return true;
    final confirmed = await showSdkSheetAlert<bool>(
      context: context,
      icon: Assets.iconsDialogWarningIcon,
      tone: SdkDialogTone.warning,
      title: 'passport_expires_soon_title'.tr(),
      message: 'passport_expires_soon_message'
          .tr(namedArgs: {'passengers': numbers.join(', ')}),
      actions: [
        SdkDialogAction(label: 'continue'.tr(), value: true),
        SdkDialogAction(
          label: 'change'.tr(),
          value: false,
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
    if (confirmed != true) return false;
    _expiryAcknowledged.addAll(keys);
    return true;
  }

  /// Fondagi reys tekshiruvini kutadi (bron yuklanish oynasi ostida).
  /// `true` — bron qilish mumkin; `false` — xato yoki foydalanuvchi yangi
  /// narxni rad etdi (sahifada qoladi yoki natijalarga qaytadi).
  Future<bool> _awaitFlightValidation(PassengerCubit cubit) async {
    while (true) {
      final pending = _pendingValidation;
      if (pending == null) return true;

      LoadingDialog.show(context);
      final result = await pending.result;
      if (!mounted) return false;

      final decision = BookingGate.decide(
        shown: _element,
        result: result,
        currency: context.currencyProvider.currency,
      );
      switch (decision) {
        case BookingGateProceed(:final element):
          // Yuklanish oynasi yopilmaydi — bron so'rovi shu zahoti boshlanadi.
          _applyValidatedFlight(element, cubit);
          return true;
        case BookingGatePriceChanged():
          LoadingDialog.dismiss(context);
          // Yangi narx darhol qo'llanadi — rad etilsa ham keyingi bosishda
          // aynan shu (ko'rsatilgan) narx bilan bron qilinadi.
          _applyValidatedFlight(decision.element, cubit);
          final confirmed = await ProjectDialogs.showPriceIncreasedConfirm(
            context,
            oldPrice: decision.oldPrice,
            newPrice: decision.newPrice,
            currencyLabel: decision.currencyLabel,
          );
          return confirmed && mounted;
        case BookingGateFailed(:final failure):
          LoadingDialog.dismiss(context);
          final retry = await _showValidationError(failure, pending);
          if (!retry || !mounted) return false;
          setState(() => _pendingValidation = pending.retry());
      }
    }
  }

  void _applyValidatedFlight(FlightElement element, PassengerCubit cubit) {
    cubit.updateFlight(trId: element.id, price: element.price);
    setState(() {
      _element = element;
      _pendingValidation = null;
    });
  }

  /// Reys tekshiruvdan o'tmadi: "Qayta urinish" (`true`) yoki "Qayta
  /// qidirish" — natijalar sahifasiga qaytib, xuddi shu parametrlar bilan
  /// qayta qidiriladi. Kiritilgan yo'lovchilar qoralamada saqlanib qoladi.
  Future<bool> _showValidationError(
      FlightValidationFailed failure, FlightValidation pending) async {
    final action = await ProjectDialogs.showApiErrorDialog(
      context,
      message: failure.message,
      errorType: failure.errorType,
      showRetry: pending.canRetry,
      secondaryLabel: "search_again".tr(),
    );
    if (!mounted) return false;
    if (action == ErrorDialogAction.retry) return true;
    if (!RecommendationsTicketPage.returnAndSearchAgain(context)) {
      Navigator.of(context).maybePop();
    }
    return false;
  }

  void _updateContactControllers(String email, String phone) {
    if (email.isNotEmpty) {
      _emailController.text = email;
    }
    final digits = normalizePhoneDigits(phone);
    if (digits.isNotEmpty) {
      _rawPhoneDigits = digits;
      _phoneController.text = formatInternationalPhone(digits);
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      ),
      title: Text(
        'booking'.tr(),
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      // Qo'llab-quvvatlash faqat shu yerda — sahifa ichidagi karta olib
      // tashlandi.
      actions: const [_SupportAppBarAction()],
    );
  }

  Widget _buildContactForm(BuildContext context, PassengerLoaded state) {
    final cubit = context.read<PassengerCubit>();

    return ContactFormWidget(
      emailController: _emailController,
      phoneController: _phoneController,
      showErrors: state.showErrors,
      emailSuggestions: _cachedSuggestions('email'),
      onEmailChanged: (value) => cubit.updateEmail(value),
      emailKey: _emailKey,
      phoneKey: _phoneKey,
      emailFocusNode: _emailFocusNode,
      phoneFocusNode: _phoneFocusNode,
      onPhoneChanged: (digits) => _onPhoneChanged(cubit, digits),
      onNextField: _goToNextEmptyField,
    );
  }

  void _onPhoneChanged(PassengerCubit cubit, String digits) {
    // setState yo'q — sahifa har raqamda qayta qurilmaydi.
    _rawPhoneDigits = digits;
    cubit.updatePhone(digits);
  }

  /// Panel matni ("Keyingi" / "Davom etish") maydonlar to'lishiga bog'liq —
  /// faqat panel controller'larni tinglab qayta quriladi.
  Widget _buildKeyboardNextBar(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_emailController, _phoneController]),
      builder: (context, _) => _buildKeyboardNextBarContent(context),
    );
  }

  Widget _buildKeyboardNextBarContent(BuildContext context) {
    final isDark = context.isDarkMode;
    final targets = _fieldTargets;
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

  /// Yo'lovchilar bitta kartada ro'yxat qatorlari ko'rinishida: holat
  /// belgisi (bo'sh / to'ldirilgan / xato), ism yoki "N-yo'lovchi", yosh
  /// toifasi va strelka. Bosilganda alohida [PassengerFormPage] ochiladi.
  Widget _buildPassengersList(BuildContext context, PassengerLoaded state) {
    return BookingCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (int index = 0; index < _totalPassengers; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: context.color.outline.withValues(alpha: 0.6),
              ),
            _buildPassengerSlot(context, state, index),
          ],
        ],
      ),
    );
  }

  String _passengerAgeLabel(int index) {
    if (index < widget.adt) return "above_12".tr();
    if (index < widget.adt + widget.chd) return "between_2_12".tr();
    return "under_2".tr();
  }

  Widget _buildPassengerSlot(
    BuildContext context,
    PassengerLoaded state,
    int index,
  ) {
    final passenger = state.passengers[index];
    final bool filled = passenger.displayName.isNotEmpty;
    final bool complete = passenger.isValid &&
        PassengerRules.invalidFields(
          passenger,
          firstFlight: _firstFlightDate(_element),
          lastFlight: _lastFlightDate(_element),
        ).isEmpty;
    final bool hasError = state.showErrors && !complete;
    final bool isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final Color muted = BookingFormStyle.label(context);

    final (String icon, Color iconColor, Color iconBg) = hasError
        ? (
            Assets.iconsBookingAlertIcon,
            ProjectTheme.error,
            ProjectTheme.error.withValues(alpha: isDark ? 0.18 : 0.10),
          )
        : complete
            ? (
                Assets.iconsBookingDoneIcon,
                isDark ? Colors.white : brand,
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : brand.withValues(alpha: 0.10),
              )
            : (
                Assets.iconsBookingUserIcon,
                muted,
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF1F4F9),
              );

    final String subtitle = hasError
        ? "incomplete_passenger_data".tr()
        : filled
            ? _passengerAgeLabel(index)
            : "${_passengerAgeLabel(index)} · ${"fill_passenger_data".tr()}";

    return InkWell(
      key: _passengerSlotKeys[index],
      onTap: () => _openPassengerForm(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: SvgPicture.asset(
                icon,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filled
                        ? passenger.displayName
                        : "passenger_number"
                            .tr(namedArgs: {"number": "${index + 1}"}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasError ? ProjectTheme.error : muted,
                    ),
                  ),
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
    );
  }

  Future<void> _openPassengerForm(int index) async {
    _dismissKeyboard();
    final cubit = context.read<PassengerCubit>();
    final current = cubit.state;
    if (current is! PassengerLoaded) return;

    final result = await Navigator.of(context).push<PassengerFormResult>(
      MaterialPageRoute(
        settings: const RouteSettings(name: PassengerFormPage.routeName),
        builder: (_) => PassengerFormPage(
          initial: current.passengers[index],
          index: index,
          adultCount: widget.adt,
          childCount: widget.chd,
          initialSaveToProfile: current.saveToProfile.contains(index),
          firstFlightDate: _firstFlightDate(_element),
          lastFlightDate: _lastFlightDate(_element),
          excludedDocnums: cubit.docnumsUsedExcept(index),
          // Orqaga qaytilganda chala kiritilganlar ham yo'qolmaydi —
          // slotga qoralama sifatida yoziladi (tekshiruv "Davom etish"da).
          onDraft: (draft) {
            if (cubit.isClosed) return;
            cubit.setPassenger(index, draft.passenger,
                saveToProfile: draft.saveToProfile);
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    cubit.setPassenger(
      index,
      result.passenger,
      saveToProfile: result.saveToProfile,
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return KeyedSubtree(
      key: _continueButtonKey,
      child: ValueListenableBuilder<Duration>(
        valueListenable: _holdLeft,
        builder: (context, left, _) => NextButtonWidget(
          // Alohida "Ma'lumotlarni tasdiqlash" sahifasi yo'q (№22) — bu
          // bosish bronni yaratadi va to'lov sahifasini ochadi.
          nextTittle: 'confirm_and_book',
          analyticsId: 'booking_passenger_continue',
          // Vaqt tugagach tugma o'chadi — davom etib bo'lmaydi.
          onPressed: _holdExpired
              ? null
              : () {
                  if (_bookingBusy) return;
                  _dismissKeyboard();
                  context.read<PassengerCubit>().validateAndSave();
                },
          passenger: _totalPassengers,
          showButton: true,
          // Tasdiqlash sahifasi yo'q (№22) — to'lovdan oldingi oxirgi
          // ekran, shuning uchun jami summa shu yerda qoladi.
          price: _element.price,
          noteHighlight: 'booking_free'.tr(),
          note: 'price_may_change_note'.tr(namedArgs: {'time': _mmss(left)}),
          footer: const _OfferNotice(),
        ),
      ),
    );
  }

  GlobalKey? _getFieldKeyByName(int? index, String? fieldName) {
    if (fieldName == 'email') return _emailKey;
    if (fieldName == 'phone') return _phoneKey;
    if (index == null) return null;
    return _passengerSlotKeys[index];
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
    _dismissKeyboard();
    await _scrollToField(_continueButtonKey);
  }

  String? _validateRequired(String value, String emptyMessage) {
    if (value.trim().isEmpty) return emptyMessage;
    return null;
  }

  bool _fieldNeedsAttention(_BookingFieldTarget target) {
    final text = target.getText();
    if (text.trim().isEmpty) return true;
    final error = target.validator?.call(text);
    return error != null && error.isNotEmpty;
  }

  /// Kontakt maydonlari bo'ylab ketma-ket tartib — yo'lovchilar alohida
  /// sahifada to'ldiriladi.
  List<_BookingFieldTarget> get _fieldTargets {
    return <_BookingFieldTarget>[
      _BookingFieldTarget(
        fieldName: 'email',
        key: _emailKey,
        focusNode: _emailFocusNode,
        getText: () => _emailController.text,
        validator: (v) =>
            _validateRequired(v, 'enter_email_address'.tr()) ??
            (PassengerCubit.isValidEmail(v) ? null : 'srv_invalid_email'.tr()),
      ),
      _BookingFieldTarget(
        fieldName: 'phone',
        key: _phoneKey,
        focusNode: _phoneFocusNode,
        getText: () => _rawPhoneDigits,
        validator: (_) => _rawPhoneDigits.length < kMinPhoneDigits
            ? 'enter_full_phone_number'.tr()
            : null,
      ),
    ];
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

    cubit.showErrors();

    final targets = _fieldTargets;
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
    _dismissKeyboard();
    await _scrollToContinueButton();
  }

  Future<void> _activateField(_BookingFieldTarget target) async {
    await _scrollToField(target.key);
    target.focusNode?.requestFocus();
  }

  void _showSnackBar(String message) {
    showErrorMessage(message, context: context);
  }
}

class _BookingFieldTarget {
  final String fieldName;
  final GlobalKey key;
  final FocusNode? focusNode;
  final String Function() getText;
  final String? Function(String value)? validator;

  const _BookingFieldTarget({
    required this.fieldName,
    required this.key,
    required this.getText,
    this.focusNode,
    this.validator,
  });
}

/// Tugma ostidagi oferta qatori (№22): "davom etish — shartlarga rozilik";
/// "Oferta" bosilsa ommaviy oferta matni ochiladi (til — uz/ru/en).
class _OfferNotice extends StatelessWidget {
  const _OfferNotice();

  @override
  Widget build(BuildContext context) {
    final Color muted = BookingFormStyle.label(context);
    final Color link =
        context.isDarkMode ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(context, WebViewScreen.routName,
          arguments: "https://mysafar.uz/${dataLang()}/oferta"),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "${"offer_accept_by_booking".tr()} · "),
              TextSpan(
                text: "offer_title".tr(),
                style: TextStyle(
                  color: link,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: link,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: muted,
          ),
        ),
      ),
    );
  }
}

/// Yo'lovchilar ro'yxati ustidagi eslatma: chipta hujjatdagi ma'lumotlar
/// bo'yicha rasmiylashtiriladi — bron qilishdan oldin tekshirib chiqish kerak.
class _CheckDataNotice extends StatelessWidget {
  const _CheckDataNotice();

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color accent = isDark ? ProjectTheme.accentLight : brand;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SvgPicture.asset(
              Assets.iconsBookingInfoIcon,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "confirm_data_hint".tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AppBar'ning o'ng burchagidagi yordam tugmasi — bosilganda
/// qo'llab-quvvatlash menyusi ochiladi (host sozlamalaridagi aloqa).
class _SupportAppBarAction extends StatelessWidget {
  const _SupportAppBarAction();

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final radius = BorderRadius.circular(_size * .32);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Material(
          color: isDark
              ? Colors.white.withValues(alpha: .08)
              : ProjectTheme.swimmer200,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => ProjectDialogs.showSupportMenu(context),
            child: Padding(
              padding: const EdgeInsets.all(_size * .08),
              child: Image.asset(
                'packages/mysafar_sdk/assets/img/home/icons/support_ic.png',
                width: _size * .84,
                height: _size * .84,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Birinchi uchish sanasi (yosh toifasi shu kun bo'yicha).
DateTime? _firstFlightDate(FlightElement element) {
  final segments = element.segments ?? const [];
  if (segments.isEmpty) return null;
  return PassengerRules.parseFlightDate(segments.first.dep.date);
}

/// Oxirgi qo'nish sanasi (pasport safar tugaguncha amal qilishi kerak).
DateTime? _lastFlightDate(FlightElement element) {
  final segments = element.segments ?? const [];
  if (segments.isEmpty) return null;
  return PassengerRules.parseFlightDate(segments.last.arr.date) ??
      PassengerRules.parseFlightDate(segments.last.dep.date);
}
