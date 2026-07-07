import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart' show Provider;

import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart' show CurrencyProvider;
import 'package:mysafar_sdk/src/core/widgets/response_state.dart';
import 'package:mysafar_sdk/src/cubit/booking/confirm/booking_confirm_states.dart';
import 'package:mysafar_sdk/src/model/remote/avia/recommendation/get_recom_res_model.dart'
    show FlightPrice;
import 'package:mysafar_sdk/src/view/booking/ticket_pdf_page.dart';
import 'package:mysafar_sdk/src/view/booking/widget/card_payment_constants.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/booking/widget/payment_widgets.dart';
import 'package:mysafar_sdk/src/view/booking/widget/paymentbottomsheet.dart';

/// Karta to'lovi bottom sheet
///
/// UZCARD va HUMO kartalari orqali to'lov qilish uchun
class PaymentCardBottomSheet extends StatefulWidget {
  final String trId;
  final String cardType;
  final FlightPrice? price;

  const PaymentCardBottomSheet({
    super.key,
    required this.trId,
    required this.cardType,
    required this.price,
  });

  @override
  State<PaymentCardBottomSheet> createState() => _PaymentCardBottomSheetState();
}

class _PaymentCardBottomSheetState extends State<PaymentCardBottomSheet> {
  final _cardNumberController = TextEditingController();
  final _cardExpController = TextEditingController();

  // Har bir instance uchun alohida formatter
  late final MaskTextInputFormatter _cardNumberFormatter;
  late final MaskTextInputFormatter _cardExpFormatter;

  CardInfo _cardInfo = const CardInfo();

  @override
  void initState() {
    super.initState();
    _cardNumberFormatter = CardFormatters.createCardNumberFormatter();
    _cardExpFormatter = CardFormatters.createCardExpFormatter();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _cardNumberController.text.length == CardPaymentConstants.cardNumberMaskedLength &&
      _cardExpController.text.isNotEmpty &&
      _cardInfo.isValid;

  String get _formattedCardNumber => _cardNumberFormatter.getUnmaskedText();

  String get _formattedExpiry => _reverseMonthYear(_cardExpFormatter.getMaskedText());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingConfirmCubit(''),
      child: BlocConsumer<BookingConfirmCubit, BookingConfirmStates>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmSuccessState) {
      _handlePaymentSuccess(context, state);
    } else if (state is BookingConfirmCardInfoSuccessState) {
      setState(() => _cardInfo = CardInfo.fromJson(state.data));
    } else if (state is BookingConfirmErrorState) {
      ResponseState.errorState(state.error, context);
    }
  }

  void _handlePaymentSuccess(BuildContext context, BookingConfirmSuccessState state) {
    if (state.data['otp_token'] != null) {
      showPaymentOtpBottomSheet(
        context: context,
        data: state.data,
        params: _buildPaymentParams(),
        price: widget.price,
      );
    }
  }

  Map<String, dynamic> _buildPaymentParams() => {
    'transaction_type': CardPaymentConstants.transactionType,
    'tr_id': widget.trId,
    'card_number': _formattedCardNumber,
    'expire': _formattedExpiry,
  };

  Widget _buildContent(BuildContext context, BookingConfirmStates state) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                PaymentSheetHeader(title: 'pay'.tr()),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildForm(context, state),
                  ),
                ),
                _buildPayButton(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, BookingConfirmStates state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'pay_with_humo'.tr(namedArgs: {'cardType': widget.cardType}),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),

        // Karta raqami
        CustomInputField(
          inputFormatters: [_cardNumberFormatter],
          keyboardType: TextInputType.number,
          showError: false,
          controller: _cardNumberController,
          label: 'card_number'.tr(),
          validator: (_) => null,
          onChanged: (value) => _onCardNumberChanged(context, value),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
        ),

        // Loading indicator
        if (_cardNumberController.text.length == CardPaymentConstants.cardNumberMaskedLength)
          _buildCardInfoLoader(state),

        const SizedBox(height: 8),

        // Karta muddati
        CustomInputField(
          inputFormatters: [_cardExpFormatter],
          keyboardType: TextInputType.number,
          showError: false,
          controller: _cardExpController,
          label: 'valid_until'.tr(),
          validator: (_) => null,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
        ),
      ],
    );
  }

  Widget _buildCardInfoLoader(BookingConfirmStates state) {
    if (state is BookingConfirmCardInfoLoadingState) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPayButton(BuildContext context, BookingConfirmStates state) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final isLoading = state is BookingConfirmLoadingState;
    final priceText = widget.price != null
        ? currencyProvider.getElementPrice(widget.price!)
        : '';

    return PaymentButton(
      text: '${'pay'.tr()} $priceText',
      analyticsId: 'payment_pay_card',
      isLoading: isLoading,
      isEnabled: _isFormValid,
      onPressed: () => _onPayPressed(context, state),
    );
  }

  void _onCardNumberChanged(BuildContext context, String value) {
    if (value.length == CardPaymentConstants.cardNumberMaskedLength) {
      context.read<BookingConfirmCubit>().getCardInfo(
        cardNumber: _formattedCardNumber,
      );
    }
    setState(() {});
  }

  void _onPayPressed(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmLoadingState) return;
    if (!_cardInfo.isValid) return;

    context.read<BookingConfirmCubit>().confirmBooking(
      params: _buildPaymentParams(),
    );
  }

  String _reverseMonthYear(String value) {
    if (value.length < 5) return value;
    final parts = value.split('/');
    if (parts.length != 2) return value;
    return '${parts[1]}${parts[0]}';
  }
}

