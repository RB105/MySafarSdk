// part of '../main_page.dart';

// class MultiwayFlightParams extends StatefulWidget {
//   final int? errorIndex;
//   final List<RecommendationReqBodySegment> multiwaySegments;
//   final void Function(List<RecommendationReqBodySegment> multiwaySegments)
//       callBack;
//   const MultiwayFlightParams(
//       {super.key,
//       required this.multiwaySegments,
//       required this.callBack,
//       this.errorIndex});

//   @override
//   State<MultiwayFlightParams> createState() => _MultiwayFlightParamsState();
// }

// class _MultiwayFlightParamsState extends State<MultiwayFlightParams>
//     with TickerProviderStateMixin {
//   final GlobalKey<AnimatedListState> animatedListKey =
//       GlobalKey<AnimatedListState>();

//   List<RecommendationReqBodySegment> segments = [];

//   List<SlidableController> _controllers = [];

//   int? error;

//   Map<String, dynamic> passParams = {"adt": 1, "klass": "a"};

//   String klass = "a";

//   int passengerCount = 1;

//   @override
//   void initState() {
//     error = widget.errorIndex;
//     segments = widget.multiwaySegments;
//     _controllers =
//         List.generate(segments.length, (_) => SlidableController(this));
//     super.initState();
//   }

//   void _removeSegment(int index) {
//     animatedListKey.currentState
//         ?.removeItem(index, (context, animation) => const SizedBox.shrink());
//     segments.removeAt(index);
//     _controllers =
//         List.generate(segments.length, (_) => SlidableController(this));
//     setState(() {});
//     widget.callBack(segments);
//   }

//   void _addSegment() {
//     segments.add(RecommendationReqBodySegment());
//     animatedListKey.currentState?.insertItem(segments.length - 1);
//     _controllers.add(SlidableController(this));
//     setState(() {});
//     widget.callBack(segments);
//   }

