import 'package:mysafar_sdk/src/cubit/profile/profile_cubit.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/view/booking/widget/booking_auth_bottom_sheet.dart'
    show showBookingAuthBottomSheet;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:shimmer/shimmer.dart';

import '../logic/refund_requests_cubit.dart';
import '../service/refund_models.dart';
import 'refund_request_form_page.dart';
import 'refund_shared_widgets.dart';
import 'refund_ticket_picker.dart';

part 'refund_request_card.dart';
part 'refund_request_details.dart';

/// [RefundRequestsPage] ga uzatiladigan argumentlar — bilet kartasidan
/// yig'iladi (sahifa biletning to'liq modelini bilishi shart emas).
class RefundArgs {
  /// Ariza qaysi biletga — `POST /tickets/refund/request` dagi `billing_id`.
  final String billingId;

  /// Sarlavhadagi ko'rsatkichlar (mas. "TAS-IST", "HY", 7 585 086 UZS).
  final String direction;
  final String airline;
  final num? amount;

  const RefundArgs({
    required this.billingId,
    this.direction = '',
    this.airline = '',
    this.amount,
  });
}

/// Bilet vozvrati oynasi: ARIZALAR ro'yxati va pastda doim ko'rinib turadigan
/// "Yangi ariza" tugmasi.
///
/// Ikki rejimda ishlaydi:
///   • [args] `null` (profil bo'limidan kirilgan) — foydalanuvchining BARCHA
///     arizalari ko'rinadi, "Yangi ariza" avval bilet tanlash oynasini ochadi.
///   • [args] berilgan (aniq biletdan kirilgan) — faqat o'sha biletning
///     arizalari va to'g'ridan-to'g'ri forma.
///
/// Foydalanuvchi biletni o'zi qaytara olmaydi — u ariza qoldiradi, support
/// ko'rib chiqadi. Shu sabab bu yerda "Qaytarish" emas, "Ariza yuborish".
class RefundRequestsPage extends StatefulWidget {
  final RefundArgs? args;

  const RefundRequestsPage({super.key, this.args});

  static const String routeName = "/refundRequests";

  @override
  State<RefundRequestsPage> createState() => _RefundRequestsPageState();
}

class _RefundRequestsPageState extends State<RefundRequestsPage> {
  late final RefundRequestsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = RefundRequestsCubit(billingId: widget.args?.billingId);
    // Arizalar shaxsiy ma'lumot — login qilinmagan bo'lsa serverga umuman
    // bormaymiz (401 xatosi o'rniga login taklifi ko'rsatiladi).
    if (_isLoggedIn) _cubit.load();
  }

  /// Foydalanuvchi telefon raqami bilan kirganmi.
  bool get _isLoggedIn => MySafarSdk.tokens.isLoggedIn;

  /// Login shart bo'lgan amaldan oldin chaqiriladi: kirilmagan bo'lsa MyID
  /// oqimidagi kabi telefon+SMS oynasi ochiladi va profil keshi yangilanadi
  /// (keyin formada raqamni qo'lda kiritish shart bo'lmaydi).
  /// Kirilgan bo'lsa (yoki kirish muvaffaqiyatli tugasa) `true` qaytaradi.
  Future<bool> _ensureLoggedIn() async {
    if (_isLoggedIn) return true;

    final result = await showBookingAuthBottomSheet(context);
    if (!mounted || result != true) return false;

    // Profil (shu jumladan telefon raqam) keshga yoziladi — formada raqam
    // shu yerdan olinadi.
    await ProfileCubit().getProfileData(forceRefresh: true);
    if (!mounted) return false;

    if (!_isLoggedIn) return false;
    setState(() {});
    _cubit.load(silent: true);
    return true;
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Yangi ariza formasini ochadi. Forma `201` bilan yopilsa yaratilgan
  /// arizani qaytaradi — ro'yxatga darhol qo'shamiz (serverni kutmasdan).
  Future<void> _openForm() async {
    // Ariza faqat login qilingan foydalanuvchi nomidan yuboriladi.
    if (!await _ensureLoggedIn() || !mounted) return;

    var args = widget.args;
    // Profil bo'limidan kirilgan — avval qaysi bilet ekanini so'raymiz.
    if (args == null) {
      args = await showRefundTicketPicker(
        context,
        blockedBillingIds: _cubit.state.requests
            .where((e) => e.status.isOpen)
            .map((e) => e.billingId ?? '')
            .where((e) => e.isNotEmpty)
            .toSet(),
      );
      if (!mounted || args == null) return;
    }

    final created = await Navigator.push<RefundRequestModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RefundRequestFormPage(args: args!),
      ),
    );
    if (!mounted) return;
    if (created == null) {
      // Forma bekor qilindi yoki `409 ALREADY_REQUESTED` bilan yopildi —
      // ro'yxatni jimgina yangilaymiz (ochiq ariza bo'lsa shu yerda ko'rinadi).
      _cubit.load(silent: true);
      return;
    }
    _cubit.addLocal(created);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBarWidget(title: "refund_title".tr()),
        body: BlocBuilder<RefundRequestsCubit, RefundRequestsState>(
          builder: (context, state) => RefreshIndicator(
            onRefresh: () => _cubit.load(silent: true),
            child: _body(context, state),
          ),
        ),
        bottomNavigationBar:
            BlocBuilder<RefundRequestsCubit, RefundRequestsState>(
          builder: (context, state) => _BottomBar(
            // Profil rejimida tugma hech qachon bloklanmaydi — ochiq ariza
            // BOSHQA biletga tegishli bo'lishi mumkin; bandlari bilet tanlash
            // oynasida alohida belgilanadi.
            hasOpenRequest:
                widget.args != null && state.hasOpenRequest,
            onTap: _openForm,
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RefundRequestsState state) {
    // Ro'yxat har doim scroll bo'lsin — bo'sh/xato holatda ham
    // pull-to-refresh ishlashi uchun (AlwaysScrollableScrollPhysics).
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (widget.args != null)
          _TicketSummary(args: widget.args!)
        else
          const _RefundIntro(),
        context.szBoxHeight16,
        // Login qilinmagan — arizalar ro'yxati o'rniga kirish taklifi.
        if (!_isLoggedIn) ...[
          _LoginBox(onTap: _ensureLoggedIn),
        ] else ...[
        Row(
          children: [
            Text(
              "refund_my_requests".tr(),
              style: context.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            if (state.requests.isNotEmpty)
              _CountBadge(count: state.requests.length),
          ],
        ),
        context.szBoxHeight12,
        if (state.isLoading && state.requests.isEmpty)
          const _RequestsShimmer()
        else if (state.status == RefundRequestsStatus.failure &&
            state.requests.isEmpty)
          _ErrorBox(message: state.error, onRetry: () => _cubit.load())
        else if (state.isEmpty)
          _EmptyBox(perTicket: widget.args != null)
        else
          for (int i = 0; i < state.requests.length; i++) ...[
            if (i > 0) context.szBoxHeight12,
            _RefundRequestCard(request: state.requests[i]),
          ],
        ],
      ],
    );
  }
}

