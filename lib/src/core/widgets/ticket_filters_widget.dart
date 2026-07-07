import 'dart:io' show Platform;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/local/recom_req_model.dart'
    show RecommendationRequestBody, RequestBodyAirlineModel;

class TicketFiltersWidget extends StatefulWidget {
  final RecommendationRequestBody params;
  const TicketFiltersWidget({super.key, required this.params});

  @override
  State<TicketFiltersWidget> createState() => _TicketFiltersWidgetState();
}

/// Lightweight, const-constructible radio indicator. Extracting it lets Flutter
/// reuse the const subtree across rebuilds and avoids re-parsing the SVG on
/// every setState when the active state is unchanged.
class _RadioIcon extends StatelessWidget {
  final bool isActive;
  const _RadioIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgPicture.asset(isActive
          ? Assets.homeRadioButtonActive
          : Assets.homeRadioButtonDeactive),
    );
  }
}

class _TicketFiltersWidgetState extends State<TicketFiltersWidget> {
  /// Categories keys
  final List<GlobalKey> filterCategories = [
    GlobalKey(debugLabel: "order"),
    GlobalKey(debugLabel: "baggae"),
    GlobalKey(debugLabel: "transfer"),
    GlobalKey(debugLabel: "klass"),
    GlobalKey(debugLabel: "company"),
  ];

  /// Scroll Controller
  late ScrollController scrollController;

  /// Tab Context
  BuildContext? tabContext;

  late RecommendationRequestBody filterParams;

  @override
  void initState() {
    filterParams = widget.params;
    scrollController = ScrollController();
    scrollController.addListener(animateToTab);
    super.initState();
  }

  /// Animate To Tab
  void animateToTab() {
    late RenderBox box;

    for (var i = 0; i < filterCategories.length; i++) {
      box = filterCategories[i].currentContext!.findRenderObject() as RenderBox;
      Offset position = box.localToGlobal(Offset.zero);

      if (scrollController.offset >= position.dy) {
        DefaultTabController.of(tabContext!).animateTo(
          i,
          duration: const Duration(milliseconds: 100),
        );
      }
    }
  }

  /// Scroll to Index
  void scrollToIndex(int index) async {
    scrollController.removeListener(animateToTab);
    final categories = filterCategories[index].currentContext!;
    await Scrollable.ensureVisible(
      categories,
      duration: const Duration(milliseconds: 600),
    );
    scrollController.addListener(animateToTab);
  }

