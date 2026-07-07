/*
 * Rustam Abdirakhmonov(c) 2024-8-28. 11:16 Toshkent , Uzbekistan
 *
 */


// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/const_measures.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/extension/get_default_size.dart';
import 'package:mysafar_sdk/src/core/widgets/separator.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/tickets/horizantolly_animation.dart';

class MySafarTicketShimmer extends StatelessWidget {
  const MySafarTicketShimmer({super.key, required this.isReturn});

  final bool isReturn;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        padding: EdgeInsets.only(top: context.kPadding16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3, // Limit shimmer items for better performance
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: Container(
              margin: EdgeInsets.only(bottom: context.k16VSpace),
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: context.k16HSpace,
                vertical: context.k12VSpace,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SingleItem(),
                  if (isReturn) SizedBox(height: context.k12VSpace),
                  if (isReturn) const _SingleItem(),
                  SizedBox(height: context.k12VSpace),
                  SizedBox(
                    width: context.width * .34,
                    child: const ShimmerWidget(height: 20),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SingleItem extends StatelessWidget {
  const _SingleItem();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
          width: context.width * .24,
          child: ShimmerWidget(
            height: 20,
          ),
        ),
        SizedBox(
          height: context.k12VSpace,
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ShimmerWidget(
                    height: 20,
                  ),
                  const SizedBox(height: 2),
                  ShimmerWidget(
                    height: 18,
                  ),
                  const SizedBox(height: 2),
                  ShimmerWidget(
                    height: 16,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: context.k8HSpace,
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerWidget(
                    height: 14,
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(Assets.mySafarDots),
                          Expanded(
                              child: MySeparator(
                            color: context.theme.hintColor,
                          )),
                          SvgPicture.asset(Assets.mySafarDots),
                        ],
                      ),
                      HorizontalLoopAnimation(child: SvgPicture.asset(Assets.mySafarAirplaneAltRed,height: 28,))
                    ],
                  ),
                  const SizedBox(height: 4),
                  ShimmerWidget(
                    height: 14,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: context.k8HSpace,
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ShimmerWidget(
                    height: 20,
                  ),
                  const SizedBox(height: 2),
                  ShimmerWidget(
                    height: 18,
                  ),
                  const SizedBox(height: 2),
                  ShimmerWidget(
                    height: 16,
                  ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }
}
class ShimmerWidget extends StatelessWidget {
  final double? width;
  final double height;
  const ShimmerWidget({super.key, this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor,borderRadius: context.kRadius),
      width: width ?? double.infinity,
      height: height,
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
        blendMode: BlendMode.srcATop,

        duration: 4.seconds, angle: 45, colors: [
      Colors.grey[300]!,
      Colors.grey[100]!,
      Colors.grey[300]!,
    ]);
  }
}