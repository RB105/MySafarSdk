import 'package:flutter/gestures.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/view/booking/widget/card_payment_constants.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/add_card/add_card_service.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/add_card/card_otp_page.dart';
import 'package:mysafar_sdk/src/view/profile/pages/my_contracts/view/add_card/oferta_page.dart';

class AddCardPage extends StatefulWidget {
  final int contractId;

  const AddCardPage({super.key, required this.contractId});

  static const String routeName = "/addCard";

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _offerAccepted = false;
  bool _sending = false;
  final _service = AddCardService();

  CardInfo _cardInfo = const CardInfo();
  bool _cardInfoLoading = false;
  String? _cardInfoError;
  String _lastQueriedCard = '';

  final _cardFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  final _expiryFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _cardController.addListener(_onCardChanged);
    _expiryController.addListener(() => setState(() {}));
  }

  void _onCardChanged() {
    final unmasked = _cardFormatter.getUnmaskedText();
    if (unmasked.length == 16) {
      if (unmasked != _lastQueriedCard && !_cardInfoLoading) {
        _fetchCardInfo(unmasked);
      }
    } else {
      if (_cardInfo.isValid ||
          _cardInfoError != null ||
          _lastQueriedCard.isNotEmpty) {
        _cardInfo = const CardInfo();
        _cardInfoError = null;
        _lastQueriedCard = '';
      }
    }
    setState(() {});
  }

  Future<void> _fetchCardInfo(String cardNumber) async {
    setState(() {
      _cardInfoLoading = true;
      _cardInfoError = null;
      _cardInfo = const CardInfo();
      _lastQueriedCard = cardNumber;
    });
    final response = await _service.getCardInfo(cardNumber: cardNumber);
    if (!mounted) return;
    final current = _cardFormatter.getUnmaskedText();
    if (current != cardNumber) {
      setState(() => _cardInfoLoading = false);
      if (current.length == 16 && current != _lastQueriedCard) {
        _fetchCardInfo(current);
      }
      return;
    }
    if (response is NetworkSuccessResponse) {
      final data = response.data;
      final info = data is Map<String, dynamic>
          ? CardInfo.fromJson(data)
          : const CardInfo();
      setState(() {
        _cardInfo = info;
        _cardInfoLoading = false;
        _cardInfoError = info.isValid ? null : "card_invalid".tr();
      });
    } else if (response is NetworkErrorResponse) {
      setState(() {
        _cardInfoLoading = false;
        _cardInfoError = response.getError();
      });
    } else {
      setState(() => _cardInfoLoading = false);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  bool get _isCardValid =>
      _cardFormatter.getUnmaskedText().length == 16 &&
      _expiryFormatter.getUnmaskedText().length == 4;

  bool get _canContinue =>
      _isCardValid && _offerAccepted && _cardInfo.isValid && !_cardInfoLoading;

  Future<void> _openOferta() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OfertaPage()),
    );
    if (!mounted) return;
    if (result == true) {
      setState(() => _offerAccepted = true);
    }
  }

  void _toggleCheckbox() {
    if (!_offerAccepted) {
      _openOferta();
      return;
    }
    setState(() => _offerAccepted = false);
  }

  String? _readProfilePhone() {
    final cached = ProfileCache().read();
    if (cached == null) return null;
    final phone = cached['phone_number']?.toString().trim();
    return (phone == null || phone.isEmpty) ? null : phone;
  }

  Future<void> _onContinue() async {
    if (_sending) return;
    final cardNumber = _cardFormatter.getUnmaskedText();
    final expire = _expiryFormatter.getUnmaskedText();
    final cardType = _cardInfo.cardType;
    final phone = _readProfilePhone();

    if (cardType == null) {
      _showSnack("card_type_unknown".tr());
      return;
    }
    if (phone == null) {
      _showSnack("phone_required".tr());
      return;
    }

    setState(() => _sending = true);
    final response = await _service.sendCardOtp(
      cardNumber: cardNumber,
      expire: expire,
      cardType: cardType,
      phone: "+$phone",
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (response is NetworkSuccessResponse) {
      final id = _extractId(response.data);
      if (id == null) {
        _showSnack("error_other".tr());
        return;
      }
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CardOtpPage(
            otpId: id,
            cardType: cardType,
            cardNumber: cardNumber,
            expiry: expire,
            contractId: widget.contractId,
          ),
        ),
      );
      if (!mounted) return;
      // Karta qo'shildi — shartnomalar ro'yxatigacha qaytishni davom ettiramiz.
      if (added == true) {
        Navigator.of(context).pop(true);
      }
    } else if (response is NetworkErrorResponse) {
      _showSnack(response.getError());
    }
  }

  String? _extractId(dynamic data) {
    if (data is Map) {
      final result = data['result'];
      if (result is Map && result['id'] != null) {
        return result['id'].toString();
      }
      if (data['id'] != null) return data['id'].toString();
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("add_card".tr()),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _CardPreview(
              numberMasked: _cardFormatter.getMaskedText(),
              expiryMasked: _expiryFormatter.getMaskedText(),
              pcType: _cardInfo.pcType,
            ),
            const SizedBox(height: 20),
            CustomInputField(
              label: "card_number".tr(),
              controller: _cardController,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              inputFormatters: [_cardFormatter],
              showError: false,
            ),
            _CardInfoStatus(
              loading: _cardInfoLoading,
              info: _cardInfo,
              error: _cardInfoError,
            ),
            context.szBoxHeight12,
            CustomInputField(
              label: "card_expiry".tr(),
              controller: _expiryController,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              inputFormatters: [_expiryFormatter],
              showError: false,
            ),
            context.szBoxHeight24,
            _OfferRow(
              accepted: _offerAccepted,
              onToggle: _toggleCheckbox,
              onOpenOffer: _openOferta,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
        child: _ContinueButton(
          enabled: _canContinue && !_sending,
          loading: _sending,
          onTap: _onContinue,
        ),
      ),
    );
  }

}

