import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:near_me360/services/map_places_service.dart';

import '../models/listing_model.dart';

class HomeProvider extends ChangeNotifier {
  List<ListingModel> _allListings = [];
  List<ListingModel> _filteredListings = [];

  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isCustomSearching = false;
  Position? _userPosition;

  ListingModel? _selectedListing;
  List<LatLng> _routePoints = [];
  LatLng? _mapCenter;
  double _mapZoom = 12.0;
  double _selectedRadius = 50.0;

  int _currentPage = 0;
  final int _itemsPerPage = 4;

  final Map<String, LatLng> _listingCoordsMap = {};

  // 🕒 রিসেন্ট সার্চের জন্য সেফ অবজেক্ট লিস্ট (নাম, ল্যাট, লন সহ)
  List<Map<String, dynamic>> _recentSearchesList = [];
  List<Map<String, dynamic>> get recentSearches => _recentSearchesList;
  final recentBox = Hive.box('recent_searches');

  List<ListingModel> get listings {
    int start = _currentPage * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (start >= _filteredListings.length) return [];
    if (end > _filteredListings.length) end = _filteredListings.length;
    return _filteredListings.sublist(start, end);
  }

  Map<String, LatLng> get allListingCoords => _listingCoordsMap;
  int get currentPage => _currentPage + 1;
  int get totalPages => (_filteredListings.length / _itemsPerPage).ceil();
  bool get hasNextPage => (_currentPage + 1) < totalPages;
  bool get hasPreviousPage => _currentPage > 0;
  int get totalItems => _filteredListings.length;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isCustomSearching => _isCustomSearching;
  double get selectedRadius => _selectedRadius;
  ListingModel? get selectedListing => _selectedListing;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get mapCenter => _mapCenter;
  double get mapZoom => _mapZoom;

