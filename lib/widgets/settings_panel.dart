import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Quick Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.emergency),
            title: Text('Emergency Mode'),
            dense: true,
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('Education Filter'),
            dense: true,
          ),
        ],
      ),
    );
  }
}
