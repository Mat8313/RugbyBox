import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Autorise le défilement au doigt sur l'écran tactile, et à la souris en
/// développement (Flutter ne l'active pas sur bureau par défaut).
class TouchScrollBehavior extends MaterialScrollBehavior {
  const TouchScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