//   @override
//   void didUpdateWidget(covariant MultiwayFlightParams oldWidget) {
//     error = widget.errorIndex;
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         context.szBoxHeight16,
//         AnimatedList.separated(
//           removedSeparatorBuilder: (context, index, animation) =>
//               SizeTransition(
//             sizeFactor: animation,
//             child: context.szBoxHeight16,
//           ),
//           separatorBuilder: (context, index, animation) => SizeTransition(
//             sizeFactor: animation,
//             child: context.szBoxHeight16,
//           ),
//           key: animatedListKey,
//           initialItemCount: segments.length,
//           physics: NeverScrollableScrollPhysics(),
//           padding: EdgeInsets.zero,
//           shrinkWrap: true,
//           itemBuilder: (context, index, animation) {
//             return Slidable(
//               key: GlobalKey(),
//               controller: _controllers[index],
//               enabled: segments.length > 1,
//               endActionPane: ActionPane(
//                 motion: const ScrollMotion(),
//                 extentRatio: 0.25,
//                 children: [
//                   context.szBoxWidth8,
//                   Expanded(
//                     child: InkWell(
//                       onTap: () => _removeSegment(index),
//                       child: SizedBox(
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                               color: ProjectTheme.redBgLight,
//                               borderRadius: BorderRadius.circular(8.0)),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child:
//                                     SvgPicture.asset(ProjectAssets.trashIcon),
//                               ),
//                               Text(
//                                 "delete".tr(),
//                                 style: context.textTheme.titleSmall?.copyWith(
//                                     fontSize: 14, color: ProjectTheme.error),
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//               child: Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   SizeTransition(
//                     sizeFactor: animation,
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 64,
//                       child: DecoratedBox(
//                         decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8.0),
//                             border: error == index
//                                 ? context.boxErrorBorder
//                                 : context.boxBorder),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 8.0, horizontal: 16.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               IntrinsicHeight(
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                         child: InkWell(
//                                       onTap: () async {
//                                         final airPortsModel =
//                                             await ProjectDialogs
//                                                 .showCitySearchPicker(
//                                                     context, 0);
//                                         if (airPortsModel != null) {
//                                           setState(() {
//                                             segments[index].from =
//                                                 airPortsModel;
//                                             widget.callBack(segments);
//                                           });
//                                         }
//                                       },
//                                       child: Visibility(
//                                           replacement: Align(
//                                             alignment: Alignment.center,
//                                             child: Text(
//                                               "from".tr(),
//                                               style: context
//                                                   .textTheme.headlineMedium
//                                                   ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.w500),
//                                             ),
//                                           ),
//                                           visible: segments[index].from != null,
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 segments[index]
//                                                         .from
//                                                         ?.cityIataCode ??
//                                                     "",
//                                                 style: context
//                                                     .textTheme.bodyMedium,
//                                               ),
//                                               Text(
//                                                 segments[index]
//                                                         .from
//                                                         ?.cityName ??
//                                                     "",
//                                                 style: context
//                                                     .textTheme.headlineSmall,
//                                               ),
//                                             ],
//                                           )),
//                                     )),
//                                     Padding(
//                                       padding: context.k16horizontalPadding,
//                                       child: Icon(
//                                         Icons.adaptive.arrow_forward,
//                                         color: ProjectTheme.borderLight,
//                                       ),
//                                     ),
//                                     Expanded(
//                                         child: InkWell(
//                                       onTap: () async {
//                                         final airPortsModel =
//                                             await ProjectDialogs
//                                                 .showCitySearchPicker(
//                                                     context, 1);
//                                         if (airPortsModel != null) {
//                                           setState(() {
//                                             segments[index].to = airPortsModel;
//                                             widget.callBack(segments);
//                                           });
//                                         }
//                                       },
//                                       child: Visibility(
//                                           replacement: Align(
//                                             alignment: Alignment.center,
//                                             child: Text(
//                                               "to".tr(),
//                                               style: context
//                                                   .textTheme.headlineMedium
//                                                   ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.w500),
//                                             ),
//                                           ),
//                                           visible: segments[index].to != null,
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 segments[index]
//                                                         .to
//                                                         ?.cityIataCode ??
//                                                     "",
//                                                 style: context
//                                                     .textTheme.bodyMedium,
//                                               ),
//                                               Text(
//                                                 segments[index].to?.cityName ??
//                                                     "",
//                                                 style: context
//                                                     .textTheme.headlineSmall,
//                                               ),
//                                             ],
//                                           )),
//                                     )),
//                                     context.szBoxWidth8,
//                                     VerticalDivider(
//                                         thickness: 1,
//                                         color: ProjectTheme.borderLight),
//                                     context.szBoxWidth8,
//                                     Expanded(
//                                         child: InkWell(
//                                       onTap: () async {
//                                         final date = await ProjectDialogs
//                                             .showCalendartPicker(
//                                                 context,
//                                                 0,
//                                                 PickerDateRange(
//                                                     segments[index].getDateTime,
//                                                     null),
//                                                 segments[index].from,
//                                                 segments[index].to);
//                                         if (date != null) {
//                                           setState(() {
//                                             segments[index].date = date
//                                                 .startDate?.formattedDotDate;
//                                             widget.callBack(segments);
//                                           });
//                                         }
//                                       },
//                                       child: Visibility(
//                                           replacement: Align(
//                                             alignment: Alignment.center,
//                                             child: Text(
//                                               "depDate".tr(),
//                                               style: context
//                                                   .textTheme.headlineMedium
//                                                   ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.w500),
//                                             ),
//                                           ),
//                                           visible: segments[index].date != null,
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 ElementFormatter.formatDate(
//                                                     segments[index].date ?? ""),
//                                                 style: context
//                                                     .textTheme.bodyMedium,
//                                               ),
//                                               Text(
//                                                 ElementFormatter.getWeekDay(
//                                                     segments[index].date ?? ""),
//                                                 style: context
//                                                     .textTheme.headlineSmall,
//                                               ),
//                                             ],
//                                           )),
//                                     )),
//                                   ],
//                                 ),
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (segments.length > 1)
//                     Positioned(
//                         top: -5,
//                         right: -5,
//                         child: InkWell(
//                           onTap: () {
//                             _controllers[index].openEndActionPane();
//                           },
//                           child: Icon(
//                             Icons.cancel,
//                             color: ProjectTheme.error,
//                           ),
//                         ))
//                 ],
//               ),
//             );
//           },
//         ),
//         context.szBoxHeight16,
//         TextButton(
//             onPressed: () => _addSegment(), child: Text("add_race".tr())),
//         context.szBoxHeight16,
//         InkWell(
//           onTap: () async {
//             final res =
//             await ProjectDialogs.showPassengerCountPicker(context, passParams);
//             if (res != null) {
//                       passParams = res;
//                       setState(() {
//                         final int adt = passParams['adt'];
//                         final int chd = passParams['chd'];
//                         final int inf = passParams['inf'];
//                         klass = passParams['klass'];
//                         passengerCount = adt + chd + inf;
//                       });
//                       // widget.passengerParams(passParams);
//                     }
//           },
//           borderRadius: BorderRadius.circular(8),
//           child: SizedBox(
//             height: 64,
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                   color: context.color.primaryContainer,
//                   borderRadius: BorderRadius.circular(8),
//                   border: context.boxBorder),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(passengerCount > 1
//                               ? "passengers_count"
//                                   .tr(namedArgs: {"count": "$passengerCount"})
//                               : "passenger_count".tr()),
//                           Text(_getKlass(),
//                               style: context.textTheme.headlineSmall)
//                         ]),
//                     Center(
//                         child: SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: SvgPicture.asset(ProjectAssets.usersIcon))),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   /// e - эконом класс, b - бизнес класс, f - первый класс, w - комфорт, a - все классы
//   String _getKlass() {
//     switch (klass) {
//       case "e":
//         return "klass_e".tr();
//       case "b":
//         return "klass_b".tr();
//       case "f":
//         return "klass_f".tr();
//       case "w":
//         return "klass_w".tr();
//       case "a":
//         return "klass_a".tr();
//       default:
//         return "Noma'lum klass";
//     }
//   }
// }
