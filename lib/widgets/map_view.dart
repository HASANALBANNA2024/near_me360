import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:near_me360/models/listing_model.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // 🎯 ফুল স্ক্রিন মোড ট্র্যাক করার লোকাল স্টেট
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeProvider = Provider.of<HomeProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

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

    // ২. এপিআই থেকে আসা সব লোকেশন একসাথে ম্যাপে পিন করা হচ্ছে (আপনার লজিক ১০০% সেম)
    homeProvider.allListingCoords.forEach((name, latLng) {
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
              if (currentItem != null) {
                homeProvider.selectListingAndShowRoute(context, currentItem);
              } else {
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

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        height: _isFullScreen
            ? (isMobile
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 0.85)
            : 250,
        // 🎯 ফিক্স: অসীম (infinity) বাদ দিয়ে রিয়েল স্ক্রিন উইডথ ব্যবহার করা হয়েছে, যা অ্যানিমেশন এরর চিরতরে দূর করবে
        width: _isFullScreen
            ? (isMobile ? screenWidth : 1100)
            : (screenWidth > 1100 ? 1100 : screenWidth),
        margin: _isFullScreen
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: _isFullScreen && isMobile
              ? BorderRadius.zero
              : BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: _isFullScreen && isMobile
              ? BorderRadius.zero
              : BorderRadius.circular(16),
          child: Stack(
            children: [
              FlutterMap(
                key: ValueKey('map_${_isFullScreen}_${homeProvider.mapCenter}'),
                options: MapOptions(
                  initialCenter:
                      homeProvider.mapCenter ?? homeProvider.userLatLng,
                  initialZoom: homeProvider.mapZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nearme360.app',
                    tileProvider: CachedTileProvider(store: MemCacheStore()),
                  ),
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
                  MarkerLayer(markers: allMarkers),
                ],
              ),

              Positioned(
                top: _isFullScreen && isMobile
                    ? MediaQuery.of(context).padding.top + 16
                    : 16,
                left: 16,
                right: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: "dashboard_map_toggle",
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 4,
                  child: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = !_isFullScreen;
                    });
                  },
                ),
              ),

              if (_isFullScreen)
                Positioned(
                  top: _isFullScreen && isMobile
                      ? MediaQuery.of(context).padding.top + 12
                      : 12,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFullScreen = false;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
