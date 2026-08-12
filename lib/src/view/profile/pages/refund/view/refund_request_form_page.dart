import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:mysafar_sdk/src/core/tools/card_number_validator.dart'
    show CardNumberValidator;
import 'package:mysafar_sdk/src/core/tools/project_dialogs.dart';
import 'package:mysafar_sdk/src/service/profile/profile_cache.dart';
import 'package:mysafar_sdk/src/view/booking/widget/custom_input_field_widget.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

import '../logic/refund_create_cubit.dart';
import '../service/refund_models.dart';
import 'refund_requests_page.dart' show RefundArgs;
import 'refund_shared_widgets.dart';

/// Yangi vozvrat arizasi formasi (`POST /tickets/refund/request`).
///
/// Muvaffaqiyatli yuborilganda sahifa yaratilgan [RefundRequestModel] bilan
/// yopiladi — chaqiruvchi uni ro'yxatga darhol qo'shadi.
class RefundRequestFormPage extends StatefulWidget {
  final RefundArgs args;

  const RefundRequestFormPage({super.key, required this.args});

  @override
  State<RefundRequestFormPage> createState() => _RefundRequestFormPageState();
}

class _RefundRequestFormPageState extends State<RefundRequestFormPage> {
  final _cubit = RefundCreateCubit();

  final _cardController = TextEditingController();
  final _holderController = TextEditingController();
  final _reasonController = TextEditingController();

  /// Aloqa raqami — formaga kirishdan oldin foydalanuvchi telefon raqami
  /// bilan login qilingan, shu sababli raqam profildan olinadi va qo'lda
  /// kiritilmaydi (faqat ko'rsatiladi).
  late final String _phone = _profilePhone() ?? '';

  RefundType _type = RefundType.voluntary;

  /// "Yuborish" bosilgandan keyingina maydon xatolari ko'rsatiladi —
  /// forma ochilishi bilan qizarib turmasin.
  bool _showErrors = false;

  /// Serverdan kelgan maydon xatosi (`CARD_INVALID`).
  String? _serverCardError;

  static const int _reasonMaxLength = 500;

