// import 'package:flutter_mrz_scanner/flutter_mrz_scanner.dart';
// import 'package:lottie/lottie.dart';
// import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
// import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
// import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class ScanPage extends StatefulWidget {
//   const ScanPage({super.key});
//
//   @override
//   State<ScanPage> createState() => _ScanPageState();
// }
//
// class _ScanPageState extends State<ScanPage> {
//   bool isParsed = false;
//   MRZController? controller;
//   bool hasPermission = false;
//
//   Future<void> _checkCameraPermission() async {
//     final status = await Permission.camera.status;
//     if (status.isGranted) {
//       setState(() => hasPermission = true);
//     } else {
//       final result = await Permission.camera.request();
//       if (result.isGranted) {
//         setState(() => hasPermission = true);
//       }
//     }
//   }
//
//   @override
//   void initState() {
//     _checkCameraPermission();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('document_scanner'.tr()),
//       ),
//       body: Column(
//         children: [
//           context.szBoxHeight16,
//           Text("scan_instruction".tr(),
//               textAlign: TextAlign.center,
//               style: context.textTheme.displayMedium),
//           SizedBox(
//             width: double.infinity,
//             height: context.height * 0.2,
//             child: Lottie.asset(ProjectAssets.documentAnimation, repeat: true),
//           ),
//           context.szBoxHeight16,
//           Expanded(
//             child: hasPermission
//                 ? MRZScanner(
//                     withOverlay: true,
//                     onControllerCreated: onControllerCreated,
//                   )
//                 : Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         openAppSettings();
//                       },
//                       child: Text("allow_camera".tr()),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     controller?.stopPreview();
//     super.dispose();
//   }
//
//   void onControllerCreated(MRZController controller) async {
//     this.controller = controller;
//     controller.onParsed = (result) async {
//       if (isParsed) {
//         return;
//       }
//       isParsed = true;
//       ProjectDialogs.showLoader(context);
//       Future.delayed(
//         Duration(milliseconds: 1500),
//         () {
//           ProjectDialogs.dismissCurrentDialog();
//           // ignore: use_build_context_synchronously
//           Navigator.of(context).pop(result);
//         },
//       );
//     };
//     controller.onError = (error) => debugPrint(error);
//
//     if (hasPermission) {
//       controller.startPreview();
//     }
//   }
// }
