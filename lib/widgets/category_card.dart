import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected; // ✅ এটি চেক করবে কার্ডটি কি এখন সিলেক্টেড?

  const CategoryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false, // ✅ ডিফল্ট ফলস রাখা হলো
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        // 🎨 আপনার অরিজিনাল UI লজিক ঠিক রেখে শুধু সিলেক্টেড থাকলে বর্ডার দেওয়া হলো
        border: isSelected
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
