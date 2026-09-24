// ignore_for_file: unused_element

import 'dart:async' show unawaited;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart' show AppCurrency;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart' show dataLang;
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/core/widgets/ticket_tariffs_widget.dart'
    show TariffPickerWidget;
import 'package:mysafar_sdk/src/cubit/booking/create/booking_gate.dart'
    show BookingGate, FlightValidation;
import 'package:mysafar_sdk/src/cubit/tickets/tariff/ticket_tariff_cubit.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightPrice, FlightSegment, Upgrade;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_information_page.dart';
import 'package:mysafar_sdk/src/view/tickets/flight_route_map_test_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart' show Shimmer;

part 'ticket_info_price.dart';
part 'ticket_info_flight.dart';
part 'ticket_info_actions.dart';

class TicketInfoPage extends StatefulWidget {
  final FlightElement flightElement;

  const TicketInfoPage({
    super.key,
    required this.flightElement,
  });

  static const routeName = '/ticketInfo';

  /// Chipta tafsilotini bottom sheet sifatida ochadi (navigatsiya o‘rniga).
  static Future<T?> show<T>(BuildContext context, FlightElement flight) {
    return showSdkModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => TicketInfoPage(flightElement: flight),
    );
  }

  @override
  State<TicketInfoPage> createState() => _TicketInfoPageState();
}

class _TicketInfoPageState extends State<TicketInfoPage> {
  static const Radius _sheetTopRadius = Radius.circular(20);

  late FlightElement flightElement;

  final AviaService _aviaService = AviaService();
  bool _checking = true;
  String? _checkError;
  bool _checkStarted = false;
  bool _checkErrorDialogOpen = false;

  // Reysni qayta tekshirish (GDS) fonda ketadi — "Bron qilish" tugmasi
  // shu paytda ham bosiladi va yo'lovchi sahifasi DARHOL ochiladi (№36):
  // tugallanmagan tekshiruv ([FlightValidation]) sahifaga beriladi, bron
  // yaratishdan oldin kutiladi (id/token va narx tekshirilgan elementdan).
  // Tekshiruv sheet ochiq turganda xato bersa — tugma o'chadi (dialog).
  FlightValidation? _validation;

  /// Oxirgi boshlangan tekshiruv raqami — eskirgan tekshiruv (masalan tarif
  /// almashgandan keyin kelgan asl reys natijasi) holatni o'zgartirmaydi.
  int _checkSeq = 0;

  /// Foydalanuvchi ko'rgan (va qabul qilgan) narx: kartadagi yoki tarif
  /// oynasida tanlangan tarif narxi. Tekshiruv natijasi shu bilan
  /// solishtiriladi (№60) — allaqachon yangilangan narx bilan emas.
  FlightPrice? _acceptedPrice;

