import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart' show SizeContext;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart' show AppCacheManager;
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart' show ProjectDialogs;
import 'package:mysafar_sdk/src/cubit/tickets/tickets_cubit.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody;
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightElement, FlightSegment;
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, BlocProvider;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:mysafar_sdk/src/view/tickets/ticket_info_page.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

import 'my_safar_ticket_shimmer.dart';

part '_tickets_container_widgets.dart';

part '_ticket_loading_widget.dart';

class RecommendationsTicketPage extends StatefulWidget {
  final RecommendationRequestBody requestBody;

  const RecommendationsTicketPage({super.key, required this.requestBody});

  static const routeName = '/tickets';

  @override
  State<RecommendationsTicketPage> createState() =>
      _RecommendationsTicketPageState();
}

class _RecommendationsTicketPageState extends State<RecommendationsTicketPage> {
  // ── Yuklash indikatori holati ──────────────────────────────────────────
  // Yuklash boshlanganda indikator sekin to'ladi; natija kelganda tezda 100%
  // ga to'lib, so'ng o'chadi. `_finishing` — natija kelgandan keyin tugallanish
  // animatsiyasi o'ynalishi uchun indikatorni ko'rinishda ushlab turadi.
  bool _prevLoading = false;
  bool _finishing = false;

  // ── Narx eskirishi ogohlantirishi ─────────────────────────────────────
  // Foydalanuvchi natijalar ekranida uzoq (5 daqiqa) tursa, bilet narxlari
  // eskirgan bo'lishi mumkin. Shu sababli ogohlantiruvchi dialog ko'rsatib,
  // xuddi shu parametrlar bilan qaytadan qidirishni taklif qilamiz.
  //
  // MUHIM: dialog FAQAT shu sahifa ekranda ko'rinib turganda chiqsin.
  // Foydalanuvchi boshqa ekranga (masalan, bilet tafsilotlari) o'tib ketsa,
  // taymer ishlashda davom etadi, lekin dialog ko'rsatilmaydi — sahifaga
  // qaytib kelgandagina chiqadi. Buni har safar `ModalRoute.isCurrent` orqali
  // tekshiramiz (navigator stack holatidan; observer kerak emas).
  static const Duration _priceRefreshTimeout = Duration(minutes: 5);
  // Sahifa ko'rinmay turganda dialogni ko'rsatish o'rniga shuncha vaqtdan keyin
  // qayta tekshiramiz (sahifaga qaytishni "kutish" intervali).
  static const Duration _visibilityRecheck = Duration(milliseconds: 500);
  Timer? _priceRefreshTimer;
  bool _refreshDialogOpen = false;

  // ── Har saralanishda eng arzonni ko'rsatish ───────────────────────────
  // Natijalar 3 ta manbadan bosqichma-bosqich keladi va ro'yxat har safar narx
  // bo'yicha qayta saralanadi (eng arzon tepaga) — oxirgi manbani kutmasdan.
  // Agar foydalanuvchi shu paytgacha pastga scroll qilib ketgan bo'lsa, yangi
  // eng arzonni sezmay qoladi. Shuning uchun har bir manba kelganda (2-, 3-...),
  // user tepada bo'lmasa, ro'yxatni silliq tepaga suramiz.
  //
  // Bunda kartalarni qayta tartiblovchi FLIP animatsiyasi scroll bilan bir
  // vaqtda to'qnashmasligi uchun, shu bitta yangilanishda FLIP o'tkazib
  // yuboriladi (`_reorderSuppressed`) — ro'yxat tekis saralangan holda suriladi.
  bool _reorderSuppressed = false;
  // NestedScrollView body'sining ichki (koordinatsiyalangan) scroll controlleri.
  ScrollController? _innerScroll;

  /// Eski taymerni bekor qilib, 5 daqiqalik yangi taymerni ishga tushiradi.
  void _restartPriceRefreshTimer(TicketCubit cubit) {
    _priceRefreshTimer?.cancel();
    _priceRefreshTimer =
        Timer(_priceRefreshTimeout, () => _onPriceRefreshTimeout(cubit));
  }