  @override
  void dispose() {
    scrollController.removeListener(animateToTab);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Builder(
        builder: (BuildContext context) {
          tabContext = context;
          return Scaffold(
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Padding(
              padding: EdgeInsets.only(
                  bottom: Platform.isIOS ? 44 : 0, right: 16.0, left: 16.0),
              child: Row(
                children: [
                  Expanded(
                      child: SizedBox(
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(boxShadow: context.shadowDown),
                      child: ElevatedButton(
                          style: context.filterCancelButtonStyle,
                          onPressed: () {
                            setState(() {
                              HapticFeedback.mediumImpact();
                              filterParams.setDefaultFilterParams();
                            });
                          },
                          child: Text(
                            "reset".tr(),
                            style: context.textTheme.bodyMedium,
                          )),
                    ),
                  )),
                  context.szBoxWidth12,
                  Expanded(
                      child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                        style: ProjectTheme.blueButtonStyle,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(filterParams);
                        },
                        child: Text(
                          "apply".tr(),
                          style: context.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white),
                        )),
                  ))
                ],
              ),
            ),
            appBar: AppBar(
                leading: SizedBox(),
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                    ),
                  )
                ],
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'filter_title'.tr(),
                      style: context.textTheme.bodyMedium,
                    )
                  ],
                ),
                bottom: TabBar(
                    indicatorPadding: const EdgeInsets.only(
                        left: 0.0, right: 0.0, top: 2, bottom: 2),
                    indicatorWeight: 1,
                    tabAlignment: TabAlignment.center,
                    splashBorderRadius: BorderRadius.circular(12),
                    dividerColor: ProjectTheme.borderLight,
                    dividerHeight: 0.5,
                    indicatorAnimation: TabIndicatorAnimation.linear,
                    indicatorSize: TabBarIndicatorSize.tab,
                    padding:
                        EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
                    labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 14),
                    indicator: BoxDecoration(
                      color: ProjectTheme.brandColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isScrollable: true,
                    tabs: [
                      Tab(child: Text('order_by_tab'.tr())),
                      Tab(child: Text('baggage_tab'.tr())),
                      Tab(child: Text('transfer_tab'.tr())),
                      Tab(child: Text('klass_tab'.tr())),
                      Tab(child: Text('airlines_tab'.tr()))
                    ],
                    onTap: (int index) => scrollToIndex(index))),
            body: Padding(
              padding: context.k16horizontalPadding,
              child: SingleChildScrollView(
                controller: scrollController,
                clipBehavior: Clip.none,
                child: ListTileTheme(
                  contentPadding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SizedBox(key: filterCategories[0], height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "order_by_tab".tr(),
                            style: context.textTheme.displayMedium,
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                            },
                            child: Text("reset".tr(),
                                style: context.textTheme.headlineMedium
                                    ?.copyWith(color: ProjectTheme.error)),
                          )
                        ],
                      ),
                      context.szBoxHeight8,
                      _getOrderWidget(
                        filterParams.getOrder(),
                        (order) {
                          setState(() {
                            filterParams.setOrder(order);
                          });
                        },
                      ),
                      context.szBoxHeight16,
                      Row(
                        key: filterCategories[1],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "with_baggage".tr(),
                            style: context.textTheme.displayMedium,
                          ),
                          // InkWell(
                          //   splashColor: Colors.transparent,
                          //   highlightColor: Colors.transparent,
                          //   onTap: () {
                          //     HapticFeedback.lightImpact();
                          //   },
                          //   child: Text("Qayta o'rnatish",
                          //       style: context.textTheme.headlineMedium
                          //           ?.copyWith(color: ProjectTheme.error)),
                          // )
                        ],
                      ),
                      context.szBoxHeight8,
                      _getBaggage(
                        filterParams.getBaggage(),
                        (isBaggage) => setState(() {
                          filterParams.isBaggage = isBaggage;
                        }),
                      ),
                      context.szBoxHeight16,
                      Row(
                        key: filterCategories[2],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "transfer_tab".tr(),
                            style: context.textTheme.displayMedium,
                          ),
                          // InkWell(
                          //   splashColor: Colors.transparent,
                          //   highlightColor: Colors.transparent,
                          //   onTap: () {
                          //     HapticFeedback.lightImpact();

                          //   },
                          //   child: Text("Qayta o'rnatish",
                          //       style: context.textTheme.headlineMedium
                          //           ?.copyWith(color: ProjectTheme.error)),
                          // )
                        ],
                      ),
                      context.szBoxHeight8,
                      _getTransfersWidget(
                        filterParams.isDirect(),
                        (isDirect) {
                          setState(() {
                            if (isDirect) {
                              filterParams.isDirectOnly = 1;
                            } else {
                              filterParams.isDirectOnly = 0;
                            }
                          });
                        },
                      ),
                      context.szBoxHeight16,
                      Row(
                        key: filterCategories[3],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "klass_tab".tr(),
                            style: context.textTheme.displayMedium,
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => filterParams.klass = "a");
                            },
                            child: Text("reset".tr(),
                                style: context.textTheme.headlineMedium
                                    ?.copyWith(color: ProjectTheme.error)),
                          )
                        ],
                      ),
                      context.szBoxHeight8,
                      _getKlassWidget(
                        filterParams.klass ?? "a",
                        (type) => setState(() => filterParams.klass = type),
                      ),
                      context.szBoxHeight16,
                      Row(
                        key: filterCategories[4],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "airlines_tab".tr(),
                            style: context.textTheme.displayMedium,
                          ),
                          InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                for (final e
                                    in filterParams.filterAirlines ?? []) {
                                  e.isChosed = true;
                                }
                              });
                            },
                            child: Text("reset".tr(),
                                style: context.textTheme.headlineMedium
                                    ?.copyWith(color: ProjectTheme.error)),
                          )
                        ],
                      ),
                      context.szBoxHeight8,
                      _getAviaCompanyWidget(
                        filterParams.filterAirlines ?? [],
                        (airlines) => setState(
                            () => filterParams.filterAirlines = airlines),
                      ),
                      SizedBox(
                        height: Platform.isIOS
                            ? context.height * 0.2
                            : context.height * 0.15,
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SizedBox _getKlassWidget(String type, void Function(String type) callBack) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack("e");
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == "e"),
                      context.szBoxWidth12,
                      Text("klass_e".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack("b");
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == "b"),
                      context.szBoxWidth12,
                      Text("klass_b".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack("a");
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == "a"),
                      context.szBoxWidth12,
                      Text("klass_a".tr())
                    ],
                  ),
                ),
              ),
              context.szBoxHeight12
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _getBaggage(bool isBaggage, void Function(bool isBaggage) callBack) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack(true);
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: isBaggage),
                      context.szBoxWidth12,
                      Text("add_baggage".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack(false);
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: !isBaggage),
                      context.szBoxWidth12,
                      Text("without_baggage".tr())
                    ],
                  ),
                ),
              ),
              context.szBoxHeight12
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _getAviaCompanyWidget(List<RequestBodyAirlineModel> airlines,
      void Function(List<RequestBodyAirlineModel> airlines) callBack) {
    late bool isAll = true;

    for (final element in airlines) {
      if (element.isChosed == false) {
        isAll = false;
        break;
      }
    }
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: context.k16horizontalPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  for (final e in airlines) {
                    e.isChosed = !isAll;
                  }
                  callBack(airlines);
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "all_airlines".tr(),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w400),
                      ),
                      Checkbox(
                        value: isAll,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          for (final e in airlines) {
                            e.isChosed = value;
                          }
                          callBack(airlines);
                        },
                      ),
                    ]),
              ),
              Divider(
                thickness: 1.0,
                color: ProjectTheme.borderLight,
              ),
              Column(
                children: List.generate(
                  airlines.length,
                  (index) => InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final isChosen = airlines[index].isChosed ?? false;
                      airlines[index].isChosed = !isChosen;
                      callBack(airlines);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  ProjectAssets.getSegmentProviderImg(
                                      airlines[index].code ?? ""),
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        context.szBoxWidth8,
                        Text(
                          airlines[index].name ?? "",
                          style: context.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w400),
                        ),
                        Expanded(child: SizedBox()),
                        Checkbox(
                          value: airlines[index].isChosed,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            airlines[index].isChosed = value;
                            callBack(airlines);
                          },
                        ),
                      ],
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

  SizedBox _getTransfersWidget(
      bool isDirect, void Function(bool isDirect) callBack) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack(false);
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: !isDirect),
                      context.szBoxWidth12,
                      Text("all".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    callBack(true);
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: isDirect),
                      context.szBoxWidth12,
                      Text("only_direct".tr())
                    ],
                  ),
                ),
              ),
              context.szBoxHeight12,
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _getOrderWidget(int type, void Function(int order) callBack) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          boxShadow: context.shadowDown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      callBack(0);
                    });
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == 0),
                      context.szBoxWidth12,
                      Text("price_order".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      callBack(1);
                    });
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == 1),
                      context.szBoxWidth12,
                      Text("dep_order".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      callBack(2);
                    });
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == 2),
                      context.szBoxWidth12,
                      Text("arr_order".tr())
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      callBack(3);
                    });
                  },
                  child: Row(
                    children: [
                      _RadioIcon(isActive: type == 3),
                      context.szBoxWidth12,
                      Text("duration_order".tr())
                    ],
                  ),
                ),
              ),
              context.szBoxHeight12
            ],
          ),
        ),
      ),
    );
  }
}
