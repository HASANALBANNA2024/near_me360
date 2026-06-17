import 'package:flutter/material.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Dhaka, Bangladesh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on, color: Colors.blue, size: 40),
          ),
        ],
      ),
    );
  }
}
