import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/favorite_screen.dart';

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
    // Access HomeProvider without listening to operational flow rebuilds
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

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

          // 🏠 Home (Resets filter state and routes back to home view)
          _buildNavItem(context, 0, Icons.home, 'Home', () {
            homeProvider.filterByCategory('');
            onIndexChanged(0);
          }),

          // 🏥 Emergency (Triggers strategic localized emergency queries)
          _buildNavItem(context, 1, Icons.emergency, 'Emergency', () {
            onIndexChanged(0);
            homeProvider.searchCustomGroup('emergency');
          }),

          // 🎓 Education (Triggers school/college filtering rules)
          _buildNavItem(context, 2, Icons.school, 'Education', () {
            onIndexChanged(0);
            homeProvider.searchCustomGroup('education');
          }),

          // 🚌 Transport (Triggers transportation service group search)
          _buildNavItem(context, 3, Icons.directions_bus, 'Transport', () {
            onIndexChanged(0);
            homeProvider.searchCustomGroup('transport');
          }),

          // ❤️ Favorites (Directly pushes the dedicated FavoritesScreen)
          _buildNavItem(context, 4, Icons.favorite, 'Favorites', () {
            // Check if the current context can pop (useful if used inside a Drawer)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            onIndexChanged(4); // Updates active navigation state highlights
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          }),

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

  // Modified helper method utilizing custom VoidCallback parameter mappings
  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    VoidCallback customOnTap,
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
      onTap: customOnTap, // Custom actionable callback execution line
    );
  }
}
