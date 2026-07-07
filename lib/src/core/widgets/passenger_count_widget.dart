import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart' show SizeContext;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;

class PassengerCountWidget extends StatefulWidget {
  final Map<String, dynamic> params;
  const PassengerCountWidget({
    super.key,
    required this.params,
  });

  @override
  State<PassengerCountWidget> createState() => _PassengerCountWidgetState();
}

class _PassengerCountWidgetState extends State<PassengerCountWidget> {
  int adt = 1;
  int chd = 0;
  int inf = 0;

  String klass = 'a';

  @override
  void initState() {
    if (widget.params.isNotEmpty) {
      final params = widget.params;
      adt = params['adt'];
      chd = params['chd'] ?? 0;
      inf = params['inf'] ?? 0;
      klass = params['klass'] ?? "a";
    }
    super.initState();
  }

  bool get isMax => adt + chd + inf == 9;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox.shrink(),
        title: Text(
          "passenger_count_title".tr(),
          style: context.textTheme.displayMedium,
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: Icon(Icons.close))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Center(
            //   child: Padding(
            //     padding: context.k8verticalPadding,
            //     child: SvgPicture.asset(ProjectAssets.dragImgSvg),
            //   ),
            // ),
            Divider(
              thickness: 1,
              color: ProjectTheme.borderLight,
            ),
            context.szBoxHeight16,
            Padding(
              padding: context.k16horizontalPadding,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "passenger_count_header".tr(),
                      style: context.textTheme.displayMedium
                          ?.copyWith(fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    height: context.k24Space,
                  ),
                  getPassengerCounter(
                      type: 0,
                      title: "above_12".tr(),
                      remove: () {
                        if (adt > 1) {
                          setState(() {
                            HapticFeedback.lightImpact();
                            adt--;
                          });
                        }
                      },
                      add: () {
                        if (isMax) {
                          return;
                        }

                        setState(() {
                          HapticFeedback.lightImpact();
                          adt++;
                        });
                      }),
                  context.szBoxHeight16,
                  getPassengerCounter(
                      type: 1,
                      title: "between_2_12".tr(),
                      remove: () {
                        if (chd > 0) {
                          setState(() {
                            HapticFeedback.lightImpact();
                            chd--;
                          });
                        }
                      },
                      add: () {
                        if (isMax) {
                          return;
                        }

                        setState(() {
                          HapticFeedback.lightImpact();
                          chd++;
                        });
                      }),
                  context.szBoxHeight16,
                  getPassengerCounter(
                      type: 2,
                      title: "under_2".tr(),
                      remove: () {
                        if (inf > 0) {
                          setState(() {
                            HapticFeedback.lightImpact();
                            inf--;
                          });
                        }
                      },
                      add: () {
                        if (isMax) {
                          return;
                        }
                        setState(() {
                          HapticFeedback.lightImpact();
                          inf++;
                        });
                      }),
                  context.szBoxHeight16,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "show_age_feedback_subtitle".tr(),
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  context.szBoxHeight8,
                  Divider(
                    thickness: 1,
                    color: ProjectTheme.borderLight,
                  ),
                  context.szBoxHeight16,
                  getKlass(
                    'e',
                    'klass_e'.tr(),
                    (type) => setState(() => klass = type),
                  ),
                  context.szBoxHeight16,
                  getKlass(
                    'b',
                    'klass_b'.tr(),
                    (type) => setState(() => klass = type),
                  ),
                  context.szBoxHeight16,
                  getKlass(
                    'f',
                    'klass_f'.tr(),
                    (type) => setState(() => klass = type),
                  ),
                  context.szBoxHeight16,
                  getKlass(
                    'w',
                    'klass_w'.tr(),
                    (type) => setState(() => klass = type),
                  ),
                  context.szBoxHeight16,
                  getKlass(
                    'a',
                    'klass_a'.tr(),
                    (type) => setState(() => klass = type),
                  ),
                  SizedBox(
                    height: context.k24Space,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                              style: context.filterCancelButtonStyle,
                              onPressed: () {
                                setState(() {
                                  adt = 1;
                                  chd = 0;
                                  inf = 0;
                                  klass = 'a';
                                });
                              },
                              child: Text("reset".tr())),
                        ),
                      ),
                      context.szBoxWidth12,
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                              style: ProjectTheme.blueButtonStyle,
                              onPressed: () {
                                Navigator.of(context).pop({
                                  "adt": adt,
                                  "chd": chd,
                                  "inf": inf,
                                  "klass": klass
                                });
                              },
                              child: Text("apply".tr())),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InkWell getKlass(
      String type, String title, void Function(String type) callback) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        HapticFeedback.lightImpact();
        callback(type);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium,
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: SvgPicture.asset(type == klass
                ? Assets.homeRadioButtonActive
                : Assets.homeRadioButtonDeactive),
          )
        ],
      ),
    );
  }

  /// Type :
  ///
  /// 0 for adt
  ///
  /// 1 for chd
  ///
  /// 2 for inf
  Widget getPassengerCounter(
      {required int type,
      required String title,
      required void Function() remove,
      required void Function() add}) {
    return Row(
      children: [
        Expanded(
            flex: 6,
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontSize: 18),
            )),
        Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedOpacity(
                  opacity: getOpacity(type),
                  duration: Duration(milliseconds: 500),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => remove(),
                    child: SizedBox(
                      height: 36,
                      width: 36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 8.0,
                                  offset: Offset(0, 2),
                                  color: ProjectTheme.shadowDropLight)
                            ],
                            color: ProjectTheme.brandColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          Icons.remove,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(getCount(type)),
                AnimatedOpacity(
                  duration: Duration(milliseconds: 500),
                  opacity: isMax ? 0.4 : 1.0,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => add(),
                    child: SizedBox(
                      height: 36,
                      width: 36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 8.0,
                                  offset: Offset(0, 2),
                                  color: ProjectTheme.shadowDropLight)
                            ],
                            color: ProjectTheme.brandColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ))
      ],
    );
  }

  double getOpacity(int type) {
    if (type == 0 && adt > 1) {
      return 1.0;
    } else if (type == 1 && chd > 0) {
      return 1.0;
    } else if (type == 2 && inf > 0) {
      return 1.0;
    }
    return 0.4;
  }

  String getCount(int type) {
    if (type == 0) {
      return "$adt";
    } else if (type == 1) {
      return "$chd";
    } else {
      return "$inf";
    }
  }
}
