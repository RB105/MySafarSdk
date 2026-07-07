import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';

class ExpireTimeText extends StatefulWidget {
  final String createdAt;
  const ExpireTimeText({super.key, required this.createdAt});

  @override
  State<ExpireTimeText> createState() => _ExpireTimeTextState();
}

class _ExpireTimeTextState extends State<ExpireTimeText> {
  late Timer _timer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    remainingSeconds = ElementFormatter().bookingExpireRemainingSeconds(widget.createdAt);
    if (remainingSeconds > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          remainingSeconds--;
        });
      }

      if (remainingSeconds <= 0) {
        _timer.cancel();
      }
    });
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      remainingSeconds > 0
          ? formatDuration(remainingSeconds)
          : "Vaqt tugagan",
      style: context.textTheme.bodySmall?.copyWith(
        color:Colors.white,
        fontSize: 16,
      ),
    );
  }
}
