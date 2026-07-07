import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart' show ProjectAssets;
import 'package:mysafar_sdk/src/cubit/profile/cheques/ofd_cheques_cubit.dart';
import 'package:mysafar_sdk/src/view/booking/support/payment_helper.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class OFDChequesPage extends StatelessWidget {
  const OFDChequesPage({super.key});
  static const String routeName = "/cheques";

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (context) => OfdChequesCubit(),
      child: Scaffold(
        appBar: AppBar(centerTitle: false, title: Text("my_cheques".tr())),
        body: BlocBuilder<OfdChequesCubit, OfdChequesState>(
          builder: (context, state) {
            final currencyProvider = Provider.of<CurrencyProvider>(context);
            switch (state) {
              case OfdChequesErrorState _:
                return Center(child: Text(state.error));
              case OfdChequesLoadingState _:
                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 5,
                  separatorBuilder: (context, index) => context.szBoxHeight16,
                  itemBuilder: (context, index) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade400,
                        highlightColor: const Color(0xff395A87),
                        child: Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                      context.szBoxHeight8,

                      // Card shimmer (same shape and padding as success card)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: context.shadowDown,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              // Order number section
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    shimmerLine(width: 80, height: 14),
                                    context.szBoxHeight8,
                                    shimmerLine(width: 100, height: 18),
                                  ],
                                ),
                              ),

                              // Amount section
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    shimmerLine(width: 60, height: 14),
                                    context.szBoxHeight8,
                                    shimmerLine(width: 100, height: 18),
                                  ],
                                ),
                              ),

                              // Download icon section
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey.shade400,
                                  highlightColor: const Color(0xff395A87),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              case OfdChequesEmptyState _:
                return Center(
                  child: Text("Sizda chek mavjud emas"),
                );
              case OfdChequesSuccesState _:
                return ListView.separated(
                    separatorBuilder: (context, index) => context.szBoxHeight12,
                    padding: EdgeInsets.all(16.0),
                    itemCount: state.cheques.length,
                    itemBuilder: (context, index) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  state.cheques[index].createdAt
                                      .formattedDotDate,
                                  style: context.textTheme.headlineSmall
                                      ?.copyWith(fontSize: 14.0)),
                              context.szBoxHeight8,
                              SizedBox(
                                  width: double.infinity,
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          boxShadow: context.shadowDown,
                                          color:
                                              context.color.primaryContainer),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 16.0),
                                        child: Row(children: [
                                          Expanded(
                                              flex: 4,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        "order_number_header"
                                                            .tr(),
                                                        style: context.textTheme
                                                            .headlineSmall
                                                            ?.copyWith(
                                                                fontSize:
                                                                    14.0)),
                                                    context.szBoxHeight8,
                                                    Text(
                                                        state.cheques[index]
                                                            .orderNumber,
                                                        style: context.textTheme
                                                            .displayMedium)
                                                  ])),
                                          Expanded(
                                              flex: 4,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text("sum_header".tr(),
                                                        style: context.textTheme
                                                            .headlineSmall
                                                            ?.copyWith(
                                                                fontSize:
                                                                    14.0)),
                                                    context.szBoxHeight8,
                                                    Text(
                                                        currencyProvider
                                                            .getPriceWithCurrency(
                                                                state
                                                                    .cheques[
                                                                        index]
                                                                    .amount
                                                                    .toString(),
                                                                state
                                                                    .cheques[
                                                                        index]
                                                                    .currency),
                                                        style: context.textTheme
                                                            .displayMedium)
                                                  ])),
                                          InkWell(
                                            onTap: () {
                                              PaymentHelper.openExternalUrl(
                                                  state.cheques[index].qrUrl);
                                            },
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color:
                                                      ProjectTheme.brandColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: Center(
                                                  child: SvgPicture.asset(
                                                    ProjectAssets
                                                        .downloadIconProfile,
                                                    height: 24,
                                                    width: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                      )))
                            ]));
              default:
                return SizedBox.shrink();
            }
          },
        ),
      ));

  Widget shimmerLine({double width = double.infinity, double height = 16.0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade400,
      highlightColor: const Color(0xff395A87),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
    );
  }
}
