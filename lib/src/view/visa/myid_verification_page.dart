// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/tools/project_assets.dart';
import 'package:mysafar_sdk/src/cubit/visa/my_id_session/myid_session_cubit.dart';
import 'package:mysafar_sdk/src/service/ban_chek_and_visa_service.dart';
import 'package:mysafar_sdk/src/view/ban_register/widget/container_column_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/booking_auth_bottom_sheet.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:myid/myid.dart';
import 'package:myid/myid_config.dart';
import 'package:myid/enums.dart';

class MyIdVerificationPage extends StatefulWidget {
  static const routName = "/myIdVerification";

  final String? appBarTitle;
  final String? bannerTitle;
  final String? bannerImage;
  final VoidCallback? onVerified;

  const MyIdVerificationPage({
    super.key,
    this.appBarTitle,
    this.bannerTitle,
    this.bannerImage,
    this.onVerified,
  });

  @override
  State<MyIdVerificationPage> createState() => _MyIdVerificationPageState();
}

class _MyIdVerificationPageState extends State<MyIdVerificationPage> {
  ProfileModel? profileData;

  late TextEditingController docController;
  late TextEditingController birthdayController;
  late MaskTextInputFormatter activeFormatter;

  @override
  void initState() {
    super.initState();
    activeFormatter = MyIdMaskFormatter.passportNumberFormatter;
    docController = TextEditingController();
    birthdayController = TextEditingController();
    docController.addListener(_updateButtonState);
    birthdayController.addListener(_updateButtonState);

    final cachedData = ProfileCache().read();
    if (cachedData != null) {
      profileData = ProfileModel.fromJson(cachedData);
    } else {
      ProfileCubit(needGetProfile: true).getProfileData().then((value) {
        if (value is NetworkSuccessResponse) {
          if (!mounted) return;
          setState(() {
            profileData = value.data;
          });
        } else if (value is NetworkErrorResponse) {
          debugPrint("MyID profile fetch error: ${value.getError()}");
        }
      });
    }
  }

