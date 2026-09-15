// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:shimmer/shimmer.dart';

import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/app_segmented_tab_bar.dart';
import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart'
    show ConfirmedTicketsModel;
import 'package:mysafar_sdk/src/service/review/in_app_review_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_constants.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/ticked_list_page.dart';

/// "Buyurtmalar" sahifasi — sahifa fonidagi markazlangan sarlavha, brend
/// pill'li segment tab panel (jonli chipta sonlari bilan) va holatlar
/// orasida silliq o'tish.

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
      // Header sahifa fonida — status bar ikonkalari temaga mos.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              context.isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              context.isDarkMode ? Brightness.dark : Brightness.light,
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
  //  HEADER
  // ──────────────────────────────────────────────────────────────────

  /// Yo'nalishlar tabi bilan bir xil header: sahifa fonida markazlangan
  /// sarlavha va (login bo'lsa) jonli sonli segment tab panel. [counts] —
  /// [hammasi, to'langan, to'lanmagan] sonlari; `null` bo'lsa badge'lar
  /// ko'rsatilmaydi.
  Widget _buildHeader(BuildContext context,
      {List<int>? counts, bool showTabs = true}) {
    // Sahifa router orqali alohida ochilganda (bottom-nav tab emas)
    // header'da orqaga tugmasi chiqadi.
    final bool showBack =
        ModalRoute.of(context)?.settings.name == BookedTicketsPage.routeName;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: showBack ? 48 : 0),
                    child: Text(
                      'orders'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _backButton(context),
                    ),
                ],
              ),
            ),
            if (showTabs) ...[
              const SizedBox(height: 14),
              _buildTabBar(context, counts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Material(
      color: context.color.primaryContainer,
      shape: CircleBorder(side: BorderSide(color: context.color.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: context.textTheme.displayLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, List<int>? counts) {
    return AppSegmentedTabBar(
      controller: _tabController,
      height: BookedTicketsConstants.tabBarHeight,
      segments: [
        AppSegment(label: 'all'.tr(), count: counts?[0]),
        AppSegment(label: 'paid'.tr(), count: counts?[1]),
        AppSegment(label: 'unpaid'.tr(), count: counts?[2]),
      ],
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
    final isDark = context.isDarkMode;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, 16 + MediaQuery.paddingOf(context).bottom),
      itemCount: BookedTicketsConstants.shimmerItemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.white12 : const Color(0xFFE9EDF3),
          highlightColor: isDark ? Colors.white24 : const Color(0xFFF7F9FC),
          child: const _TicketSkeleton(),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return AppRefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          OrdersStateView(
            iconAsset: Assets.iconsBookingAlertIcon,
            title: error,
            isError: true,
            actionLabel: "retry".tr(),
            onAction: () => _refresh(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          OrdersStateView(
            iconAsset: Assets.iconsOrderTicketIcon,
            title: 'not_found_booked_tickets'.tr(),
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

  bool _isTicketed(ConfirmedTicketsModel ticket) {
    // Kartadagi chip bilan bir xil manba (callback_status → order.status).
    return ticket.orderStatus.toLowerCase() ==
        BookedTicketsConstants.statusTicketed;
  }

  // ──────────────────────────────────────────────────────────────────
  //  LOGIN QILINMAGAN HOLAT
  // ──────────────────────────────────────────────────────────────────

  Widget _buildLoggedOutContent() {
    return Builder(
      builder: (context) => Column(
        children: [
          // Login bo'lmasa ham header (sarlavha) qoladi — sahifa o'z qiyofasini
          // yo'qotmaydi; tab panel esa ko'rsatilmaydi.
          _buildHeader(context, showTabs: false),
          Expanded(child: _buildLoginPrompt(context)),
        ],
      ),
    );
  }

  /// Login taklifi — sokin ikonka, matn va kirish tugmasi.
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            0, 24, 0, 24 + MediaQuery.paddingOf(context).bottom),
        child: OrdersStateView(
          iconAsset: Assets.iconsOrderTicketIcon,
          title: 'enter_profile'.tr(),
          subtitle: 'enter_profile_desc'.tr(),
          actionLabel: 'enter_login'.tr(),
          onAction: () => ProjectDialogs.showAuthPhoneSheet(context),
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
