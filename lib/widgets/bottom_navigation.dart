import 'package:flutter/material.dart';

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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onIndexChanged,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey,
      backgroundColor: Theme.of(context).cardColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.emergency), label: 'Police'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listings'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