/// OTP tasdiqlash bottom sheet
class OtpPaymentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> params;
  final FlightPrice? sum;

  const OtpPaymentBottomSheet({
    super.key,
    required this.data,
    required this.params,
    required this.sum,
  });

  @override
  State<OtpPaymentBottomSheet> createState() => _OtpPaymentBottomSheetState();
}

class _OtpPaymentBottomSheetState extends State<OtpPaymentBottomSheet> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _timerNotifier = ValueNotifier<int>(CardPaymentConstants.otpTimerSeconds);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _timerNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerNotifier.value = CardPaymentConstants.otpTimerSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerNotifier.value <= 0) {
        timer.cancel();
        _otpController.clear();
      } else {
        _timerNotifier.value--;
      }
    });
  }

  bool get _isOtpValid =>
      _otpController.text.length == CardPaymentConstants.otpLength;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingConfirmCubit(''),
      child: BlocConsumer<BookingConfirmCubit, BookingConfirmStates>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmOtpSuccessState) {
      Navigator.pushNamed(context, TicketPdfPage.routeName, arguments: state.data);
    } else if (state is BookingConfirmSuccessState) {
      _startTimer();
    } else if (state is BookingConfirmErrorState) {
      ResponseState.errorState(state.error, context);
    }
  }

  Widget _buildContent(BuildContext context, BookingConfirmStates state) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            PaymentSheetHeader(
              title: 'pay'.tr(),
              onClose: () {
                _timer?.cancel();
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _buildOtpForm(context),
              ),
            ),
            _buildPayButton(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enter_confirmation_code'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Center(child: _buildPinput(context)),
        const SizedBox(height: 36),
        Center(child: _buildTimerWidget(context)),
        const SizedBox(height: 16),
        Text(
          'unired_sms_verification_text'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPinput(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 48,
      textStyle: context.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.outline, width: 1.5),
      ),
    );

    return Pinput(
      autofocus: true,
      controller: _otpController,
      length: CardPaymentConstants.otpLength,
      focusNode: _focusNode,
      defaultPinTheme: defaultPinTheme,
      separatorBuilder: (_) => const SizedBox(width: 8),
      onCompleted: (_) => _focusNode.unfocus(),
      onChanged: (_) => setState(() {}),
      cursor: Container(
        width: 2,
        height: 24,
        color: const Color(CardPaymentConstants.focusColorValue),
      ),
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(
            color: const Color(CardPaymentConstants.focusColorValue),
            width: 1.5,
          ),
        ),
      ),
      submittedPinTheme: defaultPinTheme,
      errorPinTheme: defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildTimerWidget(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _timerNotifier,
      builder: (context, value, _) {
        if (value > 0) {
          return _buildCountdown(context, value);
        }
        return _buildResendButton(context);
      },
    );
  }

  Widget _buildCountdown(BuildContext context, int seconds) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'resend_code_in'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          TextSpan(
            text: '00:${seconds.toString().padLeft(2, '0')}',
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<BookingConfirmCubit>().confirmBooking(params: widget.params);
        _otpController.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.outline, width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'resend_code'.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, BookingConfirmStates state) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final isLoading = state is BookingConfirmLoadingState;
    final priceText = widget.sum != null
        ? currencyProvider.getElementPrice(widget.sum!)
        : '';

    return PaymentButton(
      text: '${'pay'.tr()} $priceText',
      analyticsId: 'payment_pay_otp',
      isLoading: isLoading,
      isEnabled: _isOtpValid,
      onPressed: () => _onPayPressed(context, state),
    );
  }

  void _onPayPressed(BuildContext context, BookingConfirmStates state) {
    if (state is BookingConfirmLoadingState) return;
    if (!_isOtpValid) return;

    context.read<BookingConfirmCubit>().otpPaymont(
      otpToken: widget.data['otp_token'].toString(),
      trId: widget.data['tr_id'].toString(),
      otpCode: int.parse(_otpController.text),
    );
  }
}