  LatLng get userLatLng => LatLng(
    _userPosition?.latitude ?? 23.8103,
    _userPosition?.longitude ?? 90.4125,
  );

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      notifyListeners();
    }
  }

  void updateRadius(double newRadius) {
    _selectedRadius = newRadius;
    _mapZoom = newRadius <= 10 ? 13.5 : (newRadius <= 30 ? 12.0 : 10.0);
    loadCachedData(isSilent: true);
  }

  // 📥 ক্যাশ ও লাইভ ডাটা লোড মেথড
  Future<void> loadCachedData({bool isSilent = false}) async {
    if (!isSilent && !_isCustomSearching) {
      _isLoading = true;
      notifyListeners();
    }

    // 🔒 🛡️ ক্রাশ প্রোটেকশন চেক: পুরোনো ডাটা ফরম্যাট মিসম্যাচ ফিক্স
    final List<dynamic>? cachedSearches = recentBox.get('searches');
    if (cachedSearches != null) {
      try {
        _recentSearchesList = cachedSearches
            .where(
              (e) => e is Map,
            ) // পুরোনো কোনো Plain String থাকলে সেটিকে বাদ দিয়ে দিবে
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        print("Hive Data Safe Migration Error: $e");
        _recentSearchesList =
            []; // সমস্যা হলে ডাটা রিমুভ করে ফ্লিট ব্লক হওয়া আটকাবে
      }
    }

    try {
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
      if (_selectedCategory.isNotEmpty) {
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
        String name = e['name'] ?? 'Unknown Place';
        String subtitle = e['subtitle'] ?? 'Near Your Area';
        String categoryRaw = e['category'] ?? _selectedCategory;

        if (name != 'Unknown Place' && lat != 0.0 && lng != 0.0) {
          _listingCoordsMap[name] = LatLng(lat, lng);
        }

        String finalDistance = "0.1km";
        if (_userPosition != null && lat != 0.0 && lng != 0.0) {
          double meters = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            lat,
            lng,
          );
          finalDistance = meters >= 1000
              ? "${(meters / 1000).toStringAsFixed(1)}km"
              : "${meters.toStringAsFixed(0)}m";
        }

        return ListingModel(
          name: name,
          subtitle: subtitle,
          distance: finalDistance,
          icon: getIconForCategory(categoryRaw),
          iconColor: getColorForCategory(categoryRaw),
        );
      }).toList();

      _currentPage = 0;
      _applyFilters();
    } catch (e) {
      print("Error loading data: $e");
      _applyFilters();
    }

    _isLoading = false;
    _isCustomSearching = false;
    notifyListeners();
  }

  // 💾 লোকেশন Hive-এ অবজেক্ট আকারে সেভ (লাস্ট ৫০ টি)
  void saveSelectedLocationToHive(String name, double lat, double lng) {
    if (name.trim().isEmpty || lat == 0.0 || lng == 0.0) return;

    _recentSearchesList.removeWhere((element) => element['name'] == name);

    _recentSearchesList.insert(0, {
      'name': name,
      'latitude': lat,
      'longitude': lng,
    });

    if (_recentSearchesList.length > 50) {
      _recentSearchesList.removeLast();
    }

    recentBox.put('searches', _recentSearchesList);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearchesList.clear();
    recentBox.delete('searches');
    notifyListeners();
  }

  // 🚀 কার্ড বা পিনে ক্লিক করলে লোকেশন সেভ করবে এবং রুট জেনারেট করবে
  Future<void> selectListingAndShowRoute(
    BuildContext context,
    ListingModel item,
  ) async {
    _selectedListing = item;
    LatLng? destLocation = _listingCoordsMap[item.name];
    if (destLocation == null || destLocation.latitude == 0.0) return;

    _mapCenter = destLocation;
    _mapZoom = 14.5;

    // 🎯 নাম ও ল্যাট-লোনসহ অফলাইনে স্টোর হচ্ছে
    saveSelectedLocationToHive(
      item.name,
      destLocation.latitude,
      destLocation.longitude,
    );

    await _fetchRoute(destLocation);
  }

  // 🕒 রিসেন্ট প্যানেল বা সি-মোর পপ-আপ থেকে ক্লিক করলে অফলাইন ডাটা নিয়ে সরাসরি ম্যাপ মুভ করবে
  Future<void> selectRecentOfflineLocation(String name, LatLng location) async {
    _selectedListing = ListingModel(
      name: name,
      subtitle: 'Saved Location',
      distance: 'Calculating...',
      icon: Icons.place,
      iconColor: Colors.redAccent,
    );

    _mapCenter = location;
    _mapZoom = 14.5;
    _listingCoordsMap[name] = location;

    notifyListeners();
    await _fetchRoute(location);
  }

  Future<void> _fetchRoute(LatLng destLocation) async {
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

  void searchCustomQuery(String query) {
    if (query.trim().isEmpty) return;
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;
    _currentPage = 0;
    _isCustomSearching = true;
    _selectedCategory = query;
    notifyListeners();
    loadCachedData(isSilent: false);
  }

  void filterByCategory(String category) {
    _selectedCategory = _selectedCategory == category ? '' : category;
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;
    _currentPage = 0;
    _isCustomSearching = _selectedCategory.isNotEmpty;
    _applyFilters();
    notifyListeners();
    loadCachedData(isSilent: false);
  }

  void searchListings(String query) {
    _searchQuery = query.toLowerCase();
    _currentPage = 0;
    _applyFilters();
  }

  void _applyFilters() {
    List<ListingModel> temp = [];
    final knownIcons = [
      Icons.local_hospital,
      Icons.local_police,
      Icons.school,
      Icons.mosque,
      Icons.local_gas_station,
      Icons.directions_bus,
    ];

    for (var item in _allListings) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery) ||
          item.subtitle.toLowerCase().contains(_searchQuery);

      double itemKM =
          double.tryParse(
            item.distance.replaceAll('km', '').replaceAll('m', '').trim(),
          ) ??
          0.0;
      if (item.distance.contains('m') && !item.distance.contains('km')) {
        itemKM = itemKM / 1000;
      }

      bool matchesRadius = itemKM == 0.0 || itemKM <= _selectedRadius;
      bool matchesCat = _selectedCategory.isEmpty;

      if (!matchesCat) {
        String selected = _selectedCategory.toLowerCase().trim();
        IconData targetIcon = getIconForCategory(selected);

        if (selected == 'all') {
          matchesCat = true;
        } else if (selected == 'others' || targetIcon == Icons.place) {
          bool isUnknownCategory = !knownIcons.contains(item.icon);
          bool nameMatchesQuery = item.name.toLowerCase().contains(selected);
          matchesCat = isUnknownCategory || nameMatchesQuery;
        } else {
          matchesCat =
              item.icon == targetIcon ||
              item.name.toLowerCase().contains(selected);
        }
      }

      if (matchesSearch && matchesRadius && matchesCat) {
        temp.add(item);
      }
    }

    temp.sort((a, b) {
      double distA =
          double.tryParse(
            a.distance.replaceAll('km', '').replaceAll('m', '').trim(),
          ) ??
          999.0;
      if (a.distance.contains('m') && !a.distance.contains('km')) distA /= 1000;
      double distB =
          double.tryParse(
            b.distance.replaceAll('km', '').replaceAll('m', '').trim(),
          ) ??
          999.0;
      if (b.distance.contains('m') && !b.distance.contains('km')) distB /= 1000;
      return distA.compareTo(distB);
    });

    _filteredListings = temp;
    notifyListeners();
  }

  IconData getIconForCategory(String category) {
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
      case 'others':
        return Icons.search;
      default:
        return Icons.place;
    }
  }

  Color getColorForCategory(String category) {
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
      case 'others':
        return Colors.purple;
      default:
        return Colors.purpleAccent;
    }
  }
}
