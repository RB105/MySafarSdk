// ignore_for_file: unused_element

import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkErrorResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/service/avia_service.dart' show AviaService;
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart'
    show AppCurrency, AppCurrencyExtension;
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
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/core/widgets/ticket_tariffs_widget.dart'
    show TariffPickerWidget;
import 'package:mysafar_sdk/src/core/widgets/fare_status_icon.dart';
import 'package:mysafar_sdk/src/core/widgets/plane_silhouette.dart';
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

part 'ticket_info_hero.dart';
part 'ticket_info_tariffs.dart';
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

  /// Chipta tafsilotini ALOHIDA sahifada ochadi (ilgari bottom sheet edi —
  /// tariflar lentasi va reys ma'lumoti varaqqa sig'masdi). SDK ichki
  /// navigator'ida ochiladi (`Navigator.of(context)` — SDK sahifalari
  /// konteksti), host root navigator'iga chiqmaydi.
  static Future<T?> show<T>(BuildContext context, FlightElement flight) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: routeName),
        builder: (_) => TicketInfoPage(flightElement: flight),
      ),
    );
  }

  @override
  State<TicketInfoPage> createState() => _TicketInfoPageState();
}

class _TicketInfoPageState extends State<TicketInfoPage> {
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
  // Tekshiruv sahifa ochiq turganda xato bersa — tugma o'chadi (dialog).
  FlightValidation? _validation;

  /// Oxirgi boshlangan tekshiruv raqami — eskirgan tekshiruv (masalan tarif
  /// almashgandan keyin kelgan asl reys natijasi, yoki yo'lovchi sahifasiga
  /// topshirilgan tekshiruv) holatni o'zgartirmaydi.
  int _checkSeq = 0;

  /// Foydalanuvchi ko'rgan (va qabul qilgan) narx: kartadagi yoki lentada
  /// tanlangan tarif narxi. Tekshiruv natijasi shu bilan solishtiriladi
  /// (№60) — allaqachon yangilangan narx bilan emas.
  FlightPrice? _acceptedPrice;

  // ── Tariflar (`/avia/get-tariff`) ─────────────────────────────────────
  // Sahifa ochilishi bilan yuklanadi. Kelmasa yoki bitta bo'lsa — lentada
  // faqat joriy tarif qoladi.
  final List<FlightTariffModel> _tariffs = [];

  /// Lentada tanlangan tarif indeksi; `-1` — joriy reys ro'yxatda topilmadi
  /// (u alohida karta bo'lib turadi, hech bir tarif jimgina tanlanmaydi).
  int _selectedTariff = -1;

  /// Borish-kelishda pastda ko'rsatilayotgan yo'nalish: 0 — borish,
  /// 1 — qaytish. Ikkalasi ketma-ket cho'zilib ketmasin uchun bittasi
  /// ko'rinadi, tepasidagi tugmalar bilan almashtiriladi.
  int _direction = 0;

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

    // So'rov sahifa yopilsa ham davom etadi — natijasini yo'lovchi sahifasi
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
  /// (№60). Ilgari faqat tugmadagi narx jimgina o'zgarardi. Rad etilsa sahifa
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

  /// Tariflar kelgach: ro'yxat saqlanadi, joriy reys qaysi tarif ekani
  /// aniqlanadi — avval asl id, so'ng barqaror kalit (tekshiruvdan keyin id
  /// bron token'iga almashadi, №61). Topilmasa `-1`: joriy reys o'zgarmaydi
  /// (ilovadagidek birinchi tarifga jimgina almashtirilmaydi — u
  /// tekshirilmagan bo'lardi).
  void _applyTariffs(List<FlightTariffModel> tariffs) {
    final index = TariffPickerWidget.indexOfCurrent(
        tariffs, widget.flightElement.id, widget.flightElement);
    setState(() {
      _tariffs
        ..clear()
        ..addAll(tariffs);
      _selectedTariff = index;
    });
  }

