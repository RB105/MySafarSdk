// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart'
    show HapticFeedback, SystemUiOverlayStyle;
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart' show ProjectUtils;
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/cubit/main/ai/ai_search_cubit.dart';
import 'package:mysafar_sdk/src/cubit/main/hot/hot_tickets_cubit.dart';
import 'package:mysafar_sdk/src/cubit/main/popularDestinations/pop_destinations_cubit.dart';
import 'package:mysafar_sdk/src/cubit/main/version/check_version_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/hot_tickets_model.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';
import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationReqBodySegment, RecommendationRequestBody;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/avia/recent_search_cache.dart';
import 'package:mysafar_sdk/src/view/main/pages/all_hot_tickets_page.dart';
import 'package:mysafar_sdk/src/view/main/showcase_keys.dart';
import 'package:mysafar_sdk/src/view/main/src/home_background_carousel.dart';
import 'package:mysafar_sdk/src/service/geolacator/location_airport_service.dart';
import 'package:mysafar_sdk/src/service/pexels/pexels_service.dart';
import 'package:mysafar_sdk/src/view/booking/passenger_information_page.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/destinations/destinations_info_map_page.dart';
import 'package:mysafar_sdk/src/view/booking/ticketed_booking_search_page.dart';
import 'package:mysafar_sdk/src/view/tickets/ticket_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:mysafar_sdk/src/cubit/profile/profile_cubit.dart';

part 'src/widgets.dart';
part 'src/main_search_form.dart';


class MainPage extends StatefulWidget
{
    const MainPage({super.key});

    @override
    State<MainPage> createState() => _MainPageState();

    static const String routeName = "/main";
}

class _MainPageState extends State<MainPage>
{
    AirPortsModel? _nearbyAirport;
    final LocationAirportService _locationAirportService =
        LocationAirportService();

    ProfileCubit? _profileCubit;

    final ScrollController _scrollController = ScrollController();
    // 0 = tepada (appbar shaffof, rasm ustida), 1 = scroll qilingan (appbar ko'k).
    final ValueNotifier<double> _headerColorT = ValueNotifier<double>(0);

    void _onScroll()
    {
        final t = (_scrollController.offset / 130).clamp(0.0, 1.0);
        if ((t - _headerColorT.value).abs() > 0.001) _headerColorT.value = t;
    }

    Future<void> _loadProfileData() async
    {
        // Profilni yangilab keshga yozamiz (boshqa ekranlar foydalanadi).
        // Bosh sahifada endi ko'rsatilmaydi (Figma — header'da faqat slogan).
        await _profileCubit!.getProfileData();
    }

    @override
    void dispose()
    {
        _scrollController.dispose();
        _headerColorT.dispose();
        _profileCubit?.close();
        super.dispose();
    }

    @override
    void initState()
    {
        super.initState();

        _scrollController.addListener(_onScroll);

        // Keshdagi profilni (Hive) xavfsiz o'qiymiz — buzilgan/bo'sh bo'lsa
        // tarmoqdan yuklashga o'tamiz (ProfileCubit'dagi himoya kabi).
        final profileMap = ProfileCache().read();
        if (profileMap != null)
        {
            try
            {
                // Keshni tekshiramiz — buzilgan bo'lsa tarmoqdan qayta yuklaymiz.
                ProfileModel.fromJson(profileMap);
            }
            catch (e)
            {
                debugPrint("⚠️ profile cache parse failed: $e");
                _profileCubit = ProfileCubit(needGetProfile: true);
                _loadProfileData();
            }
        }
        else
        {
            _profileCubit = ProfileCubit(needGetProfile: true);
            _loadProfileData();
        }

        // Load nearby airport based on geolocation (after frame to ensure context is available)
        WidgetsBinding.instance.addPostFrameCallback((_)
        {
            _loadNearbyAirport();
        }
        );
    }

    /// Load nearby airport when geolocation permission is granted
    Future<void> _loadNearbyAirport() async
    {
        // First check if we have cached airport
        final cachedAirport = _locationAirportService.cachedNearbyAirport;
        if (cachedAirport != null)
        {
            if (mounted)
            {
                setState(()
                {
                    _nearbyAirport = cachedAirport;
                }
                );
            }
            return;
        }

        // Try to get nearby airport
        final lang = mounted ? context.locale.languageCode : 'en';
        final airport = await _locationAirportService.getNearbyAirport(lang: lang);

        if (airport != null && mounted)
        {
            setState(()
            {
                _nearbyAirport = airport;
            }
            );
        }
    }

