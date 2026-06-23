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

  // Recent searches cache list (name, lat, lng objects)
  List<Map<String, dynamic>> _recentSearchesList = [];
  List<Map<String, dynamic>> get recentSearches => _recentSearchesList;
  final recentBox = Hive.box('recent_searches');

  // Sidebar group filter state tracking variables
  String _currentActiveGroup = '';
  String get currentActiveGroup => _currentActiveGroup;

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

  // Load cached and live network data
  Future<void> loadCachedData({bool isSilent = false}) async {
    if (!isSilent && !_isCustomSearching) {
      _isLoading = true;
      notifyListeners();
    }

    // Crash protection check: Fix old data format mismatch
    final List<dynamic>? cachedSearches = recentBox.get('searches');
    if (cachedSearches != null) {
      try {
        _recentSearchesList = cachedSearches
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        print("Hive Data Safe Migration Error: $e");
        _recentSearchesList = [];
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
        // If a group is active, resolve standard keyword mapping for OSM API
        String fetchKeyword = _selectedCategory;
        if (_currentActiveGroup == 'emergency') fetchKeyword = 'hospital';
        if (_currentActiveGroup == 'education') fetchKeyword = 'school';
        if (_currentActiveGroup == 'transport') fetchKeyword = 'bus';

        list = await MapPlacesService.fetchLivePlaces(
          userLocation: userLatLng,
          radiusInKm: _selectedRadius,
          category: fetchKeyword,
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

  // Save selected location to Hive (stores up to last 50 entries)
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

  // Triggered on card or marker click to save location and fetch route
  Future<void> selectListingAndShowRoute(
    BuildContext context,
    ListingModel item,
  ) async {
    _selectedListing = item;
    LatLng? destLocation = _listingCoordsMap[item.name];
    if (destLocation == null || destLocation.latitude == 0.0) return;

    _mapCenter = destLocation;
    _mapZoom = 14.5;

    saveSelectedLocationToHive(
      item.name,
      destLocation.latitude,
      destLocation.longitude,
    );

    await _fetchRoute(destLocation);
  }

  // Navigate to offline location directly via recent panel
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

  // Custom group search handling for sidebar menu actions
  void searchCustomGroup(String groupType) {
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;
    _currentPage = 0;
    _isCustomSearching = true;
    _currentActiveGroup = groupType.toLowerCase().trim();

    if (_currentActiveGroup == 'emergency') {
      _selectedCategory = 'Emergency';
    } else if (_currentActiveGroup == 'education') {
      _selectedCategory = 'Education';
    } else if (_currentActiveGroup == 'transport') {
      _selectedCategory = 'Transport';
    } else {
      _selectedCategory = '';
      _isCustomSearching = false;
    }

    notifyListeners();
    loadCachedData(isSilent: false);
  }

  void searchCustomQuery(String query) {
    if (query.trim().isEmpty) return;
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _mapZoom = 12.0;
    _currentPage = 0;
    _isCustomSearching = true;
    _currentActiveGroup = ''; // Reset group filter on manual custom search
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
    _currentActiveGroup =
        ''; // Reset group filter on explicit category selection
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
        // Multi-keyword matching logic if a custom group sidebar filter is active
        if (_currentActiveGroup == 'emergency') {
          final n = item.name.toLowerCase();
          final s = item.subtitle.toLowerCase();
          matchesCat =
              n.contains('hospital') ||
              n.contains('police') ||
              n.contains('fire') ||
              n.contains('pharmacy') ||
              s.contains('hospital') ||
              s.contains('police') ||
              s.contains('fire') ||
              s.contains('pharmacy');
        } else if (_currentActiveGroup == 'education') {
          final n = item.name.toLowerCase();
          final s = item.subtitle.toLowerCase();
          matchesCat =
              n.contains('school') ||
              n.contains('college') ||
              n.contains('university') ||
              n.contains('madrasah') ||
              n.contains('madrasa') ||
              s.contains('school') ||
              s.contains('college') ||
              s.contains('university') ||
              s.contains('madrasah') ||
              s.contains('madrasa');
        } else if (_currentActiveGroup == 'transport') {
          final n = item.name.toLowerCase();
          final s = item.subtitle.toLowerCase();
          matchesCat =
              n.contains('train') ||
              n.contains('cng') ||
              n.contains('bus') ||
              n.contains('petrol') ||
              n.contains('station') ||
              s.contains('train') ||
              s.contains('cng') ||
              s.contains('bus') ||
              s.contains('petrol') ||
              s.contains('station');
        } else if (_currentActiveGroup == 'favorites') {
          // Verify against localized favorite tag status
          matchesCat = item.isFavorite;
        } else {
          // Standard categorical filtering fallback
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
    final cat = category.toLowerCase().trim();
    if (cat == 'emergency') return Icons.gpp_bad;
    if (cat == 'education') return Icons.cast_for_education;
    if (cat == 'transport') return Icons.commute;
    if (cat == 'favorites') return Icons.favorite;

    switch (cat) {
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
    final cat = category.toLowerCase().trim();
    if (cat == 'emergency') return Colors.redAccent;
    if (cat == 'education') return Colors.deepOrangeAccent;
    if (cat == 'transport') return Colors.amber;
    if (cat == 'favorites') return Colors.redAccent;

    switch (cat) {
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

  // Dynamic graph data generator for the 7th custom bar segment
  List<Map<String, dynamic>> get separateGraphList {
    List<Map<String, dynamic>> items = [
      {
        'id': 'hospital',
        'name': 'Hospital',
        'icon': Icons.local_hospital,
        'color': Colors.blue,
        'count': 0,
      },
      {
        'id': 'police',
        'name': 'Police',
        'icon': Icons.local_police,
        'color': Colors.indigo,
        'count': 0,
      },
      {
        'id': 'school',
        'name': 'School',
        'icon': Icons.school,
        'color': Colors.orange,
        'count': 0,
      },
      {
        'id': 'mosque',
        'name': 'Mosque',
        'icon': Icons.mosque,
        'color': Colors.green,
        'count': 0,
      },
      {
        'id': 'petrol',
        'name': 'Petrol',
        'icon': Icons.local_gas_station,
        'color': Colors.teal,
        'count': 0,
      },
      {
        'id': 'bus',
        'name': 'Bus',
        'icon': Icons.directions_bus,
        'color': Colors.cyan,
        'count': 0,
      },
    ];

    for (var item in _allListings) {
      if (item.icon == Icons.local_hospital)
        items[0]['count'] = (items[0]['count'] as int) + 1;
      if (item.icon == Icons.local_police)
        items[1]['count'] = (items[1]['count'] as int) + 1;
      if (item.icon == Icons.school)
        items[2]['count'] = (items[2]['count'] as int) + 1;
      if (item.icon == Icons.mosque)
        items[3]['count'] = (items[3]['count'] as int) + 1;
      if (item.icon == Icons.local_gas_station)
        items[4]['count'] = (items[4]['count'] as int) + 1;
      if (item.icon == Icons.directions_bus)
        items[5]['count'] = (items[5]['count'] as int) + 1;
    }

    String currentCat = _selectedCategory.trim();
    List<String> knownKeys = [
      'hospital',
      'police',
      'school',
      'mosque',
      'petrol',
      'bus',
      'madrasah',
      'madrasa',
    ];

    if (currentCat.isNotEmpty &&
        !knownKeys.contains(currentCat.toLowerCase())) {
      String shortName = currentCat;
      IconData shortIcon = Icons.search;
      Color shortColor = Colors.purpleAccent;

      if (_currentActiveGroup == 'emergency') {
        shortName = 'Emergency';
        shortIcon = Icons.gpp_bad;
        shortColor = Colors.redAccent;
      } else if (_currentActiveGroup == 'education') {
        shortName = 'Education';
        shortIcon = Icons.cast_for_education;
        shortColor = Colors.deepOrangeAccent;
      } else if (_currentActiveGroup == 'transport') {
        shortName = 'Transport';
        shortIcon = Icons.commute;
        shortColor = Colors.amber;
      } else if (_currentActiveGroup == 'favorites') {
        shortName = 'Favorites';
        shortIcon = Icons.favorite;
        shortColor = Colors.redAccent;
      }

      items.add({
        'id': 'custom',
        'name': shortName,
        'icon': shortIcon,
        'color': shortColor,
        'count': _filteredListings.length,
      });
    }

    return items;
  }

  /// =================== FAVORITE FEATURE LOGIC ===================

  void toggleFavorite(ListingModel item) {
    item.isFavorite = !item.isFavorite;

    List<dynamic> favList = recentBox.get('favorites_list', defaultValue: []);
    List<Map<String, dynamic>> updatedFavs = favList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (item.isFavorite) {
      /// Fetch destination coordinates from global map memory to store into Hive box safely
      LatLng? coords = _listingCoordsMap[item.name];

      updatedFavs.add({
        'name': item.name,
        'subtitle': item.subtitle,
        'distance': item.distance,
        'category': item.name.toLowerCase(),
        'latitude': coords?.latitude ?? 0.0,

        ///  Latitude Stored
        'longitude': coords?.longitude ?? 0.0,

        ///  Longitude Stored
      });
    } else {
      updatedFavs.removeWhere((element) => element['name'] == item.name);
    }

    recentBox.put('favorites_list', updatedFavs);

    if (_currentActiveGroup == 'favorites') {
      showFavoritesOnly();
    } else {
      notifyListeners();
    }
  }

  Future<void> selectFavoriteAndShowRoute({
    required String name,
    required double destLat,
    required double destLng,
  }) async {
    if (destLat == 0.0 || destLng == 0.0) return;

    LatLng destLocation = LatLng(destLat, destLng);

    // 1. Point map center camera directly to the target destination pointer
    _mapCenter = destLocation;
    _mapZoom = 14.5;
    _listingCoordsMap[name] = destLocation;

    // 2. Fetch fresh instant live coordinates of where the user is standing right now
    try {
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print("GPS Core Existing Refresh Error: $e");
    }

    notifyListeners();

    // 3. Fire OSRM routing protocol using the updated live user positioning states
    await _fetchRoute(destLocation);
  }

  void showFavoritesOnly() {
    _routePoints = [];
    _selectedListing = null;
    _mapCenter = userLatLng;
    _currentPage = 0;
    _isCustomSearching = true;
    _currentActiveGroup = 'favorites';
    _selectedCategory = 'favorites';

    List<dynamic> favList = recentBox.get('favorites_list', defaultValue: []);

    _allListings = favList.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ListingModel(
        name: map['name'] ?? '',
        subtitle: map['subtitle'] ?? '',
        distance: map['distance'] ?? '0.1km',
        icon: getIconForCategory(map['category'] ?? ''),
        iconColor: getColorForCategory(map['category'] ?? ''),
        isFavorite: true,
      );
    }).toList();

    _filteredListings = List.from(_allListings);
    notifyListeners();
  }
}