  @override
  void initState() {
    super.initState();
    for (final c in [_cardController, _reasonController]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [_cardController, _reasonController]) {
      c.removeListener(_onFieldChanged);
    }
    _cardController.dispose();
    _holderController.dispose();
    _reasonController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) return;
    // Foydalanuvchi tahrirlashni boshlagach serverning eski xatosi o'chadi.
    if (_serverCardError != null) _serverCardError = null;
    setState(() {});
  }

  /// Profilda saqlangan telefon (login qilingan raqam). Kesh bo'sh bo'lsa
  /// `null` — bunda raqam yuborilmaydi va server uni profildan o'zi oladi.
  String? _profilePhone() {
    final cached = ProfileCache().read();
    final phone = cached?['phone_number']?.toString().trim();
    return (phone == null || phone.isEmpty) ? null : phone;
  }

  String get _cardDigits => CardNumberValidator.digitsOf(_cardController.text);

  /// Backend qoidasi: karta 13–19 raqam.
  bool get _isCardLengthValid => CardNumberValidator.hasValidLength(_cardDigits);

  /// Uzunlik + nazorat raqami (Luhn) — noto'g'ri terilgan raqam serverga
  /// ketmasdan shu yerda ushlanadi (pul qaytariladigan karta xato bo'lsa
  /// ariza befoyda ketardi).
  bool get _isCardValid => CardNumberValidator.isValid(_cardDigits);

  bool get _canSubmit => _isCardValid;

  String? get _cardError {
    if (_serverCardError != null) return _serverCardError;
    if (!_showErrors || _isCardValid) return null;
    // Uzunligi joyida-yu Luhn o'tmadi — demak raqamlardan biri xato terilgan.
    return (_isCardLengthValid ? "card_number_checksum_invalid" : "refund_card_invalid")
        .tr();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);
    if (!_canSubmit) return;

    _cubit.submit(
      billingId: widget.args.billingId,
      cardNumber: _cardDigits,
      cardHolder: _holderController.text,
      // Profildagi raqam (bo'sh bo'lsa server o'zi profildan oladi).
      phoneNumber: _phone,
      reason: _reasonController.text,
      refundType: _type,
    );
  }

  void _onStateChanged(BuildContext context, RefundCreateState state) {
    if (state.status == RefundCreateStatus.success && state.created != null) {
      _showSuccessSheet(state.created!);
      return;
    }
    if (state.status != RefundCreateStatus.failure) return;

    final failure = state.failure;
    if (failure == null) return;

    // Maydonga tegishli xatolar — o'sha maydon ostida ko'rsatiladi.
    if (failure.isCardError) {
      setState(() => _serverCardError = failure.message);
      return;
    }
    // Telefon endi maydon emas (profildan olinadi) — xato bo'lsa toast.
    if (failure.isPhoneError) {
      ProjectDialogs.showCustomToast(context, failure.message);
      return;
    }
    // Bu biletga ochiq ariza bor — forma ma'nosiz, ortga qaytamiz.
    if (failure.isAlreadyRequested) {
      ProjectDialogs.showCustomToast(context, failure.message);
      Navigator.of(context).maybePop();
      return;
    }
    ProjectDialogs.showCustomToast(context, failure.message);
  }

  /// `201` — ariza qabul qilindi. Foydalanuvchi "Tushunarli" ni bosgach
  /// forma yaratilgan ariza bilan yopiladi.
  Future<void> _showSuccessSheet(RefundRequestModel created) async {
    final isDark = context.themeProvider.isDark;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: context.color.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProjectTheme.success.withAlpha(isDark ? 46 : 26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 34, color: ProjectTheme.success),
              ),
              context.szBoxHeight16,
              Text(
                "refund_success_title".tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "refund_success_desc".tr(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark
                      ? ProjectTheme.secondaryTextDark
                      : ProjectTheme.secondaryTextLight,
                ),
              ),
              context.szBoxHeight24,
              MainButtonWidget(
                title: "refund_understood".tr(),
                analyticsId: 'refund_success_ok',
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RefundCreateCubit, RefundCreateState>(
        listener: _onStateChanged,
        builder: (context, state) => Scaffold(
          appBar: AppBarWidget(title: "refund_new_request".tr()),
          body: GestureDetector(
            // Bo'sh joyga bosilganda klaviatura yopilsin.
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _billingBanner(context),
                context.szBoxHeight16,
                _sectionTitle(context, "refund_section_card".tr()),
                context.szBoxHeight12,
                CustomInputField(
                  label: "refund_card_number".tr(),
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CardNumberInputFormatter()],
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  showError: false,
                  hintText: "0000 0000 0000 0000",
                  suffix: _cardDigits.isEmpty
                      ? null
                      : Icon(
                          _isCardValid
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 20,
                          color: _isCardValid
                              ? ProjectTheme.success
                              : ProjectTheme.error,
                        ),
                ),
                _fieldError(context, _cardError),
                context.szBoxHeight12,
                CustomInputField(
                  label: "refund_card_holder".tr(),
                  controller: _holderController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  showError: false,
                  hintText: "ALI VALIYEV",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z' ]")),
                  ],
                ),
                if (_phone.isNotEmpty) ...[
                  context.szBoxHeight12,
                  RefundCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: RefundInfoRow(
                      icon: Icons.phone_iphone_rounded,
                      label: "refund_phone".tr(),
                      value: _phone,
                      maxLines: 1,
                    ),
                  ),
                ],
                context.szBoxHeight24,
                _sectionTitle(context, "refund_section_reason".tr()),
                context.szBoxHeight12,
                _typeSelector(context),
                context.szBoxHeight12,
                _reasonField(context),
              ],
            ),
          ),
          bottomNavigationBar: _bottomBar(context, state),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: context.textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      );

  /// Qaysi biletga ariza berilayotgani — foydalanuvchi adashmasin.
  Widget _billingBanner(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 30 : 14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.args.direction.isEmpty
                  ? "ID: ${widget.args.billingId}"
                  : "${widget.args.direction.replaceAll('-', ' → ')}"
                      "  •  ID: ${widget.args.billingId}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldError(BuildContext context, String? error) {
    if (error == null || error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6),
      child: Text(
        error,
        style: context.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ProjectTheme.error,
        ),
      ),
    );
  }

  /// `voluntary` / `involuntary` tanlovi.
  Widget _typeSelector(BuildContext context) {
    return Row(
      children: [
        for (final type in RefundType.values) ...[
          if (type != RefundType.values.first) const SizedBox(width: 10),
          Expanded(child: _typeTile(context, type)),
        ],
      ],
    );
  }

  Widget _typeTile(BuildContext context, RefundType type) {
    final isDark = context.themeProvider.isDark;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    final selected = _type == type;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withAlpha(isDark ? 40 : 16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : context.color.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected
                      ? accent
                      : (isDark
                          ? ProjectTheme.secondaryTextDark
                          : ProjectTheme.secondaryTextLight),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    type.labelKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              type.descriptionKey.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                height: 1.3,
                color: isDark
                    ? ProjectTheme.secondaryTextDark
                    : ProjectTheme.secondaryTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ko'p qatorli "sabab" maydoni — [CustomInputField] bir qatorli
  /// (56px) bo'lgani uchun shu yerda alohida quriladi, lekin chegara/radius
  /// tili bir xil.
  Widget _reasonField(BuildContext context) {
    final secondary = context.themeProvider.isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _reasonController,
          maxLines: 4,
          maxLength: _reasonMaxLength,
          textInputAction: TextInputAction.newline,
          style: context.textTheme.bodyMedium?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText: "refund_reason_hint".tr(),
            hintStyle: context.textTheme.bodySmall
                ?.copyWith(fontSize: 13.5, color: secondary),
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(width: 1.5, color: context.color.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(width: 1.5, color: ProjectTheme.brandColor),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(width: 1.5, color: context.color.outline),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${_reasonController.text.characters.length}/$_reasonMaxLength",
          style: context.textTheme.bodySmall
              ?.copyWith(fontSize: 11.5, color: secondary),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, RefundCreateState state) {
    final isDark = context.themeProvider.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.color.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(18)
                : Colors.black.withAlpha(12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: MainButtonWidget(
            title: "refund_submit".tr(),
            analyticsId: 'refund_submit',
            isLoading: state.isSubmitting,
            onTap: state.isSubmitting ? null : _submit,
          ),
        ),
      ),
    );
  }
}
