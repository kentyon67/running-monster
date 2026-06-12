import 'package:flutter/services.dart';

class HapticService {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();

  static void levelUp() => HapticFeedback.heavyImpact();
  static void evolution() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120),
        () => HapticFeedback.mediumImpact());
  }

  static void gacha() => HapticFeedback.mediumImpact();
  static void runStart() => HapticFeedback.mediumImpact();
  static void runStop() => HapticFeedback.heavyImpact();
  static void missionComplete() => HapticFeedback.lightImpact();
  static void buttonTap() => HapticFeedback.selectionClick();
}
