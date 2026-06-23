import 'package:flutter/material.dart';
import 'package:near_me360/providers/home_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/category_grid.dart';
import '../widgets/map_view.dart';
import '../widgets/nearby_listing_card.dart';
import '../widgets/recent_searches_panel.dart';
import 'all_listings_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // 🌍 অ্যাপ ওপেন হওয়ার পর ফার্স্ট-টাইম ডাটা লোড ও জিপিএস লক করবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).loadCachedData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    final homeProvider = Provider.of<HomeProvider>(context);
    final listings = homeProvider.listings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // -----------------------------------------------------------------
          // 📦 ১. মূল ইউআই কন্টেন্ট লেয়ার (🔒 কড়া লক কন্ডিশন: নো ফ্লিকার!)
          // -----------------------------------------------------------------
          homeProvider.isLoading &&
                  homeProvider.totalItems == 0 &&
                  !homeProvider.isCustomSearching
              ? const Center(child: CircularProgressIndicator())
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

                        _buildSectionTitle(
                          context,
                          'Nearby Listings (${homeProvider.totalItems})',
                        ),
                        const SizedBox(height: 8),

                        listings.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No services found 🔍'),
                                ),
                              )
                            : Column(
                                children: [
                                  ...listings
                                      .map(
                                        (item) =>
                                            NearbyListingCard(listing: item),
                                      )
                                      .toList(),
                                  _buildPaginationController(
                                    context,
                                    homeProvider,
                                  ),
                                ],
                              ),

                        // const SizedBox(height: 16),
                        // const StatsPanel(),
                        const SizedBox(height: 16),
                        const RecentSearchesPanel(), // ক্লিন রিসেন্ট সার্চ
                        const SizedBox(height: 16),
                        // const SettingsPanel(),
                      ] else ...[
                        /// ------ web and big screen layout ------
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  const CategoryGrid(),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      // Expanded(child: StatsPanel()),
                                      // SizedBox(width: 16),
                                      Expanded(
                                        child: RecentSearchesPanel(),
                                      ), // ফুল রেসপনসিভ প্যানেল
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                    context,
                                    'Nearby Listings (${homeProvider.totalItems})',
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
                                          children: [
                                            ...listings
                                                .map(
                                                  (item) => NearbyListingCard(
                                                    listing: item,
                                                  ),
                                                )
                                                .toList(),
                                            _buildPaginationController(
                                              context,
                                              homeProvider,
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 16),
                                  // const SettingsPanel(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

          // -----------------------------------------------------------------
          // 🚀 ২. টপ লাক্সারি লাইটওয়েট লিনিয়ার ইন্ডিকেটর
          // -----------------------------------------------------------------
          if (homeProvider.isCustomSearching)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  homeProvider.getColorForCategory(
                    homeProvider.selectedCategory,
                  ),
                ),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllListingsScreen(),
              ),
            );
          },
          child: const Text('See all'),
        ),
      ],
    );
  }

  Widget _buildPaginationController(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Page ${homeProvider.currentPage} of ${homeProvider.totalPages}",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
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
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 6),
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
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
