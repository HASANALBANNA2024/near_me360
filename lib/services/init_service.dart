import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart'
    as geo; // মোবাইলের জন্য নাম আলাদা করা হলো
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InitService {
  static const String _configBox = 'app_config';
  static const String _dataBox = 'cached_listings';

  static Future<void> initializeApp() async {
    // 🛡️ সম্পূর্ণ কোডকে একটি মেইন ক্র্যাশ-প্রুফ ট্রাই-ক্যাচে ঢুকিয়ে দেওয়া হলো
    try {
      await Hive.initFlutter();
      final config = await Hive.openBox(_configBox);
      final dataBox = await Hive.openBox(_dataBox);

      // ১. চেক করা হচ্ছে ডেটা অলরেডি ডাউনলোড করা আছে কিনা
      bool isDownloaded = config.get('isDataDownloaded', defaultValue: false);

      if (isDownloaded) {
        print("🎉 ডেটা অলরেডি ডিভাইসে (Web/Mobile) লকড আছে! নো নতুন ডাউনলোড।");
        return;
      }

      String country =
          "Bangladesh"; // ফেইলসেফ ডিফল্ট দেশ (যদি লোকেশন কাজ না করে)

      // 🛡️ ২. শুধু লোকেশন লজিকটুকুর জন্য আলাদা সেফটি ব্লক
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          // ৩. রিয়েল-টাইম কারেন্ট পজিশন (টাইমআউটসহ, যাতে ব্রাউজার হ্যাং না করে)
          Position position =
              await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
              ).timeout(
                const Duration(seconds: 4),
              ); // ৪ সেকেন্ডে রেসপন্স না পেলে স্কিপ করবে

          // ৪. প্ল্যাটফর্ম অনুযায়ী দেশের নাম বের করার ইন্টেলিজেন্ট লজিক
          if (kIsWeb) {
            // 🌐 ওয়েবের জন্য নিরাপদ আইপি/লোকেশন এপিআই
            final response = await Dio().get(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
            );
            if (response.statusCode == 200 &&
                response.data['countryName'] != null) {
              country = response.data['countryName'];
            }
          } else {
            // 📱 মোবাইলের জন্য নেটিভ জিওকোডিং
            List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty && placemarks.first.country != null) {
              country = placemarks.first.country!;
            }
          }
        }
      } catch (locationError) {
        // ব্রাউজারে লোকেশন এরর দিলে এখানে আসবে, কিন্তু অ্যাপ ক্র্যাশ করবে না
        print("⚠️ Location bypass on Web/Mobile: $locationError");
      }

      print("📍 ইউজার এখন আছেন (Platform Verified): $country");

      // 🛡️ ৫. ডাউনলোড লজিকের জন্য আলাদা সেফটি ব্লক (URL ব্লক থাকলেও ক্র্যাশ করবে না)
      try {
        print("📥 $country-এর জন্য ফুল ডেটা ডাউনলোড শুরু হচ্ছে...");

        String url =
            "https://your-storage.com/maps/${country.toLowerCase()}_data.json";

        var response = await Dio().get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          await dataBox.put('full_country_data', response.data);
          await config.put('isDataDownloaded', true);
          print("💾 ফুল ডেটা Hive ডাটাবেজে লকড হয়ে গেছে! ডাউনলোড সাকসেসফুল।");
        }
      } catch (downloadError) {
        // ডামি বা ভুল URL এর কারণে Dio ফেল মারলে এখানে হ্যান্ডেল হবে
        print(
          "⚠️ Download failed or URL not active yet (App working fine): $downloadError",
        );
      }
    } catch (criticalCoreError) {
      // চরম কোনো এরর হলেও অ্যাপের মেইন স্ক্রিনকে সচল রাখবে
      print("🛑 Critical Core Bypass: $criticalCoreError");
    }
  }
}
