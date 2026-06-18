import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing_model.dart';
import '../providers/home_provider.dart';

class NearbyListingCard extends StatelessWidget {
  final ListingModel listing;

  const NearbyListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 🎯 ফিক্স: এখানে প্রথমে context এবং পরে listing পাস করা হয়েছে যেন বটম শীট ওপেন হতে পারে
          Provider.of<HomeProvider>(
            context,
            listen: false,
          ).selectListingAndShowRoute(context, listing);
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
          trailing: Text(
            listing.distance,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
