import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class PersonalInformationPage extends StatefulWidget {
  final ProfileModel profileData;
  const PersonalInformationPage({super.key, required this.profileData});

  static const String routeName = "PersonalInformationPage";

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  late ProfileModel profileData;

  @override
  void initState() {
    super.initState();
    profileData = widget.profileData;
    nameController.text = profileData.firstname ?? "";
    surnameController.text = profileData.lastname ?? "";
    dateController.text = profileData.brithDate ?? "";
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    dateController.dispose();
    super.dispose();
  }

  String? validator(String? v) {
    if (v?.isEmpty ?? false) {
      return "isEmpty".tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text('my_data'.tr()), centerTitle: false),
        body: Form(
          key: _key,
          child: Padding(
            padding: context.k16Padding,
            child: Column(
              children: [
                TextFormFieldWidget(
                    hintText: "first_name".tr(),
                    style: context.textTheme.bodyMedium,
                    controller: nameController),
                SizedBox(height: 16),
                TextFormFieldWidget(
                    hintText: "last_name".tr(),
                    style: context.textTheme.bodyMedium,
                    controller: surnameController),
                SizedBox(height: 16),
                TextFormFieldWidget(
                    hintText: "birth_date".tr(),
                    style: context.textTheme.bodyMedium,
                    controller: dateController,
                    onTap: () async {
                      DateTime? time =
                          await ProjectDialogs.showAdaptiveDateTimePicker(
                              context,
                              initialDate: DateTime.tryParse(
                                  profileData.brithDate ?? ""));
                      if (time != null) {
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(time);
                      }
                    },
                    readOnly: true),
                Spacer(),
                context.szBoxHeight16,
                MainButtonWidget(
                  size: 48,
                  title: 'save'.tr(),
                  onTap: () {
                    if (_key.currentState?.validate() ?? false) {
                      Navigator.of(context).pop(profileData.copyWith(
                          firstname: nameController.text,
                          lastname: surnameController.text,
                          brithDate: dateController.text));
                    }
                  },
                ),
                context.szBoxHeight16,
              ],
            ),
          ),
        ));
  }
}
