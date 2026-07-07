import 'package:flutter/material.dart';

class HorizontalLoopAnimation extends StatefulWidget {
  const HorizontalLoopAnimation({super.key, required this.child});
  final Widget child;

  @override
  State<HorizontalLoopAnimation> createState() =>
      _HorizontalLoopAnimationState();
}

class _HorizontalLoopAnimationState extends State<HorizontalLoopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration for one loop
    );

    _animation = Tween<Offset>(
      begin: const Offset(-3.0, 0.0), // Start from left outside the screen
      end: const Offset(3.0, 0.0), // Move to right outside the screen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear, // Linear motion for consistent speed
    ));

    _controller.repeat(); // Repeat indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(position: _animation, child: widget.child),
    );
  }
}
