import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/profile_passenger_form.dart';

/// Profilga yangi yo'lovchi qo'shish. Saqlansa `true` bilan yopiladi.
class AddPassengerPage extends StatelessWidget {
  const AddPassengerPage({super.key});
  static const String routeName = "/addPassenger";

  @override
  Widget build(BuildContext context) => const ProfilePassengerForm();
}
