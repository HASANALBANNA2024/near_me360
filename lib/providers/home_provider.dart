import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/listing_model.dart';
// 👈 অনলাইন থেকে লাইভ ডাটা আনার আলাদা সার্ভিস ফাইল
import '../services/map_places_service.dart';

class HomeProvider extends ChangeNotifier {
  List<ListingModel> _allListings = [];
  List<ListingModel> _filteredListings = [];

  String _selectedCategory = '';
  String _searchQuery = '';

  // 🎯 প্রথমবার অ্যাপ ওপেনের সময় true থাকবে, কিন্তু পরে ক্যাটাগরি ক্লিকের সময় স্ক্রিন ব্লাঙ্ক করবে না
  bool _isLoading = true;
  Position? _userPosition;

  ListingModel? _selectedListing;
  List<LatLng> _routePoints = [];
  LatLng? _mapCenter;
  double _mapZoom = 12.0;

  // 🎯 নতুন রেডিয়াস কিলোমিটার ভ্যারিয়েবল (ইউজার স্লাইডার দিয়ে কন্ট্রোল করতে পারবে)
  double _selectedRadius = 30.0;

  // 🎯 জিপিএস রুট ট্র্যাক করার জন্য রিয়েল-টাইম ডাটা ম্যাপ
  final Map<String, LatLng> _listingCoordsMap = {};

  List<ListingModel> get listings => _filteredListings;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  double get selectedRadius => _selectedRadius; // স্লাইডার উইজেটের জন্য গেটার

  ListingModel? get selectedListing => _selectedListing;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get mapCenter => _mapCenter;
  double get mapZoom => _mapZoom;

  LatLng get userLatLng => LatLng(
    _userPosition?.latitude ?? 23.8103,
    _userPosition?.longitude ?? 90.4125,
  );

  // 🔄 ইউজারের রেডিয়াস চেঞ্জ করার মেথড (কিলোমিটার বাড়ালে-কমালে এটি রান হবে)
  void updateRadius(double newRadius) {
    _selectedRadius = newRadius;
    if (newRadius <= 10) {
      _mapZoom = 13.5;
    } else if (newRadius <= 30) {
      _mapZoom = 12.0;
    } else {
      _mapZoom = 10.0;
    }

    // রেডিয়াস পরিবর্তন হলে ব্যাকগ্রাউন্ডে ডাটা আপডেট হবে, স্ক্রিন হারাবে না
    loadCachedData(isSilent: true);
  }

  // 🌍 ডাটা লোড করার মেইন মেথড
  // [isSilent = true] দিলে ব্যাকগ্রাউন্ডে ডাটা রিফ্রেশ হবে, স্ক্রিন ব্লাঙ্ক হয়ে স্পিনার আসবে না!
  Future<void> loadCachedData({bool isSilent = false}) async {
    if (!isSilent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 🛰️ ইউজারের বর্তমান জিপিএস লোকেশন নেওয়া হচ্ছে
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

      List<dynamic> list = [];

      // 🔄 ১. ডাটাবেজে পিওর রিয়েল ডেটা থাকলে তা লিস্টে নেবে
      if (rawData != null && rawData['listings'] != null) {
        list = rawData['listings'];
      }

      // 🌍 ২. ডাটাবেজ টোটাল খালি থাকলে সরাসরি অনলাইন ম্যাপস থেকে লাইভ রিয়েল ডাটা আনবে!
      if (list.isEmpty) {
        list = await MapPlacesService.fetchLivePlaces(
          userLocation: userLatLng,
          radiusInKm: _selectedRadius,
          category: _selectedCategory,
        );
      }

      _listingCoordsMap.clear();

      _allListings = list.map((e) {
        double lat = double.tryParse(e['latitude']?.toString() ?? '0.0') ?? 0.0;
        double lng =
            double.tryParse(e['longitude']?.toString() ?? '0.0') ?? 0.0;
        String name = e['name'] ?? '';
        String categoryRaw = e['category'] ?? '';

        // অরিজিনাল কোঅর্ডিনেট ম্যাপে লক করে রাখা হচ্ছে যেন পরে রুট খোঁজার সময় মিস না হয়
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
          subtitle: e['subtitle'] ?? 'Near Your Location',
          distance: finalDistance,
          icon: _getIconForCategory(categoryRaw),
          iconColor: _getColorForCategory(categoryRaw),
        );
      }).toList();

      _applyFilters();
    } catch (e) {
      print("Error loading real data: $e");
      _applyFilters();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🏎️ 🎯 ওএসআরএম রিয়েল ড্রাইビング রাউটিং এপিআই রিকোয়েস্ট (বাস্তব আঁকাবাঁকা রাস্তা)
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

  // ⚡ ফিক্সড ইন্টেলিজেন্ট ক্যাটাগরি ফিল্টার মেথড (কোনো স্ক্রিন ব্লাঙ্ক হবে না)
  void filterByCategory(String category) {
    if (_selectedCategory == category) {
      _selectedCategory = ''; // দ্বিতীয়বার ক্লিকে ফিল্টার রিলিজ
    } else {
      _selectedCategory = category;
    }
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;

    // 🎯 মূল যাদু এখানে: আমরা লোকাল ডাটা ফিল্টার ইনস্ট্যান্ট অ্যাপ্লাই করে দেব
    _applyFilters();

    // 🔄 ব্যাকগ্রাউন্ডে অনলাইন থেকে লাইভ নতুন ডাটা নিয়ে আসবে, স্ক্রিন একদম কাঁপবেও না!
    loadCachedData(isSilent: true);
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

      // 🎯 স্লাইডারের দূরত্বের ওপর ভিত্তি করে ফিল্টারিং লজিক
      double itemKM =
          double.tryParse(item.distance.replaceAll('km', '')) ?? 0.0;
      bool matchesRadius = itemKM <= _selectedRadius;

      bool matchesCat = _selectedCategory.isEmpty;
      if (!matchesCat) {
        String selected = _selectedCategory.toLowerCase();
        IconData targetIcon = _getIconForCategory(selected);

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
      return matchesSearch && matchesRadius && matchesCat;
    }).toList();

    // 🏎️ ডিস্ট্যান্স অনুযায়ী চমৎকার সোর্टिंग (সবচেয়ে কাছের প্লেসগুলো উপরে থাকবে)
    _filteredListings.sort((a, b) {
      double distA = double.tryParse(a.distance.replaceAll('km', '')) ?? 999.0;
      double distB = double.tryParse(b.distance.replaceAll('km', '')) ?? 999.0;
      return distA.compareTo(distB);
    });

    notifyListeners();
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'school':
      case 'college':
      case 'university':
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
      case 'college':
      case 'university':
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
