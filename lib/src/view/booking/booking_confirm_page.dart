import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mysafar_sdk/src/api/callbacks.dart'
    show MySafarCardTokenRequest;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/api/user_data.dart' show MySafarUzsCard;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart'
    show AppMessageType;
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/cubit/booking/confirm/booking_confirm_states.dart';
import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyRub, FluffyUzs;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_payment_status.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart'
    show Result;
import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_repository.dart';
import 'package:mysafar_sdk/src/service/payment/card_token_encoder.dart';
import 'package:mysafar_sdk/src/view/booking/support/payment_helper.dart';
import 'package:mysafar_sdk/src/view/booking/support/webview_debug.dart';
import 'package:mysafar_sdk/src/view/booking/ticket_pdf_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart'
    show BookingFieldError, BookingFormStyle;
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_countdown_card.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_status_card.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_type_card.dart';
import 'package:mysafar_sdk/src/view/booking/widget/saved_cards_sheet.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart'
    show RecommendationsTicketPage;
import 'package:provider/provider.dart' show ChangeNotifierProvider;

class BookingConfirmPage extends StatefulWidget {
  static const routeName = '/bookingConfirm';

  final BookingCreateModel bookingCreateModel;
  final int passengerNumber;
  final FlightPrice? price;

  const BookingConfirmPage({
    super.key,
    required this.passengerNumber,
    required this.bookingCreateModel,
    required this.price,
  });

  @override
  State<BookingConfirmPage> createState() => _BookingConfirmPageState();
}

class _BookingConfirmPageState extends State<BookingConfirmPage> {
  Timer? _timer;
  Timer? _copyResetTimer;

  /// Vaqt tugagach chiptalar sahifasiga qaytishni rejalashtiruvchi taymer.
  Timer? _expiryTimer;
  bool _leavingAfterExpiry = false;

  /// Vaqt tugaganda sahifada qolmasdan (foydalanuvchi natijani ko'rib olishi
  /// uchun) shuncha kutib, chiptalar sahifasiga qaytamiz.
  static const Duration _expiryLeaveDelay = Duration(milliseconds: 1800);
  int _remainingSeconds = 0;

  final ValueNotifier<int> _remainingNotifier = ValueNotifier<int>(0);
  final GlobalKey _methodsKey = GlobalKey();
  String? _selectedPaymentType;

  /// Usul tanlanmay "To'lovga o'tish" bosilganda ro'yxat qizil konturlanadi.
  bool _showSelectionError = false;
  bool _idCopied = false;

  List<PaymentTypeEntry> _paymentTypeItems = [];
  bool _paymentTypesLoading = true;

  /// "HUMO / Uzcard" uchun sheet'da tanlangan saqlangan karta — to'lov URL'i
  /// kelgach unga `card_token` qo'shiladi. `null` — oddiy (qo'lda) to'lov.
  MySafarUzsCard? _pendingSavedCard;

  /// Host'dan `card_token` kutilmoqda — tugma yuklanish holatida turadi.
  bool _preparingCardToken = false;
  bool _savedCardsSheetOpen = false;

  /// Host `card_token` qaytarishi uchun maksimal kutish.
  static const Duration _cardTokenTimeout = Duration(seconds: 20);

  /// To'lov sahifasi bosqichi — `idle` dan boshqasida to'lov tugmasi o'chadi
  /// va vaqt tugashi foydalanuvchini sahifadan chiqarib yubormaydi.
  _PaymentPhase _phase = _PaymentPhase.idle;

  /// Oxirgi `ticket-data` javobi (narx o'zgarishi, chipta PDF'i uchun).
  BookingPaymentStatus? _ticketData;

  /// `transaction_paid` / revenue faqat bir marta yuboriladi.
  bool _paidTracked = false;

  /// Pastki panelda bron valyutasi belgisini ko'rsatish uchun.
  _BookingCurrencyProvider? _currencyOverride;

