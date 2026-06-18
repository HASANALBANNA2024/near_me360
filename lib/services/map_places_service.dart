import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPlacesService {
  static Future<List<Map<String, dynamic>>> fetchLivePlaces({
    required LatLng userLocation,
    required double radiusInKm,
    required String category,
  }) async {
    List<Map<String, dynamic>> places = [];

    String queryTag = category.toLowerCase().trim();
    if (queryTag.isEmpty) return [];

    // ওপেন স্ট্রিট ম্যাপ ট্যাগ কনভার্সন
    if (queryTag == 'school') queryTag = 'school';
    if (queryTag == 'mosque' ||
        queryTag == 'madrasah' ||
        queryTag == 'madrasa') {
      queryTag = 'place_of_worship';
    }
    if (queryTag == 'hospital') queryTag = 'hospital';
    if (queryTag == 'petrol') queryTag = 'fuel';
    if (queryTag == 'bus') queryTag = 'bus_station';
    if (queryTag == 'police') queryTag = 'police';

    double safeRadius = radiusInKm > 20.0
        ? 20.0
        : radiusInKm; // ২৫ কিমি সেফ জোন
    double radiusInMeters = safeRadius * 1000;

    // 🚀 সার্ভার লিস্ট (প্রথমটা ফেল করলে পরেরটায় যাবে)
    List<String> servers = [
      'https://overpass.kumi.systems/api/interpreter', // 🇫🇷 ফাস্ট ফরাসি সার্ভার
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter', // 🇷🇺 ব্যাকআপ রুশ সার্ভার
      'https://overpass-api.de/api/interpreter', // 🇩🇪 মেইন জার্মান সার্ভার
    ];

    String queryBody =
        '?data=[out:json][timeout:25];'
        '('
        'node(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        'way(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        'relation(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        ');'
        'out center;';

    // 🔄 লুপ চালিয়ে ব্যাকআপ সার্ভার চেক করা হচ্ছে
    for (String server in servers) {
      try {
        print("🛰️ Trying server: $server");
        final response = await http
            .get(Uri.parse('$server$queryBody'))
            .timeout(const Duration(seconds: 25)); // ২৫ সেকেন্ড টাইমআউট

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['elements'] != null) {
            for (var element in data['elements']) {
              double lat =
                  element['lat'] ??
                  (element['center'] != null ? element['center']['lat'] : 0.0);
              double lng =
                  element['lon'] ??
                  (element['center'] != null ? element['center']['lon'] : 0.0);

              var tags = element['tags'];
              String name = tags != null
                  ? (tags['name'] ?? tags['name:en'] ?? '')
                  : '';

              if (name.isEmpty || lat == 0.0 || lng == 0.0) continue;

              places.add({
                'name': name,
                'subtitle':
                    tags['addr:full'] ??
                    tags['addr:street'] ??
                    'Near Your Location',
                'latitude': lat.toString(),
                'longitude': lng.toString(),
                'category': category,
              });
            }
          }
          print(
            "🎉 Success from server: $server (Found ${places.length} items)",
          );
          return places; // ডাটা পেয়ে গেলে এখানেই কোড শেষ, পরের সার্ভারে যাবে না।
        }
      } catch (serverError) {
        print(
          "⚠️ Server $server failed or timed out: $serverError. Trying next...",
        );
      }
    }

    print("🛑 All Overpass servers failed to respond.");
    return places;
  }
}
