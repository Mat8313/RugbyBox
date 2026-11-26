import 'package:flutter/painting.dart';

/// Palette de l'app : fond très sombre (l'écran reste allumé toute la
/// journée), cartes un ton au-dessus, un seul rouge pour attirer l'œil.
abstract final class AppColors {
  static const background = Color(0xFF0A0E17);
  static const surface = Color(0xFF141A26);
  static const surfaceRaised = Color(0xFF1C2433);

  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFF8A93A6);
  static const textMuted = Color(0xFF545D70);

  /// Équipe mise en avant, et match en direct.
  static const highlight = Color(0xFFE2142D);

  /// Zones du classement.
  static const zoneSemiFinal = Color(0xFF2ECC71);
  static const zonePlayoff = Color(0xFF3FA9F5);
  static const zoneRelegationPlayoff = Color(0xFFF39C12);
  static const zoneRelegation = Color(0xFFE74C3C);
}

/// Chiffres à largeur fixe : « 11 » et « 18 » prennent la même place, les
/// colonnes de scores et de points restent alignées.
const tabularFigures = [FontFeature.tabularFigures()];