/// Login qilinmagan foydalanuvchiga: arizalar shaxsiy bo'lgani uchun avval
/// telefon raqam orqali kirish kerak (MyID oqimidagi bilan bir xil qadam).
class _LoginBox extends StatelessWidget {
  final Future<bool> Function() onTap;

  const _LoginBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = context.themeProvider.isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return RefundCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          Icon(Icons.phone_iphone_rounded,
              size: 44, color: ProjectTheme.brandColor),
          context.szBoxHeight12,
          Text(
            "refund_login_title".tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "refund_login_desc".tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              height: 1.4,
              color: secondary,
            ),
          ),
          context.szBoxHeight16,
          ElevatedButton(
            style: ProjectTheme.blueButtonStyle,
            onPressed: () => onTap(),
            child: Text("login".tr()),
          ),
        ],
      ),
    );
  }
}

/// Qaysi bilet uchun ariza berilayotgani — yo'nalish, aviakompaniya, ID va
/// to'langan summa.
class _TicketSummary extends StatelessWidget {
  final RefundArgs args;

  const _TicketSummary({required this.args});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;

    return RefundCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withAlpha(isDark ? 40 : 18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.airplane_ticket_rounded,
                    size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.direction.isEmpty
                          ? "refund_title".tr()
                          : args.direction.replaceAll('-', ' → '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID: ${args.billingId}"
                      "${args.airline.isEmpty ? '' : ' • ${args.airline}'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ProjectTheme.secondaryTextDark
                            : ProjectTheme.secondaryTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (args.amount != null)
                Text(
                  "${ElementFormatter.formatNumberWithSpaces(args.amount!)} UZS",
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
            ],
          ),
          context.szBoxHeight12,
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withAlpha(isDark ? 26 : 12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "refund_hint".tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil bo'limidan kirilganda — bo'lim nima ekanini tushuntiruvchi blok
/// (bu yerda aniq bilet yo'q, foydalanuvchi uni keyin tanlaydi).
class _RefundIntro extends StatelessWidget {
  const _RefundIntro();

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return RefundCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(isDark ? 40 : 18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_return_rounded,
                size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "refund_title".tr(),
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "refund_hint".tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? ProjectTheme.secondaryTextDark
                        : ProjectTheme.secondaryTextLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastdagi doimiy panel: "Yangi ariza" tugmasi hech qachon yo'qolmaydi.
/// Ochiq (pending) ariza bo'lsa tugma bloklanadi — server baribir
/// `409 ALREADY_REQUESTED` qaytaradi, shuning uchun sababini oldindan aytamiz.
class _BottomBar extends StatelessWidget {
  final bool hasOpenRequest;
  final VoidCallback onTap;

  const _BottomBar({required this.hasOpenRequest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.color.surface,
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasOpenRequest) ...[
                Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 15, color: ProjectTheme.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "refund_already_sent_hint".tr(),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ProjectTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              MainButtonWidget(
                title: hasOpenRequest
                    ? "refund_already_sent".tr()
                    : "refund_new_request".tr(),
                analyticsId: 'refund_new_request',
                onTap: hasOpenRequest ? null : onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 40 : 18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$count",
        style: context.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final bool perTicket;

  const _EmptyBox({required this.perTicket});

  @override
  Widget build(BuildContext context) {
    final secondary = context.themeProvider.isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return RefundCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 44, color: secondary),
          context.szBoxHeight12,
          Text(
            "refund_empty_title".tr(),
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (perTicket ? "refund_empty_desc" : "refund_empty_desc_all").tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              height: 1.4,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return RefundCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 42, color: ProjectTheme.error),
          context.szBoxHeight12,
          Text(
            message.isEmpty ? "error_other".tr() : message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
          ),
          context.szBoxHeight16,
          ElevatedButton(
            style: ProjectTheme.blueButtonStyle,
            onPressed: onRetry,
            child: Text("retry".tr()),
          ),
        ],
      ),
    );
  }
}

class _RequestsShimmer extends StatelessWidget {
  const _RequestsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    Widget bar(double width, double height) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: RefundCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    bar(110, 24),
                    const Spacer(),
                    bar(60, 14),
                  ],
                ),
                context.szBoxHeight16,
                bar(double.infinity, 12),
                const SizedBox(height: 10),
                bar(160, 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
