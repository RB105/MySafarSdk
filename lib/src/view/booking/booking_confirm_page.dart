import 'dart:async';
import 'dart:io';

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/cubit/booking/confirm/booking_confirm_states.dart';
import 'package:mysafar_sdk/src/model/local/payment_type.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice, FluffyRub, FluffyUzs;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkSuccessResponse;
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart' show Result;
import 'package:mysafar_sdk/src/model/remote/payment/payment_type_config.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/booking_service.dart';
import 'package:mysafar_sdk/src/service/payment/payment_type_repository.dart';
import 'package:mysafar_sdk/src/view/booking/support/payment_helper.dart';
import 'package:mysafar_sdk/src/view/booking/widget/next_button_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_type_card.dart';


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
  int _remainingSeconds = 0;

  final ValueNotifier<int> _remainingNotifier = ValueNotifier<int>(0);
  String? _selectedPaymentType;


  List<PaymentTypeEntry> _paymentTypeItems = [];
  bool _paymentTypesLoading = true;

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
  /// oldini oladi). setState ichida chaqiriladi.
  void _reconcileSelection() {
    if (!_isSelectionActive()) {
      _selectedPaymentType = null;
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
      final hasNetworkImage = c.imageUrl.trim().isNotEmpty;
      // Na Firebase rasm, na lokal asset bo'lsa — ko'rsatib bo'lmaydi.
      if (base == null && !hasNetworkImage) continue;
      // Yorliq — joriy tilga mos; bo'sh bo'lsa lokal (hardcoded) yorliqqa qaytadi.
      final label = c.cardNameFor(lang);
      final type = PaymentType(
        id: base?.id ?? c.name,
        imagePath: base?.imagePath ?? '',
        // Firebase rasm bo'lsa ikkilamchi (UzCard+Humo) logotip ko'rsatilmaydi.
        secondaryImagePath: hasNetworkImage ? null : base?.secondaryImagePath,
        cardName: label.isNotEmpty ? label : base?.cardName,
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
      final remaining = PaymentConstants.paymentTimeLimitSeconds - diff.inSeconds;
      final clamped = remaining > 0 ? remaining : 0;

      final wasActive = _remainingSeconds > 0;
      _remainingSeconds = clamped;
      // Faqat ko'rsatkich uchun: butun daraxtni qayta chizmaydi.
      _remainingNotifier.value = clamped;

      // Faqat 0 chegarasidan o'tilganda butun sahifani yangilash kerak
      // (davom etish tugmasi o'chadi).
      if (wasActive && clamped <= 0) {
        setState(() {});
      }

      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: SafeArea(
                top: Platform.isAndroid,
                bottom: Platform.isAndroid,
                child: Scaffold(
                  appBar: _buildAppBar(context),
                  body: _buildBody(context, state),
                  bottomNavigationBar: _buildBottomButton(context, state),
                ),
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
    final shouldExit = await _showExitConfirmDialog(context);
    if (shouldExit && context.mounted) {
      PaymentHelper.navigateToHome(context);
    }
  }

  Future<bool> _showExitConfirmDialog(BuildContext context) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(useRootNavigator: false, 
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isExpired = _remainingSeconds <= 0;
        return Dialog(
          backgroundColor: context.color.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'exit_payment_title'.tr(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'exit_payment_message'.tr(
                    namedArgs: {
                      'time': isExpired
                          ? 'payment_time_expired'.tr()
                          : PaymentHelper.formatDuration(_remainingSeconds),
                    },
                  ),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ProjectTheme.brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      'exit_payment_continue'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      'exit_payment_exit'.tr(),
                      style: const TextStyle(
                        color: Color(0xffEF2323),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  void _handleStateChanges(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmSuccessState) {
      _handlePaymentSuccess(context, state);
    } else if (state is BookingConfirmErrorState) {
      AnalyticsService().trackPaymentFailed(
        trId: widget.bookingCreateModel.trId ?? '',
        billingId: widget.bookingCreateModel.billingId ?? '',
        errorMessage: state.error,
        paymentMethod: _selectedPaymentType,
      );
      ResponseState.errorState(state.error, context);
    } else if (state is BookingConfirmChangeAmountSuccessState) {
      _handlePriceChange(context, state);
    }
  }

  void _handlePaymentSuccess(BuildContext context, BookingConfirmSuccessState state) {
    final data = state.data;
    final type = (_selectedPaymentType ?? '').toUpperCase();

    String? url;
    switch (type) {
      case PaymentConstants.paygine: // PAYGINE — QR sahifasi
        url = data['paygine_qr_url'] as String?;
        break;
      case PaymentConstants.visa: // VISA — ecom sahifasi
        url = data['visa_ecom'] as String?;
        break;
      default:
        url = data['payment_url'] as String?;
    }

    if (url != null) PaymentHelper.openInWebView(context, url);
  }

  void _handlePriceChange(BuildContext context, BookingConfirmChangeAmountSuccessState state) {
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
    final isDark = context.themeProvider.isDark;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: context.color.primaryContainer,
      leadingWidth: 56,
      leading: Center(
        child: Material(
          color:
              isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final shouldExit = await _showExitConfirmDialog(context);
              if (shouldExit && context.mounted) {
                PaymentHelper.navigateToHome(context);
              }
            },
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 17),
            ),
          ),
        ),
      ),
      title: Text(
        'ticket_payment'.tr(),
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? const Color(0xff3A3A3A) : const Color(0xffEAEBEE),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingConfirmStates state) {
    // Kichik ekranlarda (yoki to'lov turlari ko'payganda) kontent sig'masligi
    // mumkin — shuning uchun scroll qilinadi. Pastda tugma (bottomNavigationBar)
    // bilan urilmasligi uchun ozroq bo'sh joy qoldiramiz.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeader(context, 'select_payment_method'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaymentTypesGrid(
              items: _paymentTypeItems,
              isLoading: _paymentTypesLoading,
              selectedType: _selectedPaymentType,
              onTypeSelected: (type) {
                setState(() => _selectedPaymentType = type);
              },
            ),
          ),
          context.szBoxHeight24,
          _buildRemainingTime(context),
          context.szBoxHeight16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBillingIdInfo(context),
          ),
          context.szBoxHeight16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOfferAgreement(context),
          ),
        ],
      ),
    );
  }

  /// Oferta roziligi qatori — doim belgilangan (yongan), informativ.
  /// Foydalanuvchi bosishi shart emas: "Xaridni davom ettirish orqali oferta
  /// shartlarini qabul qilgan bo'lasiz". Davom etish tugmasini bloklamaydi.
  Widget _buildOfferAgreement(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: brand.withAlpha(isDark ? 38 : 16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [brand, ProjectTheme.accentLight]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'offer_accept_by_continue'.tr(),
              softWrap: true,
              style: context.textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// To'lov ID'sini nusxalash + to'lovda muammo bo'lsa nima qilish bo'yicha
  /// qisqa yo'riqnoma. Foydalanuvchi ushbu ID orqali keyinroq «Xizmatlar»
  /// bo'limidan qayta to'lov qilishi yoki texnik xizmatga murojaat qilishi mumkin.
  Widget _buildBillingIdInfo(BuildContext context) {
    final billingId = widget.bookingCreateModel.billingId ?? '';
    if (billingId.isEmpty) return const SizedBox.shrink();

    final isDark = context.themeProvider.isDark;
    final muted = isDark ? const Color(0xffCCCFD3) : const Color(0xff8E8E92);
    final brand = ProjectTheme.brandColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'payment_order_id'.tr(),
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      billingId,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: billingId)).then((_) {
                    if (context.mounted) {
                      ProjectDialogs.showCustomToast(
                          context, "id_copied".tr());
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: brand.withAlpha(isDark ? 46 : 25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brand.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: brand),
                      const SizedBox(width: 6),
                      Text(
                        'copy'.tr(),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'payment_id_help'.tr(),
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ProjectTheme.brandColor, ProjectTheme.accentLight],
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
        ],
      ),
    );
  }

  Widget _buildRemainingTime(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final muted = isDark ? const Color(0xffCCCFD3) : const Color(0xff8E8E92);

    // Soniyalik yangilanish faqat shu blokni qayta chizadi.
    return ValueListenableBuilder<int>(
      valueListenable: _remainingNotifier,
      builder: (context, remaining, _) {
        final isExpired = remaining <= 0;
        final low = !isExpired && remaining < 120;
        final color = isExpired
            ? const Color(0xFFD92D20)
            : (low ? const Color(0xFFE2AE12) : ProjectTheme.brandColor);

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 38 : 20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(95)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: color, size: 22),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'payment_time_left'.tr(),
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isExpired
                          ? 'payment_time_expired'.tr()
                          : PaymentHelper.formatDuration(remaining),
                      style: TextStyle(
                        fontFamily: "packages/mysafar_sdk/Gilroy",
                        fontSize: 20,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(BuildContext context, BookingConfirmStates state) {
    final isLoading = state is BookingConfirmLoadingState;
    final canProceed = _isSelectionActive() && _remainingSeconds > 0;

    return NextButtonWidget(
      nextTittle: 'continue_purchase',
      analyticsId: 'booking_confirm_continue',
      isLoading: isLoading,
      passenger: widget.passengerNumber,
      price: _getDisplayPrice(state),
      showButton: true,
      onPressed: canProceed ? () => _onPaymentPressed(context, state) : null,
    );
  }

  FlightPrice? _getDisplayPrice(BookingConfirmStates state) {
    if (state is BookingConfirmChangeAmountSuccessState) {
      final bookData = state.data['data']?['book'];
      if (bookData != null) {
        final isPriceChanged = bookData['is_search_price_changed'] == true ||
            bookData['is_price_changed'] == true;

        if (isPriceChanged) {
          final newPrice = _toDouble(bookData['agent_mode_prices']
              ?['total_amount_for_active_agent_mode']);
          final oldPrice = _toDouble(widget.bookingCreateModel.amount);

          // Faqat summa haqiqatan o'zgargandagina yangi narxni ko'rsatamiz;
          // aks holda to'liq asl narx obyektini (widget.price) qaytaramiz.
          if (newPrice != null &&
              (oldPrice == null || (oldPrice - newPrice).abs() >= 0.5)) {
            // `FluffyRub/FluffyUzs.amount` — String?; int berilsa
            // "int is not a subtype of type 'String?'" runtime xatosi chiqadi,
            // shuning uchun har uchala valyutaga ham matn beramiz.
            final amountStr = newPrice.toStringAsFixed(0);
            return FlightPrice(
              rub: FluffyRub(amount: amountStr),
              uzs: FluffyUzs(amount: amountStr),
              usd: FluffyRub(amount: amountStr),
            );
          }
        }
      }
    }
    return widget.price;
  }

  void _onPaymentPressed(BuildContext context, BookingConfirmStates state) {
    if (!_isSelectionActive()) {
      ProjectDialogs.showCustomToast(context, 'select_payment_type'.tr());
      return;
    }

    if (state is BookingConfirmLoadingState) return;

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
