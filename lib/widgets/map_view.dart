import 'package:dio_cache_interceptor/dio_cache_interceptor.dart'; // ওয়েব ও মোবাইলের ক্যাশ ইন্টারসেপ্টর
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ১. ওপেন-স্ট্রিট ক্যাশ ম্যাপ (ওয়েব এবং মোবাইল দুটোর জন্যই উপযোগী)
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(23.8103, 90.4125), // ঢাকা ডিফল্ট
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nearme360.app',
                  tileProvider: CachedTileProvider(
                    // MemCacheStore ওয়েব ব্রাউজার এবং মোবাইল দুই জায়গাতেই ১০০% সাপোর্টেড
                    store: MemCacheStore(),
                  ),
                ),
              ],
            ),

            // ২. টপ-লেফট লোকেশন ব্যানার
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Text(
                  'Dhaka, Bangladesh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ৩. সেন্টারে থাকা লোকেশন পিন
            const Center(
              child: Icon(Icons.location_on, color: Colors.blue, size: 40),
            ),
          ],
        ),
      ),
    );
  }
}
