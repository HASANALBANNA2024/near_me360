import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/listing_model.dart';

class HomeProvider extends ChangeNotifier {
  List<ListingModel> _allListings = [];
  List<ListingModel> _filteredListings = [];

  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  Position? _userPosition;

  ListingModel? _selectedListing;
  List<LatLng> _routePoints = [];
  LatLng? _mapCenter;
  double _mapZoom = 12.0;

  // 🎯 জিপিএস রুট ট্র্যাক করার জন্য রিয়েল-টাইম ডাটা ম্যাপ
  final Map<String, LatLng> _listingCoordsMap = {};

  List<ListingModel> get listings => _filteredListings;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  ListingModel? get selectedListing => _selectedListing;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get mapCenter => _mapCenter;
  double get mapZoom => _mapZoom;

  LatLng get userLatLng => LatLng(
    _userPosition?.latitude ?? 23.8103,
    _userPosition?.longitude ?? 90.4125,
  );

  Future<void> loadCachedData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 🛰️ ইউজারের বর্তমান জিপিএস লোকেশন নেওয়া হচ্ছে
      try {
        _userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        _mapCenter = userLatLng;
      } catch (e) {
        print("GPS Position Error: $e");
      }

      final dataBox = Hive.box('cached_listings');
      final rawData = dataBox.get('full_country_data');

