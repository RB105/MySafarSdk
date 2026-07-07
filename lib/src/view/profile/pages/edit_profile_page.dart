import 'dart:io';

import 'package:mysafar_sdk/src/cubit/profile/update_profile/update_profile_cubit.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profileModel;

  const EditProfilePage({super.key, required this.profileModel});

  static const String routeName = "/editProfilePage";

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController middleNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  final _formKey = GlobalKey<FormState>();
  bool showErrors = false;

  @override
  void initState() {
    super.initState();
    firstNameController =
        TextEditingController(text: widget.profileModel.firstname ?? "");
    lastNameController =
        TextEditingController(text: widget.profileModel.lastname ?? "");
    middleNameController =
        TextEditingController(text: widget.profileModel.middlename ?? "");
    emailController =
        TextEditingController(text: widget.profileModel.email ?? "");
    phoneController =
        TextEditingController(text: widget.profileModel.phoneNumber ?? "");
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateProfileCubit(),
      child: BlocConsumer<UpdateProfileCubit, UpdateProfileState>(
        listener: (context, state) {
          if (state is UpdateProfileLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is UpdateProfileSuccess) {
            Navigator.pop(context);
            Navigator.pop(context, state.profileModel);
          } else if (state is UpdateProfileError) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: Text(
                'editProfile'.tr(),
                style: context.textTheme.displayLarge,
              ),
            ),
            body: SafeArea(
              top: Platform.isAndroid,
              bottom: Platform.isAndroid,
              child: SingleChildScrollView(
                padding: context.k16Padding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ism
                      CustomInputField(
                        controller: firstNameController,
                        label: "first_name".tr(),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        showError: showErrors,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "field_is_required_validator_text".tr();
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),

                      context.szBoxHeight16,

                      // Familiya
                      CustomInputField(
                        controller: lastNameController,
                        label: "last_name".tr(),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        showError: showErrors,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "field_is_required_validator_text".tr();
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),

                      context.szBoxHeight16,

                      // Otasining ismi
                      CustomInputField(
                        controller: middleNameController,
                        label: "father".tr(),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        showError: false,
                        keyboardType: TextInputType.name,
                        onChanged: (value) => setState(() {}),
                      ),

                      context.szBoxHeight16,

                      // Email
                      CustomInputField(
                        controller: emailController,
                        label: "email".tr(),
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.next,
                        showError: false,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => setState(() {}),
                      ),

                      context.szBoxHeight16,

                      // Telefon (faqat ko'rsatish uchun)
                      CustomInputField(
                        controller: phoneController,
                        label: "phone".tr(),
                        textCapitalization: TextCapitalization.none,
                        textInputAction: TextInputAction.done,
                        showError: false,
                        keyboardType: TextInputType.phone,
                      ),

                      context.szBoxHeight32,

                      // Saqlash tugmasi
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ProjectTheme.blueButtonStyle,
                          onPressed: () => _saveProfile(context),
                          child: Text(
                            "save".tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveProfile(BuildContext context) {
    setState(() => showErrors = true);

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      return;
    }

    final updatedProfile = widget.profileModel.copyWith(
      firstname: firstNameController.text.trim(),
      lastname: lastNameController.text.trim(),
      middlename: middleNameController.text.trim(),
      email: emailController.text.trim(),
      phoneNumber: phoneController.text.trim(),
    );

    BlocProvider.of<UpdateProfileCubit>(context).updateProfile(updatedProfile);
  }
}
