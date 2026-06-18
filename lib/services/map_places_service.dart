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

    // 🗺️ ওপেন স্ট্রিট ম্যাপের স্ট্যান্ডার্ড ট্যাগ কনভার্সন
    if (queryTag == 'mosque' ||
        queryTag == 'madrasah' ||
        queryTag == 'madrasa') {
      queryTag = 'place_of_worship';
    } else if (queryTag == 'petrol') {
      queryTag = 'fuel';
    } else if (queryTag == 'bus') {
      queryTag = 'bus_station';
    }

    // অতিরিক্ত বড় রিকোয়েস্ট এড়াতে ২০ কিমি সেফ জোন করা হয়েছে
    double safeRadius = radiusInKm > 20.0 ? 20.0 : radiusInKm;
    double radiusInMeters = safeRadius * 1000;

    // 🚀 গ্লোবাল ওভারপাস সার্ভার লিস্ট (প্রথমটা ফেল করলে অটো পরেরটায় যাবে)
    List<String> servers = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
      'https://overpass-api.de/api/interpreter',
    ];

    String queryBody =
        '?data=[out:json][timeout:25];'
        '('
        'node(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        'way(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        'relation(around:$radiusInMeters,${userLocation.latitude},${userLocation.longitude})[amenity=$queryTag];'
        ');'
        'out center;';

    for (String server in servers) {
      try {
        print("🛰️ Trying server: $server");
        final response = await http
            .get(Uri.parse('$server$queryBody'))
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['elements'] != null) {
            for (var element in data['elements']) {
              // নোড বা ওয়ের সেন্টার থেকে ল্যাট-লোন বের করা হচ্ছে
              double lat =
                  element['lat'] ??
                  (element['center'] != null ? element['center']['lat'] : 0.0);
              double lng =
                  element['lon'] ??
                  (element['center'] != null ? element['center']['lon'] : 0.0);

              var tags = element['tags'];
              if (tags == null || lat == 0.0 || lng == 0.0) continue;

              // 🎯 গ্লোবাল ইংলিশ ট্যাগ ('name:en') আগে রিড করবে, না থাকলে মেইন 'name' নিবে
              String name = tags['name:en'] ?? tags['name'] ?? '';
              if (name.isEmpty) continue;

              // সাবটাইটেল বা অ্যাড্রেসও ইংলিশে নেওয়ার সর্বোচ্চ চেষ্টা করবে
              String subtitle =
                  tags['addr:street:en'] ??
                  tags['addr:street'] ??
                  tags['addr:full'] ??
                  tags['addr:suburb'] ??
                  'Near Your Location';

              places.add({
                'name': name,
                'subtitle': subtitle,
                'latitude': lat.toString(),
                'longitude': lng.toString(),
                'category': category,
              });
            }
          }
          print(
            "🎉 Success from server: $server (Found ${places.length} items)",
          );
          return places; // ডাটা সাকসেসফুলি চলে আসলে লুপ ব্রেক করে রিটার্ন করবে
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
