import 'package:flutter/material.dart';

class TransportContent extends StatelessWidget {
  const TransportContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Bus Station & Petrol Pump Finder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'কাছের বাস স্টেশন এবং জ্বালানি পাম্পের তালিকা এখানে পাবেন।',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
