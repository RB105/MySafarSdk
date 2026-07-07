// ignore_for_file: use_build_context_synchronously

import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/dashedline.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/add_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/updated_passenger_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/user_shimmer_widget.dart';

class MyDataPage extends StatefulWidget {
  final ProfileModel? profileModel;
  const MyDataPage({super.key, required this.profileModel});
  static const String routeName = "/mydata";
  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "my_information".tr(),
          style: context.textTheme.bodyMedium
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      body: BlocProvider(
        create: (context) => UsersDataCubit(needGetUsers: true),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                children: [
                  Text(
                    "contact_info".tr(),
                    style: context.textTheme.bodyMedium
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Spacer()
                  // TextButton(
                  //     onPressed: () {
                  //       // Navigator.push(
                  //       //   context,
                  //       //   PageRouteBuilder(
                  //       //     transitionDuration:
                  //       //         const Duration(milliseconds: 400),
                  //       //     pageBuilder: (_, __, ___) =>
                  //       //         UpdatePhoneAndEmailPage(
                  //       //             profileModel: widget.profileModel!),
                  //       //     transitionsBuilder: (context, animation,
                  //       //         secondaryAnimation, child) {
                  //       //       final offsetAnimation = Tween<Offset>(
                  //       //         begin: const Offset(1.0, 0.0),
                  //       //         end: Offset.zero,
                  //       //       ).animate(animation);
                  //       //
                  //       //       return SlideTransition(
                  //       //         position: offsetAnimation,
                  //       //         child: child,
                  //       //       );
                  //       //     },
                  //       //   ),
                  //       // );
                  //     },
                  //     child: Text("change".tr(),
                  //         style: context.textTheme.bodyMedium?.copyWith(
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w400,
                  //             color: ProjectTheme.brandColor))),
                ],
              ),
              context.szBoxHeight12,
              Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.color.primaryContainer,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: context.themeProvider.isDark
                            ? Colors.transparent
                            : Color(0x80C6C7C9),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.profileModel?.email?.isNotEmpty ?? false) ...[
                          Text("${"email".tr()}:",
                              style: context.textTheme.headlineMedium?.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w400)),
                          Text(
                            widget.profileModel?.email ?? "",
                            style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(
                            height: 16,
                            width: double.infinity,
                          ),
                        ],
                        if (widget.profileModel?.phoneNumber?.isNotEmpty ?? false) ...[
                          Text("${"phone_number_label".tr()}:",
                              style: context.textTheme.headlineMedium?.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w400)),
                          Text(
                            widget.profileModel?.phoneNumber ?? "",
                            style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  "passenger_data_title".tr(),
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              BlocBuilder<UsersDataCubit, UsersDataState>(
                builder: (context, state) {
                  if (state is UsersDataLoadingState) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: context.themeProvider.isDark
                                      ? Colors.transparent
                                      : const Color(0x80C6C7C9),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                              color: context.color.primaryContainer,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                        5,
                                        (index) => const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: PassengerShimmer()))))));
                  }
                  if (state is UsersDataErrorState) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${"error_occurred".tr()}: ${state.error}"),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<UsersDataCubit>()
                                  .fetchFromServer();
                            },
                            child: Text("retry".tr()),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UsersDataEmptyState) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: context.themeProvider.isDark
                                      ? Colors.transparent
                                      : const Color(0x80C6C7C9),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                              color: context.color.primaryContainer,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: Lottie.asset(
                                      Assets.profileUtyanEmpty,
                                      height: 160,
                                      repeat: true,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  context.szBoxHeight16,
                                  Text(
                                    "no_passenger_info".tr(),
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            )));
                  }

                  if (state is UsersDataSuccessState) {
                    final List<UsersModel> passengers = state.usersModel;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: context.themeProvider.isDark
                                  ? Colors.transparent
                                  : const Color(0x80C6C7C9),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                          color: context.color.primaryContainer,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: passengers.length,
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 8,
                                    right: 16,
                                    bottom: 12,
                                  ),
                                  child: PassengerContainer(
                                    passenger: passengers[index],
                                  ),
                                ),
                                if (index != passengers.length - 1)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: DashedLine(color: Color(0xffDBDCDF)),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
              Builder(
                builder: (innerContext) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        innerContext,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 400),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const AddPassengerPage(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      ).then((value) {
                        if (value == true) {
                          innerContext.read<UsersDataCubit>().fetchFromServer();
                        }
                      });
                    },
                    child: Padding(padding: EdgeInsets.only(top: 16),child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ProjectTheme.brandColor)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 28,
                              color: ProjectTheme.brandColor,
                            ),
                            context.szBoxWidth8,
                            Text(
                              "add_new_passenger".tr(),
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: ProjectTheme.brandColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerContainer extends StatelessWidget {
  final UsersModel passenger;

  const PassengerContainer({
    super.key,
    required this.passenger,
  });

  @override
  Widget build(BuildContext context) {
    Brightness brightness = Theme.of(context).brightness;
    TextStyle labelStyle;
    if (brightness == Brightness.dark) {
      labelStyle = TextStyle(
        fontSize: 12,
        overflow: TextOverflow.ellipsis,
        color: Color(0xffCCCFD3),
      );
    } else {
      labelStyle = const TextStyle(
        fontSize: 12,
        overflow: TextOverflow.ellipsis,
        color: Color(0xff8E8E92),
      );
    }

    TextStyle? valueStyle = context.textTheme.bodyLarge
        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600);

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                "${passenger.firstname ?? ''} ${passenger.lastname ?? ''}",
                style: context.textTheme.bodyMedium
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              )),
              Builder(
                builder: (innerContext) {
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        innerContext,
                        UpdatedPassengerPage.routeName,
                        arguments: passenger,
                      ).then((value) {
                        if (value == true) {
                          innerContext.read<UsersDataCubit>().fetchFromServer();
                        }
                      });
                    },
                    child: Text(
                      "change".tr(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: ProjectTheme.brandColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${"citizenship".tr()}:", style: labelStyle),
                  Text(
                    getCountry(passenger.citizen ?? "")["name"][dataLang()],
                    style: valueStyle,
                  ),
                  const SizedBox(height: 12),
                  Text("${"birth_date".tr()}:", style: labelStyle),
                  Text(passenger.birthdate ?? '-', style: valueStyle),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${"passport_number".tr()}:", style: labelStyle),
                  Text(passenger.docnum ?? '-', style: valueStyle),
                  const SizedBox(height: 12),
                  Text("${"passport_validity".tr()}:", style: labelStyle),
                  Text(passenger.docexp ?? '-', style: valueStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
