import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/model/remote/fornex/pop_destinations.dart';

class DestinationDetailsPage extends StatelessWidget {
  final PopDestinationsModel destination;
  const DestinationDetailsPage({super.key, required this.destination});
  static const routeName = '/destinationDetails';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            destination.images[0].image,
          )),
    );
  }
}
