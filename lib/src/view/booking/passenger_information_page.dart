// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/widgets/stable_keyboard_insets.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_cubit.dart';
import 'package:mysafar_sdk/src/cubit/booking/passenger/passenger_state.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/local/passenger_rules.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement;
import 'package:mysafar_sdk/src/view/booking/booking_create_page.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_form_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/contact_form_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
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

  bool _isContactControllersFilled = false;
  bool _formFieldFocused = false;

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
    if (hasFormFocus != _formFieldFocused && mounted) {
      setState(() => _formFieldFocused = hasFormFocus);
    }
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRouteSummary(context),
                          const SizedBox(height: 12),
                          const SupportWidget(),
                          const SizedBox(height: 20),
                          _SectionTitle("passenger_data_title".tr()),
                          _buildPassengersList(context, state),
                          const SizedBox(height: 20),
                          _SectionTitle("your_contacts".tr()),
                          _buildContactForm(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
                // Klaviatura har kadrda o'zgaradi — faqat pastki qism qayta
                // quriladi, butun sahifa emas.
                Builder(builder: _buildBottomArea),
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
      _navigateToBookingPage(context, state);
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

  Future<void> _navigateToBookingPage(
      BuildContext context, PassengerSaved state) async {
    // SDK'da login talab qilinmaydi — sessiyani host boshqaradi (web-register).
    // Token tekshiruvi va auth bottom-sheet olib tashlangan.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingCreatePage(
          passenger: state.passengersJson,
          passengersToSave: state.passengersToSaveJson,
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

    final bool isRoundTrip = dir1.isNotEmpty;
    final bool isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;

    return BookingCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(BookingFormStyle.radius),
            ),
            child: SvgPicture.asset(
              Assets.iconsPlaceAirportIcon,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        origin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isRoundTrip
                            ? Icons.swap_horiz_rounded
                            : Icons.arrow_forward_rounded,
                        size: 17,
                        color: BookingFormStyle.label(context),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        dest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  parts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: 13,
                    color: BookingFormStyle.label(context),
                  ),
                ),
              ],
            ),
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
      emailSuggestions: _cachedSuggestions('email'),
      onEmailChanged: (value) => cubit.updateEmail(value),
      emailKey: _emailKey,
      phoneKey: _phoneKey,
      emailFocusNode: _emailFocusNode,
      phoneFocusNode: _phoneFocusNode,
      onPhoneChanged: (digits) => _onPhoneChanged(cubit, digits),
      onNextField: _goToNextEmptyField,
      rawPhoneDigits: _rawPhoneDigits,
    );
  }

  void _onPhoneChanged(PassengerCubit cubit, String digits) {
    setState(() => _rawPhoneDigits = digits);
    cubit.updatePhone(digits);
  }

  Widget _buildKeyboardNextBar(BuildContext context) {
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
          firstFlight: _firstFlightDate(widget.element),
          lastFlight: _lastFlightDate(widget.element),
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
          firstFlightDate: _firstFlightDate(widget.element),
          lastFlightDate: _lastFlightDate(widget.element),
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
        validator: (v) => _validateRequired(v, 'enter_email_address'.tr()),
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
