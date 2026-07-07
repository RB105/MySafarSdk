// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysafar_sdk/src/core/tools/app_cache_manager.dart' show AppCacheManager;
import 'package:mysafar_sdk/src/cubit/main/popularDestinations/pop_destinations_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart'
    show PopDestinationsText;
import 'package:mysafar_sdk/src/view/ban_register/ban_register_page.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart';
import 'package:shimmer/shimmer.dart';

import 'destinations_info_map_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late PageController pageController;
  int currentPage = 0;
  Timer? _timer;
  int _destinationsLength = 0;

  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _initialPage);
    currentPage = _initialPage;
  }

  @override
  void dispose() {
    pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel();

    if (itemCount <= 1) return;

    _destinationsLength = itemCount;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !pageController.hasClients) {
        timer.cancel();
        return;
      }

      pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  int _getActualIndex(int virtualIndex) {
    if (_destinationsLength == 0) return 0;
    return virtualIndex % _destinationsLength;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PopularDestinationCubit(),
      child: Column(
        children: [
          BlocBuilder<PopularDestinationCubit, PopularDestinationState>(
              builder: (context, state) {
            switch (state) {
              case PopularDestinationLoadingState():
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              child: Container(
                                color: Colors.grey.shade400,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withAlpha(60),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 24,
                              left: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 150,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 120,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      3,
                                      (i) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          height: 8,
                                          width:
                                              _getActualIndex(currentPage) == i
                                                  ? 20
                                                  : 8,
                                          decoration: BoxDecoration(
                                            color:
                                                _getActualIndex(currentPage) ==
                                                        i
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withAlpha(90),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              case PopularDestinationSuccessState():
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_destinationsLength != state.destinations.length) {
                    _startTimer(state.destinations.length);
                  }
                });

                return SizedBox(
                  height: context.height * 0.48,
                  child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: pageController,
                            onPageChanged: (index) {
                              setState(() {
                                currentPage = index;
                              });
                              _startTimer(state.destinations.length);
                            },
                            itemBuilder: (context, index) {
                              final actualIndex = _getActualIndex(index);
                              final destination =
                                  state.destinations[actualIndex];
                              return Stack(
                                children: [
                                  CachedNetworkImage(
                                    cacheManager: AppCacheManager.instance,
                                    imageUrl: destination.images[0].image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    imageBuilder: (context, imageProvider) {
                                      return Image(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    },
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey.shade300),
                                    errorWidget: (context, url, error) =>
                                        Container(color: Colors.grey.shade200),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color.fromRGBO(0, 0, 0, 0.0),
                                            Color.fromRGBO(0, 0, 0, 0.0),
                                            Color.fromRGBO(0, 0, 0, 0.5),
                                            Color.fromRGBO(0, 0, 0, 1.0),
                                          ],
                                          stops: [0.0, 0.4, 0.6, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _getName(state
                                      .destinations[
                                          _getActualIndex(currentPage)]
                                      .destination
                                      .name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1.5, 1.5),
                                        blurRadius: 4.0,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getName(state
                                      .destinations[
                                          _getActualIndex(currentPage)]
                                      .name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1.5, 1.5),
                                        blurRadius: 4.0,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                    DestinationInfoMapWidget.routeName,
                                    arguments: state.destinations[
                                        _getActualIndex(currentPage)],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: Text(
                                    "view".tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    state.destinations.length,
                                    (i) {
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        height: 8,
                                        width: _getActualIndex(currentPage) == i
                                            ? 20
                                            : 8,
                                        decoration: BoxDecoration(
                                          color:
                                              _getActualIndex(currentPage) == i
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(90),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                );

              default:
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      color: Colors.grey.shade200,
                    ),
                  ),
                );
            }
          }),
          context.szBoxHeight16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context)
                        .pushNamed(BanRegisterPage.routName),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: context.height * 0.213,
                          decoration: BoxDecoration(
                            color: context.color.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: context.shadowDown,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 12),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "ban_list".tr(),
                                style: context.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -12,
                          right: -50,
                          left: 0,
                          child: Center(
                            child: Image.asset(
                              Assets.homeConfirm,
                              height: context.height * 0.17,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                context.szBoxWidth16,
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //     builder: (context) => const DeliveryLocationPage(),
                      //   ),
                      // );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: context.height * 0.213,
                          decoration: BoxDecoration(
                            color: context.color.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: context.shadowDown,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 12),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "order_visa_card".tr(),
                                style: context.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -16,
                          right: -50,
                          left: 0,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  Assets.homeVisaBron,
                                  height: context.height * 0.17,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 36),
              child:   const BookedTicketPaymentBanner(),)
        ],
      ),
    );
  }

  String _getName(PopDestinationsText name) {
    switch (dataLang()) {
      case 'ru':
        return name.ru;
      case 'en':
        return name.en;
      default:
        return name.uz;
    }
  }
}
