import 'package:flutter/material.dart';

/// Adds an iOS-style left-edge "swipe back" gesture to screens whose back
/// action is NOT a plain `Navigator.pop` — multi-step wizards that rewind one
/// step (`currentScreen--`), in-screen state resets, or forced redirects
/// (`pushRemove(HomePage)`).
///
/// Such screens sit behind a `PopScope(canPop: false)` so they can intercept
/// the system back button and run that custom logic. But `canPop: false`
/// ALSO disables the native CupertinoPageRoute interactive-pop gesture, so the
/// left-edge swipe stops working — which is exactly the gap this widget fills.
///
/// A narrow [edgeWidth]-wide translucent strip on the left edge listens for a
/// rightward drag and calls [onBack] — the SAME callback you wire into the
/// screen's `PopScope.onPopInvoked` and AppBar back button — so all three back
/// triggers behave identically. Because the strip only covers the very left
/// edge, inner content (including horizontal scrollables like a TabBarView or
/// a carousel) is left untouched.
///
/// Set [enabled] to false when the native pop gesture is already available
/// (e.g. a wizard's first step where back == pop and the host passes
/// `canPop: true`), to avoid two competing gestures on the same edge.
class EdgeSwipeBack extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;
  final double edgeWidth;
  final bool enabled;

  const EdgeSwipeBack({
    super.key,
    required this.child,
    required this.onBack,
    this.edgeWidth = 28,
    this.enabled = true,
  });

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  // Horizontal travel accumulated during the current drag.
  double _dx = 0;
  // Guards against firing [onBack] twice within a single drag (once mid-drag
  // when the distance threshold is hit, then again on release).
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: widget.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _dx = 0;
              _fired = false;
            },
            onHorizontalDragUpdate: (d) {
              if (_fired) return;
              _dx += d.delta.dx;
              // Commit mid-drag as soon as the gesture has travelled far
              // enough to the right. Firing here (instead of only on release)
              // is more responsive and avoids dropping the gesture when the
              // pointer is lifted outside the narrow edge strip.
              if (_dx > width * 0.20) {
                _fired = true;
                widget.onBack();
              }
            },
            onHorizontalDragEnd: (d) {
              if (_fired) return;
              final velocity = d.primaryVelocity ?? 0;
              // A quick rightward flick commits even on a short drag.
              if (velocity > 220 && _dx > 12) {
                widget.onBack();
              }
              _dx = 0;
            },
          ),
        ),
      ],
    );
  }
}
