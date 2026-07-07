// part of '../main_page.dart';

// class RegularFlightParamsWidget extends StatefulWidget {
//   final int type;
//   final TopCityModel? topCity;
//   final PickerDateRange? pickerDateRange;
//   final Map<String, dynamic>? passParams;
//   final void Function(PickerDateRange dateRange) dateCallBack;
//   final void Function(Map<String, dynamic> params) passengerParams;
//   final void Function(AirPortsModel toDir) toDirectionCallBack;
//   final void Function(AirPortsModel fromDir) fromDirectionCallBack;
//   final void Function() switchCallBack;

//   const RegularFlightParamsWidget(
//       {super.key,
//       this.passParams,
//       required this.type,
//       required this.dateCallBack,
//       required this.passengerParams,
//       required this.switchCallBack,
//       required this.toDirectionCallBack,
//       required this.fromDirectionCallBack,
//       this.topCity,
//       required this.pickerDateRange});

//   @override
//   State<RegularFlightParamsWidget> createState() =>
//       _RegularFlightParamsWidgetState();
// }

// class _RegularFlightParamsWidgetState extends State<RegularFlightParamsWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   PickerDateRange? pickerDateRange;
//   Map<String, dynamic> passParams = {"adt": 1, "klass": "a"};
//   AirPortsModel? fromDir;
//   AirPortsModel? toDir;

//   String klass = "a";

//   int passengerCount = 1;
//   @override
//   void initState() {
//     pickerDateRange = widget.pickerDateRange;

//     updateByPopCity();
//     super.initState();
//     _controller = AnimationController(
//       reverseDuration: const Duration(milliseconds: 500),
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//   }

//   void _onPressed() {
//     if (_controller.isCompleted) {
//       widget.switchCallBack();
//       _controller.reverse();
//     } else {
//       _controller.forward();
//     }
//     setState(() {
//       final temp = fromDir;
//       fromDir = toDir;
//       toDir = temp;
//     });
//   }

//   @override
//   void didUpdateWidget(covariant RegularFlightParamsWidget oldWidget) {
//     if (widget.topCity != null && widget.topCity != oldWidget.topCity) {
//       updateByPopCity();
//     }
//     pickerDateRange = widget.pickerDateRange;
//     super.didUpdateWidget(oldWidget);
//   }