  /// 5 daqiqa o'tgach ishlaydi: ogohlantirish dialogini ko'rsatadi va
  /// foydalanuvchi tasdiqlasa, xuddi shu parametrlar bilan qayta qidiradi.
  Future<void> _onPriceRefreshTimeout(TicketCubit cubit) async {
    if (!mounted || _refreshDialogOpen) return;

    // Sahifa hozir eng ustki (ko'rinadigan) ekran emasmi — masalan foydalanuvchi
    // bilet tafsilotlari yoki boshqa ekranga o'tgan bo'lsa — dialogni hozir
    // CHIQARMAYMIZ. Biroz kutib qayta tekshiramiz; sahifaga qaytib kelgach,
    // `isCurrent` true bo'ladi va dialog o'shanda chiqadi.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      _priceRefreshTimer?.cancel();
      _priceRefreshTimer =
          Timer(_visibilityRecheck, () => _onPriceRefreshTimeout(cubit));
      return;
    }

    _refreshDialogOpen = true;
    final searchAgain = await ProjectDialogs.showPricesOutdatedDialog(context);
    _refreshDialogOpen = false;
    if (!mounted || cubit.isClosed) return;
    if (searchAgain) {
      // Joriy (filtrlangan yoki boshlang'ich) parametrlar bilan qayta qidiramiz;
      // natija kelganda taymer yana qaytadan boshlanadi.
      cubit.add(GetRecommendationsEvent(cubit.filterReqBody));
    }
  }

  @override
  void dispose() {
    _priceRefreshTimer?.cancel();
    super.dispose();
  }

  /// Indikator tugallanish animatsiyasini yakunlagach uni olib tashlaymiz.
  void _onLoadingBarCompleted() {
    if (mounted && _finishing) {
      setState(() => _finishing = false);
    }
  }

  /// Har bir manba kelib ro'yxat qayta saralanganda chaqiriladi. Foydalanuvchi
  /// pastga scroll qilgan bo'lsa — eng arzon reys tepaga chiqqanini ko'rishi
  /// uchun ro'yxatni silliq tepaga suradi. Allaqachon tepada bo'lsa hech narsa
  /// qilmaymiz (FLIP animatsiyasi qayta tartiblanishni o'zi ko'rsatadi).
  void _maybeScrollCheapestToTop() {
    final controller = _innerScroll;
    if (controller == null || !controller.hasClients) return;
    // Ozgina qoldiqni "tepada" deb hisoblaymiz (aniq 0 bo'lishi shart emas).
    if (controller.offset <= 8) return;

    // Scroll bilan bir vaqtda kartalar FLIP qilib to'qnashmasin — shu
    // yangilanishda qayta tartiblash animatsiyasini o'tkazib yuboramiz.
    _reorderSuppressed = true;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reorderSuppressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => TicketCubit(widget.requestBody, false),
        child: BlocConsumer<TicketCubit, TicketsState>(
          listener: (context, state) {
            // Yangi qidiruv boshlanganda taymerni to'xtatamiz; natija to'liq
            // kelganda (yoki bo'sh/xato bo'lganda) 5 daqiqalik taymerni
            // qaytadan boshlaymiz — shu paytdan idle hisoblanadi.
            if (state is TicketLoadingState) {
              _priceRefreshTimer?.cancel();
            } else if (state is TicketSuccessState) {
              if (!state.isLoadingMore) {
                _restartPriceRefreshTimer(
                    BlocProvider.of<TicketCubit>(context));
              }
              // Har bir manba kelib ro'yxat qayta saralanganda (2-, 3-...),
              // user pastda bo'lsa eng arzonni ko'rsatish uchun tepaga suramiz —
              // oxirgi manbani kutib turmaymiz (u kech kelishi mumkin).
              _maybeScrollCheapestToTop();
            } else if (state is TicketEmptyState || state is TicketErrorState) {
              _restartPriceRefreshTimer(BlocProvider.of<TicketCubit>(context));
            }
          },
          builder: (context, state) {
            final ticketCubit = BlocProvider.of<TicketCubit>(context);

            // Indikator holati: yuklash boshlanganda tugallanish bayrog'ini
            // o'chiramiz; loading→natija qirrasida esa indikator tezda to'lib
            // o'chish animatsiyasini o'ynashi uchun uni yoqamiz.
            final bool isLoading = state is TicketLoadingState;
            if (isLoading) {
              _finishing = false;
            } else if (_prevLoading) {
              _finishing = true;
            }
            _prevLoading = isLoading;
            final bool showLoadingBar = isLoading || _finishing;

            return Scaffold(
                body: SafeArea(
                    top: false,
                    bottom: Platform.isAndroid,
                    child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                      final bool isDark = context.themeProvider.isDark;
                      final showFilters =
                          state is TicketSuccessState || ticketCubit.isFiltered;
                      final _RecHeroFilterBar? filterBar = showFilters
                          ? _RecHeroFilterBar(
                              isDirect: ticketCubit.filterReqBody.isDirect(),
                              isBaggage:
                                  ticketCubit.filterReqBody.isBaggage ?? false,
                              onCheapestTap: () {
                                // Ro'yxat doim eng arzondan saralangan —
                                // tepasiga silliq qaytaramiz.
                                HapticFeedback.lightImpact();
                                final c = _innerScroll;
                                if (c != null && c.hasClients) {
                                  c.animateTo(0,
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeOutCubic);
                                }
                              },
                              onDirectTap: () {
                                HapticFeedback.lightImpact();
                                final filterBody = ticketCubit.filterReqBody;
                                setState(() =>
                                    ticketCubit.filterReqBody.isDirectOnly =
                                        ticketCubit.filterReqBody.isDirect()
                                            ? 0
                                            : 1);
                                ticketCubit.add(SendFilterEvent(filterBody));
                              },
                              onBaggageTap: () {
                                HapticFeedback.lightImpact();
                                final filterBody = ticketCubit.filterReqBody;
                                setState(() =>
                                    ticketCubit.filterReqBody.isBaggage =
                                        !(ticketCubit.filterReqBody.isBaggage ??
                                            false));
                                ticketCubit.add(SendFilterEvent(filterBody));
                              },
                            )
                          : null;
                      return [
                        SliverAppBar(
                          pinned: true,
                          floating: false,
                          automaticallyImplyLeading: false,
                          backgroundColor: context.color.primaryContainer,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          systemOverlayStyle: isDark
                              ? const SystemUiOverlayStyle(
                                  statusBarColor: Colors.transparent,
                                  statusBarIconBrightness: Brightness.light,
                                  statusBarBrightness: Brightness.dark)
                              : const SystemUiOverlayStyle(
                                  statusBarColor: Colors.transparent,
                                  statusBarIconBrightness: Brightness.dark,
                                  statusBarBrightness: Brightness.light),
                          toolbarHeight: 64,
                          centerTitle: true,
                          leadingWidth: 46,
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _RecHeroIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          title: _RecHeroTitle(
                            origin: widget.requestBody.firstSegmentTitle,
                            destination: widget.requestBody.lastSegmentTitle,
                            params: widget.requestBody.params,
                          ),
                          actions: [
                            _RecHeroIconButton(
                              asset: Assets.ticketsUsdIcon,
                              onTap: () =>
                                  ProjectDialogs.showCurrencyMenu(context),
                            ),
                            _RecHeroIconButton(
                              asset: Assets.ticketsFilterIcon,
                              onTap: () async {
                                final filterBody = ticketCubit.filterReqBody;
                                final response =
                                    await ProjectDialogs.showTicketFilter(
                                        context, filterBody);
                                if (response != null) {
                                  ticketCubit.add(SendFilterEvent(filterBody));
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                          bottom: (filterBar != null || showLoadingBar)
                              ? _RecHeroAppBarBottom(
                                  showLoadingBar: showLoadingBar,
                                  isLoading: isLoading,
                                  onLoadingCompleted: _onLoadingBarCompleted,
                                  filterBar: filterBar,
                                )
                              : null,
                        )
                      ];
                    }, body: Builder(builder: (context) {
                      _innerScroll = PrimaryScrollController.maybeOf(context);
                      return CustomScrollView(
                        slivers: [
                          // "To'g'ri reyslar" bloki (Figma) — transfersiz
                          // reyslar aviakompaniya kesimida, eng arzoni bilan.
                          if (state is TicketSuccessState)
                            SliverToBoxAdapter(
                              child: _DirectFlightsCard(
                                flights: state
                                    .recommendationRes.recommedations!.flights,
                                flightType:
                                    widget.requestBody.flight_Type ?? 0,
                              ),
                            ),
                          switch (state) {
                            TicketSuccessState() => _AnimatedFlightList(
                                flights: state
                                    .recommendationRes.recommedations!.flights,
                                isLoadingMore: state.isLoadingMore,
                                flightType: widget.requestBody.flight_Type ?? 0,
                                animateReorder: !_reorderSuppressed,
                              ),
                            _ => SliverPadding(
                                padding: context.k16horizontalPadding,
                                sliver: SliverToBoxAdapter(
                                  child: switch (state) {
                                    TicketLoadingState() =>
                                      MySafarTicketShimmer(
                                        isReturn:
                                            widget.requestBody.flight_Type == 1,
                                      ),
                                    TicketEmptyState() => Column(
                                        children: [
                                          context.szBoxHeight16,
                                          SizedBox(
                                              height: 48,
                                              width: 48,
                                              child: Image.asset(Assets
                                                  .ticketsSearchEmptyIcon)),
                                          Text(
                                            "not_found_tickets".tr(),
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                          ),
                                          context.szBoxHeight12,
                                          Text(
                                            "found_other_tickets".tr(),
                                            textAlign: TextAlign.center,
                                            style: context.textTheme.bodyMedium,
                                          )
                                        ],
                                      ),
                                    TicketErrorState() => Center(
                                        child: Text(state.errorMsg),
                                      ),
                                    _ => const SizedBox(),
                                  },
                                ),
                              ),
                          },
                        ],
                      );
                    }))));
          },
        ));
  }
}

