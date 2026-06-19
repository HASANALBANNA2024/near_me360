import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({super.key});

  // 📜 সব অফলাইন ডাটা দেখার জন্য কাস্টম পপ-আপ ডায়ালগ
  void _showAllHistoryDialog(BuildContext context, HomeProvider homeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<HomeProvider>(
          builder: (context, provider, child) {
            final allHistory = provider.recentSearches;

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📜 Search History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (allHistory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        provider.clearRecentSearches();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: allHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No history found 🔍',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
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
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              item['name']?.toString() ?? 'Unknown Place',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (lat != 0.0 && lng != 0.0) {
                                provider.selectRecentOfflineLocation(
                                  item['name']?.toString() ?? 'Unknown Place',
                                  LatLng(lat, lng),
                                );
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
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
    final displayHistory = history.take(4).toList();

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
              if (history.length > 4)
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
