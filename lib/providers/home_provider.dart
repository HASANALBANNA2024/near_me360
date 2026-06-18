import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/listing_model.dart';
import '../services/map_places_service.dart';

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

  // 🎯 ডিফল্ট রেডিয়াস ৫০ কিলোমিটার সেট করা হলো
  double _selectedRadius = 50.0;

  // 🎯 জিপিএস রুট ট্র্যাক করার জন্য রিয়েল-টাইম ডাটা ম্যাপ
  final Map<String, LatLng> _listingCoordsMap = {};

  List<ListingModel> get listings => _filteredListings;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  double get selectedRadius => _selectedRadius;

  ListingModel? get selectedListing => _selectedListing;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get mapCenter => _mapCenter;
  double get mapZoom => _mapZoom;

  LatLng get userLatLng => LatLng(
    _userPosition?.latitude ?? 23.8103,
    _userPosition?.longitude ?? 90.4125,
  );

  void updateRadius(double newRadius) {
    _selectedRadius = newRadius;
    if (newRadius <= 10) {
      _mapZoom = 13.5;
    } else if (newRadius <= 30) {
      _mapZoom = 12.0;
    } else {
      _mapZoom = 10.0;
    }
    loadCachedData(isSilent: true);
  }

  // 🌍 রিয়েল-টাইম লাইভ ফেচ ইঞ্জিন
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
          timeLimit: const Duration(seconds: 5),
        );
        _mapCenter = userLatLng;
      } catch (e) {
        print("GPS Position Error: $e");
      }

      List<dynamic> list = [];

      // 🎯 ফিক্স: লোকাল ফেক ক্যাশের উপর নির্ভর না করে, ক্যাটাগরি সিলেক্টেড থাকলেই
      // সরাসরি লাইভ Overpass API থেকে রিয়েল ডাটা তুলে আনা হবে।
      if (_selectedCategory.isNotEmpty) {
        print("📡 Fetching Live Data for Category: $_selectedCategory");
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

        // ক্যাটাগরি এপিআই থেকে ব্ল্যাঙ্ক আসলে সিলেক্টেড ট্যাগ ব্যাকআপ হিসেবে কাজ করবে
        String categoryRaw = e['category'] ?? _selectedCategory;

        if (name.isNotEmpty && lat != 0.0 && lng != 0.0) {
          _listingCoordsMap[name] = LatLng(lat, lng);
        }

        // 📏 লাইভ দূরত্ব ক্যালকুলেশন লজিক
        String finalDistance = "0.1km";
        if (_userPosition != null && lat != 0.0 && lng != 0.0) {
          double meters = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          );
          finalDistance = "${(meters / 1000).toStringAsFixed(1)}km";
        } else if (e['distance'] != null) {
          finalDistance = e['distance'];
        }

        return ListingModel(
          name: name,
          subtitle: e['subtitle'] ?? 'Near Your Area',
          distance: finalDistance,
          icon: _getIconForCategory(categoryRaw),
          iconColor: _getColorForCategory(categoryRaw),
        );
      }).toList();

      _applyFilters();
    } catch (e) {
      print("Error loading data: $e");
      _applyFilters();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🏎️ 🎯 ওএসআরএম রিয়েল ড্রাইビング রাউটিং এপিআই
  Future<void> selectListingAndShowRoute(
    BuildContext context,
    ListingModel item,
  ) async {
    _selectedListing = item;

    LatLng? destLocation = _listingCoordsMap[item.name];
    if (destLocation == null || destLocation.latitude == 0.0) {
      destLocation = getRealLocationForListing(item);
    }

    if (destLocation.latitude == 0.0 || destLocation.longitude == 0.0) return;

    _mapCenter = destLocation;
    _mapZoom = 14.5;

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

    // 🗺️ আইটেমে ক্লিক করলে নিচ থেকে সুন্দর বটম শীট ভেসে উঠবে
    _showDetailsBottomSheet(context, item);
  }

  // 🔽 সুন্দর বটম শীট উইজেট মেথড
  void _showDetailsBottomSheet(BuildContext context, ListingModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.iconColor.withOpacity(0.2),
                    child: Icon(item.icon, color: item.iconColor),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Distance: ${item.distance}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.map, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  LatLng getRealLocationForListing(ListingModel item) {
    if (_listingCoordsMap.containsKey(item.name)) {
      return _listingCoordsMap[item.name]!;
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
    loadCachedData(isSilent: true);
  }

  void searchListings(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // 🧠 ১০০% নিখুঁত ডিস্ট্যান্স ফিল্টারিং ও সোর্টিং ইঞ্জিন (যা ডাটা ড্রপ করবে না)
  void _applyFilters() {
    List<ListingModel> temp = [];

    for (var item in _allListings) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery) ||
          item.subtitle.toLowerCase().contains(_searchQuery);

      // কিমি স্ট্রিং ক্লিন করে ডাবল ফরমেটে কনভার্ট করা
      double itemKM =
          double.tryParse(item.distance.replaceAll('km', '').trim()) ?? 0.0;

      // রেডিয়াসের নিখুঁত ম্যাপিং কন্ডিশন
      bool matchesRadius = itemKM == 0.0 || itemKM <= _selectedRadius;

      bool matchesCat = _selectedCategory.isEmpty;
      if (!matchesCat) {
        String selected = _selectedCategory.toLowerCase().trim();
        IconData targetIcon = _getIconForCategory(selected);

        // আইকন ম্যাচিং অথবা ডিরেক্ট টেক্সট কন্টেইন চেক
        matchesCat =
            item.icon == targetIcon ||
            item.name.toLowerCase().contains(selected) ||
            selected == 'all';
      }

      if (matchesSearch && matchesRadius && matchesCat) {
        temp.add(item);
      }
    }

    // 🏎️ 🎯 দূরত্ব অনুযায়ী শর্টেস্ট সোর্টিং (মিনিমাম ডিসট্যান্স সবার ওপরে থাকবে)
    temp.sort((a, b) {
      double distA =
          double.tryParse(a.distance.replaceAll('km', '').trim()) ?? 999.0;
      double distB =
          double.tryParse(b.distance.replaceAll('km', '').trim()) ?? 999.0;
      return distA.compareTo(distB);
    });

    _filteredListings = temp;
    notifyListeners();
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase().trim()) {
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
    switch (category.toLowerCase().trim()) {
      case 'hospital':
        return Colors.blue;
      case 'police':
        return Colors.indigo;
      case 'school':
        return Colors.orange;
      case 'madrasah':
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
