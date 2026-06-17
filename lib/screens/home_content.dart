import 'package:flutter/material.dart';

import '../models/listing_model.dart';
import '../widgets/alerts_panel.dart';
import '../widgets/category_grid.dart';
import '../widgets/map_view.dart';
import '../widgets/nearby_listing_card.dart';
import '../widgets/quick_finder_panel.dart';
import '../widgets/recent_searches_panel.dart';
import '../widgets/settings_panel.dart';
import '../widgets/stats_panel.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    /// running screen width
    final screenWidth = MediaQuery.of(context).size.width;

    //mobile screen size alignment
    final bool isMobile = screenWidth < 800;

    final listings = [
      ListingModel(
        name: 'Aga Khan Hospital',
        subtitle: 'Aga Khan Hospital',
        distance: '1.2km',
        icon: Icons.local_hospital,
        iconColor: Colors.red,
      ),
      ListingModel(
        name: 'Uttara Police Station',
        subtitle: 'Uttara Police',
        distance: '0.8km',
        icon: Icons.local_police,
        iconColor: Colors.blue,
      ),
      ListingModel(
        name: 'Uttara Police Station',
        subtitle: 'Uttara, Bangladesh',
        distance: '0.8km',
        icon: Icons.local_police,
        iconColor: Colors.green,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,

      /// background of main screen
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// map panel all view
            const MapView(),
            const SizedBox(height: 20),

            /// layout change based on screen size
            if (isMobile) ...[
              /// ------ mobile and small screen layout ------
              const CategoryGrid(),
              const SizedBox(height: 20),

              _buildSectionTitle('Nearby Listings'),
              const SizedBox(height: 8),
              ...listings.map((item) => NearbyListingCard(listing: item)),
              const SizedBox(height: 16),

              /// all panel add for mobile view
              const QuickFinderPanel(),
              const SizedBox(height: 16),
              const AlertsPanel(),
              const SizedBox(height: 16),
              const StatsPanel(),
              const SizedBox(height: 16),
              const RecentSearchesPanel(),
              const SizedBox(height: 16),
              const SettingsPanel(),
            ] else ...[
              /// ------ web and big screen layout ------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// category, quick finder and graph
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const CategoryGrid(),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(child: QuickFinderPanel()),
                            SizedBox(width: 16),
                            Expanded(child: AlertsPanel()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(child: StatsPanel()),
                            SizedBox(width: 16),
                            Expanded(child: RecentSearchesPanel()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  /// listing quick settings
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Nearby Listings'),
                        const SizedBox(height: 12),
                        ...listings.map(
                          (item) => NearbyListingCard(listing: item),
                        ),
                        const SizedBox(height: 16),
                        const SettingsPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// title build to helper method
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }
}
