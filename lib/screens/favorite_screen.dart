import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing_model.dart';
import '../providers/home_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // Fetch directly from the locally stored Hive favorites list
    final List<dynamic> favRawList = homeProvider.recentBox.get(
      'favorites_list',
      defaultValue: [],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // 🎯 AppBar All Clear Action remains exactly as it is
        actions: [
          if (favRawList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Clear All Favorites',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Clear All?'),
                      content: const Text(
                        'Do you want to remove all items from favorites?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            homeProvider.recentBox.put('favorites_list', []);
                            if (homeProvider.currentActiveGroup ==
                                'favorites') {
                              homeProvider.showFavoritesOnly();
                            } else {
                              // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                              homeProvider.notifyListeners();
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: favRawList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No favorites added yet!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favRawList.length,
                  itemBuilder: (context, index) {
                    final map = Map<String, dynamic>.from(
                      favRawList[index] as Map,
                    );

                    // Reconstruct individual model profiles from local db parameters
                    final item = ListingModel(
                      name: map['name'] ?? '',
                      subtitle: map['subtitle'] ?? '',
                      distance: map['distance'] ?? '0.1km',
                      icon: homeProvider.getIconForCategory(
                        map['category'] ?? '',
                      ),
                      iconColor: homeProvider.getColorForCategory(
                        map['category'] ?? '',
                      ),
                      isFavorite:
                          true, // It is a favorite screen, so hardcoded true
                    );

                    double lat =
                        double.tryParse(map['latitude']?.toString() ?? '0.0') ??
                        0.0;
                    double lng =
                        double.tryParse(
                          map['longitude']?.toString() ?? '0.0',
                        ) ??
                        0.0;

                    // 🚀 Cleaner and optimized custom ListTile layout instead of nested duplicated card structures
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Theme.of(context).cardColor,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),

                        /// to direction on map
                        onTap: () async {
                          homeProvider.filterByCategory('');

                          await homeProvider.selectFavoriteAndShowRoute(
                            name: item.name,
                            destLat: lat,
                            destLng: lng,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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

                          /// favorite icon
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.distance,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  /// to remove favorite
                                  homeProvider.toggleFavorite(item);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