// ════════════════════════════════════════════════════════════════════
//  LIGHT APP BAR (Figma): orqaga + yo'nalish pill'i + valyuta/filter;
//  ostida qora sana-narx lentasi va filter chip'lari.
// ════════════════════════════════════════════════════════════════════

/// App bar tugmasi — och fonda to'q rangli oddiy ikonka (doirasiz).
class _RecHeroIconButton extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final VoidCallback onTap;

  const _RecHeroIconButton({this.icon, this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = context.themeProvider.isDark
        ? Colors.white
        : const Color(0xFF16244A);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: asset != null
                ? SvgPicture.asset(
                    asset!,
                    width: 21,
                    height: 21,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, color: color, size: 19),
          ),
        ),
      ),
    );
  }
}

/// Markazdagi yo'nalish pill'i (Figma): "Toshkent → Dubai" va pastida
/// "27 iyun · 1 yo'lovchi · Ekonom" parametrlari.
class _RecHeroTitle extends StatelessWidget {
  final String origin;
  final String destination;
  final String params;

  const _RecHeroTitle({
    required this.origin,
    required this.destination,
    required this.params,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.themeProvider.isDark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF16244A);
    final Color subColor =
        isDark ? Colors.white70 : ProjectTheme.secondaryTextLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFEFF2F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  origin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: textColor),
              ),
              Flexible(
                child: Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (params.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              params,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Appbar ostidagi chip'lar qatori (Figma): [Eng arzon] [Yuk bilan] [To'g'ri].
class _RecHeroFilterBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDirect;
  final bool isBaggage;
  final VoidCallback onCheapestTap;
  final VoidCallback onDirectTap;
  final VoidCallback onBaggageTap;

  const _RecHeroFilterBar({
    required this.isDirect,
    required this.isBaggage,
    required this.onCheapestTap,
    required this.onDirectTap,
    required this.onBaggageTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: _RecHeroChip(
                active: true,
                label: "ticket_chip_cheapest".tr(),
                onTap: onCheapestTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecHeroChip(
                active: isBaggage,
                label: "ticket_chip_baggage".tr(),
                onTap: onBaggageTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecHeroChip(
                active: isDirect,
                label: "ticket_chip_direct".tr(),
                onTap: onDirectTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stadion shaklidagi chip: faol — ko'k to'ldirilgan (oq matn); nofaol — oq.
class _RecHeroChip extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _RecHeroChip({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.themeProvider.isDark;
    final Color bg = active
        ? ProjectTheme.brandColor
        : (isDark ? Colors.white.withAlpha(26) : Colors.white);
    final Color fg =
        active ? Colors.white : (isDark ? Colors.white : const Color(0xFF16244A));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: active
                ? null
                : Border.all(
                    color:
                        isDark ? Colors.white24 : const Color(0xFFE3E7F0),
                    width: 1),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Appbar pastki qismi: sana-narx lentasi + chip'lar + yuklash indikatori.
class _RecHeroAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  /// Indikator umuman ko'rinadimi (yuklash + tugallanish animatsiyasi davomida).
  final bool showLoadingBar;

  /// `true` — natija kutilmoqda (sekin to'ladi); `false` — natija keldi
  /// (tezda to'lib o'chadi).
  final bool isLoading;

  /// Indikator tugallanish animatsiyasini yakunlaganda chaqiriladi.
  final VoidCallback onLoadingCompleted;

  final _RecHeroFilterBar? filterBar;

  const _RecHeroAppBarBottom({
    required this.showLoadingBar,
    required this.isLoading,
    required this.onLoadingCompleted,
    this.filterBar,
  });

  /// Yuklash indikatori egallaydigan balandlik (chiziq + pastki bo'shliq).
  static const double _loadingHeight = 11;

  @override
  Size get preferredSize => Size.fromHeight(
        (filterBar?.preferredSize.height ?? 0) +
            (showLoadingBar ? _loadingHeight : 0),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (filterBar != null) filterBar!,
        if (showLoadingBar)
          _RecHeroLoadingBar(
            key: const ValueKey('rec-hero-loading-bar'),
            isLoading: isLoading,
            onCompleted: onLoadingCompleted,
          ),
      ],
    );
  }
}

/// Gradient hero ostidagi yupqa progress indikatori.
///
/// Natija kutilayotganda sekinlik bilan ~90% gacha to'ladi (tobora sekinlashib);
/// natija kelganda ([isLoading] `false` bo'lganda) tezda 100% ga to'lib, so'ng
/// o'chadi va [onCompleted] chaqiriladi.
class _RecHeroLoadingBar extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onCompleted;

  const _RecHeroLoadingBar({
    super.key,
    required this.isLoading,
    required this.onCompleted,
  });

  @override
  State<_RecHeroLoadingBar> createState() => _RecHeroLoadingBarState();
}

class _RecHeroLoadingBarState extends State<_RecHeroLoadingBar>
    with TickerProviderStateMixin {
  // To'lish ulushi (0→1).
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  );

  // Ko'rinish (1→0) — tugaganda o'chish (fade out) uchun.
  late final AnimationController _opacity = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _startTrickle();
  }

  @override
  void didUpdateWidget(covariant _RecHeroLoadingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _startTrickle();
      } else {
        _finish();
      }
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _opacity.dispose();
    super.dispose();
  }

  /// Natija kelishigacha sekinlik bilan ~90% gacha to'ladi (tobora sekinlashib).
  void _startTrickle() {
    _opacity.value = 1.0;
    _progress.value = 0.0;
    _progress.animateTo(
      0.9,
      duration: const Duration(milliseconds: 9000),
      curve: Curves.easeOut,
    );
  }

  /// Natija keldi — tezda 100% ga to'lib, so'ng o'chadi.
  Future<void> _finish() async {
    try {
      await _progress.animateTo(
        1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      if (!mounted || widget.isLoading) return;
      await _opacity.animateTo(
        0.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    } catch (_) {
      // TickerCanceled — yangi yuklash boshlandi yoki widget yo'q qilindi.
      return;
    }
    if (!mounted || widget.isLoading) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 3,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_progress, _opacity]),
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: CustomPaint(
                painter: _LoadingBarPainter(
                  fillFraction: _progress.value,
                  track: ProjectTheme.brandColor.withAlpha(40),
                  fill: ProjectTheme.brandColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yumaloq uchli yo'l (track) ustida chapdan o'ngga to'ladigan yorqin chiziq.
class _LoadingBarPainter extends CustomPainter {
  /// 0→1 oralig'ida to'ldirilgan ulush (curve qo'llanilgan).
  final double fillFraction;
  final Color track;
  final Color fill;

  _LoadingBarPainter({
    required this.fillFraction,
    required this.track,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final full = RRect.fromRectAndRadius(Offset.zero & size, radius);

    // Yarim-shaffof yo'l (track).
    canvas.drawRRect(full, Paint()..color = track);

    final fillWidth = (size.width * fillFraction).clamp(0.0, size.width);
    if (fillWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    // Boshlanishi yumshoqroq, uchi yorqinroq — "to'lib borish" hissi.
    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [fill.withAlpha(110), fill],
    ).createShader(fillRect);

    canvas.save();
    canvas.clipRRect(full);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, radius),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoadingBarPainter old) =>
      old.fillFraction != fillFraction ||
      old.track != track ||
      old.fill != fill;
}

/// Natijalar ro'yxati ostida ko'rsatiladigan "yana qidirilmoqda" indikatori —
/// bir manba natijasi chiqqach, qolgan manbalar kutilayotganda ko'rinadi.
class _MoreResultsLoading extends StatelessWidget {
  const _MoreResultsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(ProjectTheme.brandColor),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "searching".tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  NARX BO'YICHA SARALANADIGAN, SILLIQ SILJISH ANIMATSIYALI RO'YXAT
// ════════════════════════════════════════════════════════════════════

/// Narx satridan sonni ajratadi. `amount` formatlangan bo'lishi mumkin
/// ("1 500 000", "1,500,000" kabi) — shuning uchun raqam va nuqtadan boshqa
/// barcha belgilarni (bo'shliq, vergul, valyuta) olib tashlab parse qilamiz.
double _parseAmount(String? s) {
  if (s == null) return double.infinity;
  final cleaned = s.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
  final v = double.tryParse(cleaned);
  return (v == null || v <= 0) ? double.infinity : v;
}

/// FlightElement narxini (son) qaytaradi — saralash uchun. Avval UZS, bo'lmasa
/// USD, so'ng RUB. Valyutalar chiziqli konvertatsiya bo'lgani uchun tartib
/// istalgan valyutada bir xil. Noaniq/yo'q narx ro'yxat oxiriga tushadi.
double _flightPriceUzs(FlightElement f) {
  final uzs = _parseAmount(f.price?.uzs?.amount);
  if (uzs != double.infinity) return uzs;
  final usd = _parseAmount(f.price?.usd?.amount);
  if (usd != double.infinity) return usd;
  return _parseAmount(f.price?.rub?.amount);
}

/// Reys natijalari ro'yxati.
///
/// • Manbalar hali kelayotganda ([isLoadingMore] `true`) — kelish (merge)
///   tartibida ko'rsatadi.
/// • Barcha manbalar tugagach ([isLoadingMore] `false`) — narx bo'yicha o'sish
///   tartibida saralaydi (eng arzon tepada). Saralashda tartib o'zgargan
///   kartalar yangi o'rniga FLIP texnikasi bilan SILLIQ suriladi (qo'pol
///   sakrash yo'q).
class _AnimatedFlightList extends StatefulWidget {
  final List<FlightElement> flights;
  final bool isLoadingMore;
  final int flightType;

  /// `false` bo'lsa, bu yangilanishda kartalarni qayta tartiblovchi FLIP
  /// animatsiyasi o'tkazib yuboriladi (ro'yxat tepaga scroll qilinayotganda,
  /// ikki animatsiya to'qnashmasligi uchun).
  final bool animateReorder;

  const _AnimatedFlightList({
    required this.flights,
    required this.isLoadingMore,
    required this.flightType,
    this.animateReorder = true,
  });

  @override
  State<_AnimatedFlightList> createState() => _AnimatedFlightListState();
}

class _AnimatedFlightListState extends State<_AnimatedFlightList> {
  /// Ekranda qurilgan (mounted) kartalar: id → ularning holati. FLIP uchun
  /// pozitsiyalarni o'lchash va animatsiyani ishga tushirishda ishlatamiz.
  final Map<String, _FlipItemState> _active = {};

  /// Hozir ko'rsatilayotgan tartib (yuklanayotganda — kelish tartibi; tugagach
  /// — narx bo'yicha saralangan).
  late List<FlightElement> _display;

  @override
  void initState() {
    super.initState();
    _display = _computeDisplay();
  }

  void _register(String id, _FlipItemState s) => _active[id] = s;
  void _unregister(String id, _FlipItemState s) {
    if (_active[id] == s) _active.remove(id);
  }

  /// Ko'rsatiladigan tartibni hisoblaydi. Tugagach — narx bo'yicha barqaror
  /// (teng narxlarda kelish tartibini saqlovchi) saralash.
  List<FlightElement> _computeDisplay() {
    // Har doim narx bo'yicha saralaymiz — manbalar bosqichma-bosqich kelsa ham
    // (2-, 3-...) eng arzon darhol tepaga chiqsin, oxirgi manbani kutmasdan.
    final indexed = <MapEntry<int, FlightElement>>[
      for (int i = 0; i < widget.flights.length; i++)
        MapEntry(i, widget.flights[i]),
    ];
    indexed.sort((a, b) {
      final c = _flightPriceUzs(a.value).compareTo(_flightPriceUzs(b.value));
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    final sorted = [for (final e in indexed) e.value];
    // ── VAQTINCHA DIAGNOSTIKA — saralash ishladimi tekshirish uchun ──
    // (Muammo hal bo'lgach o'chiriladi.)
    assert(() {
      final before = widget.flights
          .take(5)
          .map((f) => '${f.price?.uzs?.amount}->${_flightPriceUzs(f)}')
          .toList();
      final after = sorted.take(5).map((f) => _flightPriceUzs(f)).toList();
      debugPrint('SORT: count=${widget.flights.length} '
          'isLoadingMore=${widget.isLoadingMore}');
      debugPrint('SORT: rawFirst5=$before');
      debugPrint('SORT: sortedFirst5=$after');
      return true;
    }());
    return sorted;
  }

  @override
  void didUpdateWidget(covariant _AnimatedFlightList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldDisplay = _display;
    final newDisplay = _computeDisplay();
    _display = newDisplay;

    // Ota-widget shu yangilanishda ro'yxatni tepaga scroll qilayotgan bo'lsa,
    // FLIP'ni o'tkazib yuboramiz — ro'yxat to'g'ridan-to'g'ri saralangan holda
    // ko'rsatiladi (scroll animatsiyasi bilan to'qnashmasin).
    if (!widget.animateReorder) return;

    final oldIds = [for (final f in oldDisplay) f.id];
    final newIds = [for (final f in newDisplay) f.id];
    if (!_orderChanged(oldIds, newIds)) return;

    // Eski (joriy layout) pozitsiyalarni — yangi tartib qurilishidan OLDIN —
    // o'lchab olamiz. Faqat ekrandagi kartalar o'lchanadi.
    final Map<String, Offset> oldOffsets = {};
    _active.forEach((id, s) {
      final off = s.slotOffset();
      if (off != null) oldOffsets[id] = off;
    });
    final oldIndex = {for (int i = 0; i < oldIds.length; i++) oldIds[i]: i};

    // Yangi layout chizilgach, yangi pozitsiyalarni o'lchab, farq (delta)
    // bo'yicha har bir kartani eski o'rnidan yangisiga silliq suramiz.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runFlip(oldOffsets, oldIndex, newIds),
    );
  }

  bool _orderChanged(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  void _runFlip(
    Map<String, Offset> oldOffsets,
    Map<String, int> oldIndex,
    List<String> newIds,
  ) {
    if (!mounted) return;

    // Yangi pozitsiyalar + o'rtacha karta balandligi (ekrandan tashqaridan
    // kiruvchilar uchun taxminiy siljishni hisoblashda kerak).
    final newOffsets = <String, Offset>{};
    double avgHeight = 0;
    int measured = 0;
    _active.forEach((id, s) {
      final off = s.slotOffset();
      if (off != null) {
        newOffsets[id] = off;
        final h = s.slotHeight();
        if (h != null && h > 0) {
          avgHeight += h;
          measured++;
        }
      }
    });
    if (measured > 0) avgHeight /= measured;
    if (avgHeight <= 0) avgHeight = 160;

    final screenH = MediaQuery.of(context).size.height;
    final newIndex = {for (int i = 0; i < newIds.length; i++) newIds[i]: i};

    newOffsets.forEach((id, newOff) {
      final s = _active[id];
      if (s == null) return;

      Offset delta;
      final old = oldOffsets[id];
      if (old != null) {
        // Aniq FLIP: eski → yangi pozitsiya farqi.
        delta = old - newOff;
      } else {
        // Ekrandan tashqaridan kirdi — indeks yo'nalishi bo'yicha taxminiy
        // siljish (pastdan ko'tarilsa pastdan, tepadan tushsa tepadan).
        final oi = oldIndex[id];
        if (oi == null) return; // butunlay yangi element — animatsiyasiz
        final ni = newIndex[id] ?? 0;
        double dy = ((oi - ni) * avgHeight).clamp(-screenH, screenH);
        delta = Offset(0, dy);
      }

      if (delta.dy.abs() < 0.5 && delta.dx.abs() < 0.5) return;
      s.playFrom(delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flights = _display;
    final count = flights.length;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      sliver: SliverList.separated(
        itemCount: count + (widget.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          // Oxirgi element — qolgan manbalar kutilayotgani uchun loading.
          if (index >= count) {
            return const _MoreResultsLoading();
          }
          final flight = flights[index];
          return _FlipItem(
            key: ValueKey(flight.id),
            id: flight.id,
            controller: this,
            child: RepaintBoundary(
              child: switch (widget.flightType) {
                1 => _ReturnDateFlightContainer(flightElement: flight),
                2 => _MultipleDateFlightContainer(flightElement: flight),
                _ => _SingleDateFlightContainer(flightElement: flight),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Bitta karta o'rami: tartib o'zgarganda [playFrom] orqali berilgan boshlang'ich
/// siljishdan nolga qarab silliq suriladi. Tashqi `SizedBox` — o'lchov uchun
/// (layout o'rni); siljish ichki `Transform` bilan beriladi, shuning uchun
/// o'lchov animatsiyadan ta'sirlanmaydi.
class _FlipItem extends StatefulWidget {
  final String id;
  final _AnimatedFlightListState controller;
  final Widget child;

  const _FlipItem({
    required Key key,
    required this.id,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<_FlipItem> createState() => _FlipItemState();
}

class _FlipItemState extends State<_FlipItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  Offset _from = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.controller._register(widget.id, this);
  }

  @override
  void didUpdateWidget(covariant _FlipItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      widget.controller._unregister(oldWidget.id, this);
      widget.controller._register(widget.id, this);
    }
  }

  @override
  void dispose() {
    widget.controller._unregister(widget.id, this);
    _ctrl.dispose();
    super.dispose();
  }

  /// Karta layout o'rnining global pozitsiyasi (tashqi `SizedBox` — Transform
  /// ichkarida bo'lgani uchun animatsiya bu o'lchovga ta'sir qilmaydi).
  Offset? slotOffset() {
    final obj = context.findRenderObject();
    if (obj is RenderBox && obj.attached && obj.hasSize) {
      return obj.localToGlobal(Offset.zero);
    }
    return null;
  }

  double? slotHeight() {
    final obj = context.findRenderObject();
    if (obj is RenderBox && obj.attached && obj.hasSize) {
      return obj.size.height;
    }
    return null;
  }

  /// Kartani [delta] siljishdan boshlab nolga qarab animatsiya bilan suradi.
  void playFrom(Offset delta) {
    if (!mounted) return;
    setState(() => _from = delta);
    _ctrl.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _from = Offset.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          if (_from == Offset.zero) return child!;
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          final off = Offset.lerp(_from, Offset.zero, t)!;
          return Transform.translate(offset: off, child: child);
        },
        child: widget.child,
      ),
    );
  }
}
