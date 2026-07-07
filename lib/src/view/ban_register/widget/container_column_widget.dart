import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';

class ContainerColumnWidget extends StatelessWidget {
  final String title;
  final String imege;
  const ContainerColumnWidget(
      {super.key, required this.title, required this.imege});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: context.shadowDown,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imege, height: 90, width: 90),
              context.szBoxHeight8,
              Text(title,textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500))
            ],
          ),
        ),
      ),
    );
  }
}
