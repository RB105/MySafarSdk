import 'package:mysafar_sdk/src/cubit/profile/tickets/confirmed_tickets_cubit.dart';
import 'package:mysafar_sdk/src/model/remote/profile/confirmed_ticket_models.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart' show ElementFormatter;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

import 'refund_requests_page.dart' show RefundArgs;

/// Qaysi bilet uchun ariza berilishini tanlash oynasi (pastdan chiqadigan
/// sheet). Ro'yxat `/avia/user-confirmed-tickets` dan keladi — unda
/// foydalanuvchi o'zi olgan biletlar ham, **operator/call-center uning
/// raqamiga olib bergan** biletlar ham bo'ladi.
///
/// [blockedBillingIds] — allaqachon ochiq arizasi bor biletlar; ular tanlanmaydi
/// (server `409 ALREADY_REQUESTED` qaytaradi).
///
/// Tanlansa [RefundArgs], bekor qilinsa `null` qaytaradi.
Future<RefundArgs?> showRefundTicketPicker(
  BuildContext context, {
  Set<String> blockedBillingIds = const {},
}) {
  return showModalBottomSheet<RefundArgs>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.color.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RefundTicketPicker(blockedBillingIds: blockedBillingIds),
  );
}

class _RefundTicketPicker extends StatefulWidget {
  final Set<String> blockedBillingIds;

  const _RefundTicketPicker({required this.blockedBillingIds});

  @override
  State<_RefundTicketPicker> createState() => _RefundTicketPickerState();
}

class _RefundTicketPickerState extends State<_RefundTicketPicker> {
  late final ConfirmedTicketsCubit _cubit;
  final _searchController = TextEditingController();

  /// Chiqarilgan (to'langan) biletlar — ariza faqat shular uchun beriladi.
  /// Solishtirish kichik harflarda: server statusni turlicha yozishi mumkin
  /// ("Ticketed" / "ticketed").
  static const Set<String> _paidStatuses = {
    'paid',
    'ticketed',
    'partiallyticketed',
    'ticketedwaitingpnr',
  };

  /// Bilet to'langanmi (chiptalashtirilganmi).
  static bool _isPaid(ConfirmedTicketsModel t) =>
      _paidStatuses.contains((t.callbackStatus ?? '').trim().toLowerCase());