class _CardPreview extends StatelessWidget {
  final String numberMasked;
  final String expiryMasked;
  final int? pcType;

  const _CardPreview({
    required this.numberMasked,
    required this.expiryMasked,
    required this.pcType,
  });

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final accent = ProjectTheme.blueBg;
    final display = numberMasked.isEmpty
        ? "•••• •••• •••• ••••"
        : numberMasked.padRight(19, '•');
    final expiryDisplay = expiryMasked.isEmpty ? "MM/YY" : expiryMasked;

    return SizedBox(
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand, accent],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.contactless_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      _BrandBadge(pcType: pcType),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "card_expiry_short".tr(),
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expiryDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  final int? pcType;

  const _BrandBadge({required this.pcType});

  @override
  Widget build(BuildContext context) {
    final label = _brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String get _brand {
    switch (pcType) {
      case 1:
        return 'UZCARD';
      case 3:
        return 'HUMO';
      default:
        return 'CARD';
    }
  }
}

class _OfferRow extends StatelessWidget {
  final bool accepted;
  final VoidCallback onToggle;
  final VoidCallback onOpenOffer;

  const _OfferRow({
    required this.accepted,
    required this.onToggle,
    required this.onOpenOffer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand = ProjectTheme.brandColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accepted ? brand : Colors.transparent,
                border: Border.all(
                  color: accepted
                      ? brand
                      : (isDark
                          ? Colors.white.withAlpha(80)
                          : Colors.black.withAlpha(80)),
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: accepted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: "${"offer_intro".tr()} "),
                    TextSpan(
                      text: "offer_link".tr(),
                      style: TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: brand,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onOpenOffer,
                    ),
                    TextSpan(text: " ${"offer_outro".tr()}"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfoStatus extends StatelessWidget {
  final bool loading;
  final CardInfo info;
  final String? error;

  const _CardInfoStatus({
    required this.loading,
    required this.info,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, left: 4),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
          error!,
          style: context.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
        ),
      );
    }
    if (info.isValid && (info.bankName ?? '').isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 16, color: ProjectTheme.brandColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                info.bankName!,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: enabled
                  ? LinearGradient(
                      colors: [ProjectTheme.brandColor, ProjectTheme.blueBg],
                    )
                  : null,
              color: enabled ? null : ProjectTheme.brandColor.withAlpha(40),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "continue".tr(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

