import 'package:flutter/material.dart';

class QuickFinderPanel extends StatelessWidget {
  const QuickFinderPanel({super.key});

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
            'Quick Finder',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Hospitals',
              'Police',
              'Schools',
              'Madrasas',
              'Petrol Pumps',
              'Bus Stations',
            ].map((e) => Chip(label: Text(e))).toList(),
          ),
        ],
      ),
    );
  }
}
