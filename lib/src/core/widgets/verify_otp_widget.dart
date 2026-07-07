import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart' show showToastMessage;
import 'package:mysafar_sdk/src/view/auth/logic/bloc/auth_cubit.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:pinput/pinput.dart';

class VerifyOtpWidget extends StatefulWidget {
  final String phone;
  final String otpToken;

  const VerifyOtpWidget(
      {super.key, required this.phone, required this.otpToken});

  @override
  State<VerifyOtpWidget> createState() => _VerifyOtpWidgetState();
}

class _VerifyOtpWidgetState extends State<VerifyOtpWidget> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool isValidOtp = false;

  final ValueNotifier<int> timerNotifier = ValueNotifier<int>(120);
  Timer? timer;
  bool timerStarted = false;

  void _startTimer() {
    if (timerStarted) return;
    timerStarted = true;
    timer?.cancel();
    timerNotifier.value = 120;

    timer = Timer.periodic(const Duration(seconds: 1), (timerTick) {
      if (timerNotifier.value == 0) {
        timerStarted = false;
        otpController.clear();
        timer?.cancel();
        if (mounted) setState(() {});
      } else {
        timerNotifier.value--;
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    otpController.dispose();
    timerNotifier.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _startTimer();
    super.initState();
  }

  String formatPhoneNumber(String phone) {
    if (phone.length <= 7) return phone;
    String maskedPart = '*' * (phone.length - 7);
    return '${phone.substring(0, 3)} ${phone.substring(3, 5)} $maskedPart-${phone.substring(phone.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: context.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: context.themeProvider.isDark
            ? context.theme.primaryColor
            : Color(0xffF2F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return BlocProvider(
        create: (context) => AuthCubit(),
        child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state.verifyStatus == ActionStatus.isSuccess) {
                Navigator.of(context).pop(true);
              } else if (state.verifyStatus == ActionStatus.isError) {
                showToastMessage(state.verifyError);
              }
            },
            builder: (context, state) => Scaffold(
                  backgroundColor: context.color.primaryContainer,
                  appBar: AppBar(
                    centerTitle: true,
                    leading: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: ProjectTheme.blueBg,
                        )),
                  ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: context.k16horizontalPadding,
                        child: Column(children: [
                          context.szBoxHeight12,
                          Text(
                            "enter_confirmation_code".tr(),
                            style: context.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          context.szBoxHeight16,
                          Text("we_sent_an_SMS_code_to_the_number".tr(
                              namedArgs: {
                                "number": formatPhoneNumber(widget.phone)
                              })),
                          context.szBoxHeight16,
                          Center(
                            child: Pinput(
                              autofocus: true,
                              controller: otpController,
                              length: 5,
                              focusNode: focusNode,
                              defaultPinTheme: defaultPinTheme,
                              separatorBuilder: (index) =>
                                  const SizedBox(width: 8),
                              onCompleted: (pin) {
                                if (pin.length == 5) {
                                  isValidOtp = true;
                                  setState(() {});
                                  context.read<AuthCubit>().verifyOtp(
                                      phone: widget.phone,
                                      token: widget.otpToken,
                                      otp: otpController.text);
                                  focusNode.unfocus();
                                } else {
                                  isValidOtp = false;
                                  setState(() {});
                                }
                              },
                              onChanged: (value) {
                                debugPrint('Changed: $value');
                              },
                              cursor: Container(
                                width: 24,
                                height: 2,
                                color: const Color(0xFF0064FA),
                              ),
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration:
                                    defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(
                                      color: const Color(0xFF0064FA),
                                      width: 1.5),
                                ),
                              ),
                              submittedPinTheme: defaultPinTheme,
                              errorPinTheme: defaultPinTheme.copyWith(
                                decoration:
                                    defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: Colors.redAccent),
                                ),
                              ),
                            ),
                          ),
                          if (otpController.text.length == 5 &&
                              (state.verifyStatus == ActionStatus.isError))
                            Padding(
                              padding: EdgeInsets.only(
                                top: 16,
                              ),
                              child: Text(state.verifyError,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.red)),
                            ),
                          context.szBoxHeight24,
                          SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ProjectTheme.blueButtonStyle,
                                onPressed: timerStarted
                                    ? null
                                    : () {
                                        otpController.text = "";
                                        _startTimer();
                                        context
                                            .read<AuthCubit>()
                                            .sendOtp(widget.phone);
                                      },
                                child: Center(
                                  child: state.verifyStatus ==
                                          ActionStatus.isLoading
                                      ? adaptiveLoader()
                                      : ValueListenableBuilder<int>(
                                          valueListenable: timerNotifier,
                                          builder: (context, value, child) {
                                            return Text.rich(
                                              TextSpan(
                                                children: [
                                                  if (value > 0) ...[
                                                    TextSpan(
                                                      text:
                                                          "resend_code_in".tr(),
                                                      style: context
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    TextSpan(text: " "),
                                                    TextSpan(
                                                      text:
                                                          "${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}",
                                                      style: context
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    WidgetSpan(
                                                      alignment:
                                                          PlaceholderAlignment
                                                              .middle,
                                                      child: Text(
                                                        "resend_code".tr(),
                                                        style: context.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ))
                        ]),
                      ),
                      Visibility(
                          visible:
                              state.loginAuthStatus == ActionStatus.isLoading,
                          child: AlertDialog.adaptive(
                            backgroundColor: context.color.primaryContainer,
                            content: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          )),
                    ],
                  ),
                )));
  }

  Widget adaptiveLoader() {
    return Platform.isIOS
        ? const CupertinoActivityIndicator(radius: 10, color: Colors.white)
        : const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          );
  }
}
