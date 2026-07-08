import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/cubit/ban_chek/uz_ban_check_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/ban_register/widget/container_column_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';

class UzBanRegisterPage extends StatefulWidget {
  static const routName = "/uzBanRegister";
  const UzBanRegisterPage({super.key});

  @override
  State<UzBanRegisterPage> createState() => _UzBanRegisterPageState();
}

class _UzBanRegisterPageState extends State<UzBanRegisterPage> {
  late TextEditingController controller;
  late TextEditingController jshircontroller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    jshircontroller = TextEditingController();
    controller.addListener(_updateButtonState);
    jshircontroller.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    controller.dispose();
    jshircontroller.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    final passportUnmasked =
    controller.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final jshshirUnmasked =
    jshircontroller.text.replaceAll(RegExp(r'[^0-9]'), '');

    return passportUnmasked.length == 9 && jshshirUnmasked.length == 14;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UzBanCheckCubit(),
      child: BlocConsumer<UzBanCheckCubit, UzBanCheckState>(
        listener: (context, state) {
          if (state is UzBanCheckSuccessState) {
            if (state.data["result"]["result"] == null) {
              showCustomBottomSheet(context);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(title: Text("exit_from_uzbekistan".tr())),
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:SingleChildScrollView(
                  child: Column(
                  children: [
                    ContainerColumnWidget(
                      title: "check_exit_possibility".tr(),
                      imege: Assets.homeExitUzb,
                    ),
                    context.szBoxHeight16,
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: context.shadowDown,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CustomInputField(
                              inputFormatters: [
                                UpperCaseTextFormatter(),
                                MaskTextFormatter.passportNumberFormatter
                              ],
                              label: "passport_or_id_info".tr(),
                              controller: controller,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              showError: false,
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                            context.szBoxHeight12,
                            CustomInputField(
                              inputFormatters: [
                                MaskTextFormatter.jshshirFormatter
                              ],
                              keyboardType: TextInputType.number,
                              label: "jshshir_pinfl_info".tr(),
                              controller: jshircontroller,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              showError: false,
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ),
            floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor:
                    ProjectTheme.brandColor.withAlpha(40),
                    backgroundColor: ProjectTheme.brandColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isFormValid &&state is! UzBanCheckLoadingState
                      ? () {
                    context.read<UzBanCheckCubit>().getUzBanChek({
                      "passport_sn": MaskTextFormatter
                          .passportNumberFormatter
                          .getUnmaskedText()
                          .substring(0, 2),
                      "passport_num": MaskTextFormatter
                          .passportNumberFormatter
                          .getUnmaskedText()
                          .substring(2),
                      "sender_pinfl": MaskTextFormatter.jshshirFormatter
                          .getMaskedText()
                    });
                  }
                      : null,
                  child: state is UzBanCheckLoadingState
                      ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    "check".tr(),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MaskTextFormatter {
  static MaskTextInputFormatter passportNumberFormatter =
  MaskTextInputFormatter(
    mask: 'AA #######',
    type: MaskAutoCompletionType.lazy,
    filter: {
      'A': RegExp(r'[A-Za-z]'),
      '#': RegExp(r'[0-9]'),
    },
  );

  static MaskTextInputFormatter jshshirFormatter = MaskTextInputFormatter(
    mask: "##############", // 14 ta #
    type: MaskAutoCompletionType.lazy,
    filter: {
      '#': RegExp(r'[0-9]'),
    },
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final upperText = newValue.text.toUpperCase();
    return TextEditingValue(
      text: upperText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

void showCustomBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 64),
        child: Container(
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "successfully_confirmed".tr(),
                  style: context.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  "can_leave_freely".tr(),
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectTheme.brandColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "understand_close".tr(),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}