// ignore_for_file: depend_on_referenced_packages

import 'package:lottie/lottie.dart';

import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/review/in_app_review_service.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/booked_tickets_constants.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/ticked_list_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/user_shimmer_widget.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: BookedTicketsConstants.tabCount,
      vsync: this,
    );
    _reviewService.requestReviewIfNeeded();
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
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text('ticket'.tr()),
        ),
        body: _isLoggedIn ? _buildContent() : _buildLoginPrompt(context),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildTabBar(context),
        ),
        Expanded(
          child: BlocBuilder<ConfirmedTicketsCubit, ConfirmedTicketsState>(
            builder: (context, state) => _buildStateContent(context, state),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final unselectedColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Container(
      height: BookedTicketsConstants.tabBarHeight,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(60)
                : Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: context.textTheme.bodyMedium!.copyWith(fontSize: 14),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: unselectedColor,
          labelPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brand, ProjectTheme.blueBg],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: brand.withAlpha(110),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          padding: const EdgeInsets.all(4),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            _buildTab('all'.tr()),
            _buildTab('paid'.tr()),
            _buildTab('unpaid'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text) {
    return Tab(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, ConfirmedTicketsState state) {
    return switch (state) {
      ConfirmedTicketsLoadingState() => _buildLoadingState(context),
      ConfirmedTicketsErrorState() => _buildErrorState(context, state.error),
      ConfirmedTicketsEmptyState() => _buildEmptyState(context),
      ConfirmedTicketsSuccessState() => _buildSuccessState(context, state),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _refresh(BuildContext context, {bool silent = false}) {
    // Qo'lda yangilash — biletlarni serverdan majburan qayta oladi.
    return context
        .read<ConfirmedTicketsCubit>()
        .getTickets(silent: silent, forceRefresh: true);
  }

  Widget _buildLoadingState(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: BookedTicketsConstants.shimmerItemCount,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: context.themeProvider.isDark
                      ? Colors.transparent
                      : const Color(0x80C6C7C9),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: PassengerShimmer(),
            ),
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
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
      BuildContext context, ConfirmedTicketsSuccessState state) {
    final all = state.confirmedTickets;
    final paid = all.where(_isTicketed).toList();
    final unpaid = all.where((e) => !_isTicketed(e)).toList();

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

  Widget _buildLoginPrompt(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return Center(
      child: Padding(
        padding: context.k16Padding,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: context.shadowDown,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [brand, ProjectTheme.blueBg],
                        ),
                      ),
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(80),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'enter_profile'.tr(),
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'enter_profile_desc'.tr(),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      MainButtonWidget(
                        onTap: () =>
                            ProjectDialogs.showAuthPhoneSheet(context),
                        title: 'enter_login'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
