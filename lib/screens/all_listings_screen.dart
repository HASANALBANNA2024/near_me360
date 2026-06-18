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
        title: Text(
          '${homeProvider.selectedCategory.isEmpty ? 'All' : homeProvider.selectedCategory} - All Places (${homeProvider.totalItems})',
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

                // 🎯 ফিক্স (লাল স্ক্রিন এরর দূরীকরণ):
                // প্রথম ১০টার লিমিটেড 'listings' এ না খুঁজে, গ্লোবাল '_allListings' এর সাথে ম্যাচ করার ব্যাকআপ মেকানিজম।
                // এটি থাকলে অ্যাপ আর কখনো 'No element' এরর দিয়ে ক্র্যাশ করবে না।
                ListingModel item;
                try {
                  item = homeProvider.listings.firstWhere(
                    (l) => l.name == name,
                  );
                } catch (_) {
                  // যদি কারেন্ট পেজের বাইরে থাকে, তবে ডাইনামিক সেফ মডেল তৈরি হবে
                  item = ListingModel(
                    name: name,
                    subtitle: 'Near Your Area',
                    distance: 'Calculating...',
                    icon: Icons.place,
                    iconColor: Colors.red,
                  );
                }

                return Center(
                  child: Container(
                    // 🎯 ওয়েবের জন্য ম্যাক্সিমাম উইডথ ১১০০ পিক্সেল এবং সেন্টারিং, মোবাইলে ফুল উইডথ
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
                          subtitle: Text(item.subtitle),
                          trailing: const Icon(Icons.map, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 🎯 ৭৫% - ৮৫% হাইটের কাস্টম রেসপন্সিভ এবং ক্র্যাশ-ফ্রি ম্যাপ পপআপ শীট
  void _showResponsiveMapSheet(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // মোবাইলে ৮৫% এবং ওয়েবে ৭৫% পারফেক্ট রেসপন্সিভ হাইট
    double sheetHeight = isMobile
        ? (screenHeight * 0.85)
        : (screenHeight * 0.75);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Center(
          // 🎯 ওয়েবে শীটটিকে স্ক্রিনের মাঝখানে রাখার জন্য
          child: Container(
            height: sheetHeight,
            // 🎯 আপনার রিকোয়ারমেন্ট: ওয়েবে সর্বোচ্চ ১১০০ পিক্সেল উইডথ, মোবাইলে রেসপন্সিভ ফুল স্ক্রিন
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
                // 🗺️ ম্যাপ লেয়ার
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Consumer<HomeProvider>(
                    builder: (context, provider, child) {
                      List<Marker> markers = [];

                      // ইউজারের লাইভ জিপিএস লোকেশন পিন
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

                      // সমস্ত এপিআই পিন একসাথে রেন্ডার
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
                          // 🔵 OSRM রুট পাথ লেয়ার
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

                // 🔝 শীট ড্র্যাগ ইন্ডিকেটর নচ
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

                // ❌ ক্লোজ বাটন
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
