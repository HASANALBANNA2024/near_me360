import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class AllListingsScreen extends StatelessWidget {
  const AllListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // 🎯 প্রোভাইডারের কারেন্ট পেজের ডাটা লিস্ট (এখন প্রতি পেজে ৮টি করে আসবে)
    final currentListings = homeProvider.listings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '${homeProvider.selectedCategory.isEmpty ? 'All' : homeProvider.selectedCategory} - All Places (${homeProvider.totalItems})',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: homeProvider.totalItems == 0
          ? const Center(child: Text('No services found 🔍'))
          : Column(
              children: [
                // 📦 ১. মেইন লিস্ট ভিউ সেকশন
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: currentListings.length,
                    itemBuilder: (context, index) {
                      final item = currentListings[index];

                      final bool hasSubtitle =
                          item.subtitle.isNotEmpty &&
                          item.subtitle != 'Near Your Area' &&
                          item.subtitle != 'Near Your Location';

                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Theme.of(context).cardColor,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // 🎯 ক্লিক করলে ওএসআরএম রুট ম্যাপ ক্যালকুলেট হবে এবং নিচ থেকে ম্যাপ ওপেন হবে
                                homeProvider
                                    .selectListingAndShowRoute(context, item)
                                    .then((_) {
                                      _showResponsiveMapSheet(
                                        context,
                                        homeProvider,
                                      );
                                    });
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: item.iconColor.withOpacity(
                                    0.1,
                                  ),
                                  child: Icon(item.icon, color: item.iconColor),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: hasSubtitle
                                    ? Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : const Text('Near Your Area'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.distance,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.map,
                                      color: Colors.blue,
                                      size: 20,
                                    ), // ম্যাপ ইন্ডিকেটর আইকন
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🎯 ২. নিচে পেজিনেশন কন্ট্রোলার উইজেট (< এবং > বাটন)
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      top: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 📄 পেজ কাউন্টার টেক্সট
                        Text(
                          "Page ${homeProvider.currentPage} of ${homeProvider.totalPages}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ⬅️ Previous Button (<)
                        IconButton(
                          onPressed: homeProvider.hasPreviousPage
                              ? () => homeProvider.previousPage()
                              : null,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: homeProvider.hasPreviousPage
                                ? Theme.of(context).cardColor
                                : Colors.grey.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ➡️ Next Button (>)
                        IconButton(
                          onPressed: homeProvider.hasNextPage
                              ? () => homeProvider.nextPage()
                              : null,
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          style: IconButton.styleFrom(
                            backgroundColor: homeProvider.hasNextPage
                                ? Theme.of(context).cardColor
                                : Colors.grey.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// maps widgets
  void _showResponsiveMapSheet(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    /// height and width 80% of Existing screen
    final double defaultHeight = screenHeight * 0.80;
    final double defaultWidth = screenWidth * 0.80;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        bool isFullScreen = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: isFullScreen ? screenHeight : defaultHeight,
                width: isFullScreen ? screenWidth : defaultWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: isFullScreen
                      ? BorderRadius.zero
                      : BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: isFullScreen
                      ? BorderRadius.zero
                      : BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      /// main map layer
                      Positioned.fill(
                        child: Consumer<HomeProvider>(
                          builder: (context, provider, child) {
                            List<Marker> markers = [];

                            /// live gps location pinned
                            markers.add(
                              Marker(
                                point: provider.userLatLng,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.green,
                                  size: 30,
                                ),
                              ),
                            );

                            /// fixed loop
                            provider.allListingCoords.forEach((name, latLng) {
                              bool isSelected =
                                  provider.selectedListing?.name == name;
                              markers.add(
                                Marker(
                                  point: latLng,
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.location_on,
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.grey,
                                    size: isSelected ? 40 : 28,
                                  ),
                                ),
                              );
                            });

                            return FlutterMap(
                              options: MapOptions(
                                initialCenter:
                                    provider.mapCenter ?? provider.userLatLng,
                                initialZoom: provider.mapZoom,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.nearme360.app',
                                  tileProvider: CachedTileProvider(
                                    store: MemCacheStore(),
                                  ),
                                ),
                                if (provider.routePoints.isNotEmpty)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: provider.routePoints,
                                        strokeWidth: 6.0,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(markers: markers),
                              ],
                            );
                          },
                        ),
                      ),

                      /// flow control button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              /// full screen and minimize button
                              CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: Icon(
                                    isFullScreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      isFullScreen = !isFullScreen;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              /// close button
                              CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
