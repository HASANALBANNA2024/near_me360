import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:near_me360/models/listing_model.dart';
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

    // ২. 🎯 ফিক্স: পেজের ১০টা না, এপিআই থেকে আসা সব লোকেশন (allListingCoords) একসাথে ম্যাপে পিন করা হচ্ছে!
    homeProvider.allListingCoords.forEach((name, latLng) {
      // এই স্পেসিফিক পিনটার নাম দিয়ে listings-এর ভেতর থেকে মেইন মডেল অবজেক্টটা খুঁজে বের করা হচ্ছে
      // যদি কারেন্ট পেজে নাও থাকে, তাও আমরা একটা ডাইনামিক মডেল জেনারেট করে ম্যাপে আইকন শো করাবো
      var matchItems = homeProvider.listings.where((l) => l.name == name);
      var currentItem = matchItems.isNotEmpty ? matchItems.first : null;

      IconData markerIcon = currentItem?.icon ?? Icons.place;
      Color markerColor = currentItem?.iconColor ?? Colors.red;

      bool isSelected = homeProvider.selectedListing?.name == name;

      allMarkers.add(
        Marker(
          point: latLng,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              // পিনে ক্লিক করলে ওএসআরএম রুট এবং বটম শীট ওপেন হবে
              if (currentItem != null) {
                homeProvider.selectListingAndShowRoute(context, currentItem);
              } else {
                // যদি আইটেমটি পরের পেজেও থাকে, তাও রুট ড্র করার জন্য ব্যাকআপ লজিক
                homeProvider.selectListingAndShowRoute(
                  context,
                  ListingModel(
                    name: name,
                    subtitle: 'Near Your Area',
                    distance: 'Calculating...',
                    icon: markerIcon,
                    iconColor: markerColor,
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: markerColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                markerIcon,
                color: isSelected ? Colors.red : markerColor,
                size: isSelected ? 36 : 28,
              ),
            ),
          ),
        ),
      );
    });

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
              // 🎯 ফিক্স: প্রোভাইডারের ম্যাপ সেন্টার ও জুম রিড করবে, ক্যাটাগরি ক্লিক করলেই ম্যাপ পজিশন চেঞ্জ হবে
              options: MapOptions(
                initialCenter:
                    homeProvider.mapCenter ?? homeProvider.userLatLng,
                initialZoom: homeProvider.mapZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nearme360.app',
                  tileProvider: CachedTileProvider(store: MemCacheStore()),
                ),

                // 🔵 ডাটাবেজের রিয়েল স্পটের আঁকাবাঁকা আসল রাস্তার লেয়ার (OSRM Route)
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

                // 📍 সবগুলো রিয়েল মার্কার ডিসপ্লে লেয়ার একসাথে
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
                      : '${homeProvider.selectedCategory.isEmpty ? 'All' : homeProvider.selectedCategory} Real Places Locked (${homeProvider.totalItems})',
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
