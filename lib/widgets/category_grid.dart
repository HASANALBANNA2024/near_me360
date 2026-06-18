import 'package:flutter/material.dart';
import 'package:near_me360/providers/home_provider.dart'; // ✅ সঠিক ইমপোর্ট পাথ দেওয়া হলো
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

        // ➕ All / Reset Button
        GestureDetector(
          onTap: () => homeProvider.filterByCategory(''),
          child: CategoryCard(
            icon: Icons.add,
            label: 'All',
            color: Colors.grey,
            isSelected: selectedCat == '',
          ),
        ),
      ],
    );
  }
}
