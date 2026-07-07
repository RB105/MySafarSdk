import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/visa/myid_verification_page.dart';

class OrderingVisaCardPage extends StatelessWidget {
  static const routName = "/visaCardOrder";
  final String? deliveryAddress;

  const OrderingVisaCardPage({super.key, this.deliveryAddress});

  @override
  Widget build(BuildContext context) {
    return MyIdVerificationPage(
      appBarTitle: "visa_order_title".tr(),
      bannerTitle: "visa_order_subtitle".tr(),
      bannerImage: ProjectAssets.visaBronPerson,
    );
  }
}