  bool get _paymentBusy => _phase != _PaymentPhase.idle;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    // Widget to'liq mount bo'lgandan keyin (birinchi frame'dan so'ng) chaqiramiz.
    // Bu context.locale kabi InheritedWidget'larga xavfsiz murojaat qilish imkonini beradi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPaymentTypes();
    });
  }

  /// To'lov turlarini Firebase'dan (Hive keshi orqali) yuklaydi.
  ///
  /// Rasm/logotip 100% LOKAL qoladi (`PaymentConstants.paymentTypeByName`) —
  /// Firestore'dan faqat matn/holat (isActive, cardName) keladi. Har bir turni
  /// statik rasmga bog'laydi; rasm topilmagan (noma'lum) turlar chiqarilmaydi.
  ///
  /// Oqim: kesh bo'lsa darhol ko'rsatamiz → Firestore'dan yangilaymiz. Firestore
  /// ham, kesh ham bo'sh bo'lsa — zaxira faol turlar (fallbackActiveNames).
  Future<void> _loadPaymentTypes() async {
    final repo = PaymentTypeRepository();

    // 1. Keshdagi turlarni darhol ko'rsatamiz (agar bor bo'lsa).
    final cached = repo.cached();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _paymentTypeItems = _buildPaymentEntries(cached);
        _paymentTypesLoading = false;
        _reconcileSelection();
      });
    }

    // 2. Firebase'dan yangilaymiz.
    List<PaymentTypeConfig> configs;
    try {
      configs = await repo.fetch();
    } catch (_) {
      configs = const [];
    }
    if (!mounted) return;

    var entries = _buildPaymentEntries(configs);

    // Firebase bo'sh, lekin keshda ko'rsatilgan turlar bor — keshni saqlaymiz
    // (tanlov kesh ro'yxatiga qarshi qilingani uchun hali ham amal qiladi).
    if (entries.isEmpty && configs.isEmpty && cached.isNotEmpty) {
      return;
    }

    // 3. Firebase natija bermasa (ulanolmadi yoki bo'sh) — ESKI usul: serverdan
    //    `/get-payment-type` orqali olamiz.
    if (entries.isEmpty) {
      entries = await _loadPaymentTypesFromServer();
      if (!mounted) return;
    }

    // 4. U ham bo'lmasa — lokal zaxira faol turlar.
    if (entries.isEmpty) {
      entries = _buildPaymentEntries(
        PaymentConstants.fallbackActiveNames
            .map((name) => PaymentTypeConfig(name: name, isActive: true))
            .toList(),
      );
    }

    setState(() {
      _paymentTypeItems = entries;
      _paymentTypesLoading = false;
      _reconcileSelection();
    });
  }

  /// Eski usul — to'lov turlarini serverdan (`/get-payment-type`) oladi.
  /// Firebase ishlamagan/bo'sh bo'lganda zaxira sifatida ishlatiladi.
  Future<List<PaymentTypeEntry>> _loadPaymentTypesFromServer() async {
    try {
      final response = await BookingService().getPaymentType();
      if (response is NetworkSuccessResponse && response.data is List<Result>) {
        final results = response.data as List<Result>;
        final configs = results
            .map((r) => PaymentTypeConfig(
                  name: (r.name ?? '').toUpperCase(),
                  isActive: r.isActive ?? false,
                ))
            .toList();
        return _buildPaymentEntries(configs);
      }
    } catch (_) {
      // jim — chaqiruvchi keyingi zaxiraga o'tadi
    }
    return const [];
  }

  /// Ro'yxat yangilangach tanlovni tekshiradi — tanlangan tur endi faol emas
  /// yoki umuman yo'q bo'lsa, tanlovni bekor qiladi (o'chirilgan turni to'lashning
  /// oldini oladi). Faqat bitta faol tur bo'lsa — uni avtomatik tanlaydi.
  /// setState ichida chaqiriladi.
  void _reconcileSelection() {
    if (!_isSelectionActive()) {
      _selectedPaymentType = null;
    }
    final active = _paymentTypeItems.where((e) => e.isActive).toList();
    if (_selectedPaymentType == null && active.length == 1) {
      _selectedPaymentType = active.first.type.id;
    }
  }

  /// Tanlangan to'lov turi ro'yxatda mavjud VA faolmi.
  bool _isSelectionActive() {
    final sel = _selectedPaymentType;
    if (sel == null) return false;
    return _paymentTypeItems.any((e) => e.type.id == sel && e.isActive);
  }

  /// Firestore/kesh config'larini lokal rasm/nom bilan birlashtiradi.
  /// `imagePath`/`secondaryImagePath` — har doim lokal asset; `isActive` va
  /// (bo'lsa) `cardName` — Firebase'dan.
  List<PaymentTypeEntry> _buildPaymentEntries(List<PaymentTypeConfig> configs) {
    final lang = context.locale.languageCode;
    final items = <PaymentTypeEntry>[];
    for (final c in configs) {
      // Faqat faol (`isActive: true`) turlarni ko'rsatamiz.
      // Admin panelda o'chirilgan turlar UI'da umuman ko'rinmaydi.
      if (!c.isActive) continue;

      final base = PaymentConstants.paymentTypeByName(c.name);
      // Firebase rasm faqat ilovada lokal logosi yo'q yangi turlar uchun (mobile-home).
      final hasNetworkImage = base == null && c.imageUrl.trim().isNotEmpty;
      // Na Firebase rasm, na lokal asset bo'lsa — ko'rsatib bo'lmaydi.
      if (base == null && !hasNetworkImage) continue;
      // Yorliq — joriy tilga mos; bo'sh bo'lsa lokal (hardcoded) yorliqqa qaytadi.
      final label = c.cardNameFor(lang);
      final type = PaymentType(
        id: (base?.id ?? c.name).trim().toUpperCase(),
        imagePath: base?.imagePath ?? '',
        // Firebase rasm bo'lsa ikkilamchi (UzCard+Humo) logotip ko'rsatilmaydi.
        secondaryImagePath: hasNetworkImage ? null : base?.secondaryImagePath,
        cardName: label.isNotEmpty ? label : base?.cardName,
        subtitle: base?.subtitle,
        // Firebase rasm bo'lsa — uni, aks holda lokal asset ishlatiladi.
        imageUrl: hasNetworkImage ? c.imageUrl.trim() : null,
      );
      items.add(PaymentTypeEntry(type: type, isActive: c.isActive));
    }
    return items;
  }

  void _initializeCountdown() {
    _remainingSeconds = ElementFormatter().bookingExpireRemainingSeconds(
      widget.bookingCreateModel.createdAt ?? '',
    );
    _remainingNotifier.value = _remainingSeconds;

    if (_remainingSeconds > 0) {
      _startCountdown();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onTimeExpired());
    }
  }

  void _startCountdown() {
    final createdTime = PaymentHelper.parseCreatedAt(
      widget.bookingCreateModel.createdAt,
    );
    if (createdTime == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final diff = now.difference(createdTime);
      final remaining =
          PaymentConstants.paymentTimeLimitSeconds - diff.inSeconds;
      final clamped = remaining > 0 ? remaining : 0;

      final wasActive = _remainingSeconds > 0;
      _remainingSeconds = clamped;
      // Faqat ko'rsatkich uchun: butun daraxtni qayta chizmaydi.
      _remainingNotifier.value = clamped;

      // Faqat 0 chegarasidan o'tilganda butun sahifani yangilash kerak
      // (davom etish tugmasi o'chadi).
      if (wasActive && clamped <= 0) {
        setState(() {});
        _onTimeExpired();
      }

      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  /// To'lov vaqti tugadi: sahifada qotib qolmasdan, qisqa pauzadan so'ng
  /// chiptalar sahifasiga qaytib xuddi shu yo'nalish bo'yicha qayta qidiramiz.
  ///
  /// Sahifa hozir ko'rinmayotgan bo'lsa (masalan to'lov WebView'i yoki dialog
  /// ochiq) — foydalanuvchini to'lov o'rtasida uzib qo'ymaymiz; sahifaga
  /// qaytgach ishlaydi.
  void _onTimeExpired() {
    if (!mounted || _leavingAfterExpiry) return;
    // To'lov sahifasi ochiq, to'lov tekshirilmoqda yoki to'langan —
    // chiqarib yubormaymiz. "To'lanmagan" natijasidan so'ng qayta chaqiriladi.
    if (_paymentBusy) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      _expiryTimer?.cancel();
      _expiryTimer = Timer(const Duration(milliseconds: 500), _onTimeExpired);
      return;
    }
    setState(() => _leavingAfterExpiry = true);
    _expiryTimer?.cancel();
    _expiryTimer = Timer(_expiryLeaveDelay, _leaveAfterExpiry);
  }

  void _leaveAfterExpiry() {
    if (!mounted || _paymentBusy) return;
    final route = ModalRoute.of(context);
    // Kutish paytida dialog ochilgan bo'lsa — yopilishini kutamiz.
    if (route == null || !route.isCurrent) {
      _expiryTimer =
          Timer(const Duration(milliseconds: 500), _leaveAfterExpiry);
      return;
    }
    // Bron yaratilgan edi — buyurtmalar keshi eskirdi.
    ConfirmedTicketsCubit.clearCache();
    final returned = RecommendationsTicketPage.returnAndSearchAgain(
      context,
      message: 'payment_expired_toast'.tr(),
    );
    // Chiptalar sahifasi stack'da yo'q (masalan buyurtmalardan to'lovga
    // kelingan) — bosh sahifaga qaytamiz.
    if (!returned) PaymentHelper.navigateToHome(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _expiryTimer?.cancel();
    _copyResetTimer?.cancel();
    _remainingNotifier.dispose();
    _currencyOverride?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema almashganda (Sozlamalar / `b`) butun sahifa qayta chiziladi.
    context.themeWatcher;
    return BlocProvider(
      create: (_) => BookingConfirmCubit(
        widget.bookingCreateModel.billingId ?? '',
      ),
      child: BlocConsumer<BookingConfirmCubit, BookingConfirmStates>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBack(context);
            },
            child: EdgeSwipeBack(
              onBack: () => _handleBack(context),
              // Tashqi SafeArea yo'q: status bar ostini ham Scaffold foni
              // to'ldiradi (AppBar tepa, NextButtonWidget pastki insetni oladi).
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: _buildAppBar(context),
                body: _buildBody(context, state),
                bottomNavigationBar: _buildBottomButton(context, state),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ortga qaytish — back tugmasi, system back va chetdan swipe uchun bir
  /// xil: avval chiqishni tasdiqlash dialogi, tasdiqlansa bosh sahifaga.
  Future<void> _handleBack(BuildContext context) async {
    // To'langan yoki to'lov tekshirilayotgan bo'lsa "to'lovdan chiqish"
    // ogohlantirishi ma'nosiz — chipta "Buyurtmalar"da chiqadi.
    if (_paymentBusy) {
      PaymentHelper.navigateToHome(context);
      return;
    }
    final shouldExit = await _showExitConfirmDialog(context);
    if (shouldExit && context.mounted) {
      PaymentHelper.navigateToHome(context);
    }
  }

  Future<bool> _showExitConfirmDialog(BuildContext context) async {
    if (!context.mounted) return false;
    final isExpired = _remainingSeconds <= 0;
    final result = await showSdkAlert<bool>(
      context: context,
      icon: Assets.iconsDialogHourglassIcon,
      tone: SdkDialogTone.warning,
      barrierDismissible: false,
      title: 'exit_payment_title'.tr(),
      message: 'exit_payment_message'.tr(
        namedArgs: {
          'time': isExpired
              ? 'payment_time_expired'.tr()
              : PaymentHelper.formatDuration(_remainingSeconds),
        },
      ),
      actions: [
        SdkDialogAction(label: 'exit_payment_continue'.tr(), value: false),
        SdkDialogAction(
          label: 'exit_payment_exit'.tr(),
          value: true,
          variant: SdkDialogButtonVariant.dangerSoft,
        ),
      ],
    );
    return result ?? false;
  }

  void _handleStateChanges(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmSuccessState) {
      _handlePaymentSuccess(context, state);
    } else if (state is BookingConfirmErrorState) {
      _pendingSavedCard = null;
      AnalyticsService().trackPaymentFailed(
        trId: widget.bookingCreateModel.trId ?? '',
        billingId: widget.bookingCreateModel.billingId ?? '',
        errorMessage: state.error,
        paymentMethod: _selectedPaymentType,
      );
      ResponseState.errorState(state.error, context);
    } else if (state is BookingConfirmChangeAmountSuccessState) {
      setState(() =>
          _ticketData = BookingPaymentStatus.fromTicketData(state.data));
      _handlePriceChange(context, state);
    } else if (state is BookingConfirmPaymentCheckingState) {
      setState(() => _phase = _PaymentPhase.checking);
    } else if (state is BookingConfirmPaidState) {
      _onPaid(context, state);
    } else if (state is BookingConfirmNotPaidState) {
      _onNotPaid(context, state.status);
    } else if (state is BookingConfirmPaymentPendingState) {
      _onPaymentPending(context, state.status);
    }
  }

  Future<void> _handlePaymentSuccess(
      BuildContext context, BookingConfirmSuccessState state) async {
    final data = state.data;
    final type = (_selectedPaymentType ?? '').toUpperCase();
    final savedCard = _pendingSavedCard;
    _pendingSavedCard = null;

    final String urlKey;
    switch (type) {
      case PaymentConstants.paygine: // PAYGINE — QR sahifasi
        urlKey = 'paygine_qr_url';
        break;
      case PaymentConstants.visa: // VISA — ecom sahifasi
        urlKey = 'visa_ecom';
        break;
      default:
        urlKey = 'payment_url';
    }
    final rawUrl = data[urlKey];
    String? url = rawUrl is String && rawUrl.trim().isNotEmpty ? rawUrl : null;

    if (WebViewDebug.enabled) {
      WebViewDebug.log('== confirm javobi: type=$type '
          'keys=${data.keys.toList()} tr_id=${widget.bookingCreateModel.trId}');
      for (final key in const ['payment_url', 'visa_ecom', 'paygine_qr_url']) {
        if (data.containsKey(key)) {
          WebViewDebug.log('   $key (${data[key].runtimeType}): ${data[key]}');
        }
      }
      WebViewDebug.log('   tanlangan url: $url');
    }
    if (url == null) {
      _onPaymentUrlMissing(context, type, urlKey);
      return;
    }
    if (type == PaymentConstants.mysafarpay && savedCard != null) {
      url = await _withCardToken(url, savedCard);
      if (!context.mounted) return;
    }
    await _openPaymentPage(context, url);
  }

  /// Server kutilgan to'lov havolasini qaytarmadi — jim qolmasdan xato
  /// ko'rsatamiz (buyurtma ID'si nusxalanadi) va analitikaga yozamiz.
  void _onPaymentUrlMissing(BuildContext context, String type, String urlKey) {
    final billingId = widget.bookingCreateModel.billingId ?? '';
    AnalyticsService().trackPaymentFailed(
      trId: widget.bookingCreateModel.trId ?? '',
      billingId: billingId,
      errorMessage: 'payment_url_missing: $urlKey',
      paymentMethod: type,
    );
    ResponseState.errorState(
      'payment_url_missing'.tr(),
      context,
      copyableId: billingId,
    );
  }

  /// To'lov sahifasini ochib, yopilishini kutadi — so'ng (to'lagan-
  /// to'lamaganidan qat'i nazar) to'lov holati tekshiriladi.
  Future<void> _openPaymentPage(BuildContext context, String url) async {
    final cubit = context.read<BookingConfirmCubit>();
    setState(() => _phase = _PaymentPhase.inWebView);
    await PaymentHelper.openInWebView(context, url);
    if (!mounted) return;
    _checkPayment(cubit);
  }

  /// To'lov holatini `ticket-data` orqali (qayta) tekshiradi.
  void _checkPayment(BookingConfirmCubit cubit) {
    // Sahifa ochilgandagi tekshiruv allaqachon "to'langan" degan bo'lishi mumkin.
    if (!mounted || _phase == _PaymentPhase.paid) return;
    final billingId = widget.bookingCreateModel.billingId ?? '';
    if (billingId.isEmpty) {
      // Tekshirib bo'lmaydi — avvalgidek to'lash imkoniyatiga qaytamiz.
      setState(() => _phase = _PaymentPhase.idle);
      if (_remainingSeconds <= 0) _onTimeExpired();
      return;
    }
    setState(() => _phase = _PaymentPhase.checking);
    cubit.checkPaymentStatus(billingId: billingId);
  }

  /// To'lov tasdiqlandi: taymer to'xtaydi ("vaqt tugadi" endi chiqmaydi),
  /// to'lov tugmasi o'rniga chipta / "Buyurtmalar"ga o'tish.
  void _onPaid(BuildContext context, BookingConfirmPaidState state) {
    _timer?.cancel();
    _expiryTimer?.cancel();
    setState(() {
      _phase = _PaymentPhase.paid;
      _ticketData = state.status;
      _leavingAfterExpiry = false;
    });
    // Buyurtmalar ro'yxati eskirdi — keyingi ochilishda qayta yuklanadi.
    ConfirmedTicketsCubit.clearCache();
    if (!state.isNew) return;
    _trackPaid(state.status);
    HapticFeedback.lightImpact();
    _showPaidDialog(context);
  }

  /// `transaction_paid` + revenue (`BookingService.confirmPayment` bilan bir
  /// xil event'lar) — bir marta. Summa: bron summasi va valyutasi;
  /// noma'lum bo'lsa (buyurtmalardan kelinganda) sahifaga berilgan UZS narxi.
  void _trackPaid(BookingPaymentStatus status) {
    if (_paidTracked) return;
    _paidTracked = true;
    final booking = widget.bookingCreateModel;
    final display = _displayAmount();
    final num? amount = display?.amount ?? _toDouble(widget.price?.uzs?.amount);
    final String currency = display?.currency ?? 'UZS';
    final billingId = (booking.billingId ?? '').isNotEmpty
        ? booking.billingId
        : status.billingNumber;
    final analytics = AnalyticsService();
    if (billingId != null && billingId.isNotEmpty) {
      analytics.trackTransactionPaid(
        trId: booking.trId ?? '',
        billingNumber: billingId,
        amount: amount != null && amount > 0 ? amount : null,
        currency: amount != null && amount > 0 ? currency : null,
      );
    }
    if (amount != null && amount > 0) {
      analytics.trackRevenue(
        amount: amount,
        currency: currency,
        orderId: billingId,
      );
    }
  }

  Future<void> _showPaidDialog(BuildContext context) async {
    final hasTicket = _paidTicketArgs != null;
    final go = await showSdkAlert<bool>(
      context: context,
      icon: Assets.iconsDialogSuccessIcon,
      tone: SdkDialogTone.success,
      title: 'payment_success'.tr(),
      message: 'payment_paid_hint'.tr(),
      actions: [
        SdkDialogAction(
          label: hasTicket ? 'download_e_ticket'.tr() : 'go_to_my_orders'.tr(),
          value: true,
        ),
        SdkDialogAction(
          label: 'close'.tr(),
          value: false,
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
    if (go == true && context.mounted) _openPaidResult(context);
  }

  /// Chipta PDF'i tayyor bo'lsa — `TicketPdfPage` argumentlari.
  Map<String, dynamic>? get _paidTicketArgs {
    final status = _ticketData;
    if (status == null || (status.ticketReceiptUrl ?? '').isEmpty) return null;
    return status.ticketPdfArguments;
  }

  /// To'langandan keyingi yo'l: chipta tayyor bo'lsa — PDF sahifasi, aks
  /// holda "Buyurtmalar" (chipta berilgach shu yerda chiqadi).
  void _openPaidResult(BuildContext context) {
    final args = _paidTicketArgs;
    if (args != null) {
      Navigator.pushNamed(context, TicketPdfPage.routeName, arguments: args);
    } else {
      PaymentHelper.navigateToOrders(context);
    }
  }

  /// To'lanmagan / bekor qilingan: vaqt qolgan bo'lsa qayta to'lash mumkin.
  void _onNotPaid(BuildContext context, BookingPaymentStatus? status) {
    setState(() {
      _phase = _PaymentPhase.idle;
      if (status != null) _ticketData = status;
    });
    AnalyticsService().trackPaymentFailed(
      trId: widget.bookingCreateModel.trId ?? '',
      billingId: widget.bookingCreateModel.billingId ?? '',
      errorMessage: 'not_paid: ${status?.sign ?? 'unknown'}',
      paymentMethod: _selectedPaymentType,
    );
    if (_remainingSeconds <= 0) {
      // Tekshiruv paytida vaqt tugagan — odatiy "vaqt tugadi" oqimi.
      _onTimeExpired();
      return;
    }
    ProjectDialogs.showCustomToast(
      context,
      'payment_not_completed'.tr(),
      type: AppMessageType.warning,
    );
  }

  /// ~1 daqiqada tasdiq kelmadi: to'lov o'chiq qoladi (ikki marta to'lamasin),
  /// "Qayta tekshirish" va "Buyurtmalar" taklif qilinadi.
  Future<void> _onPaymentPending(
      BuildContext context, BookingPaymentStatus? status) async {
    setState(() {
      _phase = _PaymentPhase.pending;
      if (status != null) _ticketData = status;
    });
    final cubit = context.read<BookingConfirmCubit>();
    final checkAgain = await showSdkAlert<bool>(
      context: context,
      icon: Assets.iconsDialogHourglassIcon,
      tone: SdkDialogTone.warning,
      title: 'payment_pending_title'.tr(),
      message: 'payment_pending_message'.tr(),
      actions: [
        SdkDialogAction(label: 'payment_check_again'.tr(), value: true),
        SdkDialogAction(
          label: 'go_to_my_orders'.tr(),
          value: false,
          variant: SdkDialogButtonVariant.secondary,
        ),
      ],
    );
    if (checkAgain == null || !mounted || !context.mounted) return;
    if (checkAgain) {
      _checkPayment(cubit);
    } else {
      PaymentHelper.navigateToOrders(context);
    }
  }

  /// Saqlangan karta bilan to'lov — "Unired → MySafar card_token" hujjati
  /// bo'yicha: karta raqami, muddati, `tr_id` va `iat` AES-256-GCM bilan
  /// shifrlanib, to'lov URL'iga `card_token` qo'shiladi (sahifa kartani o'zi
  /// to'ldirib, SMS bosqichiga o'tadi).
  ///
  /// Token manbai: `callbacks.onCreateCardToken` (server) bo'lsa — u, aks
  /// holda `config.cardTokenSecret` bilan SDK o'zi shifrlaydi. Token
  /// yaratilmasa — asl URL (karta qo'lda kiritiladi, to'lov to'xtamaydi).
  Future<String> _withCardToken(String url, MySafarUzsCard card) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Token faqat https orqali uzatiladi (hujjat, 6-bo'lim).
    if (uri.scheme != 'https') {
      _debugCardToken(
          'skip', 'to\'lov URL https emas — card_token qo\'shilmaydi');
      _debugCardToken('url', url);
      return url;
    }

    // Token ichidagi tr_id URL'dagi `trid` bilan aynan bir xil bo'lishi shart.
    final trId = uri.queryParameters['trid'] ?? widget.bookingCreateModel.trId;
    if (trId == null || trId.isEmpty) {
      _debugCardToken('skip', 'trid topilmadi — card_token qo\'shilmaydi');
      return url;
    }
    final billingId = uri.queryParameters['billing_id'] ??
        widget.bookingCreateModel.billingId ??
        '';

    final token = (await _createCardToken(card, trId, billingId))?.trim();
    if (token == null || token.isEmpty) {
      _debugCardToken('token', '(yo\'q) — oddiy URL ochiladi');
      _debugCardToken('url', url);
      if (mounted) {
        ProjectDialogs.showCustomToast(
          context,
          'saved_card_token_failed'.tr(),
          type: AppMessageType.warning,
        );
      }
      return url;
    }
    final result = uri.replace(queryParameters: {
      ...uri.queryParametersAll,
      'card_token': token,
    }).toString();
    _debugCardToken('token', token);
    _debugCardToken('url', result);
    return result;
  }

  Future<String?> _createCardToken(
    MySafarUzsCard card,
    String trId,
    String billingId,
  ) async {
    final provider = MySafarSdk.callbacks.onCreateCardToken;
    if (provider != null) {
      _debugCardToken(
        'payload (host callback)',
        jsonEncode({
          'card_number': card.cardNumberDigits,
          'expire': card.expire,
          'tr_id': trId,
          'billing_id': billingId,
        }),
      );
      return _requestCardToken(
        provider,
        MySafarCardTokenRequest(card: card, trId: trId, billingId: billingId),
      );
    }

    final secret = MySafarSdk.config.cardTokenSecret;
    if (!CardTokenEncoder.isValidKey(secret)) {
      debugPrint(
          'MySafarSdk: config.cardTokenSecret (64 belgili hex) berilmagan '
          '— card_token yaratilmaydi.');
      return null;
    }
    final payload = CardTokenEncoder.payload(
      cardNumber: card.cardNumberDigits,
      expire: card.expire,
      trId: trId,
      issuedAt: DateTime.now(),
    );
    _debugCardToken('payload', jsonEncode(payload));
    try {
      return CardTokenEncoder(secret!).encrypt(payload);
    } catch (e) {
      debugPrint('MySafarSdk: card_token shifrlanmadi (${e.runtimeType})');
      return null;
    }
  }

  /// Faqat debug build'da: `card_token` uchun yig'ilgan ma'lumot va yakuniy
  /// to'lov URL'ini konsolga chiqaradi (release'da hech narsa yozilmaydi —
  /// karta raqami log'ga tushmasin).
  void _debugCardToken(String label, String value) {
    if (!kDebugMode) return;
    debugPrint('[MySafar card_token] $label: $value', wrapWidth: 1024);
  }

  Future<String?> _requestCardToken(
    Future<String?> Function(MySafarCardTokenRequest) provider,
    MySafarCardTokenRequest request,
  ) async {
    setState(() => _preparingCardToken = true);
    String? token;
    try {
      token = await provider(request).timeout(_cardTokenTimeout);
    } catch (e) {
      // Karta ma'lumotlari/token log'ga chiqmaydi — faqat xato turi.
      debugPrint('MySafarSdk: card_token olinmadi (${e.runtimeType})');
    }
    if (mounted) setState(() => _preparingCardToken = false);
    return token;
  }

  void _handlePriceChange(
      BuildContext context, BookingConfirmChangeAmountSuccessState state) {
    final bookData = state.data['data']?['book'];
    if (bookData == null) return;

    final isPriceChanged = bookData['is_search_price_changed'] == true ||
        bookData['is_price_changed'] == true;

    if (!isPriceChanged) return;

    // Qiymatlar backenddan dynamic (null, son yoki matn) bo'lib kelishi mumkin.
    // double.parse to'g'ridan-to'g'ri ishlatilsa, mas. null qiymatda
    // "Invalid double" (FormatException) beradi. Xavfsiz konvertatsiya qilamiz.
    final newPrice = _toDouble(
        bookData['agent_mode_prices']?['total_amount_for_active_agent_mode']);
    if (newPrice == null) return;

    // Eski narx aniqlanmasa (mas. amount null), yangi narxga tayanamiz — shunda
    // dialog xato ravishda "0 dan" katta farqni ko'rsatib qo'ymaydi.
    final oldPrice = _toDouble(widget.bookingCreateModel.amount) ?? newPrice;

    // Backend bayrog'i (is_price_changed) yoqilgan bo'lsa-da, haqiqiy summa
    // o'zgarmagan bo'lishi mumkin. Bunday holda "X dan X ga o'zgardi" degan
    // chalg'ituvchi dialogni ko'rsatmaymiz.
    if ((oldPrice - newPrice).abs() < 0.5) return;

    ProjectDialogs.changeAmountPrice(context, oldPrice, newPrice);
  }

  /// Backenddan keladigan dynamic qiymatni (null, num yoki matn) xavfsiz
  /// double'ga o'giradi; imkonsiz bo'lsa null qaytaradi.
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // Tema status bar'ni oq/qora bo'yaydi — sahifa fonidan farq qilmasin.
      systemOverlayStyle: (context.isDarkMode
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      leading: IconButton(
        onPressed: () => _handleBack(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
      ),
      title: Text(
        'ticket_payment'.tr(),
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingConfirmStates state) {
    // Taymer tepaga qadalgan — usul tanlash paytida ham doim ko'rinadi.
    // Qolgani: asosiy amal (to'lov usuli), so'ng yordamchi ma'lumot.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          // To'lov sahifasi yopilgach taymer o'rnida to'lov holati.
          child: switch (_phase) {
            _PaymentPhase.idle => PaymentCountdownCard(
                remaining: _remainingNotifier,
                researching: _leavingAfterExpiry,
              ),
            _PaymentPhase.inWebView || _PaymentPhase.checking =>
              const PaymentStatusCard(kind: PaymentStatusKind.checking),
            _PaymentPhase.pending =>
              const PaymentStatusCard(kind: PaymentStatusKind.pending),
            _PaymentPhase.paid =>
              const PaymentStatusCard(kind: PaymentStatusKind.paid),
          },
        ),
        Expanded(child: _buildScrollableContent(context)),
      ],
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle('select_payment_method'.tr()),
          KeyedSubtree(
            key: _methodsKey,
            // Vaqt tugagach usul tanlashning ma'nosi yo'q — ro'yxat xiralashadi.
            child: _PaymentMethodsLock(
              locked: _remainingSeconds <= 0 || _paymentBusy,
              child: PaymentMethodList(
                items: _paymentTypeItems,
                isLoading: _paymentTypesLoading,
                selectedType: _selectedPaymentType,
                hasError: _showSelectionError,
                onTypeSelected: (type) {
                  setState(() {
                    _selectedPaymentType = type;
                    _showSelectionError = false;
                  });
                  // HUMO / Uzcard + host kartalari bor — darhol kartani so'raymiz.
                  if (type == PaymentConstants.mysafarpay &&
                      _canUseSavedCards) {
                    _openSavedCardsSheet(context);
                  }
                },
              ),
            ),
          ),
          BookingFieldError(
            text: _showSelectionError ? 'select_payment_type'.tr() : null,
          ),
          const SizedBox(height: 20),
          _buildBillingIdInfo(context),
          const SizedBox(height: 12),
          const SupportWidget(),
        ],
      ),
    );
  }

  /// Buyurtma ID — nusxalash tugmasi bilan, ostida to'lovda muammo bo'lsa
  /// nima qilish bo'yicha qisqa yo'riqnoma. Foydalanuvchi ushbu ID orqali
  /// keyinroq «Xizmatlar» bo'limidan qayta to'lov qilishi mumkin.
  Widget _buildBillingIdInfo(BuildContext context) {
    final billingId = widget.bookingCreateModel.billingId ?? '';
    if (billingId.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDarkMode;
    final brand = ProjectTheme.brandColor;
    final muted = BookingFormStyle.label(context);
    final accent = isDark ? Colors.white : brand;
    final tileColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : brand.withValues(alpha: 0.08);

    return BookingCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _copyBillingId(billingId),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius:
                          BorderRadius.circular(BookingFormStyle.radius),
                    ),
                    child: SvgPicture.asset(
                      Assets.iconsOrderTicketIcon,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'payment_order_id'.tr(),
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          billingId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey(_idCopied),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _idCopied
                            ? ProjectTheme.success.withValues(alpha: 0.12)
                            : tileColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _idCopied
                              ? SvgPicture.asset(
                                  Assets.iconsBookingDoneIcon,
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                      ProjectTheme.success, BlendMode.srcIn),
                                )
                              : SvgPicture.asset(
                                  Assets.iconsOrderCopyIcon,
                                  width: 16,
                                  height: 16,
                                  colorFilter:
                                      ColorFilter.mode(accent, BlendMode.srcIn),
                                ),
                          const SizedBox(width: 6),
                          Text(
                            _idCopied ? 'id_copied'.tr() : 'copy'.tr(),
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _idCopied ? ProjectTheme.success : accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 14,
            endIndent: 14,
            color: context.color.outline.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SvgPicture.asset(
                    Assets.iconsBookingInfoIcon,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(muted, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'payment_id_help'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyBillingId(String billingId) async {
    await Clipboard.setData(ClipboardData(text: billingId));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _idCopied = true);
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _idCopied = false);
    });
  }

  Widget _buildBottomButton(BuildContext context, BookingConfirmStates state) {
    final display = _displayPrice();
    final Widget button;
    switch (_phase) {
      case _PaymentPhase.paid:
        final hasTicket = _paidTicketArgs != null;
        button = NextButtonWidget(
          nextTittle: hasTicket ? 'download_e_ticket_short' : 'go_to_my_orders',
          analyticsId:
              hasTicket ? 'booking_paid_ticket' : 'booking_paid_orders',
          isLoading: false,
          passenger: widget.passengerNumber,
          price: display.price,
          showButton: true,
          onPressed: () => _openPaidResult(context),
        );
      case _PaymentPhase.pending:
        button = NextButtonWidget(
          nextTittle: 'payment_check_again',
          analyticsId: 'booking_payment_recheck',
          isLoading: false,
          passenger: widget.passengerNumber,
          price: display.price,
          showButton: true,
          onPressed: () => _checkPayment(context.read<BookingConfirmCubit>()),
        );
      case _PaymentPhase.idle:
      case _PaymentPhase.inWebView:
      case _PaymentPhase.checking:
        final checking = _phase != _PaymentPhase.idle;
        final isLoading = state is BookingConfirmLoadingState ||
            _preparingCardToken ||
            checking;
        // Tugma faqat vaqt tugaganda o'chadi. To'lov usuli tanlanmagan bo'lsa
        // bosilganda sababini ko'rsatamiz (jim o'chirilgan tugma o'rniga).
        final canProceed =
            _remainingSeconds > 0 && !_paymentTypesLoading && !checking;
        button = NextButtonWidget(
          nextTittle: 'proceed_to_payment',
          analyticsId: 'booking_confirm_continue',
          isLoading: isLoading,
          passenger: widget.passengerNumber,
          price: display.price,
          showButton: true,
          // Tekshiruv paytida tugma baribir bosilmaydi (yuklanish holati) —
          // `null` berilsa spinner xira fonda ko'rinmay qoladi.
          onPressed: canProceed
              ? () => _onPaymentPressed(context, state)
              : (checking ? () {} : null),
        );
    }
    return _withBookingCurrency(display.currency, button);
  }

  BookingDisplayAmount? _displayAmount() => BookingDisplayAmount.resolve(
        bookingAmount: widget.bookingCreateModel.amount,
        bookingCurrency: widget.bookingCreateModel.currencyLabel,
        ticketData: _ticketData,
      );

  /// Pastki paneldagi summa: bron summasi va valyutasi (qidiruv narxi emas —
  /// narx oshgan bo'lishi mumkin), qarang [BookingDisplayAmount.resolve].
  /// Aniqlanmasa — sahifaga berilgan narx (masalan buyurtmalardan kelinganda).
  ({FlightPrice? price, String? currency}) _displayPrice() {
    final resolved = _displayAmount();
    if (resolved == null) {
      return (price: _formatPrice(widget.price), currency: null);
    }
    // `FluffyRub/FluffyUzs.amount` — String?; int berilsa
    // "int is not a subtype of type 'String?'" runtime xatosi chiqadi,
    // shuning uchun har uchala valyutaga ham matn beramiz.
    final amountStr = _formatAmount(resolved.amount.toString());
    return (
      price: FlightPrice(
        rub: FluffyRub(amount: amountStr),
        uzs: FluffyUzs(amount: amountStr),
        usd: FluffyRub(amount: amountStr),
      ),
      currency: resolved.currency,
    );
  }

  /// [NextButtonWidget] summani foydalanuvchi tanlagan valyuta belgisi bilan
  /// chiqaradi, bron esa boshqa valyutada bo'lishi mumkin (USD tanlanganda
  /// backend RUB'da bron qiladi) — tugma uchun belgini bron valyutasiga
  /// almashtiramiz.
  Widget _withBookingCurrency(String? currency, Widget child) {
    if (currency == null) return child;
    var provider = _currencyOverride;
    if (provider == null || provider.label != currency) {
      final old = provider;
      provider = _currencyOverride = _BookingCurrencyProvider(currency);
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    }
    return ChangeNotifierProvider<CurrencyProvider>.value(
      value: provider,
      child: child,
    );
  }

  /// Pastki paneldagi summa uchun nusxa: `4870000` → `4 870 000`.
  /// Asl [FlightPrice] obyektiga tegmaydi (u boshqa sahifalar bilan umumiy).
  FlightPrice? _formatPrice(FlightPrice? price) {
    if (price == null) return null;
    return FlightPrice(
      rub: price.rub == null
          ? null
          : FluffyRub(amount: _formatAmount(price.rub!.amount)),
      uzs: price.uzs == null
          ? null
          : FluffyUzs(amount: _formatAmount(price.uzs!.amount)),
      usd: price.usd == null
          ? null
          : FluffyRub(amount: _formatAmount(price.usd!.amount)),
    );
  }

  /// Butun qismni 3 xonadan bo'shliq bilan ajratadi, o'nlik qismni saqlaydi
  /// (`385.50` → `385.5`, `4870000.0` → `4 870 000`). Son bo'lmasa — o'zi.
  String? _formatAmount(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(' ', '');
    if (double.tryParse(cleaned) == null) return raw;
    final parts = cleaned.split('.');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    final decimal =
        parts.length > 1 ? parts[1].replaceFirst(RegExp(r'0+$'), '') : '';
    return decimal.isEmpty ? integer : '$integer.$decimal';
  }

  void _onPaymentPressed(BuildContext context, BookingConfirmStates state) {
    // To'lov sahifasi ochilgan / tekshirilmoqda / to'langan — ikki marta
    // to'lanmasin.
    if (_paymentBusy) return;
    if (!_isSelectionActive()) {
      HapticFeedback.mediumImpact();
      setState(() => _showSelectionError = true);
      final methodsContext = _methodsKey.currentContext;
      if (methodsContext != null) {
        Scrollable.ensureVisible(
          methodsContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
      }
      return;
    }

    if (state is BookingConfirmLoadingState || _preparingCardToken) return;

    // HUMO / Uzcard + host kartalari — avval kartani tanlatamiz (sheet'dagi
    // tanlov to'lovni o'zi boshlaydi).
    if (_selectedPaymentType == PaymentConstants.mysafarpay &&
        _canUseSavedCards) {
      _openSavedCardsSheet(context);
      return;
    }

    _submitPayment(context);
  }

  /// Saqlangan kartalar sheet'i: host UZS kartalar bergan bo'lsa.
  /// (`card_token` callback'i berilmagan bo'lsa ham sheet ochiladi — karta
  /// tanlanganda sahifa oddiy rejimda ochiladi.)
  bool get _canUseSavedCards => MySafarSdk.userData.uzsCards.isNotEmpty;

  Future<void> _openSavedCardsSheet(BuildContext context) async {
    if (_savedCardsSheetOpen ||
        _preparingCardToken ||
        _paymentBusy ||
        _remainingSeconds <= 0 ||
        context.read<BookingConfirmCubit>().state
            is BookingConfirmLoadingState) {
      return;
    }
    _savedCardsSheetOpen = true;
    final choice = await showSavedCardsSheet(
      context,
      cards: MySafarSdk.userData.uzsCards,
    );
    _savedCardsSheetOpen = false;
    if (choice == null || !mounted || !context.mounted) return;
    // Sheet ochiq turganda vaqt tugagan yoki boshqa usul tanlangan bo'lishi mumkin.
    if (_remainingSeconds <= 0 ||
        _paymentBusy ||
        _selectedPaymentType != PaymentConstants.mysafarpay) {
      return;
    }

    AnalyticsService().trackButtonTap(
      choice.isOtherCard ? 'payment_other_card' : 'payment_saved_card',
    );
    _pendingSavedCard = choice.card;
    _submitPayment(context);
  }

  void _submitPayment(BuildContext context) {
    if (_paymentBusy ||
        context.read<BookingConfirmCubit>().state
            is BookingConfirmLoadingState) {
      return;
    }
    // Tanlangan tur ID'si allaqachon API nomi (MYSAFARPAY / PAYME / PAYGINE /
    // CLICK / VISA) — uni to'g'ridan-to'g'ri transaction_type sifatida yuboramiz.
    final String transactionType = _selectedPaymentType!.toUpperCase();

    context.read<BookingConfirmCubit>().confirmBooking(
      params: {
        'transaction_type': transactionType,
        'tr_id': widget.bookingCreateModel.trId,
      },
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

class _PaymentMethodsLock extends StatelessWidget {
  const _PaymentMethodsLock({required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: locked,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: locked ? 0.5 : 1,
        child: child,
      ),
    );
  }
}

/// To'lov sahifasi (WebView) bilan bog'liq bosqich.
enum _PaymentPhase {
  /// To'lov boshlanmagan yoki to'lanmagan — to'lash mumkin.
  idle,

  /// To'lov sahifasi ochiq.
  inWebView,

  /// Sahifa yopildi — to'lov holati tekshirilmoqda.
  checking,

  /// Tekshiruv tugadi, lekin to'lov hali tasdiqlanmadi.
  pending,

  /// To'langan.
  paid,
}

/// Faqat [NextButtonWidget] uchun: summa bron valyutasi belgisi bilan.
class _BookingCurrencyProvider extends CurrencyProvider {
  _BookingCurrencyProvider(this.label);

  final String label;

  @override
  String getElementPrice(FlightPrice? price) =>
      '${price?.uzs?.amount ?? ''} $label';
}
