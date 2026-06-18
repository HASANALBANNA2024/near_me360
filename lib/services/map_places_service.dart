import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPlacesService {
  // 🌍 ম্যাপস এপিআই (OSM Overpass API) থেকে লাইভ রিয়েল প্লেসেস ডেটা ফেচ মেথড
  static Future<List<Map<String, dynamic>>> fetchLivePlaces({
    required LatLng userLocation,
    required double radiusInKm,
    required String category,
  }) async {
    List<Map<String, dynamic>> places = [];

    String queryTag = category.toLowerCase().trim();
    if (queryTag.isEmpty) queryTag = 'amenity';

    // ওএসএম স্ট্যান্ডার্ড ট্যাগ প্রিপারেশন
    if (queryTag == 'mosque' ||
        queryTag == 'madrasah' ||
        queryTag == 'madrasa') {
      queryTag = 'place_of_worship';
    } else if (queryTag == 'school' ||
        queryTag == 'college' ||
        queryTag == 'university') {
      queryTag = 'school';
    }

    double radiusInMeters = radiusInKm * 1000;

    // 📡 ইউজারের কারেন্ট জিপিএস এর চারপাশে ডাইনামিক লাইভ কুয়েরি ইউআরএল
    final url =
        'https://overpass-api.de/api/interpreter?data=[out:json];'
        'node(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];out tags;';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elements'] != null) {
          for (var element in data['elements']) {
            double lat = element['lat'] ?? 0.0;
            double lng = element['lon'] ?? 0.0;
            var tags = element['tags'];
            String name = tags != null
                ? (tags['name'] ?? tags['name:en'] ?? '')
                : '';

            if (name.isEmpty || lat == 0.0) continue;

            places.add({
              'name': name,
              'subtitle':
                  tags['addr:full'] ?? tags['addr:street'] ?? 'Near Your Area',
              'latitude': lat.toString(),
              'longitude': lng.toString(),
              'category': category.isEmpty ? 'place' : category,
            });
          }
        }
      }
    } catch (e) {
      print("Online API Maps Fetch Error: $e");
    }
    return places;
  }
}
