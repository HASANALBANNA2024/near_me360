import 'package:flutter/material.dart';

class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ListTile(
        leading: Icon(Icons.warning, color: Colors.orange),
        title: Text(
          'Nearby Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Uttara Police Station: Real-time traffic congestion reported.',
        ),
      ),
    );
  }
}
