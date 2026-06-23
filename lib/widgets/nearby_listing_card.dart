import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing_model.dart';
import '../providers/home_provider.dart';

class NearbyListingCard extends StatelessWidget {
  final ListingModel listing;

  const NearbyListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    // Access HomeProvider once to use inside the favorite button
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Trigger OSRM route map display on card tap
          homeProvider.selectListingAndShowRoute(context, listing);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: listing.iconColor.withOpacity(0.1),
            child: Icon(listing.icon, color: listing.iconColor),
          ),
          title: Text(
            listing.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(listing.subtitle),
          // Modified trailing to hold both Distance text and Favorite button side-by-side
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                listing.distance,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                width: 4,
              ), // Small spacing between distance and heart icon
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  listing.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: listing.isFavorite ? Colors.redAccent : Colors.grey,
                ),
                onPressed: () {
                  // Toggle favorite state within provider instance
                  homeProvider.toggleFavorite(listing);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
