import 'package:flutter/material.dart';

class ScreenSimulator extends StatelessWidget {
  const ScreenSimulator({
    super.key,
    required this.child,
    this.screenSize = const Size(800, 480),
  });

  final Widget child;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey,
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: screenSize,
            child: ClipRect(
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(size: screenSize, devicePixelRatio: 1),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
