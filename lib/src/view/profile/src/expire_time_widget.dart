import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart';

class ExpireTimeText extends StatefulWidget {
  final String createdAt;

  /// Taymer 0 ga tushganda chaqiriladi — parent status/tugmani yangilashi uchun.
  final VoidCallback? onExpired;

  const ExpireTimeText({
    super.key,
    required this.createdAt,
    this.onExpired,
  });

  /// To'lov muddati (bron yaratilgandan so'ng), soniya.
  static const int paymentLimitSeconds = 1800;

  /// [createdAt] dan [now] gacha o'tgan vaqtdan qolgan soniyalar (≥ 0).
  /// Sana noma'lum bo'lsa 0 (muddat o'tgan deb hisoblanadi).
  static int remainingSecondsAt(
    DateTime? createdAt,
    DateTime now, {
    int limitSeconds = paymentLimitSeconds,
  }) {
    if (createdAt == null) return 0;
    final remaining = limitSeconds - now.difference(createdAt).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  @override
  State<ExpireTimeText> createState() => _ExpireTimeTextState();
}

class _ExpireTimeTextState extends State<ExpireTimeText> {
  Timer? _timer;
  int remainingSeconds = 0;
  bool _expiredNotified = false;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant ExpireTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ro'yxat yangilangach element boshqa buyurtmaga tegishli bo'lishi mumkin.
    if (oldWidget.createdAt != widget.createdAt) {
      _timer?.cancel();
      _timer = null;
      _expiredNotified = false;
      _restart();
    }
  }

  /// Har safar `createdAt` dan qayta hisoblanadi (№88): 1 ayirish ilova
  /// fonda bo'lganda (iOS taymerni to'xtatadi) orqada qolardi.
  int _computeRemaining() => ExpireTimeText.remainingSecondsAt(
        ElementFormatter().parseCreatedAt(widget.createdAt),
        DateTime.now(),
      );

  void _restart() {
    remainingSeconds = _computeRemaining();
    if (remainingSeconds > 0) {
      _startTimer();
    } else {
      _notifyExpired();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        remainingSeconds = _computeRemaining();
      });

      if (remainingSeconds <= 0) {
        _timer?.cancel();
        _timer = null;
        _notifyExpired();
      }
    });
  }

  void _notifyExpired() {
    if (_expiredNotified) return;
    _expiredNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExpired?.call();
    });
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      remainingSeconds > 0
          ? formatDuration(remainingSeconds)
          : "payment_time_expired".tr(),
      style: context.textTheme.bodySmall?.copyWith(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }
}
