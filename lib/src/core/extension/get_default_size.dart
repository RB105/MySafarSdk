import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pixel_snap/pixel_snap.dart';

extension GetDefaultSize on BuildContext {


  double get kPadding24 {
    var ps =PixelSnap.of(this);
    return 24.pixelSnap(ps);
  }

  double get kPadding16 {
    var ps =PixelSnap.of(this);
    return 16.pixelSnap(ps);
  }

  double get kPadding20 {
    var ps =PixelSnap.of(this);
    return 20.pixelSnap(ps);
  }

  double get kPadding10 {
  var ps =PixelSnap.of(this);
  return 10.pixelSnap(ps);
}

  double get kPadding4 {
    var ps =PixelSnap.of(this);
    return 4.pixelSnap(ps);
  }

  double get kPadding30 {
    var ps =PixelSnap.of(this);
    return 30.pixelSnap(ps);
  }

  BorderRadius get kRadius {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(16).pixelSnap(ps);
  }

  BorderRadius get kRadius8 {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(16).pixelSnap(ps);
  }

  BorderRadius get k8Radius {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(8).pixelSnap(ps);
  }
  BorderRadius get k12Radius {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(12).pixelSnap(ps);
  }

  BorderRadius get kRadius16 {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(16).pixelSnap(ps);
  }

  BorderRadius get kRadius12 {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(12).pixelSnap(ps);
  }


  BorderRadius get kRadius20 {
    var ps = PixelSnap.of(this);
    return BorderRadius.circular(20).pixelSnap(ps);
  }

  BorderRadius get kRadius24 {
    var ps = PixelSnap.of(this);
    return const BorderRadius.all(Radius.circular(24)).pixelSnap(ps);
  }
}