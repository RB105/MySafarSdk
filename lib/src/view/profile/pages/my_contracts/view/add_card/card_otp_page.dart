import 'dart:async';

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/add_card/add_card_service.dart';
import 'package:pinput/pinput.dart';

class CardOtpPage extends StatefulWidget {
  final String otpId;
  final String cardType;
  final String cardNumber;
  final String expiry;
  final int contractId;

  const CardOtpPage({
    super.key,
    required this.otpId,
    required this.cardType,
    required this.cardNumber,
    required this.expiry,
    required this.contractId,
  });

  static const String routeName = "/cardOtp";

  @override
  State<CardOtpPage> createState() => _CardOtpPageState();
}

class _CardOtpPageState extends State<CardOtpPage> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _service = AddCardService();

  final ValueNotifier<int> _seconds = ValueNotifier(120);
  Timer? _timer;
  bool _verifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _startTimer() {
    _seconds.value = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      if (_seconds.value <= 0) {
        _timer?.cancel();
        return;
      }
      _seconds.value--;
    });
  }

  String get _maskedCard {
    if (widget.cardNumber.length < 4) return widget.cardNumber;
    return "•••• ${widget.cardNumber.substring(widget.cardNumber.length - 4)}";
  }

  Future<void> _verify(String code) async {
    setState(() {
      _verifying = true;
      _errorText = null;
    });

    final response = await _service.verifyCardOtp(
      id: widget.otpId,
      code: code,
      cardType: widget.cardType,
    );
    if (!mounted) return;

    if (response is NetworkErrorResponse) {
      setState(() {
        _verifying = false;
        _errorText = response.getError();
      });
      _otpController.clear();
      return;
    }
    if (response is! NetworkSuccessResponse) {
      setState(() => _verifying = false);
      return;
    }

    // Server HTTP 200 qaytarsa-da, body ichida `status: false` bo'lishi mumkin.
    if (_isFailureBody(response.data)) {
      setState(() {
        _verifying = false;
        _errorText = _bodyMessage(response.data) ?? "error_other".tr();
      });
      _otpController.clear();
      return;
    }

    final cardUuid = _extractCardUuid(response.data);
    if (cardUuid == null) {
      setState(() {
        _verifying = false;
        _errorText = "error_other".tr();
      });
      _otpController.clear();
      return;
    }

    // Karta tasdiqlandi — loadingni to'xtatmasdan card-link so'rovini yuboramiz.
    final linkResponse = await _service.linkCard(
      cardUuid: cardUuid,
      contractId: widget.contractId,
    );
    if (!mounted) return;

    if (linkResponse is NetworkSuccessResponse) {
      // Loading card-link muvaffaqiyatli bo'lgunicha to'xtamaydi — endi
      // "karta qo'shildi" oynasini ko'rsatamiz va ro'yxatga qaytamiz.
      await _showSuccessDialog();
      if (!mounted) return;
      // Shartnomalar ro'yxatigacha qaytamiz (CardOtp -> AddCard -> Detail).
      Navigator.of(context).pop(true);
    } else {
      setState(() => _verifying = false);
      final message = linkResponse is NetworkErrorResponse
          ? linkResponse.getError()
          : "error_other".tr();
      await _showLinkErrorDialog(message);
      if (!mounted) return;
      // "Qayta urinish" — OTP'dan oldingi UI'ga (karta raqami/expire/checkbox
      // saqlangan AddCardPage) qaytamiz.
      Navigator.of(context).pop();
    }
  }

  Future<void> _showLinkErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.error_outline_rounded,
          color: ProjectTheme.error,
          size: 48,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              "retry".tr(),
              style: TextStyle(
                color: ProjectTheme.brandColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle_rounded,
          color: ProjectTheme.success,
          size: 48,
        ),
        content: Text(
          "card_added_contract_success".tr(),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              "ok".tr(),
              style: TextStyle(
                color: ProjectTheme.brandColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isFailureBody(dynamic data) {
    return data is Map && data['status'] == false;
  }

  String? _bodyMessage(dynamic data) {
    if (data is! Map) return null;
    final result = data['result'];
    if (result is Map && result['message'] is String) {
      return result['message'] as String;
    }
    final error = data['error'];
    if (error is String && error.isNotEmpty) return error;
    return null;
  }

  String? _extractCardUuid(dynamic data) {
    if (data is! Map) return null;
    final direct = data['card_uuid'];
    if (direct != null) return direct.toString();
    final result = data['result'];
    if (result is Map) {
      if (result['card_uuid'] != null) {
        return result['card_uuid'].toString();
      }
      // verify-card-otp javobida uuid `result.card.card_uuid` ichida keladi.
      final card = result['card'];
      if (card is Map && card['card_uuid'] != null) {
        return card['card_uuid'].toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    final defaultPin = PinTheme(
      width: 52,
      height: 60,
      textStyle: context.textTheme.bodyLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(15)
            : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("otp_verification".tr()),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brand, ProjectTheme.blueBg],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "otp_sent_title".tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "otp_sent_subtitle".tr(),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.credit_card_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _maskedCard,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // OTP input
              Pinput(
                controller: _otpController,
                focusNode: _otpFocusNode,
                autofocus: true,
                length: 6,
                defaultPinTheme: defaultPin,
                focusedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    border: Border.all(color: brand, width: 1.5),
                  ),
                ),
                submittedPinTheme: defaultPin.copyWith(
                  decoration: defaultPin.decoration!.copyWith(
                    color: brand.withAlpha(28),
                    border: Border.all(color: brand, width: 1.2),
                  ),
                ),
                separatorBuilder: (_) => const SizedBox(width: 8),
                cursor: Container(
                  width: 22,
                  height: 2,
                  color: brand,
                ),
                onCompleted: _verifying ? null : _verify,
              ),
              const SizedBox(height: 16),
              if (_verifying)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: _seconds,
                builder: (_, sec, __) {
                  if (sec > 0) {
                    final mm = (sec ~/ 60).toString().padLeft(2, '0');
                    final ss = (sec % 60).toString().padLeft(2, '0');
                    return Text(
                      "${"resend_code_in".tr()} $mm:$ss",
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: ProjectTheme.secondaryTextLight,
                      ),
                    );
                  }
                  return TextButton.icon(
                    onPressed: () {
                      _otpController.clear();
                      _startTimer();
                    },
                    icon: Icon(Icons.refresh_rounded, color: brand),
                    label: Text(
                      "resend_code".tr(),
                      style: TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
