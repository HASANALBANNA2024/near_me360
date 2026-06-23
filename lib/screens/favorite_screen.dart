import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing_model.dart';
import '../providers/home_provider.dart';
import '../widgets/nearby_listing_card.dart'; // Make sure the path matches your project structure

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
      ),
      body: favRawList.isEmpty
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
                final map = Map<String, dynamic>.from(favRawList[index] as Map);

                // Map local offline records into the structured ListingModel definition
                final item = ListingModel(
                  name: map['name'] ?? '',
                  subtitle: map['subtitle'] ?? '',
                  distance: map['distance'] ?? '0.1km',
                  icon: homeProvider.getIconForCategory(map['category'] ?? ''),
                  iconColor: homeProvider.getColorForCategory(
                    map['category'] ?? '',
                  ),
                  isFavorite: true,
                );

                return NearbyListingCard(listing: item);
              },
            ),
    );
  }
}
