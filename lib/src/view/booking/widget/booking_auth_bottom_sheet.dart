import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/enum/status.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/view/auth/logic/bloc/auth_cubit.dart';
import 'package:mysafar_sdk/src/view/auth/widget/auth_custom_input.dart';
import 'package:pinput/pinput.dart';

Future<bool?> showBookingAuthBottomSheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) => DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, controller) => const BookingAuthBottomSheet(),
    ),
  );
}

class BookingAuthBottomSheet extends StatefulWidget {
  const BookingAuthBottomSheet({super.key});

  @override
  State<BookingAuthBottomSheet> createState() => _BookingAuthBottomSheetState();
}

class _BookingAuthBottomSheetState extends State<BookingAuthBottomSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFocusNode = FocusNode();

  static const String _dialCode = '998';
  static const String _phoneMask = '## ### ## ##';

  final _phoneFormatter = MaskTextInputFormatter(
    filter: {"#": RegExp(r'[0-9]')},
    mask: _phoneMask,
    type: MaskAutoCompletionType.lazy,
  );

  final ValueNotifier<int> _timerNotifier = ValueNotifier<int>(120);
  Timer? _timer;
  bool _timerStarted = false;

  bool _isOtpScreen = false;
  String _otpToken = '';
  bool _isGoogleErrorDialogShowing = false;

  bool get _isPhoneNumberComplete {
    final unmaskedText = _phoneFormatter.getUnmaskedText();
    final mask = _phoneFormatter.getMask();
    final expectedDigitCount = mask?.replaceAll(RegExp(r'[^#]'), '').length;
    return unmaskedText.length == expectedDigitCount;
  }

  String get _fullPhoneNumber =>
      '$_dialCode${_phoneFormatter.getUnmaskedText()}';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer?.cancel();
    _timerNotifier.value = 120;

    _timer = Timer.periodic(const Duration(seconds: 1), (timerTick) {
      if (_timerNotifier.value == 0) {
        _timerStarted = false;
        _otpController.clear();
        _timer?.cancel();
        setState(() {});
      } else {
        _timerNotifier.value--;
      }
    });
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length <= 7) return phone;
    String maskedPart = '*' * (phone.length - 7);
    return '${phone.substring(0, 3)} ${phone.substring(3, 5)} $maskedPart-${phone.substring(phone.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) {
          return previous.googleAuthStatus != current.googleAuthStatus ||
              previous.loginAuthStatus != current.loginAuthStatus ||
              previous.verifyStatus != current.verifyStatus;
        },
        listener: (context, state) async {
          if (state.loginAuthStatus == ActionStatus.isSuccess &&
              state.otpToken.isNotEmpty &&
              !_isOtpScreen) {
            setState(() {
              _isOtpScreen = true;
              _otpToken = state.otpToken;
            });
            _startTimer();
            return;
          }
          if (state.loginAuthStatus == ActionStatus.isError &&
              state.authError.isNotEmpty &&
              !_isOtpScreen) {
            await _showErrorDialog(state.authError);
            return;
          }

          if (state.verifyStatus == ActionStatus.isSuccess) {
            Navigator.of(context).pop(true);
            return;
          }
          if (state.verifyStatus == ActionStatus.isError &&
              state.verifyError.isNotEmpty) {
            await _showErrorDialog(state.verifyError);
            return;
          }

          if (state.googleAuthStatus == ActionStatus.isSuccess) {
            Navigator.of(context).pop(true);
            return;
          }
          if (state.googleAuthStatus == ActionStatus.isError &&
              state.authError.isNotEmpty &&
              !_isGoogleErrorDialogShowing) {
            _isGoogleErrorDialogShowing = true;
            await _showErrorDialog(state.authError);
            if (!context.mounted) return;
            _isGoogleErrorDialogShowing = false;
            context.read<AuthCubit>().resetGoogleAuthError();
            return;
          }
        },
        builder: (context, state) => SafeArea(
          bottom: Platform.isAndroid,
          top: Platform.isAndroid,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: context.themeProvider.isDark
                ? const Color(0xff1C1C1C)
                : context.color.primaryContainer,
            appBar: _buildAppBar(context),
            body: Padding(
              padding: context.k16Padding,
              child: _isOtpScreen
                  ? _buildOtpScreen(context, state)
                  : _buildPhoneScreen(context, state),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leadingWidth: 100,
      centerTitle: false,
      leading: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(56, 56),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          if (_isOtpScreen) {
            setState(() {
              _isOtpScreen = false;
              _otpController.clear();
              _timer?.cancel();
              _timerStarted = false;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Text(
          _isOtpScreen ? 'back'.tr() : 'close'.tr(),
          style: TextStyle(
            color: ProjectTheme.blueBg,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneScreen(BuildContext context, AuthState state) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'login_to_profile'.tr(),
              style: context.theme.textTheme.displayLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'we_will_send_verification_code'.tr(),
              style: context.theme.textTheme.displayLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            AuthCustomInputField(
              showError: false,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              controller: _phoneController,
              label: 'enter_phone_number'.tr(),
              onChanged: (value) => setState(() {}),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'enter_full_phone_number'.tr();
                } else if (!_isPhoneNumberComplete) {
                  return 'please_enter_full_phone_number'.tr();
                }
                return null;
              },
              perfex: Padding(
                padding: const EdgeInsets.only(top: 15, left: 12),
                child: Text('+$_dialCode'),
              ),
              inputFormatters: [_phoneFormatter],
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ProjectTheme.blueButtonStyle,
                onPressed: _isPhoneNumberComplete
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthCubit>().sendOtp(_fullPhoneNumber);
                        }
                      }
                    : null,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.loginAuthStatus == ActionStatus.isLoading) ...[
                        _adaptiveLoader(),
                        context.szBoxWidth8,
                      ],
                      Text(
                        'send_code'.tr(),
                        style: context.theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ProjectTheme.blueBg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: state.googleAuthStatus == ActionStatus.isLoading
                    ? null
                    : () => context.read<AuthCubit>().googleSignIn(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.googleAuthStatus == ActionStatus.isLoading) ...[
                      _adaptiveLoader(color: ProjectTheme.blueBg),
                      context.szBoxWidth8,
                    ] else ...[
                      SvgPicture.asset(
                        'assets/img/auth/google.svg',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                        ),
                      ),
                      context.szBoxWidth8,
                    ],
                    Text(
                      'sign_google'.tr(),
                      style: context.theme.textTheme.bodyLarge?.copyWith(
                        color: ProjectTheme.blueBg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpScreen(BuildContext context, AuthState state) {
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
            : const Color(0xffF2F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          context.szBoxHeight12,
          Text(
            'enter_confirmation_code'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          context.szBoxHeight16,
          Text(
            'we_sent_an_SMS_code_to_the_number'.tr(
              namedArgs: {'number': _formatPhoneNumber(_fullPhoneNumber)},
            ),
          ),
          context.szBoxHeight16,
          Center(
            child: Pinput(
              autofocus: true,
              controller: _otpController,
              length: 5,
              focusNode: _otpFocusNode,
              defaultPinTheme: defaultPinTheme,
              separatorBuilder: (index) => const SizedBox(width: 8),
              onCompleted: (pin) {
                if (pin.length == 5) {
                  context.read<AuthCubit>().verifyOtp(
                        phone: _fullPhoneNumber,
                        token: _otpToken,
                        otp: pin,
                      );
                  _otpFocusNode.unfocus();
                }
              },
              cursor: Container(
                width: 24,
                height: 2,
                color: const Color(0xFF0064FA),
              ),
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border:
                      Border.all(color: const Color(0xFF0064FA), width: 1.5),
                ),
              ),
              submittedPinTheme: defaultPinTheme,
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.redAccent),
                ),
              ),
            ),
          ),
          // Loading indicator
          if (state.verifyStatus == ActionStatus.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(child: _adaptiveLoader(color: ProjectTheme.blueBg)),
            ),
          // Error message
          if (state.verifyStatus == ActionStatus.isError)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  state.verifyError,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          context.szBoxHeight24,
          // Timer va qayta yuborish
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: _timerNotifier,
              builder: (context, seconds, _) {
                if (seconds > 0) {
                  final minutes = seconds ~/ 60;
                  final secs = seconds % 60;
                  return Text(
                    '${'resend_code_in'.tr()} ${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  );
                }
                return TextButton(
                  onPressed: state.loginAuthStatus == ActionStatus.isLoading
                      ? null
                      : () {
                          _otpController.clear();
                          context.read<AuthCubit>().sendOtp(_fullPhoneNumber);
                          _timerStarted = false;
                          _startTimer();
                        },
                  child: Text(
                    'resend_code'.tr(),
                    style: TextStyle(
                      color: ProjectTheme.blueBg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _adaptiveLoader({Color? color}) {
    return Platform.isIOS
        ? CupertinoActivityIndicator(radius: 10, color: color ?? Colors.white)
        : SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: color ?? Colors.white,
            ),
          );
  }
}