  @override
  void initState() {
    flightElement = widget.flightElement;
    _acceptedPrice = widget.flightElement.price;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkStarted) return;
    _checkStarted = true;
    // Backend faqat uz/ru/en qabul qiladi — kk/tg/tr xom yuborilmasin.
    unawaited(_checkFlight(dataLang()));
  }

  Future<void> _checkFlight(String lang) async {
    final seq = ++_checkSeq;
    final id = flightElement.id;
    if (id.isEmpty) {
      _validation = null;
      if (mounted) setState(() => _checking = false);
      return;
    }

    // So'rov sheet yopilsa ham davom etadi — natijasini yo'lovchi sahifasi
    // kutadi. Qayta urinish ham xuddi shu tilda.
    final request = _aviaService.getFlightInfo(id, lang: lang);
    _validation = FlightValidation.fromResponse(
      id,
      request,
      fetch: (tid) => AviaService().getFlightInfo(tid, lang: lang),
    );

    final response = await request;
    // Tekshiruv paytida boshqa tarif tanlangan bo'lsa — u o'z tekshiruvini
    // boshlagan; bu (eskirgan) natija tanlovni almashtirmaydi.
    if (!mounted || seq != _checkSeq) return;

    NetworkErrorResponse? error;
    FlightElement? validated;
    setState(() {
      _checking = false;
      if (response is NetworkSuccessResponse) {
        _checkError = null;
        validated = response.data as FlightElement;
        flightElement = validated!;
      } else if (response is NetworkErrorResponse) {
        _checkError = response.getError();
        error = response;
      }
    });

    if (error != null) {
      await _showCheckErrorDialog(error!, lang);
    } else if (validated != null) {
      await _confirmPriceChange(validated!);
    }
  }

  /// Tekshiruv boshqa narx qaytarsa — "narx o'zgardi: eski → yangi" oynasi
  /// (№60). Ilgari faqat tugmadagi narx jimgina o'zgarardi. Rad etilsa sheet
  /// yopiladi (natijalarga qaytiladi).
  Future<void> _confirmPriceChange(FlightElement validated) async {
    final change = BookingGate.priceChange(
        _acceptedPrice, validated.price, context.currencyProvider.currency);
    if (change == null) return;
    final confirmed = await ProjectDialogs.showPriceIncreasedConfirm(
      context,
      oldPrice: change.oldPrice,
      newPrice: change.newPrice,
      currencyLabel: change.currencyLabel,
    );
    if (!mounted) return;
    if (confirmed) {
      // Faqat hali shu element tanlangan bo'lsa (oyna ochiqligida tarif
      // almashmagan).
      if (identical(flightElement, validated)) _acceptedPrice = validated.price;
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Tarif oynasidan boshqa tarif tanlandi (№61): tanlangan tarif ko'rsatiladi
  /// va DARHOL qayta tekshiriladi — bron token'i va narxi shu tarifniki
  /// bo'ladi (ilgari tekshiruvsiz bron qilinardi). Taqqoslash asosi —
  /// tarif oynasida ko'rilgan narx.
  void _selectTariff(FlightElement tariff) {
    setState(() {
      flightElement = tariff;
      _acceptedPrice = tariff.price;
      _checking = true;
      _checkError = null;
    });
    unawaited(_checkFlight(dataLang()));
  }

  /// Tarif oynasi qaytargan tarif hozirgisi bilan bir xilmi (id yoki
  /// barqaror kalit bo'yicha) — bir xil bo'lsa tekshirilgan element qoladi.
  bool _isCurrentTariff(FlightElement tariff, List<FlightTariffModel> tariffs) {
    if (identical(tariff, flightElement) || tariff.id == flightElement.id) {
      return true;
    }
    // Barqaror kalit faqat ro'yxatda AYNAN bitta mos tarif bo'lsa ishonchli —
    // bir xil kalitli ikki tarif bo'lsa foydalanuvchi tanlovi e'tiborsiz
    // qolmasin (tanlangani qayta tekshiriladi).
    final index = TariffPickerWidget.indexOfCurrent(
        tariffs, flightElement.id, flightElement);
    return index >= 0 && identical(tariffs[index].flight, tariff);
  }

  Future<void> _showCheckErrorDialog(
      NetworkErrorResponse response, String lang) async {
    if (!mounted || _checkErrorDialogOpen) return;
    _checkErrorDialogOpen = true;
    final action = await ProjectDialogs.showApiErrorDialog(
      context,
      message: response.getError(),
      errorType: response.errorType,
    );
    _checkErrorDialogOpen = false;
    if (!mounted) return;

    if (action == ErrorDialogAction.retry) {
      setState(() => _checking = true);
      unawaited(_checkFlight(lang));
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Tekshiruv davom etayotganda ham bosish mumkin (natija yo'lovchi
  /// sahifasida kutiladi); faqat tekshiruv xato bergan bo'lsa o'chiq.
  bool get _canBook => _checking || _checkError == null;

  /// "Bron qilish" bosildi — yo'lovchi sahifasi darhol ochiladi. Tekshiruv
  /// hali tugamagan bo'lsa, u sahifaga beriladi va bron yaratishdan oldin
  /// kutiladi (xato — dialog + natijalarga qaytish; narx o'zgardi — eski →
  /// yangi narx bilan tasdiq).
  void _onBookTap(RecommendationRequestBody params) {
    HapticFeedback.lightImpact();
    // Tekshiruv doim joriy (tanlangan tarif) elementniki — tarif tanlanganda
    // qayta boshlanadi ([_selectTariff]), shuning uchun `keeping` kerak emas.
    final FlightValidation? pending = _checking ? _validation : null;
    _openPassengerPage(params, pending);
  }

  void _openPassengerPage(
      RecommendationRequestBody params, FlightValidation? pending) {
    // Sheet ochiq qolsa uning ListenableBuilder eski parent context bilan
    // rebuild bo'lishi mumkin — avval sheetni yopib, keyin yo'lovchi
    // sahifasini push qilamiz.
    final navigator = Navigator.of(context);
    final element = flightElement;
    final adt = params.adt;
    final chd = params.chd;
    final inf = params.inf;
    navigator.pop();
    navigator.push(MaterialPageRoute(
      settings: RouteSettings(name: PassengerInformationPage.routeName),
      builder: (_) => PassengerInformationPage(
        adt: adt,
        chd: chd,
        inf: inf,
        element: element,
        pendingValidation: pending,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final params = ProjectUtils.params;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor =
        isDark ? ProjectTheme.backgroundDark : ProjectTheme.backgroundLight;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: _sheetTopRadius),
      child: Material(
        color: sheetColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TicketSheetTopBar(
                topRadius: _sheetTopRadius,
                origin: params.firstSegmentTitle,
                destination: params.lastSegmentTitle,
                subtitle: _sheetSubtitle(params),
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _FareRulesCard(
                        seatCount: flightElement.getSeatCount(),
                        withCBaggage: flightElement.withCBaggage(),
                        cBaggage: flightElement.withCBaggage()
                            ? flightElement.getCBaggage()
                            : null,
                        isRefund: flightElement.isRefund ?? false,
                        isBaggage: flightElement.isBaggage ?? false,
                        baggageLabel: flightElement.getBaggage(),
                        isExchangeable: flightElement.isExchangeable(),
                        tariffSection: BlocProvider(
                          create: (context) =>
                              TicketTariffCubit(flightElement.id),
                          child:
                              BlocBuilder<TicketTariffCubit, TicketTariffState>(
                            builder: (context, state) {
                              if (state is TicketTariffLoadingState) {
                                return const _TariffPickerSkeleton();
                              }
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: state is TicketTariffSuccessState
                                    ? _TariffPickerTile(
                                        onTap: () async {
                                          final result = await ProjectDialogs
                                              .showTariffPicker(
                                            context,
                                            state.tariffs,
                                            flightElement.id,
                                            current: flightElement,
                                          );
                                          if (result == null ||
                                              !mounted ||
                                              _isCurrentTariff(
                                                  result, state.tariffs)) {
                                            return;
                                          }
                                          _selectTariff(result);
                                        },
                                      )
                                    : const SizedBox(
                                        width: double.infinity,
                                        height: 4,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildDirections(context),
                      SizedBox(height: 8 + bottomInset),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.color.primaryContainer,
                  border: Border(
                    top: BorderSide(
                      color: context.color.outline.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _BookButton(
                      enabled: _canBook,
                      // Tekshiruv natijasi yo'lovchi sahifasida kutiladi —
                      // bu yerda spinner kerak emas (№36).
                      isLoading: false,
                      passengerCount: params.adt + params.chd + params.inf,
                      priceLabel:
                          currencyProvider.getElementPrice(flightElement.price),
                      onTap: () => _onBookTap(params),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "20 Iyul · 1 yo'lovchi · Ekonom" — skrinshot uslubi.
  String _sheetSubtitle(RecommendationRequestBody params) {
    // params getter: "20 iyul, 1 pass., Ekonom" → middle-dot format
    return params.params
        .replaceAll('.,', ' ·')
        .replaceAll(', ', ' · ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String getUpgradePrice(Upgrade upgrade) {
    final currency = context.currencyProvider.currency;
    switch (currency) {
      case AppCurrency.uzs:
        return "${upgrade.increasePrice?.uzs ?? ""} UZS";
      case AppCurrency.usd:
        return "${upgrade.increasePrice?.usd ?? ""} USD";
      case AppCurrency.rub:
        return "${upgrade.increasePrice?.rub ?? ""} RUB";
    }
  }

  List<Widget> _buildDirections(BuildContext context) {
    final segmentList = flightElement.getSegmentList();
    final widgets = <Widget>[];
    for (int i = 0; i < segmentList.length; i++) {
      widgets.add(_FlightDirectionCard(
        flightElement: flightElement,
        segments: segmentList[i],
        directionIndex: i,
        showDirectionLabel: segmentList.length > 1,
      ));
      if (i != segmentList.length - 1) widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  (List<String>, List<String>) _extractRouteCodes() {
    final segs = flightElement.getSegmentList();

    List<String> codesFor(List<FlightSegment> dir) {
      final codes = <String>[];
      if (dir.isEmpty) return codes;
      final dep = dir.first.dep.airport?.code ?? dir.first.dep.city?.code ?? '';
      if (dep.isNotEmpty) codes.add(dep);
      for (final s in dir) {
        final arr = s.arr.airport?.code ?? s.arr.city?.code ?? '';
        if (arr.isNotEmpty) codes.add(arr);
      }
      return codes;
    }

    final outbound = segs.isNotEmpty ? codesFor(segs[0]) : <String>[];
    final ret = segs.length > 1 ? codesFor(segs[1]) : <String>[];
    return (outbound, ret);
  }

  void _openRouteMap(BuildContext context) {
    final (outbound, ret) = _extractRouteCodes();
    if (outbound.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: FlightRouteMapTestPage.routeName),
        builder: (_) => FlightRouteMapTestPage(
          outboundCodes: outbound,
          returnCodes: ret.length >= 2 ? ret : null,
        ),
      ),
    );
  }
}

/// Bottom sheet yuqori paneli — skrinshot: X · Tashkent → Moscow · meta.
class _TicketSheetTopBar extends StatelessWidget {
  final Radius topRadius;
  final String origin;
  final String destination;
  final String subtitle;
  final VoidCallback onClose;

  const _TicketSheetTopBar({
    required this.topRadius,
    required this.origin,
    required this.destination,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B1F4A);
    const navyEnd = Color(0xFF12306A);
    final title = origin.isNotEmpty && destination.isNotEmpty
        ? '$origin  →  $destination'
        : (origin.isNotEmpty ? origin : destination);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navy, navyEnd],
        ),
        borderRadius: BorderRadius.vertical(top: topRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topInset > 0 ? topInset : 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onClose,
                  tooltip: "close".tr(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Gilroy',
                          height: 1.15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