    @override
    Widget build(BuildContext context)
    {

        return BlocProvider(
            create: (context) => CheckVersionCubit(),
            child: BlocListener<CheckVersionCubit, CheckVersionState>(
                listener: (BuildContext context, CheckVersionState state)
                {
                    if (state is VersionUpdateRequiredState)
                    {
                        ProjectDialogs.showUpdateRequiredDialog(context);
                    }
                    else if (state is VersionUpdateOptionalState)
                    {
                        ProjectDialogs.showUpdateOptionalDialog(context);
                    }
                },
                child: Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        systemOverlayStyle: const SystemUiOverlayStyle(
                            statusBarColor: Colors.transparent,
                            statusBarIconBrightness: Brightness.light,
                            statusBarBrightness: Brightness.dark,
                        ),
                        titleSpacing: 20,
                        flexibleSpace: ValueListenableBuilder<double>(
                            valueListenable: _headerColorT,
                            builder: (context, t, _) => ColoredBox(
                                color: Color.lerp(
                                    Colors.transparent, const Color(0xFF3E5788), t)!,
                            ),
                        ),
                        // Embed rejimda host app'ga (masalan Unired) qaytish
                        // tugmasi — SDK'ning o'z stack'ida emas, host route'ini
                        // yopadi.
                        leading: MySafarSdk.isEmbedded
                            ? Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: _circleIconButton(
                                    null,
                                    MySafarSdk.exitEmbed,
                                    iconData: Icons.arrow_back_rounded),
                              )
                            : null,
                        actions: [
                            _circleIconButton(
                                ProjectAssets.callCenterIcon,
                                () => ProjectDialogs.showSupportMenu(context),
                                showcaseKey: HomeShowcaseKeys.support,
                                showcaseTitle: "showcase_support_title".tr(),
                                showcaseDesc: "showcase_support_desc".tr()),
                            const SizedBox(width: 12),
                        ],
                    ),
                    body:  SingleChildScrollView(
                                controller: _scrollController,
                                child: Column(
                                    children: [
                                        _homeHeader(context),
                                        ColoredBox(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            child: Column(
                                                children: [
                                                    const SizedBox(height: 16),
                                                    Showcase(
                                                        key: HomeShowcaseKeys.hot,
                                                        title: "showcase_hot_title".tr(),
                                                        description: "showcase_hot_desc".tr(),
                                                        targetBorderRadius: BorderRadius.circular(16),
                                                        tooltipBackgroundColor: ProjectTheme.brandColor,
                                                        textColor: Colors.white,
                                                        child: const MainHotTickets()),
                                                    // "Mashhur yo'nalishlar" olib tashlandi —
                                                    // widget ham, /destinations so'rovi ham yo'q.
                                                    // Figma: so'ngi qidiruvlar va 24/7 yordam.
                                                    const RecentSearchesWidget(),
                                                    const HomeSupportBanner(),
                                                    const SizedBox(height: 24),
                                                ],
                                            ),
                                        ),
                                    ],
                                ),

                    ),
                ),
            ));
    }

    /// Bosh sahifa header'i — aylanuvchi orqa fon rasmi BUTUN sohani (slogan +
    /// qidiruv kartasi + ostini) qoplaydi; karta rasm ichida suzib turadi (Figma).
    Widget _homeHeader(BuildContext context)
    {
        final double topInset = MediaQuery.of(context).padding.top;

        return ColoredBox(
            // Rasmning yumaloq pastki burchaklari ortida oq (body) rangi ko'rinadi.
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
            children: [
                // Orqa fon rasmi butun header'ni qoplaydi + o'qish uchun gradient.
                // Radius endi RASMning o'ziga beriladi (pastki burchaklar yumaloq),
                // avvalgidek ustidagi alohida oq konteynerga emas.
                Positioned.fill(
                    child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(28)),
                        child: Stack(
                            fit: StackFit.expand,
                            children: [
                                const HomeBackgroundCarousel(),
                                DecoratedBox(
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                                Colors.black.withOpacity(0.45),
                                                Colors.black.withOpacity(0.12),
                                                Colors.black.withOpacity(0.12),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
                // Ustki kontent: slogan + qidiruv kartasi — rasm ICHIDA suzadi.
                Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        SizedBox(height: topInset + kToolbarHeight + 4),
                        _sloganTitle(context),
                        const SizedBox(height: 20),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Showcase(
                                key: HomeShowcaseKeys.search,
                                title: "showcase_search_title".tr(),
                                description: "showcase_search_desc".tr(),
                                targetPadding: const EdgeInsets.all(6),
                                targetBorderRadius: BorderRadius.circular(24),
                                tooltipBackgroundColor: ProjectTheme.brandColor,
                                textColor: Colors.white,
                                child: MainSearchForm(
                                    homeStyle: true,
                                    nearbyAirport: _nearbyAirport),
                            ),
                        ),
                        // Karta ostida bir oz rasm ko'rinadi, so'ng kontent
                        // yumaloq burchak bilan boshlanadi (Figma kabi).
                        const SizedBox(height: 56),
                    ],
                ),
            ],
        ),
        );
    }

    /// Rasm ustidagi katta oq slogan (Figma — faqat slogan).
    Widget _sloganTitle(BuildContext context)
    {
        return Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            child: SizedBox(
                width: double.infinity,
                child: Text(
                    MySafarSdk.brandify("home_slogan".tr()),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 12,
                                offset: Offset(0, 1)),
                        ],
                    ),
                ),
            ),
        );
    }


    Widget _circleIconButton(String? asset, VoidCallback onTap,
        {IconData? iconData,
        GlobalKey? showcaseKey,
        String? showcaseTitle,
        String? showcaseDesc})
    {
        final Widget button = InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Container(

                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProjectTheme.brandColor,
                ),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: asset != null
                        ? SvgPicture.asset(
                            asset,
                            colorFilter: ColorFilter.mode(
                                Colors.white, BlendMode.srcIn
                            )
                        )
                        : Icon(iconData, size: 20, color: Colors.white)
                )
            )
        );

        if (showcaseKey == null) return button;

        return Showcase(
            key: showcaseKey,
            title: showcaseTitle,
            description: showcaseDesc,
            targetShapeBorder: const CircleBorder(),
            targetPadding: const EdgeInsets.all(4),
            tooltipBackgroundColor: ProjectTheme.brandColor,
            textColor: Colors.white,
            child: button,
        );
    }
}
