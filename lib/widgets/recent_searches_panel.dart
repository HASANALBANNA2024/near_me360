import 'package:flutter/material.dart';

class RecentSearchesPanel extends StatelessWidget {
  const RecentSearchesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...['Hospitals', 'Uttara Police Station', 'School'].map(
            (e) => ListTile(
              leading: const Icon(Icons.history, size: 18),
              title: Text(e),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}