      if (rawData != null && rawData['listings'] != null) {
        List<dynamic> list = rawData['listings'];
        _listingCoordsMap.clear();

        // 🔄 ডাটাবেজের পিওর রিয়েল ডেটা ম্যাপিং
        _allListings = list.map((e) {
          double lat =
              double.tryParse(e['latitude']?.toString() ?? '0.0') ?? 0.0;
          double lng =
              double.tryParse(e['longitude']?.toString() ?? '0.0') ?? 0.0;
          String name = e['name'] ?? '';
          String categoryRaw = e['category'] ?? '';

          // অরিজিনাল কোঅর্ডিনেট ম্যাপে লক করে রাখা হচ্ছে যেন পরে রুট খোঁজার সময় মিস না হয়
          if (name.isNotEmpty && lat != 0.0 && lng != 0.0) {
            _listingCoordsMap[name] = LatLng(lat, lng);
          }

          // লাইভ দূরত্ব হিসাব
          String finalDistance = e['distance'] ?? '0.0km';
          if (_userPosition != null && lat != 0.0 && lng != 0.0) {
            double meters = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              lat,
              lng,
            );
            finalDistance = "${(meters / 1000).toStringAsFixed(1)}km";
          }

          return ListingModel(
            name: name,
            subtitle: e['subtitle'] ?? '',
            distance: finalDistance,
            icon: _getIconForCategory(categoryRaw),
            iconColor: _getColorForCategory(categoryRaw),
          );
        }).toList();
      }

      // 🧪 সেফটি ফলব্যাক: ডাটাবেজ যদি কোনো কারণে টোটাল খালি থাকে, তবে ইউজার যেন জিরো ডাটা না দেখে
      if (_allListings.isEmpty) {
        _insertFallbackData();
      }

      _applyFilters();
    } catch (e) {
      print("Error loading real data from Hive: $e");
      _insertFallbackData();
      _applyFilters();
    }
    _isLoading = false;
    notifyListeners();
  }

  // 🏎️ 🎯 ওএসআরএম রিয়েল ড্রাইভিং রাউটিং এপিআই রিকোয়েস্ট (বাস্তব আঁকাবাঁকা রাস্তা)
  Future<void> selectListingAndShowRoute(ListingModel item) async {
    _selectedListing = item;

    LatLng? destLocation = _listingCoordsMap[item.name];
    if (destLocation == null || destLocation.latitude == 0.0) {
      destLocation = getRealLocationForListing(item);
    }

    if (destLocation.latitude == 0.0 || destLocation.longitude == 0.0) return;

    _mapCenter = destLocation;
    _mapZoom = 14.5; // পারফেক্ট ফোকাস জুম

    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${userLatLng.longitude},${userLatLng.latitude};${destLocation.longitude},${destLocation.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();
        }
      } else {
        _routePoints = [userLatLng, _mapCenter!];
      }
    } catch (e) {
      _routePoints = [userLatLng, _mapCenter!];
    }

    notifyListeners();
  }

  // 🗺️ ম্যাপে সবগুলো পিনকে রিয়েল লোকেশনে একসাথে দেখানোর জন্য ফাংশন
  LatLng getRealLocationForListing(ListingModel item) {
    if (_listingCoordsMap.containsKey(item.name)) {
      return _listingCoordsMap[item.name]!;
    }

    // ডাটা ম্যাপে ব্যাকআপ না থাকলে সরাসরি হাইভ থেকে সার্চ করা হবে
    final dataBox = Hive.box('cached_listings');
    final rawData = dataBox.get('full_country_data');
    if (rawData != null && rawData['listings'] != null) {
      final match = (rawData['listings'] as List).firstWhere(
        (e) => e['name'] == item.name,
        orElse: () => null,
      );
      if (match != null) {
        double lat =
            double.tryParse(match['latitude']?.toString() ?? '0.0') ?? 0.0;
        double lng =
            double.tryParse(match['longitude']?.toString() ?? '0.0') ?? 0.0;
        if (lat != 0.0) {
          _listingCoordsMap[item.name] = LatLng(lat, lng);
          return LatLng(lat, lng);
        }
      }
    }
    return userLatLng;
  }

  void filterByCategory(String category) {
    if (_selectedCategory == category) {
      _selectedCategory = '';
    } else {
      _selectedCategory = category;
    }
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;
    _applyFilters();
  }

  void searchListings(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // 🧠 ১০০% ফিক্সড ইন্টেলিজেন্ট ক্যাটাগরি ফিল্টারিং ইঞ্জিন
  void _applyFilters() {
    _filteredListings = _allListings.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery) ||
          item.subtitle.toLowerCase().contains(_searchQuery);

      bool matchesCat = _selectedCategory.isEmpty;
      if (!matchesCat) {
        String selected = _selectedCategory.toLowerCase();
        IconData targetIcon = _getIconForCategory(selected);

        // নামের ওপর নির্ভর না করে সরাসরি আইকন টাইপ বা আইটেমের নাম মিলিয়ে ডাটা লোড করা হচ্ছে
        if (selected == 'madrasah' ||
            selected == 'madrasa' ||
            selected == 'mosque') {
          matchesCat =
              item.icon == Icons.mosque ||
              item.name.toLowerCase().contains('madrasah') ||
              item.name.toLowerCase().contains('madrasa') ||
              item.name.toLowerCase().contains('mosque') ||
              item.subtitle.toLowerCase().contains('madrasah');
        } else {
          matchesCat =
              item.icon == targetIcon ||
              item.name.toLowerCase().contains(selected) ||
              item.subtitle.toLowerCase().contains(selected);
        }
      }
      return matchesSearch && matchesCat;
    }).toList();

    notifyListeners();
  }

  // 🛠️ টেস্ট ব্যাকআপ জেনারেটর (যদি হাইভ কোন ডেটা রিটার্ন না করে)
  void _insertFallbackData() {
    double baseLat = userLatLng.latitude;
    double baseLng = userLatLng.longitude;

    var mockList = [
      {
        'name': 'Uttara Model School',
        'subtitle': 'Sector 4, Uttara',
        'category': 'school',
        'lat': baseLat + 0.008,
        'lng': baseLng + 0.009,
      },
      {
        'name': 'Milestone College',
        'subtitle': 'Sector 11, Uttara',
        'category': 'school',
        'lat': baseLat + 0.015,
        'lng': baseLng - 0.007,
      },
      {
        'name': 'Aga Khan Hospital',
        'subtitle': 'Sector 10, Uttara',
        'category': 'hospital',
        'lat': baseLat - 0.005,
        'lng': baseLng + 0.012,
      },
      {
        'name': 'Uttara Central Mosque',
        'subtitle': 'Sector 3, Uttara',
        'category': 'mosque',
        'lat': baseLat + 0.003,
        'lng': baseLng - 0.002,
      },
      {
        'name': 'Baitul Mukarram Madrasah',
        'subtitle': 'Azampur, Dhaka',
        'category': 'madrasah',
        'lat': baseLat - 0.012,
        'lng': baseLng + 0.005,
      },
      {
        'name': 'Abdullahpur Bus Stand',
        'subtitle': 'Uttara Highway',
        'category': 'bus',
        'lat': baseLat + 0.022,
        'lng': baseLng + 0.018,
      },
      {
        'name': 'Trust Filling Station',
        'subtitle': 'House Building',
        'category': 'petrol',
        'lat': baseLat + 0.011,
        'lng': baseLng - 0.011,
      },
    ];

    _allListings = mockList.map((e) {
      String name = e['name'] as String;
      _listingCoordsMap[name] = LatLng(e['lat'] as double, e['lng'] as double);
      return ListingModel(
        name: name,
        subtitle: e['subtitle'] as String,
        distance: '2.5km',
        icon: _getIconForCategory(e['category'] as String),
        iconColor: _getColorForCategory(e['category'] as String),
      );
    }).toList();
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'school':
        return Icons.school;
      case 'madrasah':
      case 'madrasa':
      case 'mosque':
        return Icons.mosque;
      case 'petrol':
        return Icons.local_gas_station;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.place;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Colors.blue;
      case 'police':
        return Colors.indigo;
      case 'school':
        return Colors.orange;
      case 'madrasah':
        return Colors.brown;
      case 'madrasa':
      case 'mosque':
        return Colors.green;
      case 'petrol':
        return Colors.teal;
      case 'bus':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