  /// Lentadan boshqa tarif tanlandi (№61): tanlangan tarif ko'rsatiladi va
  /// DARHOL qayta tekshiriladi — bron token'i va narxi shu tarifniki bo'ladi.
  /// Taqqoslash asosi — lentada ko'rilgan narx.
  void _selectTariff(int index) {
    if (index < 0 || index >= _tariffs.length || index == _selectedTariff) {
      return;
    }
    HapticFeedback.selectionClick();
    final tariff = _tariffs[index].flight;
    setState(() {
      _selectedTariff = index;
      flightElement = tariff;
      _acceptedPrice = tariff.price;
      _checking = true;
      _checkError = null;
    });
    unawaited(_checkFlight(dataLang()));
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
  Future<void> _onBookTap(RecommendationRequestBody params) async {
    HapticFeedback.lightImpact();
    // Tekshiruv doim joriy (tanlangan tarif) elementniki — tarif tanlanganda
    // qayta boshlanadi ([_selectTariff]), shuning uchun `keeping` kerak emas.
    final FlightValidation? pending = _checking ? _validation : null;
    if (pending != null) {
      // Tekshiruv natijasini endi yo'lovchi sahifasi boshqaradi — bu sahifa
      // (u stack'da ostida qoladi) o'z dialoglarini ko'rsatmasin.
      _checkSeq++;
    }
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(
      settings: RouteSettings(name: PassengerInformationPage.routeName),
      builder: (_) => PassengerInformationPage(
        adt: params.adt,
        chd: params.chd,
        inf: params.inf,
        element: flightElement,
        pendingValidation: pending,
      ),
    ));
    // Foydalanuvchi qaytdi. Topshirilgan tekshiruv natijasi bu sahifaga
    // qo'llanmagan — joriy tarif qayta tekshiriladi.
    if (!mounted || pending == null) return;
    setState(() {
      _checking = true;
      _checkError = null;
    });
    unawaited(_checkFlight(dataLang()));
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final params = ProjectUtils.params;
    final passengerCount = params.adt + params.chd + params.inf;
    // Theme.of — themeProvider.isDark bilan sinxron chiqmay qolmasin.
    final background = context.isDarkMode
        ? ProjectTheme.backgroundDark
        : ProjectTheme.backgroundLight;

    return BlocProvider(
      create: (_) => TicketTariffCubit(widget.flightElement.id),
      child: BlocListener<TicketTariffCubit, TicketTariffState>(
        listener: (context, state) {
          if (state is TicketTariffSuccessState) _applyTariffs(state.tariffs);
        },
        child: Scaffold(
          backgroundColor: background,
          body: Column(
            children: [
              // Marshrut kodlari + sana/yo'lovchi/klass
              _TicketRouteHeader(
                flightElement: flightElement,
                origin: params.firstSegmentTitle,
                destination: params.lastSegmentTitle,
                subtitle: _sheetSubtitle(params),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BlocBuilder<TicketTariffCubit, TicketTariffState>(
                        builder: (context, state) => _TariffCarousel(
                          flightElement: flightElement,
                          tariffs: _tariffs,
                          selectedIndex: _selectedTariff,
                          loading: state is TicketTariffLoadingState ||
                              state is TicketTariffInitState,
                          passengerCount: passengerCount,
                          onSelect: _selectTariff,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildDirections(context),
                      const SizedBox(height: 8),
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
                    // Narx tariflar kelgandan keyin aniq bo'ladi — shu
                    // paytgacha pastda tugma emas, yuklanish qatori turadi.
                    // Aks holda foydalanuvchi bir necha soniya eski narxni
                    // ko'rib, u ko'z oldida almashib ketardi.
                    child: BlocBuilder<TicketTariffCubit, TicketTariffState>(
                      builder: (context, state) {
                        final waiting = state is TicketTariffInitState ||
                            state is TicketTariffLoadingState;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: waiting
                              ? const SizedBox(
                                  height: 54,
                                  child: Center(child: _TariffsLoadingRow()),
                                )
                              : _BookButton(
                                  enabled: _canBook,
                                  // Tekshiruv natijasi yo'lovchi sahifasida
                                  // kutiladi — bu yerda spinner kerak emas
                                  // (№36).
                                  isLoading: false,
                                  passengerCount: passengerCount,
                                  priceLabel: currencyProvider
                                      .getElementPrice(flightElement.price),
                                  onTap: () => _onBookTap(params),
                                ),
                        );
                      },
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
    if (segmentList.isEmpty) return const [];

    // Bir tomonga — tugmalarsiz, karta o'zi.
    if (segmentList.length == 1) {
      return [
        _FlightDirectionCard(
          flightElement: flightElement,
          segments: segmentList[0],
          directionIndex: 0,
        ),
      ];
    }

    // Tarif almashganda yo'nalishlar soni kamayib qolsa chegaradan chiqmasin.
    final dir = _direction.clamp(0, segmentList.length - 1);
    return [
      _DirectionSwitch(
        flightElement: flightElement,
        count: segmentList.length,
        selected: dir,
        onSelect: (i) {
          if (i == _direction) return;
          HapticFeedback.selectionClick();
          setState(() => _direction = i);
        },
      ),
      const SizedBox(height: 12),
      // Yo'nalish almashganda karta yumshoq fade bilan almashadi.
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        child: KeyedSubtree(
          key: ValueKey('direction-$dir-${flightElement.id}'),
          child: _FlightDirectionCard(
            flightElement: flightElement,
            segments: segmentList[dir],
            directionIndex: dir,
          ),
        ),
      ),
    ];
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

/// Sahifa yuqori paneli — "boarding pass" uslubida: katta aeroport kodlari
/// (TAS → SVO), ular orasida punktir yoy ustida uchayotgan samolyot va
/// davomiylik, kodlar ostida shahar nomlari. Eng pastda qidiruv sharti
/// (sana · yo'lovchi · klass) alohida pill'larda.
///
/// Borish-kelish bo'lsa ikkinchi — teskari yo'nalgan — yoy chiziladi.
class _TicketRouteHeader extends StatelessWidget {
  final FlightElement flightElement;
  final String origin;
  final String destination;

  /// "20 iyul · 1 yo'lovchi · Ekonom" — pill'larga bo'linadi.
  final String subtitle;

  /// Orqaga qaytish.
  final VoidCallback onClose;

  const _TicketRouteHeader({
    required this.flightElement,
    required this.origin,
    required this.destination,
    required this.subtitle,
    required this.onClose,
  });

  List<List<FlightSegment>> get _directions => flightElement.getSegmentList();

  bool get _isRoundTrip => _directions.length > 1;

  String get _fromCode {
    final dirs = _directions;
    if (dirs.isEmpty || dirs.first.isEmpty) return '';
    final dep = dirs.first.first.dep;
    return dep.airport?.code ?? dep.city?.code ?? '';
  }

  String get _toCode {
    final dirs = _directions;
    if (dirs.isEmpty || dirs.first.isEmpty) return '';
    final arr = dirs.first.last.arr;
    return arr.airport?.code ?? arr.city?.code ?? '';
  }

  String get _duration =>
      ElementFormatter.formatDuration(flightElement.getDirDuration(0));

  List<String> get _chips => subtitle
      .split('·')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Kod topilmasa (kamdan-kam) shahar nomi katta yozuv bo'lib qoladi.
    final from = _fromCode.isNotEmpty ? _fromCode : origin;
    final to = _toCode.isNotEmpty ? _toCode : destination;
    final chips = _chips;
    final text = _tiText(context);
    final muted = _tiMuted(context);

    // Neytral panel: oq (qorong'ida karta rangi) fon, to'q matn. Status bar
    // ikonkalari fonga moslab almashadi.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: DecoratedBox(
          decoration: BoxDecoration(color: context.color.primaryContainer),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, topInset + 6, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: onClose,
                    ),
                    Expanded(
                      child: Text(
                        "ticket_details_title".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'packages/mysafar_sdk/Gilroy',
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child:
                            _endpoint(context, from, origin, alignEnd: false),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _RouteArc(reverse: false),
                            if (_isRoundTrip) ...[
                              const SizedBox(height: 2),
                              _RouteArc(reverse: true),
                            ],
                            if (_duration.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _duration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'packages/mysafar_sdk/Gilroy',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child:
                            _endpoint(context, to, destination, alignEnd: true),
                      ),
                    ],
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < chips.length; i++)
                        _HeaderChip(icon: _chipIcon(i), label: chips[i]),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kod (katta) + shahar nomi (ostida, sokinroq).
  Widget _endpoint(BuildContext context, String code, String city,
      {required bool alignEnd}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: _tiText(context),
            fontSize: 26,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontFamily: 'packages/mysafar_sdk/Gilroy',
          ),
        ),
        if (city.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: _tiMuted(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'packages/mysafar_sdk/Gilroy',
            ),
          ),
        ],
      ],
    );
  }

  /// Pill ikonkasi: sana → yo'lovchi → klass tartibida.
  IconData _chipIcon(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_today_rounded;
      case 1:
        return Icons.person_rounded;
      case 2:
        return Icons.airline_seat_recline_normal_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

/// Panel ustidagi doira tugma (orqaga).
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tiTonal(context),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _tiText(context), size: 20),
        ),
      ),
    );
  }
}

