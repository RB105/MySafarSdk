import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:shimmer/shimmer.dart';

class ContractDetailShimmer extends StatelessWidget {
  const ContractDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget bar({double height = 12, double width = 100, double radius = 6}) =>
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );

    Widget circle(double size) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
        );

    Widget roundBox(double size, {double radius = 12}) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );

    Widget amountCard() => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.shadowDown,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              roundBox(34, radius: 11),
              const SizedBox(height: 10),
              bar(width: 80, height: 10),
              const SizedBox(height: 6),
              bar(width: 100, height: 14),
            ],
          ),
        );

    Widget timelineRow() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              circle(24),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bar(width: 80, height: 12),
                            const SizedBox(height: 4),
                            bar(width: 60, height: 10),
                          ],
                        ),
                      ),
                      bar(width: 80, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: highlight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 10,
                              width: 80,
                              color: highlight,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 16,
                              width: 130,
                              color: highlight,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 80,
                        decoration: BoxDecoration(
                          color: highlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                          width: 120, height: 14, color: highlight),
                      const Spacer(),
                      Container(width: 40, height: 14, color: highlight),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Amounts
          Row(
            children: [
              Expanded(child: amountCard()),
              const SizedBox(width: 12),
              Expanded(child: amountCard()),
            ],
          ),
          const SizedBox(height: 16),
          // Product card
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(18),
                boxShadow: context.shadowDown,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        roundBox(40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(width: 160, height: 14),
                              const SizedBox(height: 6),
                              bar(width: 100, height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    timelineRow(),
                    timelineRow(),
                    timelineRow(),
                    timelineRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
