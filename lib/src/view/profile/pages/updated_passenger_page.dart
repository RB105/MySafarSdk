import 'package:mysafar_sdk/src/model/remote/profile/users_model.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/widget/profile_passenger_form.dart';

/// Saqlangan yo'lovchini tahrirlash yoki o'chirish. O'zgarish bo'lsa `true`
/// bilan yopiladi.
class UpdatedPassengerPage extends StatelessWidget {
  final UsersModel usersModel;
  const UpdatedPassengerPage({super.key, required this.usersModel});
  static const String routeName = "/updatedPassenger";

  @override
  Widget build(BuildContext context) =>
      ProfilePassengerForm(initial: usersModel);
}
