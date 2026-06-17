import 'package:flutter/material.dart';

import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        CategoryCard(
          icon: Icons.local_hospital,
          label: 'Hospital',
          color: Colors.blue,
        ),
        CategoryCard(
          icon: Icons.local_police,
          label: 'Police',
          color: Colors.indigo,
        ),
        CategoryCard(icon: Icons.school, label: 'School', color: Colors.orange),
        CategoryCard(
          icon: Icons.mosque,
          label: 'Madrasah',
          color: Colors.brown,
        ),
        CategoryCard(icon: Icons.mosque, label: 'Madrasa', color: Colors.green),
        CategoryCard(
          icon: Icons.local_gas_station,
          label: 'Petrol',
          color: Colors.teal,
        ),
        CategoryCard(
          icon: Icons.directions_bus,
          label: 'Bus',
          color: Colors.cyan,
        ),
        CategoryCard(icon: Icons.add, label: '', color: Colors.grey),
      ],
    );
  }
}
