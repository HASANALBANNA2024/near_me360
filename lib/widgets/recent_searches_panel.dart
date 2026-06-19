import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';

class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ প্রোভাইডারের মাধ্যমে লাইভ কানেকশন ট্র্যাকিং
    final homeProvider = Provider.of<HomeProvider>(context);
    final history = homeProvider.recentSearches;

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
                '🕒 Recent Searches',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () => homeProvider.clearRecentSearches(),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 🔒 সেফটি লক: যদি পুরোনো কোনো সার্চ হিস্ট্রি সেভ না থাকে
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent searches found 🔍',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

          // 🔄 ডাইনামিক ডাটা লুপ রেন্ডারিং
          ...history
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.history,
                    size: 18,
                    color: Colors.grey,
                  ),
                  title: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                  dense: true,
                  onTap: () {
                    // 🚀 ক্লিক করলে ওই আইটেম দিয়ে আবার লাইভ সার্চ ফিল্টার হবে!
                    homeProvider.filterByCategory(item);
                  },
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
