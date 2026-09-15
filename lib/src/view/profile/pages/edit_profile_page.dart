import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/cubit/profile/update_profile/update_profile_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/booking/widget/booking_form_fields.dart';
import 'package:mysafar_sdk/src/view/booking/widget/support_widget.dart'
    show BookingCard;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/profile_app_bar.dart';

/// Profilni tahrirlash — bron va saqlangan yo'lovchi formalari bilan bir xil
/// uslub: tepada avatar, "Shaxsiy ma'lumotlar" va "Kontaktlar" kartalari,
/// pastda "Saqlash" (o'zgarish bo'lmasa o'chirilgan).
class EditProfilePage extends StatefulWidget {
  final ProfileModel profileModel;

  const EditProfilePage({super.key, required this.profileModel});

  static const String routeName = "/editProfilePage";

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController middleNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _middleNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _firstNameKey = GlobalKey();
  final _lastNameKey = GlobalKey();

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
    phoneController = TextEditingController(
      text: formatInternationalPhone(widget.profileModel.phoneNumber ?? ""),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _middleNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final p = widget.profileModel;
    return firstNameController.text.trim() != (p.firstname ?? '').trim() ||
        lastNameController.text.trim() != (p.lastname ?? '').trim() ||
        middleNameController.text.trim() != (p.middlename ?? '').trim() ||
        emailController.text.trim() != (p.email ?? '').trim() ||
        normalizePhoneDigits(phoneController.text) !=
            normalizePhoneDigits(p.phoneNumber ?? '');
  }

  String? _required(String value, String message) =>
      value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateProfileCubit(),
      child: BlocConsumer<UpdateProfileCubit, UpdateProfileState>(
        listener: (context, state) {
          if (state is UpdateProfileLoading) {
            showSdkLoader(context);
          } else if (state is UpdateProfileSuccess) {
            Navigator.pop(context);
            Navigator.pop(context, state.profileModel);
          } else if (state is UpdateProfileError) {
            Navigator.pop(context);
            showErrorMessage(state.error, context: context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: sdkBodyColoredAppBar(context, title: 'editProfile'.tr()),
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileAvatarHeader(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      subtitle: widget.profileModel.getAuthenticator(),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle("personal_info".tr()),
                    BookingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BookingTextField(
                            key: _firstNameKey,
                            label: "first_name".tr(),
                            controller: firstNameController,
                            focusNode: _firstNameFocus,
                            showError: showErrors,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                _required(v, "name_not_entered".tr()),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _lastNameFocus.requestFocus,
                          ),
                          const SizedBox(height: 16),
                          BookingTextField(
                            key: _lastNameKey,
                            label: "last_name".tr(),
                            controller: lastNameController,
                            focusNode: _lastNameFocus,
                            showError: showErrors,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                _required(v, "surname_not_entered".tr()),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _middleNameFocus.requestFocus,
                          ),
                          const SizedBox(height: 16),
                          BookingTextField(
                            label: "father".tr(),
                            optional: true,
                            controller: middleNameController,
                            focusNode: _middleNameFocus,
                            showError: false,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _emailFocus.requestFocus,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle("your_contacts".tr()),
                    BookingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BookingTextField(
                            label: "email".tr(),
                            hintText: 'name@mail.com',
                            controller: emailController,
                            focusNode: _emailFocus,
                            showError: false,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _phoneFocus.requestFocus,
                          ),
                          const SizedBox(height: 16),
                          // Telefon — UI: +998 99 109 88 07; API: 998991098807
                          BookingTextField(
                            label: "phone".tr(),
                            hintText: "+998 90 123 45 67",
                            controller: phoneController,
                            focusNode: _phoneFocus,
                            showError: false,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: const [
                              InternationalPhoneInputFormatter(),
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: () =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: MainButtonWidget(
                  title: "save".tr(),
                  analyticsId: 'profile_edit_save',
                  onTap: _hasChanges ? () => _saveProfile(context) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveProfile(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => showErrors = true);

    final String? firstEmpty = firstNameController.text.trim().isEmpty
        ? 'firstname'
        : lastNameController.text.trim().isEmpty
            ? 'lastname'
            : null;
    if (firstEmpty != null) {
      final isFirst = firstEmpty == 'firstname';
      final fieldContext =
          (isFirst ? _firstNameKey : _lastNameKey).currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      (isFirst ? _firstNameFocus : _lastNameFocus).requestFocus();
      return;
    }

    final updatedProfile = widget.profileModel.copyWith(
      firstname: firstNameController.text.trim(),
      lastname: lastNameController.text.trim(),
      middlename: middleNameController.text.trim(),
      email: emailController.text.trim(),
      // API: faqat raqamlar, masalan 998991098807
      phoneNumber: normalizePhoneDigits(phoneController.text),
    );

    BlocProvider.of<UpdateProfileCubit>(context).updateProfile(updatedProfile);
  }
}

/// Tepadagi avatar: bosh harflar (yozish davomida yangilanadi) yoki ikonka,
/// ostida ism va login (telefon/email).
class _ProfileAvatarHeader extends StatelessWidget {
  const _ProfileAvatarHeader({
    required this.firstName,
    required this.lastName,
    required this.subtitle,
  });

  final String firstName;
  final String lastName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color accent = isDark ? Colors.white : ProjectTheme.brandColor;
    final Color fill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : ProjectTheme.brandColor.withValues(alpha: 0.08);

    final String name = [firstName.trim(), lastName.trim()]
        .where((s) => s.isNotEmpty)
        .join(' ');
    final String initials = [firstName.trim(), lastName.trim()]
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .join();

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: initials.isNotEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    fontFamily: "packages/mysafar_sdk/Gilroy",
                    color: accent,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                )
              : SvgPicture.asset(
                  Assets.iconsBookingUserIcon,
                  width: 38,
                  height: 38,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          name.isNotEmpty ? name : 'profile'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: BookingFormStyle.label(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: context.textTheme.bodyLarge
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
