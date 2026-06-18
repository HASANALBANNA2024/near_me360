import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);

    List<Marker> allMarkers = [];

    // ১. ইউজারের লাইভ জিপিএস পিন (সবুজ রঙের)
    allMarkers.add(
      Marker(
        point: homeProvider.userLatLng,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.green, size: 30),
      ),
    );

    // ২. ফিল্টার হওয়া ক্যাটাগরির সব রিয়েল লোকেশন পিন একসাথে ম্যাপে রেন্ডার করা
    for (int i = 0; i < homeProvider.listings.length; i++) {
      var item = homeProvider.listings[i];

      // 🎯 সরাসরি Hive ডাটাবেজের রিয়েল LatLng রিড করা হচ্ছে
      LatLng realItemLocation = homeProvider.getRealLocationForListing(item);

      allMarkers.add(
        Marker(
          point: realItemLocation,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              // 🎯 ফিক্স: এখানে context এবং item দুটোই পাস করা হয়েছে
              homeProvider.selectListingAndShowRoute(context, item);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: homeProvider.selectedListing?.name == item.name
                    ? Colors.white.withOpacity(0.9)
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: homeProvider.selectedListing?.name == item.name
                    ? [
                        BoxShadow(
                          color: item.iconColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                item.icon,
                color: homeProvider.selectedListing?.name == item.name
                    ? Colors.red
                    : item.iconColor,
                size: homeProvider.selectedListing?.name == item.name ? 36 : 28,
              ),
            ),
          ),
        ),
      );
    }

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
            FlutterMap(
              options: MapOptions(
                initialCenter:
                    homeProvider.mapCenter ?? LatLng(23.8103, 90.4125),
                initialZoom: homeProvider.mapZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nearme360.app',
                  tileProvider: CachedTileProvider(store: MemCacheStore()),
                ),

                // 🔵 ডাটাবেজের রিয়েল স্পটের আঁকাবাঁকা আসল রাস্তার লেয়ার
                if (homeProvider.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: homeProvider.routePoints,
                        strokeWidth: 5.5,
                        color: Colors.blue,
                      ),
                    ],
                  ),

                // 📍 সবগুলো রিয়েল মার্কার ডিসপ্লে লেয়ার
                MarkerLayer(markers: allMarkers),
              ],
            ),

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
                child: Text(
                  homeProvider.selectedListing != null
                      ? "📍 Destination: ${homeProvider.selectedListing!.name}"
                      : '${homeProvider.selectedCategory.isEmpty ? 'All' : homeProvider.selectedCategory} Real Places Locked',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
