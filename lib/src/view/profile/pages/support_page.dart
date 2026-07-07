// ignore_for_file: deprecated_member_use

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  static const String routeName = "SupportPage";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'support'.tr()),
      body: Padding(
        padding: context.k16Padding,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: mainDecoration(context),
                padding: context.k8Padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: context.k8Padding,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(context.radius12),
                              topLeft: Radius.circular(context.radius12),
                              topRight: Radius.circular(context.radius12)),
                          color: ProjectTheme.success.withOpacity(.2)),
                      child: Text('I need help, please.',
                          style: context.theme.textTheme.titleMedium
                              ?.copyWith(fontSize: 14)),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormFieldWidget(
              maxLines: 3,
              hintText: "input_text".tr(),
            ),
            SizedBox(height: 100)
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          MainButtonWidgetCustom(size: 64, title: 'send'.tr(), onTap: () {}),
    );
  }
}
