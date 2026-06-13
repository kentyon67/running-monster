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
    debugPrint('HiveBoxes.init() failed: $e');
    runApp(const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                SizedBox(height: 24),
                Text('データの初期化に失敗しました',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                SizedBox(height: 32),
                Text('アプリを再起動してください',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
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
