import 'package:flutter/material.dart';

class EducationContent extends StatelessWidget {
  const EducationContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'School & Madrasah Finder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'আপনার আশেপাশের স্কুল এবং মাদ্রাসাগুলো এখানে খুঁজুন।',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