  /// Biletning eng kech jo'nash vaqti. Borish-qaytishda qaytish parvozi hali
  /// oldinda bo'lsa bilet "muddati o'tgan" hisoblanmaydi — shu sababli eng
  /// kechi olinadi. Sana umuman o'qilmasa `null`.
  static DateTime? _lastDeparture(ConfirmedTicketsModel t) {
    final segments = t.response?.data?.book?.flight?.segments ?? const [];
    DateTime? latest;
    for (final segment in segments) {
      final d = _parseDeparture(segment.dep);
      if (d == null) continue;
      if (latest == null || d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  /// Bilet muddati o'tmaganmi. Sana noma'lum bo'lsa (server segment
  /// bermagan) bilet ro'yxatda qoladi — uni "o'tgan" deb ayta olmaymiz.
  static bool _isUpcoming(ConfirmedTicketsModel t) {
    final dep = _lastDeparture(t);
    return dep == null || dep.isAfter(DateTime.now());
  }

  /// "26.08.2026 04:20:00" yoki "26.08.2026" (ba'zan "2026-08-26") →
  /// [DateTime]. Vaqt bo'lmasa kun oxiri olinadi — o'sha kuni jo'naydigan
  /// bilet kun davomida ro'yxatdan tushib qolmaydi.
  static DateTime? _parseDeparture(ConfirmedTicketArr? dep) {
    if (dep == null) return null;
    final source = ((dep.datetime ?? '').trim().isNotEmpty
            ? dep.datetime!
            : (dep.date ?? ''))
        .trim();
    if (source.isEmpty) return null;

    final parts = source.split(RegExp(r'[ T]'));
    final ymd = parts.first.split(RegExp(r'[.\-/]'));
    if (ymd.length != 3) return null;

    final int? first = int.tryParse(ymd[0]);
    final int? month = int.tryParse(ymd[1]);
    final int? last = int.tryParse(ymd[2]);
    if (first == null || month == null || last == null) return null;
    // "yyyy-MM-dd" va "dd.MM.yyyy" — ikkalasi ham qo'llab-quvvatlanadi.
    final bool yearFirst = ymd[0].length == 4;
    final int year = yearFirst ? first : last;
    final int day = yearFirst ? last : first;

    int hour = 23;
    int minute = 59;
    if (parts.length > 1) {
      final time = parts[1].split(':');
      final h = int.tryParse(time.first);
      if (h != null) {
        hour = h;
        minute = time.length > 1 ? (int.tryParse(time[1]) ?? 0) : 0;
      }
    }
    return DateTime(year, month, day, hour, minute);
  }

  @override
  void initState() {
    super.initState();
    // Konstruktorning o'zi biletlarni yuklaydi (avval keshdan, keyin serverdan).
    _cubit = ConfirmedTicketsCubit();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  /// Ariza berish mumkin bo'lgan biletlar: FAQAT to'langan (chiptalashtirilgan)
  /// va muddati o'tmagan (jo'nash vaqti hali kelmagan) biletlar. Qolganlari
  /// ro'yxatga tushmaydi — bekor qilingan, to'lanmagan yoki uchib bo'lingan
  /// bilet uchun vozvrat arizasi ma'nosiz. Ro'yxatda yo'q bilet uchun pastdagi
  /// "ID bilan davom etish" zaxira yo'li qoladi.
  List<ConfirmedTicketsModel> _filter(List<ConfirmedTicketsModel> tickets) {
    final list = tickets.where((t) => _isPaid(t) && _isUpcoming(t)).toList();
    // Eng yaqin parvoz tepada — vozvrat odatda yaqin sana uchun so'raladi.
    list.sort((a, b) {
      final aDep = _lastDeparture(a);
      final bDep = _lastDeparture(b);
      if (aDep == null && bDep == null) return 0;
      if (aDep == null) return 1;
      if (bDep == null) return -1;
      return aDep.compareTo(bDep);
    });
    if (_query.isEmpty) return list;
    return list.where((t) {
      final id = (t.billingId ?? '').toLowerCase();
      final dir = (t.direction ?? '').toLowerCase();
      final airline = (t.airline ?? '').toLowerCase();
      return id.contains(_query) ||
          dir.contains(_query) ||
          airline.contains(_query);
    }).toList();
  }

  /// Ro'yxatda topilmagan bilet uchun zaxira: kiritilgan matn ID ga o'xshasa
  /// (faqat raqam, 6+ belgi) o'sha ID bilan davom etish taklif qilinadi.
  bool get _canUseRawId =>
      RegExp(r'^\d{6,}$').hasMatch(_searchController.text.trim());

  void _select(RefundArgs args) => Navigator.of(context).pop(args);

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;

    return BlocProvider.value(
      value: _cubit,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondary.withAlpha(90),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "refund_pick_ticket_title".tr(),
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "refund_pick_ticket_desc".tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.35,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.text,
                style: context.textTheme.bodyMedium?.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "refund_search_ticket".tr(),
                  hintStyle: context.textTheme.bodySmall
                      ?.copyWith(fontSize: 13.5, color: secondary),
                  prefixIcon:
                      Icon(Icons.search_rounded, size: 20, color: secondary),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: secondary),
                          onPressed: _searchController.clear,
                        ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.color.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: ProjectTheme.brandColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.color.outline),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<ConfirmedTicketsCubit, ConfirmedTicketsState>(
                builder: (context, state) =>
                    _list(context, state, scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    ConfirmedTicketsState state,
    ScrollController controller,
  ) {
    if (state is ConfirmedTicketsLoadingState ||
        state is ConfirmedTicketsInitState) {
      return const Center(child: CircularProgressIndicator());
    }

    final tickets = state is ConfirmedTicketsSuccessState
        ? _filter(state.confirmedTickets)
        : const <ConfirmedTicketsModel>[];

    if (tickets.isEmpty) {
      return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Icon(Icons.search_off_rounded,
              size: 44, color: context.color.outline),
          const SizedBox(height: 12),
          Text(
            "refund_no_tickets".tr(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
          ),
          if (_canUseRawId) ...[
            const SizedBox(height: 16),
            _rawIdTile(context),
          ],
        ],
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + context.bottomPadding),
      itemCount: tickets.length + (_canUseRawId ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        if (index == tickets.length) return _rawIdTile(context);
        return _ticketTile(context, tickets[index]);
      },
    );
  }

  /// Ro'yxatdan topilmagan biletni ID orqali tanlash (zaxira yo'l).
  Widget _rawIdTile(BuildContext context) {
    final id = _searchController.text.trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(RefundArgs(billingId: id)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ProjectTheme.brandColor.withAlpha(120),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.tag_rounded,
                size: 18, color: ProjectTheme.brandColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "refund_use_id".tr(namedArgs: {"id": id}),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ProjectTheme.brandColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketTile(BuildContext context, ConfirmedTicketsModel ticket) {
    final isDark = context.themeProvider.isDark;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final billingId = (ticket.billingId ?? '').trim();
    final blocked = widget.blockedBillingIds.contains(billingId);
    final status = ticket.callbackStatus ?? '';
    final amount =
        ticket.response?.data?.book?.order?.price?.uzs?.amount;
    final accent =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;

    return Opacity(
      opacity: blocked ? 0.55 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: blocked || billingId.isEmpty
            ? null
            : () => _select(RefundArgs(
                  billingId: billingId,
                  direction: ticket.direction ?? '',
                  airline: ticket.airline ?? '',
                  amount: amount,
                )),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (ticket.direction ?? '').isEmpty
                          ? "ID: $billingId"
                          : ticket.direction!.replaceAll('-', ' → '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (amount != null)
                    Text(
                      "${ElementFormatter.formatNumberWithSpaces(amount)} UZS",
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "ID: $billingId"
                      "${(ticket.airline ?? '').isEmpty ? '' : ' • ${ticket.airline}'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                  ),
                  if (status.isNotEmpty)
                    Text(
                      status.tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _paidStatuses.contains(status.toLowerCase())
                            ? ProjectTheme.success
                            : secondary,
                      ),
                    ),
                ],
              ),
              if (blocked) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 14, color: ProjectTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      "refund_already_sent".tr(),
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ProjectTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
