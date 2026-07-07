import 'package:flutter/material.dart';

class PassengerController {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController middlenameController = TextEditingController();
  final TextEditingController docnumController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController docexpController = TextEditingController();

  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    middlenameController.dispose();
    docnumController.dispose();
    birthdateController.dispose();
    docexpController.dispose();
  }
}
