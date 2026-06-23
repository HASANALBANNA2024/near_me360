import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart'; // ✅ হোম প্রোভাইডার ইম্পোর্ট

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
    // ⚡ হোম প্রোভাইডার কল (listen: false)
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // 🚀 সাইডবারের মতো হুবহু ৪টি বাটনের অ্যাকশন লজিক
        if (index == 0) {
          // 🏠 Home
          homeProvider.filterByCategory(''); // ফিল্টার রিসেট
          onIndexChanged(0);
        } else if (index == 1) {
          // 🏥 Emergency
          onIndexChanged(0); // হোম স্ক্রিনে ব্যাক করবে
          homeProvider.searchCustomGroup('emergency'); // ৭ম পিলার অন হবে
        } else if (index == 2) {
          // 🎓 Education
          onIndexChanged(0);
          homeProvider.searchCustomGroup('education');
        } else if (index == 3) {
          // 🚌 Transport
          onIndexChanged(0);
          homeProvider.searchCustomGroup('transport');
        }
      },
      type: BottomNavigationBarType.fixed,
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
      ],
    );
  }
}
