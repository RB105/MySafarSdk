import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'
    show MaskAutoCompletionType, MaskTextInputFormatter;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/auth/logic/bloc/auth_cubit.dart';
import 'package:mysafar_sdk/src/view/auth/widget/auth_custom_input.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/cubit/profile/profile_cubit.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthPage({super.key, this.onAuthSuccess});

  static const String routeName = '/authPage';

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const String _dialCode = '998';
  static const String _phoneMask = '## ### ## ##';

  final _phoneFormatter = MaskTextInputFormatter(
    filter: {"#": RegExp(r'[0-9]')},
    mask: _phoneMask,
    type: MaskAutoCompletionType.lazy,
  );

  bool get _isPhoneNumberComplete {
    final unmaskedText = _phoneFormatter.getUnmaskedText();
    final mask = _phoneFormatter.getMask();
    final expectedDigitCount = mask?.replaceAll(RegExp(r'[^#]'), '').length;
    return unmaskedText.length == expectedDigitCount;
  }

  String get _fullPhoneNumber =>
      '$_dialCode${_phoneFormatter.getUnmaskedText()}';

  /// Login muvaffaqiyatli bo'lgach profilni serverdan olib keshga yozadi.
  /// Shu bilan bosh sahifa va profil sahifasi profilni darhol keshdan
  /// ko'rsatadi — login'dan keyin qo'lda refresh shart bo'lmaydi.
  Future<void> _cacheProfileAfterLogin() async {
    final cubit = ProfileCubit();
    try {
      await cubit.getProfileData(forceRefresh: true);
    } catch (_) {
      // Profil yuklanmasa ham login oqimi to'xtamaydi — sahifa keyin qayta
      // urinib ko'radi.
    } finally {
      await cubit.close();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => AuthCubit(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) async {
            if (state.googleAuthStatus == ActionStatus.isSuccess ||
                state.telegramAuthStatus == ActionStatus.isSuccess) {
              // Profilni serverdan olib keshga yozamiz — keyingi sahifalar uni
              // darhol keshdan ko'rsatadi (login'dan keyin qayta yuklash shart
              // emas).
              await _cacheProfileAfterLogin();
              if (!context.mounted) return;
              if (widget.onAuthSuccess != null) {
                widget.onAuthSuccess!();
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, BottomNavBarPage.routeName, (route) => false,
                    arguments: 0);
              }
            } else if (state.loginAuthStatus == ActionStatus.isSuccess) {
              final response = await ProjectDialogs.showVerifyOtpSheet(
                  context, _fullPhoneNumber, state.otpToken);
              if (response == true) {
                await _cacheProfileAfterLogin();
                if (!context.mounted) return;
                if (widget.onAuthSuccess != null) {
                  widget.onAuthSuccess!();
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context,
                      BottomNavBarPage.routeName,
                      (route) => false,
                      arguments: 0);
                }
              }
            } else if ((state.googleAuthStatus == ActionStatus.isError ||
                    state.telegramAuthStatus == ActionStatus.isError) &&
                state.authError.isNotEmpty) {
              _showErrorDialog(state.authError);
            } else if (state.loginAuthStatus == ActionStatus.isError &&
                state.authError.isNotEmpty) {
              _showErrorDialog(state.authError);
            }
          },
          builder: (context, state) {
            final isDark = context.themeProvider.isDark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? ProjectTheme.kStatusBarDark
                  : ProjectTheme.kStatusBarLight,
              child: SafeArea(
                child: Scaffold(
                    backgroundColor: isDark
                        ? ProjectTheme.backgroundDark
                        : ProjectTheme.backgroundLight,
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "close".tr(),
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: ProjectTheme.brandColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    body: Padding(
                        padding: context.k16Padding,
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),
                                  Text("login_to_profile".tr(),
                                      style: context
                                          .theme.textTheme.displayLarge
                                          ?.copyWith(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 16),
                                  Text("we_will_send_verification_code".tr(),
                                      style: context
                                          .theme.textTheme.displayLarge
                                          ?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400)),
                                  const SizedBox(height: 16),
                                  AuthCustomInputField(
                                    showError: false,
                                    textInputAction: TextInputAction.done,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    controller: _phoneController,
                                    label: "enter_phone_number".tr(),
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "enter_full_phone_number".tr();
                                      } else if (!_isPhoneNumberComplete) {
                                        return "please_enter_full_phone_number"
                                            .tr();
                                      }
                                      return null;
                                    },
                                    perfex: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 15, left: 12),
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
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  AnalyticsService()
                                                      .trackButtonTap(
                                                          'auth_phone_send_code');
                                                  context
                                                      .read<AuthCubit>()
                                                      .sendOtp(
                                                          _fullPhoneNumber);
                                                }
                                              }
                                            : null,
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              if (state.loginAuthStatus ==
                                                  ActionStatus.isLoading) ...[
                                                _adaptiveLoader(),
                                                context.szBoxWidth8,
                                              ],
                                              Text("send_code".tr(),
                                                  style: context
                                                      .theme.textTheme.bodyLarge
                                                      ?.copyWith(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                            ],
                                          ),
                                        )),
                                  ),
                                  // const SizedBox(height: 16),
                                  // SizedBox(
                                  //   height: 56,
                                  //   width: double.infinity,
                                  //   child: OutlinedButton(
                                  //     style: OutlinedButton.styleFrom(
                                  //       side: BorderSide(color: ProjectTheme.blueBg),
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(12),
                                  //       ),
                                  //     ),
                                  //     onPressed: state.telegramAuthStatus ==
                                  //             ActionStatus.isLoading
                                  //         ? null
                                  //         : () => context
                                  //             .read<AuthCubit>()
                                  //             .telegramSignIn(),
                                  //     child: Row(
                                  //       mainAxisAlignment: MainAxisAlignment.center,
                                  //       children: [
                                  //         if (state.telegramAuthStatus ==
                                  //             ActionStatus.isLoading) ...[
                                  //           _adaptiveLoader(color: ProjectTheme.blueBg),
                                  //           context.szBoxWidth8,
                                  //         ] else ...[
                                  //           Icon(
                                  //             Icons.telegram,
                                  //             size: 24,
                                  //             color: ProjectTheme.blueBg,
                                  //           ),
                                  //           context.szBoxWidth8,
                                  //         ],
                                  //         Text(
                                  //           'sign_telegram'.tr(),
                                  //           style: context.theme.textTheme.bodyLarge
                                  //               ?.copyWith(
                                  //             color: ProjectTheme.blueBg,
                                  //             fontSize: 16,
                                  //             fontWeight: FontWeight.w600,
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
                                  const SizedBox(height: 32),
                                ]),
                          ),
                        ))),
              ),
            );
          },
        ));
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(useRootNavigator: false, 
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
