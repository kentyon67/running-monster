import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/hive_boxes.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await NotificationService.init();
  await AdService.init();
  runApp(const ProviderScope(child: App()));
}
