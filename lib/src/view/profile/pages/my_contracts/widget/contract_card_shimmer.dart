import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:shimmer/shimmer.dart';

class ContractsListShimmer extends StatelessWidget {
  final int itemCount;

  const ContractsListShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => const _ContractCardShimmer(),
    );
  }
}

class _ContractCardShimmer extends StatelessWidget {
  const _ContractCardShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final brand = ProjectTheme.brandColor;
    final headerTint = isDark ? brand.withAlpha(35) : brand.withAlpha(14);

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

    Widget roundBox(double size) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

    Widget infoLine() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              roundBox(36),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: bar(height: 10, width: 80)),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: bar(height: 12, width: 140),
                ),
              ),
            ],
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.shadowDown,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: headerTint,
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        children: [
                          circle(48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                bar(width: 80, height: 10),
                                const SizedBox(height: 6),
                                bar(width: 120, height: 14),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          bar(width: 70, height: 22, radius: 11),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              bar(width: 40, height: 12),
                              const Spacer(),
                              bar(width: 140, height: 10),
                            ],
                          ),
                          const SizedBox(height: 8),
                          bar(
                              height: 8,
                              width: double.infinity,
                              radius: 4),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          infoLine(),
                          Container(height: 1, color: base.withAlpha(80)),
                          infoLine(),
                          Container(height: 1, color: base.withAlpha(80)),
                          infoLine(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: bar(
                        height: 44,
                        width: double.infinity,
                        radius: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