//   void updateByPopCity() {
//     if (widget.topCity != null) {
//       final city = widget.topCity;
//       fromDir = AirPortsModel(
//           cityName: city?.fromCityUz,
//           countryName: city?.countryFromUz,
//           cityIataCode: city?.fromIata);
//       toDir = AirPortsModel(
//           cityName: city?.toUz,
//           countryName: city?.countryToUz,
//           cityIataCode: city?.toIata);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Directions row
//         Padding(
//           padding: const EdgeInsets.only(top: 12, bottom: 12),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () async {
//                         final result =
//                             await ProjectDialogs.showCitySearchPicker(
//                                 context, 0);
//                         if (result != null) {
//                           setState(() {
//                             fromDir = result;
//                           });
//                           widget.fromDirectionCallBack(fromDir!);
//                         }
//                       },
//                       child: SizedBox(
//                         height: 64,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                               color: context.color.primaryContainer,
//                               borderRadius: BorderRadius.circular(8),
//                               border: context.boxBorder),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Visibility(
//                                   visible: fromDir != null,
//                                   replacement: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "from".tr(),
//                                         style: context.textTheme.headlineMedium,
//                                       ),
//                                       Text(
//                                         "validation_fill_field".tr(),
//                                         style: context.textTheme.bodySmall
//                                             ?.copyWith(
//                                                 color: ProjectTheme.error,
//                                                 fontWeight: FontWeight.w400),
//                                       )
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         fromDir?.cityName ?? "",
//                                         style: context.textTheme.bodyMedium,
//                                       ),
//                                       Text(
//                                         "${fromDir?.cityIataCode} • ${fromDir?.countryName}",
//                                         style: context.textTheme.headlineSmall,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     width: 12.0,
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () async {
//                         final result =
//                             await ProjectDialogs.showCitySearchPicker(
//                                 context, 1);
//                         if (result != null) {
//                           setState(() {
//                             toDir = result;
//                           });
//                           widget.toDirectionCallBack(toDir!);
//                         }
//                       },
//                       child: SizedBox(
//                         height: 64,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                               color: context.color.primaryContainer,
//                               borderRadius: BorderRadius.circular(8),
//                               border: context.boxBorder),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Visibility(
//                                   visible: toDir != null,
//                                   replacement: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       Text(
//                                         "to".tr(),
//                                         style: context.textTheme.headlineMedium,
//                                       ),
//                                       Text(
//                                         "validation_fill_field".tr(),
//                                         style: context.textTheme.bodySmall
//                                             ?.copyWith(
//                                                 color: ProjectTheme.error,
//                                                 fontWeight: FontWeight.w400),
//                                       )
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         toDir?.cityName ?? "",
//                                         style: context.textTheme.bodyMedium,
//                                       ),
//                                       Text(
//                                         "${toDir?.cityIataCode} • ${toDir?.countryName}",
//                                         style: context.textTheme.headlineSmall,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Positioned(
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(24),
//                   onTap: () {
//                     _onPressed();
//                   },
//                   child: RotationTransition(
//                     turns: _controller,
//                     child: SizedBox(
//                         width: 32,
//                         height: 32,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                             border: context.boxBorder,
//                             shape: BoxShape.circle,
//                             color: context.color.primaryContainer,
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(4.0),
//                             child: SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: SvgPicture.asset(ProjectAssets.rotateIcon),
//                             ),
//                           ),
//                         )),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         // Calendar and Passenger row
//         Visibility(
//           visible: widget.type == 0,
//           replacement: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () async {
//                         final res = await ProjectDialogs.showCalendartPicker(
//                             context,
//                             widget.type,
//                             pickerDateRange,
//                             fromDir,
//                             toDir);
//                         if (res != null) {
//                           setState(() {
//                             pickerDateRange = res;
//                           });
//                           widget.dateCallBack(pickerDateRange!);
//                         }
//                       },
//                       child: SizedBox(
//                         height: 64,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                               color: context.color.primaryContainer,
//                               borderRadius: BorderRadius.circular(8),
//                               border: context.boxBorder),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Visibility(
//                                   visible: pickerDateRange != null &&
//                                       pickerDateRange?.startDate != null,
//                                   replacement: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         "depDate".tr(),
//                                         style: context.textTheme.headlineMedium,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         "validation_fill_field".tr(),
//                                         style: context.textTheme.bodySmall
//                                             ?.copyWith(
//                                                 color: ProjectTheme.error,
//                                                 fontWeight: FontWeight.w400),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       )
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         "depDate".tr(),
//                                         style: context.textTheme.headlineSmall,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         pickerDateRange != null &&
//                                                 pickerDateRange?.startDate !=
//                                                     null
//                                             ? pickerDateRange!
//                                                 .startDate!.formattedDotDate
//                                             : "",
//                                         style: context.textTheme.bodyMedium,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 24,
//                                   height: 24,
//                                   child: SvgPicture.asset(
//                                       ProjectAssets.calendarIcon),
//                                 )
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   context.szBoxWidth12,
//                   Expanded(
//                     child: InkWell(
//                       onTap: () async {
//                         final res = await ProjectDialogs.showCalendartPicker(
//                             context,
//                             widget.type,
//                             pickerDateRange,
//                             fromDir,
//                             toDir);
//                         if (res != null) {
//                           setState(() {
//                             pickerDateRange = res;
//                           });
//                           widget.dateCallBack(pickerDateRange!);
//                         }
//                       },
//                       child: SizedBox(
//                         height: 64,
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                               color: context.color.primaryContainer,
//                               borderRadius: BorderRadius.circular(8),
//                               border: context.boxBorder),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 SizedBox(
//                                   width: 24,
//                                   height: 24,
//                                   child: SvgPicture.asset(
//                                       ProjectAssets.calendarIcon),
//                                 ),
//                                 Visibility(
//                                   visible: pickerDateRange != null &&
//                                       pickerDateRange?.endDate != null,
//                                   replacement: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     children: [
//                                       Text(
//                                         "arrDate".tr(),
//                                         style: context.textTheme.headlineMedium,
//                                       ),
//                                       Text(
//                                         "validation_fill_field".tr(),
//                                         style: context.textTheme.bodySmall
//                                             ?.copyWith(
//                                                 color: ProjectTheme.error,
//                                                 fontWeight: FontWeight.w400),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       )
//                                     ],
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.end,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         "arrDate".tr(),
//                                         style: context.textTheme.headlineSmall,
//                                       ),
//                                       Text(
//                                         pickerDateRange != null &&
//                                                 pickerDateRange?.endDate != null
//                                             ? pickerDateRange!
//                                                 .endDate!.formattedDotDate
//                                             : "",
//                                         style: context.textTheme.bodyMedium,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               context.szBoxHeight12,
//               InkWell(
//                 onTap: () async {
//                   final res = await ProjectDialogs.showPassengerCountPicker(
//                       context, passParams);

//                   if (res != null) {
//                     passParams = res;
//                     setState(() {
//                       final int adt = passParams['adt'];
//                       final int chd = passParams['chd'];
//                       final int inf = passParams['inf'];
//                       klass = passParams['klass'];
//                       passengerCount = adt + chd + inf;
//                     });
//                     widget.passengerParams(passParams);
//                   }
//                 },
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 64,
//                   child: DecoratedBox(
//                     decoration: BoxDecoration(
//                         color: context.color.primaryContainer,
//                         borderRadius: BorderRadius.circular(12),
//                         border: context.boxBorder),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16.0, vertical: 8.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(passengerCount > 1
//                                   ? "passengers_count".tr(
//                                       namedArgs: {"count": "$passengerCount"})
//                                   : "passenger_count".tr()),
//                               Text(
//                                 _getKlass(),
//                                 style: context.textTheme.headlineSmall,
//                               )
//                             ],
//                           ),
//                           Center(
//                             child: SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: SvgPicture.asset(ProjectAssets.usersIcon),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: () async {
//                     final res = await ProjectDialogs.showCalendartPicker(
//                         context, widget.type, pickerDateRange, fromDir, toDir);
//                     if (res != null) {
//                       setState(() => pickerDateRange = res);
//                       widget.dateCallBack(pickerDateRange!);
//                     }
//                   },
//                   child: SizedBox(
//                     height: 64,
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                           color: context.color.primaryContainer,
//                           borderRadius: BorderRadius.circular(8),
//                           border: context.boxBorder),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Visibility(
//                               visible: pickerDateRange != null &&
//                                   pickerDateRange?.startDate != null,
//                               replacement: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "depDate".tr(),
//                                     style: context.textTheme.headlineMedium,
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   Text(
//                                     "validation_fill_field".tr(),
//                                     style: context.textTheme.bodySmall
//                                         ?.copyWith(
//                                             color: ProjectTheme.error,
//                                             fontWeight: FontWeight.w400),
//                                   )
//                                 ],
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     pickerDateRange != null &&
//                                             pickerDateRange?.startDate != null
//                                         ? pickerDateRange!
//                                             .startDate!.formattedDotDate
//                                         : "",
//                                     style: context.textTheme.bodyMedium,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             SizedBox(
//                               width: 24,
//                               height: 24,
//                               child:
//                                   SvgPicture.asset(ProjectAssets.calendarIcon),
//                             )
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               context.szBoxWidth12,
//               Expanded(
//                 child: InkWell(
//                   onTap: () async {
//                     final res = await ProjectDialogs.showPassengerCountPicker(
//                         context, passParams);

//                     if (res != null) {
//                       passParams = res;
//                       setState(() {
//                         final int adt = passParams['adt'];
//                         final int chd = passParams['chd'];
//                         final int inf = passParams['inf'];
//                         klass = passParams['klass'];
//                         passengerCount = adt + chd + inf;
//                       });
//                       widget.passengerParams(passParams);
//                     }
//                   },
//                   child: SizedBox(
//                     height: 64,
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                           color: context.color.primaryContainer,
//                           borderRadius: BorderRadius.circular(8),
//                           border: context.boxBorder),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(passengerCount > 1
//                                     ? "passengers_count".tr(
//                                         namedArgs: {"count": "$passengerCount"})
//                                     : "passenger_count".tr()),
//                                 Text(
//                                   _getKlass(),
//                                   style: context.textTheme.headlineSmall,
//                                 )
//                               ],
//                             ),
//                             Center(
//                               child: SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child:
//                                     SvgPicture.asset(ProjectAssets.usersIcon),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
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