/// Qidiruv sharti pill'i: ikonka + matn.
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _tiTonal(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _tiMuted(context)),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _tiText(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'packages/mysafar_sdk/Gilroy',
            ),
          ),
        ],
      ),
    );
  }
}

/// Punktir yoy va uning cho'qqisidagi samolyot.
///
/// `reverse` — qaytish yo'nalishi: yoy pastga egiladi, samolyot chapga qaraydi.
class _RouteArc extends StatelessWidget {
  final bool reverse;

  const _RouteArc({required this.reverse});

  @override
  Widget build(BuildContext context) {
    final color = _tiMuted(context).withValues(alpha: 0.6);
    return SizedBox(
      // To'liq kenglik shart — aks holda Stack samolyot ikonkasi bo'yicha
      // kichrayib, yoy ikki nuqtaga yopishib qoladi.
      width: double.infinity,
      height: 22,
      child: Stack(
        alignment: reverse ? Alignment.bottomCenter : Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderArcPainter(color: color, reverse: reverse),
            ),
          ),
          // Bron sahifasidagi yoy uchidagi samolyot bilan bir xil siluet.
          PlaneSilhouette(
            size: 20,
            color: _tiText(context),
            shadeColor: context.color.primaryContainer,
            angle: reverse ? math.pi : 0,
          ),
        ],
      ),
    );
  }
}

/// Uchlarida nuqtalari bo'lgan punktir yoy.
class _HeaderArcPainter extends CustomPainter {
  final Color color;
  final bool reverse;

  _HeaderArcPainter({required this.color, required this.reverse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final baseY = reverse ? 5.0 : size.height - 5;
    final controlY = reverse ? size.height : 0.0;
    final start = Offset(5, baseY);
    final end = Offset(size.width - 5, baseY);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(size.width / 2, controlY, end.dx, end.dy);

    final metric = path.computeMetrics().first;
    const dash = 4.0;
    const gap = 4.0;
    double distance = 0;
    while (distance < metric.length) {
      canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
      distance += dash + gap;
    }

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(start, 2.6, dotPaint);
    canvas.drawCircle(end, 2.6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HeaderArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.reverse != reverse;
}
