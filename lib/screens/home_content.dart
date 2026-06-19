import 'package:flutter/material.dart';
import 'package:near_me360/providers/home_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/category_grid.dart';
import '../widgets/map_view.dart';
import '../widgets/nearby_listing_card.dart';
import '../widgets/recent_searches_panel.dart';
import '../widgets/settings_panel.dart';
import '../widgets/stats_panel.dart';
import 'all_listings_screen.dart';

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
      // 🎯 কন্টেন্ট এবং ইন্ডিকেটর একসাথ করার জন্য পুরো বডি Stack করা হলো
      body: Stack(
        children: [
          // -----------------------------------------------------------------
          // 📦 ১. মূল ইউআই কন্টেন্ট লেয়ার
          // 🎯 ম্যাজিক: ক্যাটাগরি বা কাস্টম সার্চ চললে ফুল স্ক্রিন লোডার ইউআই আটকে রাখবে না
          // -----------------------------------------------------------------
          homeProvider.isLoading && !homeProvider.isCustomSearching
              ? const Center(
                  child: CircularProgressIndicator(),
                ) // একদম ফার্স্ট টাইম ফুল লোডিং স্টেট
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

                        // 🎯 ফিক্স: এখানে context পাস করা হয়েছে
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

                                  // 🎯 মোবাইলের জন্য পেজিনেশন কন্ট্রোলার (লিস্টের ঠিক নিচে)
                                  _buildPaginationController(
                                    context,
                                    homeProvider,
                                  ),
                                ],
                              ),

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
                                  // 🎯 ফিক্স: এখানে context পাস করা হয়েছে
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

                                            // 🎯 ওয়েব/বড় স্ক্রিনের জন্য পেজিনেশন কন্ট্রোলার (লিস্টের ঠিক নিচে)
                                            _buildPaginationController(
                                              context,
                                              homeProvider,
                                            ),
                                          ],
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

          // -----------------------------------------------------------------
          // 🚀 ২. লাইটওয়েট ম্যাজিক ইন্ডিকেটর (সবার উপরে ভেসে উঠবে)
          // 🎯 যেকোনো ক্যাটাগরি বা Others কাস্টম সার্চে ক্লিক করলে রেজাল্ট আসার আগ পর্যন্ত সচল থাকবে
          // -----------------------------------------------------------------
          if (homeProvider.isCustomSearching)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                // ক্যাটাগরি ওয়াইজ কালার ডাইনামিকালি সেট হবে
                valueColor: AlwaysStoppedAnimation<Color>(
                  homeProvider.getColorForCategory(
                    homeProvider.selectedCategory,
                  ),
                ),
                minHeight: 3, // একদম স্লিম ও লাক্সারি লুক
              ),
            ),
        ],
      ),
    );
  }

  // 🎯 ফিক্সড মেথড: প্যারামিটারে BuildContext context যুক্ত করা হয়েছে যেন See All বাটন কাজ করে
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

  // 🎯 নেক্সট এবং প্রিভিয়াস ১০টি ডাটা কন্ট্রোল করার পেজিনেশন উইজেট
  Widget _buildPaginationController(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.end, // 🎯 বাটনগুলোকে একদম ডানপাশে পুশ করবে
        children: [
          // 📄 কারেন্ট পেজ কাউন্টার
          Text(
            "Page ${homeProvider.currentPage} of ${homeProvider.totalPages}",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),

          // ⬅️ Previous Button
          IconButton(
            onPressed: homeProvider.hasPreviousPage
                ? () => homeProvider.previousPage()
                : null, // প্রথম পেজে থাকলে বাটন ডিজেবল থাকবে
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

          // ➡️ Next Button
          IconButton(
            onPressed: homeProvider.hasNextPage
                ? () => homeProvider.nextPage()
                : null, // শেষ পেজে থাকলে বাটন ডিজেবল থাকবে
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
