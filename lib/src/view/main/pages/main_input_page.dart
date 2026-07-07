import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/main/main_page.dart' show MainSearchForm;
import 'package:mysafar_sdk/src/view/main/pages/notification_page.dart';
import 'package:mysafar_sdk/src/view/main/src/floating_support_badge.dart';

/// Chipta qidiruvini alohida sahifa sifatida ochadi (notification/deeplink
/// orqali kirilganda). Qidiruv formasi bosh sahifadagi bilan bir xil —
/// umumiy [MainSearchForm] widgetidan foydalanadi. Bu sahifada forma
/// ochilishi bilan shahar tanlash oynalari avtomatik ochiladi.
class MainInputPage extends StatelessWidget {
  final bool isSmart;
  final AirPortsModel? nearbyAirport;
  const MainInputPage({super.key, required this.isSmart, this.nearbyAirport});

  static const routeName = "/mainInputPage";

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 4.0,
          shadowColor: Colors.black38,
          actions: [
            InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () =>
                    Navigator.of(context).pushNamed(NotificationPage.routeName),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    Assets.iconsNotificationIcon,
                    colorFilter: ColorFilter.mode(
                        context.theme.appBarTheme.iconTheme!.color!,
                        BlendMode.srcIn),
                  ),
                )),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => ProjectDialogs.showSupportMenu(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    Assets.iconsCallCenterIcon,
                    colorFilter: ColorFilter.mode(
                        context.theme.appBarTheme.iconTheme!.color!,
                        BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: MainSearchForm(
                    isSmart: isSmart,
                    nearbyAirport: nearbyAirport,
                    autoPromptDirections: true,
                  ),
                ),
              ),
            ),
            // The floating Support badge
            Positioned(
              bottom: context.height * 0.07,
              right: 0,
              child: const FloatingSupportBadge(),
            ),
          ],
        ),
      );
}
