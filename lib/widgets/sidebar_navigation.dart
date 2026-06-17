import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SidebarNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const SidebarNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: 240,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 28),
              SizedBox(width: 8),
              Text(
                'NearMe Finder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildNavItem(context, 0, Icons.home, 'Home'),
          _buildNavItem(context, 1, Icons.emergency, 'Emergency'),
          _buildNavItem(context, 2, Icons.school, 'Education'),
          _buildNavItem(context, 3, Icons.directions_bus, 'Transport'),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dark Mode'),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
  ) {
    final isSelected = currentIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF3B82F6).withOpacity(0.1),
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => onIndexChanged(index),
    );
  }
}
