import 'package:flutter/material.dart';

class EmergencyContent extends StatelessWidget {
  const EmergencyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_police, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Emergency Police Station Finder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'আশেপাশের থানা এবং জরুরি সেবা এখানে দেখা যাবে।',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
