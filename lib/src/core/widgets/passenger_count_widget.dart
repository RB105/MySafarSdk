import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;

/// Yo'lovchilar soni va tarif (klass) tanlash sheet'i — zamonaviy karta
/// uslubida: dumaloq +/- tugmalar, tanlangan klass brand hoshiya bilan
/// ajratiladi. Natija `{"adt","chd","inf","klass"}` map ko'rinishida
/// qaytariladi (eski shartnoma saqlangan).
class PassengerCountWidget extends StatefulWidget {
  final Map<String, dynamic> params;

  const PassengerCountWidget({super.key, required this.params});

  @override
  State<PassengerCountWidget> createState() => _PassengerCountWidgetState();
}

class _PassengerCountWidgetState extends State<PassengerCountWidget> {
  int adt = 1;
  int chd = 0;
  int inf = 0;
  String klass = 'a';

  @override
  void initState() {
    super.initState();
    if (widget.params.isNotEmpty) {
      adt = widget.params['adt'] ?? 1;
      chd = widget.params['chd'] ?? 0;
      inf = widget.params['inf'] ?? 0;
      klass = widget.params['klass'] ?? 'a';
    }
  }

  bool get isMax => adt + chd + inf == 9;

  void _apply() {
    HapticFeedback.mediumImpact();
    Navigator.of(context)
        .pop({"adt": adt, "chd": chd, "inf": inf, "klass": klass});
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      adt = 1;
      chd = 0;
      inf = 0;
      klass = 'a';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Dastak.
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(110),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Sarlavha + yopish.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "passenger_count_title".tr(),
                      style: context.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  Material(
                    color: ProjectTheme.borderLight.withAlpha(120),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "passenger_count_header".tr(),
                      style: context.textTheme.headlineSmall
                          ?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    // Yo'lovchilar kartasi.
                    Container(
                      decoration: BoxDecoration(
                        color: context.color.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: context.shadowDown,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Column(
                        children: [
                          _counterRow(
                            title: "above_12".tr(),
                            count: adt,
                            canRemove: adt > 1,
                            onRemove: () => setState(() => adt--),
                            onAdd: () => setState(() => adt++),
                          ),
                          _divider(),
                          _counterRow(
                            title: "between_2_12".tr(),
                            count: chd,
                            canRemove: chd > 0,
                            onRemove: () => setState(() => chd--),
                            onAdd: () => setState(() => chd++),
                          ),
                          _divider(),
                          _counterRow(
                            title: "under_2".tr(),
                            count: inf,
                            canRemove: inf > 0,
                            onRemove: () => setState(() => inf--),
                            onAdd: () => setState(() => inf++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "show_age_feedback_subtitle".tr(),
                      style: context.textTheme.headlineSmall
                          ?.copyWith(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "klass_tab".tr(),
                      style: context.textTheme.headlineSmall
                          ?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    // Tarif (klass) tanlash — tanlangani brand hoshiya bilan.
                    for (final entry in const [
                      ('e', 'klass_e'),
                      ('b', 'klass_b'),
                      ('f', 'klass_f'),
                      ('w', 'klass_w'),
                      ('a', 'klass_a'),
                    ]) ...[
                      _klassRow(entry.$1, entry.$2.tr()),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            // Pastki tugmalar.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: context.filterCancelButtonStyle,
                        onPressed: _reset,
                        child: Text("reset".tr(),
                            style: context.textTheme.bodyMedium),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ProjectTheme.blueButtonStyle,
                        onPressed: _apply,
                        child: Text(
                          "apply".tr(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: ProjectTheme.borderLight);

  /// Bitta yo'lovchi turi qatori: nom + dumaloq -/soni/+ boshqaruvi.
  Widget _counterRow({
    required String title,
    required int count,
    required bool canRemove,
    required VoidCallback onRemove,
    required VoidCallback onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          _roundButton(
            icon: Icons.remove_rounded,
            enabled: canRemove,
            filled: false,
            onTap: () {
              if (!canRemove) return;
              HapticFeedback.lightImpact();
              onRemove();
            },
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                "$count",
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          _roundButton(
            icon: Icons.add_rounded,
            enabled: !isMax,
            filled: true,
            onTap: () {
              if (isMax) return;
              HapticFeedback.lightImpact();
              onAdd();
            },
          ),
        ],
      ),
    );
  }

  /// Dumaloq +/- tugma: qo'shish — to'ldirilgan brand, ayirish — hoshiyali.
  Widget _roundButton({
    required IconData icon,
    required bool enabled,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final Color brand = ProjectTheme.brandColor;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: filled ? brand : Colors.transparent,
        shape: filled
            ? const CircleBorder()
            : CircleBorder(side: BorderSide(color: brand, width: 1.4)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 20,
              color: filled ? Colors.white : brand,
            ),
          ),
        ),
      ),
    );
  }

  /// Klass qatori: tanlangani brand hoshiya + och fon + belgili radio.
  Widget _klassRow(String type, String title) {
    final bool selected = klass == type;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? ProjectTheme.brandColor.withAlpha(isDark ? 46 : 16)
          : context.color.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => klass = type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ProjectTheme.brandColor : ProjectTheme.borderLight,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.trim(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 22,
                color: selected
                    ? ProjectTheme.brandColor
                    : Colors.grey.withAlpha(140),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
