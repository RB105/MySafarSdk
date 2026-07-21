import 'package:flutter/material.dart';

class PassengerController {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController middlenameController = TextEditingController();
  final TextEditingController docnumController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController docexpController = TextEditingController();

  final FocusNode lastnameFocus = FocusNode(skipTraversal: true);
  final FocusNode firstnameFocus = FocusNode(skipTraversal: true);
  final FocusNode middlenameFocus = FocusNode(skipTraversal: true);
  final FocusNode birthdateFocus = FocusNode(skipTraversal: true);
  final FocusNode docnumFocus = FocusNode(skipTraversal: true);
  final FocusNode docexpFocus = FocusNode(skipTraversal: true);
  final FocusNode citizenFocus = FocusNode(skipTraversal: true);

  void dispose() {
    lastnameFocus.dispose();
    firstnameFocus.dispose();
    middlenameFocus.dispose();
    birthdateFocus.dispose();
    docnumFocus.dispose();
    docexpFocus.dispose();
    citizenFocus.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    middlenameController.dispose();
    docnumController.dispose();
    birthdateController.dispose();
    docexpController.dispose();
  }
}
