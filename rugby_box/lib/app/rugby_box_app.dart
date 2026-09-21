import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'touch_scroll_behavior.dart';
import '../core/config/app_config.dart';

class RugbyBoxApp extends ConsumerWidget {
  const RugbyBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: 'RugbyBox',
      scrollBehavior: const TouchScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const Text(
                'Hello RCT',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
              Text(
                config.useMockData ? 'Données fictives' : 'Données réelles',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
