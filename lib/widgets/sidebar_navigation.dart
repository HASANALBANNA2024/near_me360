import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart'; // ✅ হোম প্রোভাইডার ইম্পোর্ট করা হলো
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
    // ⚡ হোম প্রোভাইডার কল লিসেন বাদে (অ্যাকশন হ্যান্ডেল করার জন্য)
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

          // 🏠 Home (ক্লিক করলে সাধারণ ডিফল্ট অবস্থায় নিয়ে যাবে)
          _buildNavItem(context, 0, Icons.home, 'Home', () {
            homeProvider.filterByCategory(''); // ক্লিয়ার করে দিবে ফিল্টার
            onIndexChanged(0);
          }),

          // 🏥 Emergency (ক্লিক করলে সরাসরি ইমারজেন্সি গ্রুপ কল হবে)
          _buildNavItem(context, 1, Icons.emergency, 'Emergency', () {
            onIndexChanged(0); // 🚀 প্রথমে হোম স্ক্রিনে নিয়ে যাবে
            homeProvider.searchCustomGroup(
              'emergency',
            ); // 🎯 ৭ম পিলার আপডেট লজিক
          }),

          // 🎓 Education (ক্লিক করলে এডুকেশন গ্রুপ কল হবে)
          _buildNavItem(context, 2, Icons.school, 'Education', () {
            onIndexChanged(0); // 🚀 হোম স্ক্রিনে নিয়ে যাবে
            homeProvider.searchCustomGroup(
              'education',
            ); // 🎯 ৭ম পিলার আপডেট লজিক
          }),

          // 🚌 Transport (ক্লিক করলে ট্রান্সপোর্ট গ্রুপ কল হবে)
          _buildNavItem(context, 3, Icons.directions_bus, 'Transport', () {
            onIndexChanged(0); // 🚀 হোম স্ক্রিনে নিয়ে যাবে
            homeProvider.searchCustomGroup(
              'transport',
            ); // 🎯 ৭ম পিলার আপডেট লজিক
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

  // 🛠️ মডিফাইড হেল্পার মেথড (OnTap হ্যান্ডেল করার জন্য কাস্টম VoidCallback যুক্ত করা হয়েছে)
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
      onTap: customOnTap, // 🚀 আমাদের কাস্টমাইজড অন-ট্যাপ মেথড কাজ করবে এখানে
    );
  }
}
