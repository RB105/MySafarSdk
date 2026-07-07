import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart' show BuildContext, SizeContext, State, StatefulWidget, Text, TextStyle;

class GetAppVersion extends StatefulWidget {
  final TextStyle? textStyle;
  const GetAppVersion({super.key, this.textStyle});

  @override
  State<GetAppVersion> createState() => _GetAppVersionState();
}

class _GetAppVersionState extends State<GetAppVersion> {
  String appVersion = '';

  @override
  void initState() {
    _loadAppVersion();
    super.initState();
  }

  Future<void> _loadAppVersion() async {
    appVersion = await ProjectUtils.getVersionName();
    setState(() {});
  }

  @override
  Text build(BuildContext context) {
    return Text("v$appVersion",
        style: widget.textStyle ?? context.textTheme.bodyMedium);
  }
}
