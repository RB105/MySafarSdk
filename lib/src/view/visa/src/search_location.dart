// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> recentAddresses = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Yetkazib berish manzilini kiriting")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                GooglePlaceAutoCompleteTextField(
                  boxDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: context.color.primaryContainer),
                  textEditingController: _controller,
                  googleAPIKey: "AIzaSyCks2_bKeLIDoMV-cnSgZgiZUk-oQ5kLQg",
                  inputDecoration: InputDecoration(
                    hintText: "O’zbekiston, Toshkent, Afrosiyob 4",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  debounceTime: 400,
                  countries: ["uz"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, prediction);
                  },
                  itemClick: (Prediction prediction) {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.my_location),
              title: const Text("Mening joylashuvim"),
              onTap: () {},
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
