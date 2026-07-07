
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/ban_register/uz_ban_register.dart';
import 'package:mysafar_sdk/src/view/ban_register/widget/container_column_widget.dart';

class BanRegisterPage extends StatelessWidget {
  static const routName="/banRegister";
  const BanRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text("ban_list".tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ContainerColumnWidget(
              title: "check_restrictions_desc".tr(),
              imege: Assets.homeBanPlane,
            ),
            context.szBoxHeight16,
            BorderControlWidget()
          ],
        ),
      )
    );
  }
}

class BorderControlWidget extends StatelessWidget {
  const BorderControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       InkWell(
         borderRadius: BorderRadius.circular(16),
         onTap: ()=> Navigator.of(context).pushNamed(UzBanRegisterPage.routName),
         child:  _buildCard(
           context,
           image: Assets.homeExitUzb,
           title: "exit_uzbekistan".tr(),
           subtitle: "check_exit_restrictions".tr(),
           showArrow: true,
         ),
       ),
        const SizedBox(height: 16),
        _buildCard(
          context,
          image: Assets.homeEnterRu,
          title: "enter_russia".tr(),
          subtitle: "check_entry_status".tr(),
          showSoon: true,
        ),
      ],

    );
  }

  Widget _buildCard(BuildContext context, {
    required String image,
    required String title,
    required String subtitle,
    bool showArrow = false,
    bool showSoon = false,
  }) {
    return SizedBox(
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
                child: Row(
                  children: [
                    Image.asset(image, width: 50, height: 50),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          context.szBoxHeight12,
                          Text(
                            title,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showArrow) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            if (showSoon)
              Positioned(
                top: 28,
                right: -20,
                child: Transform.rotate(
                  angle: -0.8,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, right: 6),
                    child: Container(
                      width: 120,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'soon'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
