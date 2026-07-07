import 'package:flutter/material.dart';

class ResponseContainer extends StatelessWidget {
  final Widget title;
  const ResponseContainer({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color:  const Color.fromARGB(255, 170, 176, 220),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: title
      ),
    );
  }
}
