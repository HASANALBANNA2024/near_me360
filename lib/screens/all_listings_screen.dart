import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:near_me360/models/listing_model.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class AllListingsScreen extends StatelessWidget {
  const AllListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // 🎯 ফিল্টার হওয়া সব ডাটার নাম একসাথে নেওয়া হচ্ছে
    final allItems = homeProvider.totalItems > 0
        ? homeProvider.allListingCoords.keys.toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // 🎯 অ্যাপবার কন্টেন্ট রেসপন্সিভ করা হলো (ওয়েবে সর্বোচ্চ ১১০০px উইডথ এবং সেন্টারিং)
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeProvider.totalItems,
              itemBuilder: (context, index) {
                final name = allItems[index];

                ListingModel item;
                try {
                  item = homeProvider.listings.firstWhere(
                    (l) => l.name == name,
                  );
                } catch (_) {
                  item = ListingModel(
                    name: name,
                    subtitle: 'Near Your Area',
                    distance: 'Calculating...',
                    icon: Icons.place,
                    iconColor: Colors.red,
                  );
                }

                // 🎯 কন্ডিশনাল চেকিং: ডাটা 'Near Your Area' বা ফাঁকা থাকলে হাইড করার জন্য
                final bool hasSubtitle =
                    item.subtitle.isNotEmpty &&
                    item.subtitle != 'Near Your Area' &&
                    item.subtitle != 'Near Your Location';

                final bool hasDistance =
                    item.distance.isNotEmpty &&
                    item.distance != 'Locked' &&
                    item.distance != 'Calculating...';

                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          homeProvider
                              .selectListingAndShowRoute(context, item)
                              .then((_) {
                                _showResponsiveMapSheet(context, homeProvider);
                              });
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.iconColor.withOpacity(0.1),
                            child: Icon(item.icon, color: item.iconColor),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // 🎯 সাবটাইটেল/অ্যাড্রেস থাকলে দেখাবে, না থাকলে উইজেট গায়েব হয়ে যাবে
                          subtitle: hasSubtitle
                              ? Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          // 🎯 ডিস্ট্যান্স ভ্যালিড ডাটা হলে ট্রেইলিং-এ দেখাবে, না থাকলে আইকন দেখাবে
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDistance) ...[
                                Text(
                                  item.distance,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              const Icon(Icons.map, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 🎯 ৭৫% - ৮৫% হাইটের কাস্টম রেসপন্সিভ এবং ক্র্যাশ-ফ্রি ম্যাপ পপআপ শীট (As It Is)
  void _showResponsiveMapSheet(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    double sheetHeight = isMobile
        ? (screenHeight * 0.85)
        : (screenHeight * 0.75);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Center(
          child: Container(
            height: sheetHeight,
            constraints: const BoxConstraints(maxWidth: 1100),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      List<Marker> markers = [];

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
                              color: isSelected ? Colors.red : Colors.grey,
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
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
