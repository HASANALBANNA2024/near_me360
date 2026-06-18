import 'package:hive_flutter/hive_flutter.dart';

class InitService {
  static const String _configBox = 'app_config';
  static const String _dataBox = 'cached_listings';

  static Future<void> initializeApp() async {
    try {
      // 🎯 শুধু Hive ডাটাবেজ বক্সগুলো ওপেন করে রেডি রাখা হবে
      await Hive.initFlutter();
      await Hive.openBox(_configBox);
      await Hive.openBox(_dataBox);

      print("📦 Hive Database initialized successfully. No fake downloads!");
    } catch (criticalCoreError) {
      print("🛑 Critical Core Error in Init: $criticalCoreError");
    }
  }
}
