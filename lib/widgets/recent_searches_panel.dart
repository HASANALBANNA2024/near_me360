import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({super.key});

  // 📜 সব অফলাইন ডাটা দেখার জন্য কাস্টম পপ-আপ ডায়ালগ
  void _showAllHistoryDialog(BuildContext context, HomeProvider homeProvider) {
    final screenSize = MediaQuery.of(context).size;
    double dialogWidth = screenSize.width * 0.40;
    if (screenSize.width < 600) {
      dialogWidth = screenSize.width * 0.85;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<HomeProvider>(
          builder: (context, provider, child) {
            final allHistory = provider.recentSearches;

            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(maxHeight: screenSize.height * 0.6),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔝 হেডার সেকশন
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📜 Search History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (allHistory.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              provider.clearRecentSearches();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),

                    // 📜 কনটেন্ট সেকশন (স্ক্রোলযোগ্য)
                    Expanded(
                      child: allHistory.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: Text(
                                  'No history found 🔍',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: allHistory.length,
                              itemBuilder: (context, index) {
                                final item = allHistory[index];
                                final double lat =
                                    double.tryParse(
                                      item['latitude']?.toString() ?? '0.0',
                                    ) ??
                                    0.0;
                                final double lng =
                                    double.tryParse(
                                      item['longitude']?.toString() ?? '0.0',
                                    ) ??
                                    0.0;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  leading: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFFEFF6FF),
                                    child: Icon(
                                      Icons.location_on,
                                      size: 15,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  title: Text(
                                    item['name']?.toString() ?? 'Unknown Place',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 11,
                                    color: Colors.grey,
                                  ),
                                  onTap: () {
                                    if (lat != 0.0 && lng != 0.0) {
                                      provider.selectRecentOfflineLocation(
                                        item['name']?.toString() ??
                                            'Unknown Place',
                                        LatLng(lat, lng),
                                      );
                                    }
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                    const Divider(height: 20, thickness: 0.5),

                    // 🏁 ফুটার অ্যাকশন বাটন
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        // 👈 'children: [' কেটে শুধু 'child:' করা হয়েছে
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ), // 👈 শেষের ']' ব্র্যাকেটটি ফেলে দেওয়া হয়েছে
                    ),
                  ], // 👈 এই ক্লোজিং থার্ড ব্র্যাকেট এবং কমার অ্যালাইনমেন্ট ঠিক করা হয়েছে
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final history = homeProvider.recentSearches;
    final displayHistory = history.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🕒 Recent Places',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (history.length > 3)
                GestureDetector(
                  onTap: () => _showAllHistoryDialog(context, homeProvider),
                  child: Text(
                    'See more (${history.length})',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (displayHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent places found 🔍',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),

          ...displayHistory.map((item) {
            final double lat =
                double.tryParse(item['latitude']?.toString() ?? '0.0') ?? 0.0;
            final double lng =
                double.tryParse(item['longitude']?.toString() ?? '0.0') ?? 0.0;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.location_on,
                size: 18,
                color: Colors.blueAccent,
              ),
              title: Text(
                item['name']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey,
              ),
              dense: true,
              onTap: () {
                if (lat != 0.0 && lng != 0.0) {
                  homeProvider.selectRecentOfflineLocation(
                    item['name']?.toString() ?? '',
                    LatLng(lat, lng),
                  );
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
