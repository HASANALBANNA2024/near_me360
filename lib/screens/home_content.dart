import 'package:flutter/material.dart';
import 'package:near_me360/providers/home_provider.dart'; // ✅ হোম প্রোভাইডার ইমপোর্ট
import 'package:provider/provider.dart'; // ✅ প্রোভাইডার ইমপোর্ট

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
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    // ⚡ Hive ডাটাবেজ থেকে প্রোভাইডারের মাধ্যমে আসা লাইভ ডাটা লিস্ট
    final homeProvider = Provider.of<HomeProvider>(context);
    final listings = homeProvider.listings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: homeProvider.isLoading
          ? const Center(child: CircularProgressIndicator()) // ডাটা লোডিং স্টেট
          : SingleChildScrollView(
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

                    _buildSectionTitle('Nearby Listings (${listings.length})'),
                    const SizedBox(height: 8),

                    listings.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No services found 🔍'),
                            ),
                          )
                        : Column(
                            children: listings
                                .map((item) => NearbyListingCard(listing: item))
                                .toList(),
                          ),
                    const SizedBox(height: 16),

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
                              _buildSectionTitle(
                                'Nearby Listings (${listings.length})',
                              ),
                              const SizedBox(height: 12),

                              listings.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text('No services found 🔍'),
                                      ),
                                    )
                                  : Column(
                                      children: listings
                                          .map(
                                            (item) => NearbyListingCard(
                                              listing: item,
                                            ),
                                          )
                                          .toList(),
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
