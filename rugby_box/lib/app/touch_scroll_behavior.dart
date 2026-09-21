import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TouchScrollBehavior extends MaterialScrollBehavior {
  const TouchScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
