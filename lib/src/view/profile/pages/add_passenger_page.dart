// ignore_for_file: void_checks

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/cubit/profile/users_data/users_data_cubit.dart';
import 'package:mysafar_sdk/src/view/booking/support/country_name_list.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/gender_button.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_controller.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class AddPassengerPage extends StatefulWidget {
  const AddPassengerPage({super.key});
  static const String routeName = "/addPassenger";

  @override
  State<AddPassengerPage> createState() => _AddPassengerPageState();
}

class _AddPassengerPageState extends State<AddPassengerPage> {
  Map<String, dynamic>? country;
  String gender = "M";
  bool showErrors = false;
  late final PassengerController controllers;
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    controllers = PassengerController();

    controllers.firstnameController.addListener(_checkFormValidity);
    controllers.lastnameController.addListener(_checkFormValidity);
    controllers.middlenameController.addListener(_checkFormValidity);
    controllers.birthdateController.addListener(_checkFormValidity);
    controllers.docnumController.addListener(_checkFormValidity);
    controllers.docexpController.addListener(_checkFormValidity);
  }

  @override
  void dispose() {
    controllers.firstnameController.removeListener(_checkFormValidity);
    controllers.lastnameController.removeListener(_checkFormValidity);
    controllers.middlenameController.removeListener(_checkFormValidity);
    controllers.birthdateController.removeListener(_checkFormValidity);
    controllers.docnumController.removeListener(_checkFormValidity);
    controllers.docexpController.removeListener(_checkFormValidity);

    controllers.firstnameController.dispose();
    controllers.lastnameController.dispose();
    controllers.middlenameController.dispose();
    controllers.birthdateController.dispose();
    controllers.docnumController.dispose();
    controllers.docexpController.dispose();
    super.dispose();
  }

  void _checkFormValidity() {
    setState(() {
      isFormValid = validateForm() == null;
    });
  }

  String? validateForm() {
    if (controllers.firstnameController.text.trim().isEmpty) {
      return "name_not_entered".tr();
    }
    if (controllers.lastnameController.text.trim().isEmpty) {
      return "surname_not_entered".tr();
    }
    if (controllers.middlenameController.text.trim().isEmpty) {
      return "father_name_not_specified".tr();
    }
    if (controllers.birthdateController.text.trim().isEmpty) {
      return "birth_date_not_entered".tr();
    }
    if (controllers.docnumController.text.trim().isEmpty) {
      return "passport_data_not_entered".tr();
    }
    if (controllers.docexpController.text.trim().isEmpty) {
      return "passport_validity_not_entered".tr();
    }
    if (gender.isEmpty) {
      return "gender_not_selected".tr();
    }
    if (country == null || country?["code"] == null) {
      return "citizenship_not_selected".tr();
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
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
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
                title: Text("add_info".tr()),
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context, isFormValid);
                    clearForm();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DecoratedBox(
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
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16, width: double.infinity),
                          InkWell(
                            onTap: () async {
                              final result =
                                  await showCitySearchPicker(context);
                              if (result != null) {
                                setState(() {
                                  country = result;
                                  _checkFormValidity();
                                });
                              }
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: context.height * 0.06,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 1.5,
                                    color: context.color.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        country == null
                                            ? "citizenship".tr()
                                            : getCountry(country?["code"] ??
                                                    "")["name"][dataLang()],
                                        style: country == null
                                            ? context.textTheme.headlineSmall
                                                ?.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              )
                                            : context.textTheme.bodyMedium
                                                ?.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: CustomInputField(
                              showError: showErrors,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.characters,
                              keyboardType: TextInputType.text,
                              controller: controllers.docnumController,
                              label: "passport_data".tr(),
                              onChanged: (value) {
                                _checkFormValidity();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "passport_data_not_entered".tr();
                                }
                                return null;
                              },
                            ),
                          ),
                          CustomInputField(
                            showError: showErrors,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.number,
                            controller: controllers.docexpController,
                            label: "passport_validity".tr(),
                            inputFormatters: [ProjectUtils.docexpFormatter],
                            onChanged: (value) {
                              _checkFormValidity();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "passport_validity_not_entered".tr();
                              }
                              return null;
                            },
                            suffix: IconButton(
                              onPressed: () {
                                _showDatePicker(
                                  isFutureOnly: true,
                                  controller: controllers.docexpController,
                                  onDateSelected: (DateTime selectedDate) {
                                    setState(() {
                                      controllers.docexpController.text =
                                          DateFormat('dd.MM.yyyy')
                                              .format(selectedDate);
                                      _checkFormValidity();
                                    });
                                  },
                                );
                              },
                              icon: Icon(Icons.calendar_month),
                            ),
                          ),
                          const SizedBox(height: 16, width: double.infinity),
                          CustomInputField(
                            showError: showErrors,
                            controller: controllers.firstnameController,
                            label: "first_name".tr(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "name_not_entered".tr();
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _checkFormValidity();
                            },
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: CustomInputField(
                              showError: showErrors,
                              controller: controllers.lastnameController,
                              label: "last_name".tr(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "surname_not_entered".tr();
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _checkFormValidity();
                              },
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          CustomInputField(
                            showError: showErrors,
                            controller: controllers.middlenameController,
                            label: "father".tr(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "father_name_not_specified".tr();
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _checkFormValidity();
                            },
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16, width: double.infinity),
                          CustomInputField(
                            showError: showErrors,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.number,
                            controller: controllers.birthdateController,
                            label: "birth_date".tr(),
                            inputFormatters: [ProjectUtils.birthdateFormatter],
                            onChanged: (value) {
                              _checkFormValidity();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "birth_date_not_entered".tr();
                              }
                              return null;
                            },
                            suffix: IconButton(
                              onPressed: () {
                                _showDatePicker(
                                  isFutureOnly: false,
                                  controller: controllers.birthdateController,
                                  initialDate: DateTime(1990, 1, 1),
                                  onDateSelected: (DateTime selectedDate) {
                                    setState(() {
                                      controllers.birthdateController.text =
                                          DateFormat('dd.MM.yyyy')
                                              .format(selectedDate);
                                      _checkFormValidity();
                                    });
                                  },
                                );
                              },
                              icon: Icon(Icons.calendar_month),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 16),
                            child: Text(
                              "gender".tr(),
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: context.themeProvider.isDark
                                  ? const Color(0xff838383).withAlpha(85)
                                  : const Color(0xffC6C7C9).withAlpha(35),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  GenderButton(
                                    label: "male".tr(),
                                    value: "M",
                                    isSelected: gender == "M",
                                    onPressed: () {
                                      setState(() {
                                        gender = "M";
                                        _checkFormValidity();
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  GenderButton(
                                    label: "female".tr(),
                                    value: "F",
                                    isSelected: gender == "F",
                                    onPressed: () {
                                      setState(() {
                                        gender = "F";
                                        _checkFormValidity();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isFormValid
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

                            final formattedBirthdate = convertDateFormat(
                                controllers.birthdateController.text.trim());
                            final formattedDocexp = convertDateFormat(
                                controllers.docexpController.text.trim());

                            if (formattedBirthdate == null ||
                                formattedDocexp == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("invalid_date_format".tr()),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              setState(() {
                                showErrors = true;
                              });
                              return;
                            }

                            context.read<UsersDataCubit>().createUser(
                              params: {
                                "firstname":
                                    controllers.firstnameController.text.trim(),
                                "lastname":
                                    controllers.lastnameController.text.trim(),
                                "middlename": controllers
                                    .middlenameController.text
                                    .trim(),
                                "birthdate": formattedBirthdate,
                                "docnum":
                                    controllers.docnumController.text.trim(),
                                "docexp": formattedDocexp,
                                "gender": gender,
                                "citizen": country!["code"],
                              },
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectTheme.brandColor,
                      disabledBackgroundColor:
                          ProjectTheme.brandColor.withAlpha(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "add_info".tr(),
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

  String? convertDateFormat(String inputDate) {
    try {
      final RegExp dateRegExp = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
      if (!dateRegExp.hasMatch(inputDate)) return null;

      final parts = inputDate.split('.');
      final day = parts[0];
      final month = parts[1];
      final year = parts[2];

      final parsedDate = DateTime.parse('$year-$month-$day');
      if (parsedDate.day != int.parse(day) ||
          parsedDate.month != int.parse(month) ||
          parsedDate.year != int.parse(year)) {
        return null;
      }

      return '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
    } catch (e) {
      return null;
    }
  }

  void clearForm() {
    setState(() {
      controllers.firstnameController.clear();
      controllers.lastnameController.clear();
      controllers.middlenameController.clear();
      controllers.birthdateController.clear();
      controllers.docnumController.clear();
      controllers.docexpController.clear();
      country = null;
      gender = "M";
      showErrors = false;
      isFormValid = false;
    });
  }

  void _showDatePicker({
    required TextEditingController? controller,
    DateTime? selectedDate,
    DateTime? initialDate,
    required bool isFutureOnly,
    required Function(DateTime) onDateSelected,
  }) {
    DateTime tempPickedDate = selectedDate ?? initialDate ?? DateTime.now();
    final today = DateTime.now();
    final todayOnlyDate = DateTime(today.year, today.month, today.day);
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoTheme.of(context).copyWith(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: context.textTheme.bodyMedium
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      initialDateTime: isFutureOnly
                          ? todayOnlyDate
                          : (initialDate ?? DateTime(1990, 1, 1)),
                      mode: CupertinoDatePickerMode.date,
                      minimumDate: isFutureOnly ? todayOnlyDate : null,
                      maximumDate: isFutureOnly ? null : todayOnlyDate,
                      onDateTimeChanged: (DateTime newDate) {
                        tempPickedDate = newDate;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ProjectTheme.blueButtonStyle,
                      onPressed: () {
                        controller?.text =
                            DateFormat('dd.MM.yyyy').format(tempPickedDate);
                        onDateSelected(tempPickedDate);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "apply".tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
