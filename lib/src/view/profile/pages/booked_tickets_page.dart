// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart'
    show ConfirmedTicketsModel;
import 'package:mysafar_sdk/src/service/review/in_app_review_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_constants.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/ticked_list_page.dart';

/// "Chiptalarim" sahifasi — brand gradientli hero header (bosh sahifa
/// hero'si kabi pastki burchaklari yumaloq), ichiga qadalgan "shisha" tab
/// panel (jonli chipta sonlari bilan) va holatlar orasida silliq o'tish.

part 'booked_tickets_skeleton.dart';

class BookedTicketsPage extends StatefulWidget {
  const BookedTicketsPage({super.key});

  static const routeName = '/confirmedTickets';

  @override
  State<BookedTicketsPage> createState() => _BookedTicketsPageState();
}

class _BookedTicketsPageState extends State<BookedTicketsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _reviewService = InAppReviewService();

  /// Baholash so'rovi shu ochilishda allaqachon tekshirilganmi — har bir
  /// silent yangilanishda qayta so'ralmasligi uchun.
  bool _reviewRequested = false;

  /// Header'ning pastki yumaloq burchagi — bosh sahifa hero'si bilan bir xil.
  static const double _headerRadius = 28;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BookedTicketsConstants.tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isLoggedIn => MySafarSdk.tokens.isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConfirmedTicketsCubit(),
      // Header gradienti ikkala temada ham to'q ko'k — status bar
      // ikonkalari doim oq (bosh sahifa hero'si bilan bir xil uslub).
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: _isLoggedIn ? _buildContent() : _buildLoggedOutContent(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  LOGIN QILINGAN KONTENT
  // ──────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return BlocBuilder<ConfirmedTicketsCubit, ConfirmedTicketsState>(
      builder: (context, state) {
        // Tab badge'laridagi sonlar faqat ro'yxat kelganda ko'rsatiladi.
        final List<ConfirmedTicketsModel>? all =
            state is ConfirmedTicketsSuccessState
                ? state.confirmedTickets
                : null;
        final paid = all?.where(_isTicketed).toList();
        final unpaid = all?.where((e) => !_isTicketed(e)).toList();

        // Ilovani baholash so'rovi — faqat foydalanuvchi haqiqatan chipta
        // sotib olgan bo'lsa (yuklangan ro'yxatda kamida bitta "ticketed"
        // statusli chipta). 7 kunlik interval servisning o'zida nazoratda.
        if (!_reviewRequested && (paid?.isNotEmpty ?? false)) {
          _reviewRequested = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _reviewService.requestReviewIfNeeded(),
          );
        }

        return Column(
          children: [
            _buildHeader(
              context,
              counts: all == null
                  ? null
                  : [all.length, paid!.length, unpaid!.length],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  // Holat TURI o'zgargandagina animatsiya o'ynaydi (silent
                  // yangilashda success → success qayta animatsiya bo'lmaydi).
                  key: ValueKey<Type>(state.runtimeType),
                  child: _buildStateContent(context, state, paid, unpaid),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateContent(
    BuildContext context,
    ConfirmedTicketsState state,
    List<ConfirmedTicketsModel>? paid,
    List<ConfirmedTicketsModel>? unpaid,
  ) {
    return switch (state) {
      ConfirmedTicketsErrorState() => _buildErrorState(context, state.error),
      ConfirmedTicketsEmptyState() => _buildEmptyState(context),
      ConfirmedTicketsSuccessState() => _buildSuccessState(
          context, state.confirmedTickets, paid ?? [], unpaid ?? []),
      // Loading va boshlang'ich holat — skelet (bo'sh oq ekran o'rniga).
      _ => _buildLoadingState(context),
    };
  }

  // ──────────────────────────────────────────────────────────────────
  //  HERO HEADER
  // ──────────────────────────────────────────────────────────────────

  /// Brand gradientli header: sarlavha, dekorativ "parvoz" motivi va (login
  /// bo'lsa) jonli sonli tab panel. [counts] — [hammasi, to'langan,
  /// to'lanmagan] sonlari; `null` bo'lsa badge'lar ko'rsatilmaydi.
  Widget _buildHeader(BuildContext context,
      {List<int>? counts, bool showTabs = true}) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    final double topInset = MediaQuery.of(context).padding.top;
    // Sahifa router orqali alohida ochilganda (bottom-nav tab emas)
    // header'da orqaga tugmasi chiqadi.
    final bool showBack =
        ModalRoute.of(context)?.settings.name == BookedTicketsPage.routeName;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(_headerRadius)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand, ProjectTheme.blueBg],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(110) : brand.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(_headerRadius)),
        child: Stack(
          children: [
            // Shaffof doiralar (login kartasidagi motif — endi header'da).
            Positioned(right: -34, top: -34, child: _decorCircle(120, 18)),
            Positioned(left: -28, bottom: -46, child: _decorCircle(112, 12)),
            // Fondagi katta "parvoz" belgisi — chipta mavzusiga ishora.
            Positioned(
              right: 4,
              top: topInset - 10,
              child: Transform.rotate(
                angle: -0.35,
                child: Icon(
                  Icons.flight_rounded,
                  size: 88,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: _glassIconChip(
                              Icons.arrow_back_ios_new_rounded,
                              iconSize: 19),
                        )
                      else
                        _glassIconChip(Icons.airplane_ticket_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ticket'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showTabs) ...[
                    const SizedBox(height: 16),
                    _buildTabBar(context, counts),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, int alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(alpha),
      ),
    );
  }

  Widget _glassIconChip(IconData icon, {double iconSize = 22}) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(42),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(70), width: 1.2),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }

  /// Gradient ustidagi to'q "shisha" segment panel — faol tab oq pill bo'lib
  /// ajralib turadi, matn kontrasti ikkala holatda ham yetarli.
  Widget _buildTabBar(BuildContext context, List<int>? counts) {
    final brand = ProjectTheme.brandColor;
    return Container(
      height: BookedTicketsConstants.tabBarHeight,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1),
      ),
      // Badge ranglari faol tabga mos o'zgarishi uchun swipe paytida ham
      // qayta quriladi (AnimatedBuilder — tab almashinuvini kuzatadi).
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, _) {
          final int selected = _tabController.animation!.value.round();
          return TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: brand,
            unselectedLabelColor: Colors.white,
            labelPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStatePropertyAll(Colors.white.withAlpha(18)),
            splashBorderRadius: BorderRadius.circular(12),
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(45),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            padding: const EdgeInsets.all(4),
            labelStyle: const TextStyle(
              fontFamily: 'packages/mysafar_sdk/Gilroy',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'packages/mysafar_sdk/Gilroy',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              _buildTab('all'.tr(), counts?[0], selected == 0, brand),
              _buildTab('paid'.tr(), counts?[1], selected == 1, brand),
              _buildTab('unpaid'.tr(), counts?[2], selected == 2, brand),
            ],
          );
        },
      ),
    );
  }

  /// Bitta tab: matn (uzun tarjimalarda avtomatik kichrayadi) + jonli son.
  Widget _buildTab(String text, int? count, bool selected, Color brand) {
    return Tab(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, maxLines: 1),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  // Faol tabda (oq pill) brand tusli, nofaolda oq "tanga" —
                  // ikkala fonda ham o'qiladigan kontrast.
                  color: selected ? brand.withAlpha(26) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: brand,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HOLATLAR: YUKLANMOQDA / XATO / BO'SH / MUVAFFAQIYAT
  // ──────────────────────────────────────────────────────────────────

  Future<void> _refresh(BuildContext context, {bool silent = false}) {
    // Qo'lda yangilash — biletlarni serverdan majburan qayta oladi.
    return context
        .read<ConfirmedTicketsCubit>()
        .getTickets(silent: silent, forceRefresh: true);
  }

  /// Haqiqiy chipta kartasi siluetidagi skelet — yuklanish tugagach kontent
  /// "sakrab" o'zgarmaydi. Shimmer ranglari temaga moslashadi.
  Widget _buildLoadingState(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: BookedTicketsConstants.shimmerItemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(8),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(80)
                    : const Color(0x80C6C7C9).withAlpha(110),
                offset: const Offset(0, 4),
                blurRadius: 14,
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor:
                isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300,
            highlightColor:
                isDark ? Colors.white.withAlpha(45) : Colors.grey.shade100,
            child: const _TicketSkeleton(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ProjectTheme.error,
                      ProjectTheme.error.withAlpha(180),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ProjectTheme.error.withAlpha(90),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ProjectTheme.blueButtonStyle,
                onPressed: () => _refresh(context),
                child: Text("retry".tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          brand.withAlpha(40),
                          brand.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                  Lottie.asset(
                    Assets.homeAiStarsSearch,
                    repeat: true,
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'not_found_booked_tickets'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    List<ConfirmedTicketsModel> all,
    List<ConfirmedTicketsModel> paid,
    List<ConfirmedTicketsModel> unpaid,
  ) {
    Future<void> onRefresh() => _refresh(context, silent: true);

    return TabBarView(
      controller: _tabController,
      children: [
        TicketList(tickets: all, onRefresh: onRefresh),
        TicketList(tickets: paid, onRefresh: onRefresh),
        TicketList(tickets: unpaid, onRefresh: onRefresh),
      ],
    );
  }

  bool _isTicketed(dynamic ticket) {
    return ticket.callbackStatus?.toLowerCase() ==
        BookedTicketsConstants.statusTicketed;
  }

  // ──────────────────────────────────────────────────────────────────
  //  LOGIN QILINMAGAN HOLAT
  // ──────────────────────────────────────────────────────────────────

  Widget _buildLoggedOutContent() {
    return Builder(
      builder: (context) => Column(
        children: [
          // Login bo'lmasa ham brand header qoladi — sahifa o'z qiyofasini
          // yo'qotmaydi; tab panel esa ko'rsatilmaydi.
          _buildHeader(context, showTabs: false),
          Expanded(child: _buildLoginPrompt(context)),
        ],
      ),
    );
  }

  /// Login taklifi — yumshoq halo ichidagi gradient belgi, matn va kirish
  /// tugmasi. Header allaqachon gradient bo'lgani uchun karta sokin.
  Widget _buildLoginPrompt(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(8),
            ),
            boxShadow: context.shadowDown,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [brand.withAlpha(36), brand.withAlpha(0)],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [brand, ProjectTheme.blueBg],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brand.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'enter_profile'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'enter_profile_desc'.tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? ProjectTheme.secondaryTextDark
                      : ProjectTheme.secondaryTextLight,
                ),
              ),
              const SizedBox(height: 22),
              MainButtonWidget(
                onTap: () => ProjectDialogs.showAuthPhoneSheet(context),
                title: 'enter_login'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SKELET (SHIMMER) VIDJETLARI
// ════════════════════════════════════════════════════════════════════

/// Chipta kartasining shimmer sileti — MyTicketWidget tuzilishini
/// takrorlaydi: status qatori, reys qatori, ma'lumot qatorlari, narx paneli.
