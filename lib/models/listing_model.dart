import 'package:flutter/material.dart';

class ListingModel {
  final String name;
  final String subtitle;
  final String distance;
  final IconData icon;
  final Color iconColor;

  ListingModel({
    required this.name,
    required this.subtitle,
    required this.distance,
    required this.icon,
    required this.iconColor,
  });
}
