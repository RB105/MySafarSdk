part of 'refund_requests_page.dart';

/// Bitta ariza kartasi: holat, yuborilgan vaqt, karta/telefon, sabab va
/// (rad etilgan yoki tasdiqlangan bo'lsa) support izohi.
class _RefundRequestCard extends StatelessWidget {
  final RefundRequestModel request;

  const _RefundRequestCard({required this.request});

  /// "11.08.2026, 15:20" — vaqt lokal zonada ko'rsatiladi.
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

    return RefundCard(
      // Holat rangi karta chetida ham sezilsin — ro'yxatni ko'z bilan
      // ajratishni osonlashtiradi.
      borderColor: request.status.color.withAlpha(isDark ? 90 : 60),
      // Butun karta bosiladi — to'liq ma'lumot (ayniqsa support izohi)
      // alohida oynada ochiladi.
      onTap: () => showRefundRequestDetails(context, request),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Qaysi bilet — profil bo'limida arizalar turli biletlarga tegishli
          // bo'lgani uchun bu qator birinchi bo'lib turadi.
          if ((request.direction ?? '').isNotEmpty ||
              (request.billingId ?? '').isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.flight_takeoff_rounded, size: 15, color: secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if ((request.direction ?? '').isNotEmpty)
                        request.direction!.replaceAll('-', ' → '),
                      if ((request.billingId ?? '').isNotEmpty)
                        "ID: ${request.billingId}",
                      if ((request.airline ?? '').isNotEmpty) request.airline!,
                    ].join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              RefundStatusChip(status: request.status),
              const Spacer(),
              if (request.id != null)
                Text(
                  "№${request.id}",
                  style: context.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondary,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: secondary),
            ],
          ),
          const SizedBox(height: 12),
          if (request.maskedCard.isNotEmpty)
            RefundInfoRow(
              icon: Icons.credit_card_rounded,
              label: "refund_card_number".tr(),
              value: request.maskedCard,
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
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Quote(
              label: "refund_reason".tr(),
              text: reason,
              color: secondary,
            ),
          ],
          // Support izohi — ayniqsa `rejected` da MUHIM: foydalanuvchi
          // nima uchun rad etilganini bilishi kerak. Kartada uzun izoh
          // ro'yxatni cho'zib yubormasligi uchun qisqartiriladi, to'lig'i
          // "Batafsil" (karta bosilganda) oynasida.
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Quote(
              label: "refund_support_comment".tr(),
              text: comment,
              color: request.status.color,
              tinted: true,
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "refund_details_open".tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ProjectTheme.brandColor,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: ProjectTheme.brandColor),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sabab / support izohi uchun "iqtibos" bloki.
class _Quote extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final bool tinted;

  /// `null` — matn to'liq ko'rsatiladi (ma'lumot oynasi); son berilsa
  /// ro'yxatdagi karta uchun qisqartiriladi.
  final int? maxLines;

  const _Quote({
    required this.label,
    required this.text,
    required this.color,
    this.tinted = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tinted
            ? color.withAlpha(isDark ? 30 : 14)
            : (isDark
                ? Colors.white.withAlpha(10)
                : Colors.black.withAlpha(8)),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
