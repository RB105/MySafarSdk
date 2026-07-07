import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_tariff_model.dart'
    show FlightTariffModel;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

class TariffPickerWidget extends StatefulWidget {
  final List<FlightTariffModel> tariffs;
  final String id;

  const TariffPickerWidget(
      {super.key, required this.tariffs, required this.id});

  @override
  State<TariffPickerWidget> createState() => _TariffPickerWidgetState();
}

class _TariffPickerWidgetState extends State<TariffPickerWidget> {
  /// selected tariff index
  late int selected;
  var tariffs = <FlightTariffModel>[];

  @override
  void initState() {
    tariffs = widget.tariffs;
    selected = 0;
    for (int i = 0; i < tariffs.length; i++) {
      if (tariffs[i].flight.id == widget.id) {
        selected = i;
        break;
      }
    }
    super.initState();
  }

  String _tariffName(FlightTariffModel t, int index) {
    final marketing = t.flight.fareFamilyMarketingName?.trim() ?? '';
    if (marketing.isNotEmpty) return marketing;
    final type = t.flight.fareFamilyType?.trim() ?? '';
    if (type.isNotEmpty) return type;
    return "Tarif ${index + 1}";
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (_, __) => context.szBoxHeight12,
              itemCount: tariffs.length,
              itemBuilder: (context, index) => _TariffCard(
                tariff: tariffs[index],
                name: _tariffName(tariffs[index], index),
                priceLabel: currencyProvider
                    .getElementPrice(tariffs[index].flight.price),
                isSelected: index == selected,
                onTap: () => setState(() => selected = index),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, currencyProvider),
    );
  }

  // ── Header (grabber + title + close) ─────────────────────────────────
  Widget _header(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(45)
                    : Colors.black.withAlpha(35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'choose_other_tariff'.tr(),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Material(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pinned bottom bar ────────────────────────────────────────────────
  Widget _bottomBar(BuildContext context, CurrencyProvider currencyProvider) {
    final brand = ProjectTheme.brandColor;
    final secondary = context.themeProvider.isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final name = _tariffName(tariffs[selected], selected);
    final price =
        currencyProvider.getElementPrice(tariffs[selected].flight.price);

    return Container(
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: context.shadowUp,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall
                              ?.copyWith(fontSize: 12, color: secondary),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            price,
                            style: context.textTheme.labelLarge?.copyWith(
                              color: brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(tariffs[selected].flight);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [brand, ProjectTheme.blueBg],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brand.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "continue".tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  TARIFF CARD
// ════════════════════════════════════════════════════════════════════

class _TariffCard extends StatelessWidget {
  final FlightTariffModel tariff;
  final String name;
  final String priceLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TariffCard({
    required this.tariff,
    required this.name,
    required this.priceLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    final isDark = context.themeProvider.isDark;
    final flight = tariff.flight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: isSelected ? 2 : 1,
              color: isSelected ? brand : context.color.outline.withAlpha(120),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: brand.withAlpha(45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : context.shadowDown,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: radio + name + price badge
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    _RadioDot(isSelected: isSelected),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [brand, ProjectTheme.blueBg],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : brand.withAlpha(isDark ? 45 : 22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priceLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _DashedDivider(
                color: isDark
                    ? Colors.white.withAlpha(28)
                    : Colors.black.withAlpha(20),
              ),
              // Features
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.event_seat_rounded,
                      label: "seat_count".tr(
                          namedArgs: {"count": "${flight.getSeatCount()}"}),
                      status: null,
                    ),
                    _FeatureRow(
                      icon: Icons.shopping_bag_outlined,
                      label: flight.withCBaggage()
                          ? "luggage_size".tr(
                              namedArgs: {"count": flight.getCBaggage()})
                          : "no_luggage".tr(),
                      status: flight.withCBaggage(),
                    ),
                    _FeatureRow(
                      icon: Icons.luggage_rounded,
                      label: flight.withBaggage()
                          ? "${"baggage_button_title".tr()}: ${flight.getBaggage()}"
                          : flight.getBaggage(),
                      status: flight.withBaggage(),
                    ),
                    _FeatureRow(
                      icon: Icons.swap_horiz_rounded,
                      label: flight.isExchangeable()
                          ? "exchangeable".tr()
                          : "unexchangeable".tr(),
                      status: flight.isExchangeable(),
                    ),
                    _FeatureRow(
                      icon: Icons.currency_exchange_rounded,
                      label: (flight.isRefund ?? false)
                          ? "refundable".tr()
                          : "unrefundable".tr(),
                      status: flight.isRefund ?? false,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;

  const _RadioDot({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final brand = ProjectTheme.brandColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand, ProjectTheme.blueBg],
              )
            : null,
        border: isSelected
            ? null
            : Border.all(color: context.color.outline, width: 2),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  /// null → neutral (info), true → available (green), false → not (red)
  final bool? status;
  final bool isLast;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.status,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final brand =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brand.withAlpha(isDark ? 45 : 20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: brand),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(fontSize: 13.5),
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            Icon(
              status! ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 20,
              color: status! ? ProjectTheme.success : ProjectTheme.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 1,
        child: CustomPaint(
          painter: _DashPainter(color: color),
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash) < size.width ? (x + dash) : size.width;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}
