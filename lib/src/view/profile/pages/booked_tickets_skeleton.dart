part of 'booked_tickets_page.dart';

/// Buyurtma kartasi (MyTicketWidget) siluetidagi skelet: holat va raqam
/// chiplari, aviakompaniya qatori, vaqt chizig'i, tafsilotlar va tugma.
class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 92, height: 22, radius: 8),
            Spacer(),
            _SkeletonBox(width: 96, height: 22, radius: 8),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _SkeletonCircle(28),
            SizedBox(width: 8),
            _SkeletonBox(width: 130, height: 12),
            Spacer(),
            _SkeletonBox(width: 70, height: 12),
          ],
        ),
        SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 58, height: 20),
                SizedBox(height: 6),
                _SkeletonBox(width: 36, height: 12),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _SkeletonBox(width: 50, height: 10),
                  SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 2),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonBox(width: 58, height: 20),
                SizedBox(height: 6),
                _SkeletonBox(width: 36, height: 12),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
        _SkeletonLine(),
        SizedBox(height: 10),
        _SkeletonLine(),
        SizedBox(height: 16),
        _SkeletonBox(width: double.infinity, height: 50, radius: 14),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _SkeletonBox(width: 80, height: 12),
        Spacer(),
        _SkeletonBox(width: 110, height: 12),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle(this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
