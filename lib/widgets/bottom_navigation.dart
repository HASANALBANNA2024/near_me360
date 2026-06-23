import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../screens/favorite_screen.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Access HomeProvider without listening to structural state rebuilds
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Evaluate the triggered index and perform corresponding action syncs
        if (index == 0) {
          // Home
          homeProvider.filterByCategory('');
          onIndexChanged(0);
        } else if (index == 1) {
          // Emergency
          onIndexChanged(0);
          homeProvider.searchCustomGroup('emergency');
        } else if (index == 2) {
          // Education
          onIndexChanged(0);
          homeProvider.searchCustomGroup('education');
        } else if (index == 3) {
          // Transport
          onIndexChanged(0);
          homeProvider.searchCustomGroup('transport');
        } else if (index == 4) {
          // ✅ Directly push FavoritesScreen and update active bottom tab index highlights
          onIndexChanged(4);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
          );
        }
      },
      type:
          BottomNavigationBarType.fixed, // Keeps all 5 items visible and static
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey,
      backgroundColor: Theme.of(context).cardColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.emergency),
          label: 'Emergency',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Education'),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus),
          label: 'Transport',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorites',
        ), // ✅ Safe persistent target
      ],
    );
  }
}
