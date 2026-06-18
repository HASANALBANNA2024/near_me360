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
    await Hive.initFlutter();
    final config = await Hive.openBox(_configBox);
    final dataBox = await Hive.openBox(_dataBox);

    // ১. চেক করা হচ্ছে ডেটা অলরেডি ডাউনলোড করা আছে কিনা
    bool isDownloaded = config.get('isDataDownloaded', defaultValue: false);

    if (isDownloaded) {
      print("🎉 ডেটা অলরেডি ডিভাইসে (Web/Mobile) লকড আছে! নো নতুন ডাউনলোড।");
      return;
    }

    // ২. লোকেশন পারমিশন নেওয়া (এটি ওয়েব এবং মোবাইল দুই জায়গাতেই পপ-আপ দেখাবে)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // ৩. রিয়েল-টাইম কারেন্ট পজিশন নেওয়া (Web & Mobile দুটোতেই কাজ করবে)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      String country = "Unknown";

      // ৪. প্ল্যাটফর্ম অনুযায়ী দেশের নাম বের করার ইন্টেলিজেন্ট লজিক
      if (kIsWeb) {
        // 🌐 ওয়েবের জন্য: ফ্রি ও ওপেন সোর্স bigdatacloud API ব্যবহার করে দেশ বের করা
        try {
          final response = await Dio().get(
            'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${position.latitude}&longitude=${position.longitude}&localityLanguage=en',
          );
          if (response.statusCode == 200) {
            country = response.data['countryName'] ?? "Unknown";
          }
        } catch (e) {
          print("Web location parsing error: $e");
        }
      } else {
        // 📱 মোবাইলের জন্য: আগের সেই নেটিভ প্লাগইন
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          country = placemarks.first.country ?? "Unknown";
        } catch (e) {
          print("Mobile location parsing error: $e");
        }
      }

      print("📍 ইউজার এখন আছেন (Platform Verified): $country");

      // ৫. দেশ অনুযায়ী ওয়ান-টাইম ফুল ডেটা ডাউনলোড ও Hive-এ লক করা
      if (country != "Unknown") {
        try {
          print("📥 $country-এর জন্য ফুল ডেটা ডাউনলোড শুরু হচ্ছে...");

          String url =
              "https://your-storage.com/maps/${country.toLowerCase()}_data.json";

          // টেস্ট করার জন্য ডামি সাকসেস রেসপন্স (বাস্তবে আপনার URL কাজ করবে)
          var response = await Dio().get(url);

          if (response.statusCode == 200) {
            await dataBox.put('full_country_data', response.data);
            await config.put('isDataDownloaded', true);
            print("💾 ফুল ডেটা Hive ডাটাবেজে লকড হয়ে গেছে! ডাউনলোড সাকসেসফুল।");
          }
        } catch (e) {
          print("Error downloading database: $e");
        }
      }
    }
  }
}
