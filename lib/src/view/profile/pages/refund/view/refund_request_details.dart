part of 'refund_requests_page.dart';

/// Ariza kartasi bosilganda ochiladigan to'liq ma'lumot oynasi.
///
/// Bu yerdagi asosiy narsa — **support izohi** (`support_comment`): support
/// arizani rad etsa sababini, qaytarsa esa qaytarish tafsilotlarini shu
/// maydonga yozadi. Ro'yxatdagi karta uni qisqartirib ko'rsatadi, bu oynada
/// esa to'liq matn chiqadi.
Future<void> showRefundRequestDetails(
  BuildContext context,
  RefundRequestModel request,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.color.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RefundRequestDetails(request: request),
  );
}

class _RefundRequestDetails extends StatelessWidget {
  final RefundRequestModel request;

  const _RefundRequestDetails({required this.request});

  String _formatDate(DateTime? date) =>
      date == null ? '' : DateFormat('dd.MM.yyyy, HH:mm').format(date);

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final secondary = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final comment = (request.supportComment ?? '').trim();
    final reason = (request.reason ?? '').trim();

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "refund_details_title".tr(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (request.id != null)
                    Text(
                      "№${request.id}",
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: secondary,
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Row(children: [RefundStatusChip(status: request.status)]),
                  context.szBoxHeight12,
                  // ── Bilet ──
                  RefundCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((request.direction ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.flight_takeoff_rounded,
                            label: "refund_title".tr(),
                            value: request.direction!.replaceAll('-', ' → '),
                          ),
                        if ((request.billingId ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.tag_rounded,
                            label: "ticket_id".tr(),
                            value: request.billingId!,
                          ),
                        if ((request.airline ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.airlines_rounded,
                            label: "airline".tr(),
                            value: request.airline!,
                          ),
                        if ((request.ticketStatus ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.confirmation_number_outlined,
                            label: "refund_ticket_status".tr(),
                            value: request.ticketStatus!,
                          ),
                      ],
                    ),
                  ),
                  context.szBoxHeight12,
                  // ── Ariza ──
                  RefundCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.maskedCard.isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.credit_card_rounded,
                            label: "refund_card_number".tr(),
                            value: request.maskedCard,
                          ),
                        if ((request.cardHolder ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: "refund_card_holder".tr(),
                            value: request.cardHolder!,
                          ),
                        if ((request.phoneNumber ?? '').isNotEmpty)
                          RefundInfoRow(
                            icon: Icons.phone_rounded,
                            label: "refund_phone".tr(),
                            value: request.phoneNumber!,
                          ),
                        RefundInfoRow(
                          icon: Icons.swap_horiz_rounded,
                          label: "refund_type".tr(),
                          value: request.refundType.labelKey.tr(),
                        ),
                        if (request.createdAt != null)
                          RefundInfoRow(
                            icon: Icons.schedule_rounded,
                            label: "refund_created_at".tr(),
                            value: _formatDate(request.createdAt),
                          ),
                        if (request.processedAt != null)
                          RefundInfoRow(
                            icon: Icons.task_alt_rounded,
                            label: "refund_processed_at".tr(),
                            value: _formatDate(request.processedAt),
                          ),
                      ],
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    context.szBoxHeight12,
                    _Quote(
                      label: "refund_reason".tr(),
                      text: reason,
                      color: secondary,
                    ),
                  ],
                  context.szBoxHeight12,
                  // ── Support izohi — oynaning asosiy maqsadi ──
                  if (comment.isNotEmpty)
                    _Quote(
                      label: "refund_support_comment".tr(),
                      text: comment,
                      color: request.status.color,
                      tinted: true,
                    )
                  else
                    _Quote(
                      label: "refund_support_comment".tr(),
                      text: "refund_support_comment_empty".tr(),
                      color: secondary,
                    ),
                  context.szBoxHeight24,
                  MainButtonWidget(
                    title: "close".tr(),
                    analyticsId: 'refund_details_close',
                    onTap: () => Navigator.of(context).pop(),
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
