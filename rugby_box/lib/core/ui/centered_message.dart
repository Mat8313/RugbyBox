import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Un message centré, lisible sur fond sombre (liste vide, panne…).
class CenteredMessage extends StatelessWidget {
  const CenteredMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }
}
