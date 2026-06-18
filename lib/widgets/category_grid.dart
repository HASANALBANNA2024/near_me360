import 'package:flutter/material.dart';
import 'package:near_me360/providers/home_provider.dart'; // ✅ সঠিক ইমপোর্ট পাথ
import 'package:provider/provider.dart';

import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ প্রোভাইডার কল
    final homeProvider = Provider.of<HomeProvider>(context);
    final selectedCat = homeProvider.selectedCategory;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        // 🏥 Hospital
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Hospital'),
          child: CategoryCard(
            icon: Icons.local_hospital,
            label: 'Hospital',
            color: Colors.blue,
            isSelected: selectedCat == 'Hospital',
          ),
        ),

        // 👮 Police
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Police'),
          child: CategoryCard(
            icon: Icons.local_police,
            label: 'Police',
            color: Colors.indigo,
            isSelected: selectedCat == 'Police',
          ),
        ),

        // 🎓 School
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('School'),
          child: CategoryCard(
            icon: Icons.school,
            label: 'School',
            color: Colors.orange,
            isSelected: selectedCat == 'School',
          ),
        ),

        // 🕌 Madrasah
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Madrasah'),
          child: CategoryCard(
            icon: Icons.mosque,
            label: 'Madrasah',
            color: Colors.brown,
            isSelected: selectedCat == 'Madrasah',
          ),
        ),

        // 🕌 Madrasa
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Madrasa'),
          child: CategoryCard(
            icon: Icons.mosque,
            label: 'Madrasa',
            color: Colors.green,
            isSelected: selectedCat == 'Madrasa',
          ),
        ),

        // ⛽ Petrol
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Petrol'),
          child: CategoryCard(
            icon: Icons.local_gas_station,
            label: 'Petrol',
            color: Colors.teal,
            isSelected: selectedCat == 'Petrol',
          ),
        ),

        // 🚌 Bus
        GestureDetector(
          onTap: () => homeProvider.filterByCategory('Bus'),
          child: CategoryCard(
            icon: Icons.directions_bus,
            label: 'Bus',
            color: Colors.cyan,
            isSelected: selectedCat == 'Bus',
          ),
        ),

        // ➕ 🎯 Others Button - কাস্টম পপআপ উইথ সার্চ ফিচার
        GestureDetector(
          onTap: () {
            // 🔥 রিফ্রেশ বন্ধ! সরাসরি সুন্দর কাস্টম সার্চ পপআপ ওপেন হবে
            _showCustomSearchDialog(context, homeProvider);
          },
          child: CategoryCard(
            icon: Icons.add,
            label: 'Others',
            color: Colors.purpleAccent, // Others এর থিম কালার বেগুনি করা হলো
            isSelected:
                selectedCat.isNotEmpty &&
                ![
                  'hospital',
                  'police',
                  'school',
                  'madrasah',
                  'madrasa',
                  'petrol',
                  'bus',
                ].contains(selectedCat.toLowerCase().trim()),
          ),
        ),
      ],
    );
  }

  // 🎯 সুন্দর কাস্টম সার্চ পপআপ বক্স (AlertDialog) - ডার্ক ও লাইট মোড সাপোর্টেড
  void _showCustomSearchDialog(BuildContext context, HomeProvider provider) {
    final TextEditingController searchController = TextEditingController();

    // 🌓 থিম কালার ডিটেকশন (ডার্ক মোড নাকি লাইট মোড ট্র্যাকিং)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // ডাইনামিক কালার সেটআপ
    final dialogBgColor = isDarkMode
        ? const Color(0xFF0F172A)
        : Theme.of(context).dialogBackgroundColor;
    final inputFillColor = isDarkMode
        ? const Color(0xFF1E293B)
        : Colors.grey.withOpacity(0.15);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor, // 🎯 ডাইনামিক ব্যাকগ্রাউন্ড
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.search, color: Colors.purpleAccent),
            const SizedBox(width: 10),
            Text(
              'Find Custom Places',
              style: TextStyle(
                color: textColor, // 🎯 ডাইনামিক টাইটেল কালার
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: searchController,
          autofocus: true,
          style: TextStyle(color: textColor), // 🎯 ডাইনামিক ইনপুট টেক্সট কালার
          decoration: InputDecoration(
            hintText: "e.g. Restaurant, College, University",
            hintStyle: TextStyle(color: hintColor), // 🎯 ডাইনামিক হিন্ট কালার
            filled: true,
            fillColor: inputFillColor, // 🎯 ডাইনামিক ইনপুট বক্সের ব্যাকগ্রাউন্ড
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.purpleAccent,
                width: 1.5,
              ),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.searchCustomQuery(value.trim());
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              if (searchController.text.trim().isNotEmpty) {
                provider.searchCustomQuery(searchController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
