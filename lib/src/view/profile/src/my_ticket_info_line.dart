part of 'my_ticket_widget.dart';

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? valueColor;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    final secondaryColor = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withAlpha(isDark ? 40 : 16),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
