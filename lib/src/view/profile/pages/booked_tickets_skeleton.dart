part of 'booked_tickets_page.dart';

class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _SkeletonCircle(36),
            SizedBox(width: 10),
            _SkeletonBox(width: 76, height: 22, radius: 20),
            Spacer(),
            _SkeletonBox(width: 88, height: 22, radius: 20),
          ],
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            _SkeletonCircle(38),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 118, height: 14),
                SizedBox(height: 6),
                _SkeletonBox(width: 70, height: 10),
              ],
            ),
            Spacer(),
            _SkeletonBox(width: 64, height: 22, radius: 20),
          ],
        ),
        const SizedBox(height: 18),
        for (int i = 0; i < 2; i++) ...[
          const Row(
            children: [
              _SkeletonBox(width: 32, height: 32, radius: 10),
              SizedBox(width: 10),
              _SkeletonBox(width: 92, height: 12),
              Spacer(),
              _SkeletonBox(width: 110, height: 12),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        const _SkeletonBox(width: double.infinity, height: 48, radius: 14),
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
