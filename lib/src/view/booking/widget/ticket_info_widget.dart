import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
// import 'package:mysafar_sdk/src/core/tools/project_utils.dart';

class TicketInfoWidget extends StatelessWidget {
  const TicketInfoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "",
                      // params.firstSegmentTitle,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward),
                    ),
                    Text(
                      "",
                      // params.lastSegmentTitle,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  "",
                  // params.params,
                  style: TextStyle(
                    color: ProjectTheme.secondaryTextLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SvgPicture.asset("assets/img/booking/ticket_icon.svg",
                colorFilter: ColorFilter.mode(
                  context.theme.appBarTheme.iconTheme!.color!,
                  BlendMode.srcIn,
                )),
          ],
        ),
      ),
    );
  }
}
