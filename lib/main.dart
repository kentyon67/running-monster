import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_boxes.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };

  try {
    await HiveBoxes.init();
  } catch (e) {
    debugPrint('HiveBoxes init failed: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  try {
    await AdService.init();
  } catch (e) {
    debugPrint('AdService init failed: $e');
  }

  runApp(const ProviderScope(child: App()));
}