  Future<String?> _ensurePhoneNumber() async {
    final existing = profileData?.phoneNumber;
    if (existing != null && existing.isNotEmpty) return existing;

    final authResult = await showBookingAuthBottomSheet(context);
    if (!mounted) return null;
    if (authResult != true) return null;

    final response = await ProfileCubit(needGetProfile: true)
        .getProfileData(forceRefresh: true);
    if (!mounted) return null;
    if (response is NetworkSuccessResponse) {
      setState(() {
        profileData = response.data;
      });
    }

    final phone = profileData?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("enter_full_phone_number".tr())),
      );
      return null;
    }
    return phone;
  }

  Future<void> _refreshProfileCache() async {
    final response = await ProfileCubit().getProfileData(forceRefresh: true);
    if (!mounted) return;
    if (response is NetworkSuccessResponse) {
      setState(() {
        profileData = response.data;
      });
    } else if (response is NetworkErrorResponse) {
      debugPrint("MyID profile refresh error: ${response.getError()}");
    }
  }

  Future<void> _onCheckPressed(MyIdSessionCubit cubit) async {
    final phone = await _ensurePhoneNumber();
    if (!mounted || phone == null) return;

    cubit.myidSession({
      "phone_number": phone,
      "birth_date": _convertToIsoDate(birthdayController.text),
      "pass_data": activeFormatter.getUnmaskedText(),
    });
  }

  @override
  void dispose() {
    docController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  void _updateButtonState() => setState(() {});

  bool get _isFormValid {
    final docUnmasked =
        docController.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final birthUnmasked =
        birthdayController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final isPassport = activeFormatter == MyIdMaskFormatter.passportNumberFormatter;
    final docOk = isPassport ? docUnmasked.length == 9 : docUnmasked.length == 14;
    return docOk && birthUnmasked.length == 8;
  }

  void _onDocChanged(String value) {
    if (value.isEmpty) return;

    final firstChar = value[0];
    final isLetter = RegExp(r'[A-Za-z]').hasMatch(firstChar);
    final newFormatter = isLetter
        ? MyIdMaskFormatter.passportNumberFormatter
        : MyIdMaskFormatter.jshshirFormatter;

    if (activeFormatter != newFormatter) {
      final rawText = activeFormatter.getUnmaskedText();
      setState(() {
        activeFormatter = newFormatter;
      });
      docController.value = TextEditingValue(
        text: activeFormatter.maskText(rawText),
        selection: TextSelection.collapsed(
          offset: activeFormatter.getMaskedText().length,
        ),
      );
    }
  }

  String _convertToIsoDate(String inputDate) {
    final parts = inputDate.split('.');
    if (parts.length != 3) return inputDate;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  Future<void> _startMyIdVerification(String sessionId) async {
    try {
      const clientHash =
          """MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq1w7u/sNwxIBo+59nkboUHXqIFcotqWbqHpAfdNI8DqEND7VZgrS1I1/Q9sqdxg7jSIs29ZADkXuPrmTqXulosmHD0b338HzN52M1Zh9RAsUw1hB6yOVhW79WAtEg1uPSce5sET9tSOYxqbElDU/Qi8AVkZmhqrx/Bu/+Bcla9aRTiY0Ot2i8luTs/mQu98LGeYP0szL+HCtcrxf3k2VUJml0DbxSvWuvSnhh1s1Rtmei7T/koLb9GiFkkheMbvSdht5kko3utP+cmFRCpTLDkZo7WDQ9GKxavvfvOs1ViYKbIYbaN2Ff0RD2QlLtr8Lg1ZV2mhoqvUHE6u+CTh8UwIDAQAB""";
      const clientHashId = "7286f172-1dad-4fd0-8d11-4ec2f3ab9a99";

      final result = await MyIdClient.start(
        config: MyIdConfig(
          sessionId: sessionId,
          clientHash: clientHash,
          clientHashId: clientHashId,
          environment: MyIdEnvironment.PRODUCTION,
          entryType: MyIdEntryType.IDENTIFICATION,
        ),
      );

      debugPrint("MYID result $result");
      if (!mounted) return;

      final code = result.code;
      final phone = profileData?.phoneNumber ?? "";
      debugPrint( "MYID code: $code, phone: $phone");
      if (code != null && code.isNotEmpty && phone.isNotEmpty) {
        final userInfoResponse = await BanCheckAndVisaService()
            .getMyIdUserInfo(code: code, phoneNumber: phone);
        if (!mounted) return;
        if (userInfoResponse is NetworkErrorResponse) {
          debugPrint(
              "MYID user-info error: ${userInfoResponse.getError()}");
        } else {
          debugPrint("MYID user-info success: ${userInfoResponse.toString()}");

          await _refreshProfileCache();
          if (!mounted) return;
        }
      }

      widget.onVerified?.call();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("MyID error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyIdSessionCubit(),
      child: BlocConsumer<MyIdSessionCubit, MyIdSessionState>(
        listener: (context, state) {
          if (state is MyIdSessionSuccessState) {
            final sessionId = state.data is Map ? state.data["session_id"] : null;
            if (sessionId is String) _startMyIdVerification(sessionId);
          }
        },
        builder: (context, state) {
          final isLoading = state is MyIdSessionLoadingState;
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(widget.appBarTitle ?? "myid_verification_title".tr()),
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ContainerColumnWidget(
                        title:
                            widget.bannerTitle ?? "myid_verification_subtitle".tr(),
                        imege: widget.bannerImage ?? ProjectAssets.visaBronPerson,
                      ),
                      context.szBoxHeight16,
                      DecoratedBox(
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
                                  _UpperCaseTextFormatter(),
                                  activeFormatter,
                                ],
                                label: "passport_or_id_info".tr(),
                                controller: docController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                showError: false,
                                onChanged: _onDocChanged,
                              ),
                              context.szBoxHeight12,
                              CustomInputField(
                                inputFormatters: [
                                  MyIdMaskFormatter.birthdayFormatter,
                                ],
                                keyboardType: TextInputType.number,
                                label: "birth_date_label".tr(),
                                controller: birthdayController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.done,
                                showError: false,
                                onChanged: (_) => setState(() {}),
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
                  onPressed: (_isFormValid && !isLoading)
                      ? () => _onCheckPressed(
                          context.read<MyIdSessionCubit>())
                      : null,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "check".tr(),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
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

class MyIdMaskFormatter {
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
    mask: "##############",
    type: MaskAutoCompletionType.lazy,
    filter: {'#': RegExp(r'[0-9]')},
  );

  static MaskTextInputFormatter birthdayFormatter = MaskTextInputFormatter(
    mask: "##.##.####",
    type: MaskAutoCompletionType.lazy,
    filter: {'#': RegExp(r'[0-9]')},
  );
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}