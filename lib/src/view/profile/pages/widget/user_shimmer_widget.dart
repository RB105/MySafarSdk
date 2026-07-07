import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PassengerShimmer extends StatelessWidget {
  const PassengerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    Color baseColor = Colors.grey.shade300;
    Color highlightColor = Colors.grey.shade100;

    Widget shimmerBox({double height = 16, double width = 100}) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              shimmerBox(width: 140, height: 20),
              shimmerBox(width: 80, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerBox(width: 60, height: 12),
                  const SizedBox(height: 4),
                  shimmerBox(width: 100),
                  const SizedBox(height: 16),
                  shimmerBox(width: 60, height: 12),
                  const SizedBox(height: 4),
                  shimmerBox(width: 100),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerBox(width: 90, height: 12),
                  const SizedBox(height: 4),
                  shimmerBox(width: 120),
                  const SizedBox(height: 16),
                  shimmerBox(width: 90, height: 12),
                  const SizedBox(height: 4),
                  shimmerBox(width: 120),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
