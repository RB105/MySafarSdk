/*
 * Rustam Abdirakhmonov(c) 2024-7-26. 8:20 Toshkent , Uzbekistan
 *
 */

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';

class MySeparator extends StatelessWidget {
  const MySeparator({super.key, this.height = 1, this.color});
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: color ?? context.theme.hintColor),
              ),
            );
          }),
        );
      },
    );
  }
}
