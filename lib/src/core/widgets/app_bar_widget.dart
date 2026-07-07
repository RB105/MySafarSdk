import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppBarWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      bottom: PreferredSize(
          preferredSize: Size(double.infinity, 2),
          child: Container(
            height: 1,
            decoration:
                mainDecoration(context).copyWith(color: Colors.transparent),
          )),
      title: Text(title, style: context.theme.textTheme.bodyLarge),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
