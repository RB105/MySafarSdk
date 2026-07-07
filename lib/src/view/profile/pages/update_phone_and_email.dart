// ignore_for_file: void_checks, unnecessary_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/widgets/county_pick/country_code_picker.dart';
import 'package:mysafar_sdk/src/core/widgets/county_pick/src/country_code_model.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class UpdatePhoneAndEmailPage extends StatefulWidget {
  final ProfileModel profileModel;
  const UpdatePhoneAndEmailPage({super.key, required this.profileModel});
  static const String routeName = "/phoneAndEmail";

  @override
  State<UpdatePhoneAndEmailPage> createState() =>
      _UpdatePhoneAndEmailPageState();
}

class _UpdatePhoneAndEmailPageState extends State<UpdatePhoneAndEmailPage> {
  Map<String, dynamic>? country;
  String gender = "M";
  bool showErrors = false;
  late final PassengerController controllers;
  bool hasChanges = false;
  bool isDelete = false;
  String phoneNumber = "";

  late final Map<String, dynamic> initialData;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumController = TextEditingController();
  @override
  void initState() {
    super.initState();
    controllers = PassengerController();
    final user = widget.profileModel;

    emailController.text = user.email ?? "";

    final rawPhone = (user.phoneNumber ?? '').replaceAll(' ', '');

    final matched = codes.firstWhere(
      (e) => rawPhone.startsWith(e["country_code"] ?? ""),
      orElse: () => {},
    );

    final dialCode = matched["country_code"] ?? '998';
    final isoCode = matched["iso_code"] ?? 'UZ';
    final countryName = matched["country_name"] ?? 'Uzbekistan';
    final phoneMask = matched["phone_mask"] ?? 'XX XXX XX XX';

    countryCode = CountryCode(
      name: countryName,
      code: isoCode,
      dialCode: dialCode,
      phone_format: phoneMask,
    );

    final cleanPhone = rawPhone.startsWith(dialCode)
        ? rawPhone.substring(dialCode.length)
        : rawPhone;

    final formatter = MaskTextFormatter.phone_num_formatter;
    formatter.updateMask(
      mask: phoneMask,
      filter: {"X": RegExp(r'[0-9]')},
    );
    formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: cleanPhone),
    );
    phoneNumController.text = formatter.getMaskedText();

    initialData = {
      "email": emailController.text,
      "phone_number": phoneNumController.text,
    };

    emailController.addListener(_checkForChanges);
    phoneNumController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final currentData = {
      "email": emailController.text.trim(),
      "phone_number": phoneNumController.text.trim(),
    };

    setState(() {
      hasChanges = currentData.entries.any(
        (entry) => entry.value != initialData[entry.key],
      );
    });
  }

  @override
  void dispose() {
    emailController.removeListener(_checkForChanges);
    phoneNumController.removeListener(_checkForChanges);

    phoneNumController.dispose();
    emailController.dispose();

    super.dispose();
  }

  String? validateForm() {
    if (emailController.text.trim().isEmpty) {
      return "Email kiritilmadi";
    }
    if (phoneNumController.text.trim().isEmpty) {
      return "Phone kiritilmadi";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersDataCubit(),
      child: BlocConsumer<UsersDataCubit, UsersDataState>(
        listener: (context, state) {
          if (state is UsersDataLoadingState) {
            if (isDelete) {
              ProjectDialogs.showDeleteDialog(context);
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }

          if (state is UsersDataCreateState) {
            ProjectDialogs.showCustomBottomSheet(context, onConfirm: clearForm);
          } else if (state is UsersDataErrorState) {
            ResponseState.errorState(state.error, context);
          }
        },
        builder: (context, state) {
          return SafeArea(
            top: Platform.isAndroid,
            bottom: Platform.isAndroid,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  "Aloqa ma'lumotlarim",
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    clearForm();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.color.primaryContainer,
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
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomInputField(
                                    showError: showErrors,
                                    textInputAction: TextInputAction.done,
                                    textCapitalization: TextCapitalization.none,
                                    keyboardType: TextInputType.emailAddress,
                                    controller: emailController,
                                    label: "email".tr(),
                                    onChanged: (value) {
                                      _checkForChanges();
                                    },
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "enter_email_address".tr();
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomInputField(
                                    showError: showErrors,
                                    textInputAction: TextInputAction.done,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    controller: phoneNumController,
                                    label: "phone".tr(),
                                    onChanged: (value) {
                                      _checkForChanges();
                                      phoneNumber =
                                          "${countryCode.dialCode}${MaskTextFormatter.phone_num_formatter.getUnmaskedText()}";
                                    },
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "enter_full_phone_number".tr();
                                      } else {
                                        return null;
                                      }
                                    },
                                    perfex: CountryCodePicker(
                                      dialogBackgroundColor:
                                          context.color.primaryContainer,
                                      textStyle: context.textTheme.bodyMedium,
                                      onChanged: (CountryCode code) {
                                        updateMask(code);
            
                                        setState(() {});
                                      },
                                    ),
                                    inputFormatters: [
                                      MaskTextFormatter.phone_num_formatter
                                    ],
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ))),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (hasChanges && validateForm() == null)
                        ? () {
                            final errorMessage = validateForm();
                            if (errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              setState(() {
                                showErrors = true;
                              });
                              return;
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectTheme.brandColor,
                      disabledBackgroundColor:
                          ProjectTheme.brandColor.withAlpha(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Ma’lumotlarni saqlash",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  CountryCode countryCode = CountryCode(
    name: 'Uzbekistan',
    code: 'UZ',
    dialCode: '998',
    phone_format: 'XX XXX XX XX',
  );
  void updateMask(CountryCode code) {
    countryCode = code;

    MaskTextFormatter.phone_num_formatter.updateMask(
      mask: code.phone_format,
      filter: {"X": RegExp(r'[0-9]')},
    );

    phoneNumController.clear();

    setState(() {
      phoneNumber = code.dialCode ?? '';
    });
  }

  void clearForm() {
    setState(() {
      controllers.firstnameController.clear();
      controllers.lastnameController.clear();
      showErrors = false;
      hasChanges = false;
    });
  }
}

class MaskTextFormatter {
  static MaskTextInputFormatter phone_num_formatter = MaskTextInputFormatter(
    filter: {"X": RegExp(r'[0-9]')},
    mask: 'XX XXX XX XX',
    type: MaskAutoCompletionType.lazy,
  );
}
