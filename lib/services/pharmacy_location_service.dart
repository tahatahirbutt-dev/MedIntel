import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:med_intel/models/pharmacy.dart';

class LocationPermissionDeniedException implements Exception {
  final bool forever;
  const LocationPermissionDeniedException({this.forever = false});
}

/// Finds pharmacies near the device's GPS position using free, keyless
/// sources only: the `geolocator` plugin for location, and OpenStreetMap's
/// public Overpass API for pharmacy data. No API keys, no paid services.
class PharmacyLocationService {
  // Multiple public, keyless Overpass mirrors — queried concurrently and
  // merged so a single slow/rate-limited/down instance doesn't sink the
  // whole search or add its own timeout to the total wait.
  static const List<String> _overpassMirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.osm.ch/api/interpreter',
  ];

  // Some public Overpass instances reject requests with the Dart HTTP
  // client's default generic User-Agent as likely bot traffic (HTTP 406).
  // Overpass's own usage policy asks clients to self-identify, so send a
  // descriptive one.
  static const Map<String, String> _requestHeaders = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'User-Agent': 'MedIntel-FYP/1.0 (Flutter app; contact: medintelfyp@gmail.com)',
  };

  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException(forever: true);
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns pharmacies near the given point, sorted by distance. Starts at
  /// [radiusMeters] and automatically widens the search (then retries at
  /// larger radii) if nothing is found close by — OpenStreetMap's pharmacy
  /// coverage is patchy in some areas, so a small fixed radius often comes
  /// back empty even when the live query itself is working fine. Returns an
  /// empty list only if every radius tier comes back empty (or every mirror
  /// fails) — callers should fall back to local mock data in that case.
  static Future<List<Pharmacy>> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    final radiiToTry = <int>{radiusMeters.toInt(), 15000, 30000}
        .where((r) => r >= radiusMeters.toInt())
        .toList()
      ..sort();

    for (final radius in radiiToTry) {
      final results = await _queryOverpass(latitude, longitude, radius);
      if (results != null && results.isNotEmpty) {
        return _refineWithDrivingDistance(results, latitude, longitude);
      }
    }
    return [];
  }

  /// Replaces each pharmacy's straight-line `distance` with a real driving
  /// distance from OSRM's free, keyless public routing API — straight-line
  /// distance can be roughly half the actual road distance when there's no
  /// direct route (rivers, highways, indirect streets), which is misleading
  /// next to a "Directions" button. Falls back to the straight-line values
  /// unchanged if OSRM is unreachable or errors out.
  static Future<List<Pharmacy>> _refineWithDrivingDistance(
    List<Pharmacy> pharmacies,
    double originLat,
    double originLng,
  ) async {
    final withCoords = pharmacies
        .where((p) => p.latitude != null && p.longitude != null)
        .take(25)
        .toList();
    if (withCoords.isEmpty) return pharmacies;

    final coords = StringBuffer('$originLng,$originLat');
    for (final p in withCoords) {
      coords.write(';${p.longitude},${p.latitude}');
    }

    final uri = Uri.parse(
      'https://router.project-osrm.org/table/v1/driving/$coords'
      '?sources=0&annotations=distance',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return pharmacies;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['code'] != 'Ok') return pharmacies;

      final distances = (decoded['distances'] as List<dynamic>)[0] as List<dynamic>;

      final refined = <Pharmacy>[];
      for (var i = 0; i < withCoords.length; i++) {
        final meters = (distances[i + 1] as num?)?.toDouble();
        final p = withCoords[i];
        refined.add(meters == null
            ? p
            : Pharmacy(
                id: p.id,
                name: p.name,
                address: p.address,
                distance: meters / 1000,
                rating: p.rating,
                reviewCount: p.reviewCount,
                availability: p.availability,
                deliveryFee: p.deliveryFee,
                deliveryTime: p.deliveryTime,
                latitude: p.latitude,
                longitude: p.longitude,
                phone: p.phone,
              ));
      }

      refined.addAll(pharmacies.where((p) => p.latitude == null || p.longitude == null));
      refined.sort((a, b) => a.distance.compareTo(b.distance));
      debugPrint('[PharmacyLocationService] OSRM refined ${refined.length} distances to driving distance');
      return refined;
    } catch (e) {
      debugPrint('[PharmacyLocationService] OSRM refinement failed, keeping straight-line distance: $e');
      return pharmacies;
    }
  }

  static String _buildQuery(double lat, double lng, int radiusMeters) {
    final around = '(around:$radiusMeters,$lat,$lng)';
    return '[out:json][timeout:15];'
        '('
        'node["amenity"="pharmacy"]$around;'
        'way["amenity"="pharmacy"]$around;'
        'node["healthcare"="pharmacy"]$around;'
        'way["healthcare"="pharmacy"]$around;'
        'node["shop"="chemist"]$around;'
        'way["shop"="chemist"]$around;'
        ');'
        'out center;';
  }

  /// Queries every mirror concurrently for one radius tier and merges
  /// whatever comes back (deduped by id), rather than trying them one at a
  /// time — a slow-but-complete mirror and a fast-but-thin one both get a
  /// chance, and total wait is bounded by one timeout instead of stacking
  /// every mirror's timeout in sequence. Returns null only if every mirror
  /// failed outright (network/HTTP error).
  static Future<List<Pharmacy>?> _queryOverpass(
    double lat,
    double lng,
    int radiusMeters,
  ) async {
    final query = _buildQuery(lat, lng, radiusMeters);

    final attempts = await Future.wait(
      _overpassMirrors.map((mirror) => _queryMirror(mirror, query, lat, lng, radiusMeters)),
    );

    final successful = attempts.whereType<List<Pharmacy>>();
    if (successful.isEmpty) return null;

    final merged = <String, Pharmacy>{};
    for (final list in successful) {
      for (final pharmacy in list) {
        merged[pharmacy.id] = pharmacy;
      }
    }

    final combined = merged.values.toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    return combined;
  }

  static Future<List<Pharmacy>?> _queryMirror(
    String mirror,
    String query,
    double lat,
    double lng,
    int radiusMeters,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .post(Uri.parse(mirror), headers: _requestHeaders, body: {'data': query})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          '[PharmacyLocationService] $mirror radius=$radiusMeters -> '
          'HTTP ${response.statusCode} after ${stopwatch.elapsedMilliseconds}ms',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];

      final pharmacies = elements
          .map((e) => _parseElement(e as Map<String, dynamic>, lat, lng))
          .whereType<Pharmacy>()
          .toList();

      debugPrint(
        '[PharmacyLocationService] $mirror radius=$radiusMeters -> '
        '${pharmacies.length} pharmacies in ${stopwatch.elapsedMilliseconds}ms',
      );
      return pharmacies;
    } catch (e) {
      debugPrint(
        '[PharmacyLocationService] $mirror radius=$radiusMeters -> '
        'FAILED after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      return null;
    }
  }

  /// Returns a copy of [pharmacies] with `distance` recomputed from the
  /// given point (for entries that have coordinates) and sorted ascending.
  /// Used to make the mock-data fallback show a meaningful order relative
  /// to the user's real GPS position.
  static List<Pharmacy> sortByDistanceFrom(
    List<Pharmacy> pharmacies,
    double latitude,
    double longitude,
  ) {
    final withDistance = pharmacies.map((p) {
      if (p.latitude == null || p.longitude == null) return p;
      final distanceKm =
          Geolocator.distanceBetween(latitude, longitude, p.latitude!, p.longitude!) /
          1000;
      return Pharmacy(
        id: p.id,
        name: p.name,
        address: p.address,
        distance: distanceKm,
        rating: p.rating,
        reviewCount: p.reviewCount,
        availability: p.availability,
        deliveryFee: p.deliveryFee,
        deliveryTime: p.deliveryTime,
        latitude: p.latitude,
        longitude: p.longitude,
        phone: p.phone,
      );
    }).toList();

    withDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return withDistance;
  }

  static Pharmacy? _parseElement(
    Map<String, dynamic> element,
    double originLat,
    double originLng,
  ) {
    final center = element['center'] as Map<String, dynamic>?;
    final lat = (element['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
    final lng = (element['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final tags = (element['tags'] as Map<String, dynamic>?) ?? {};
    final name = (tags['name'] as String?)?.trim();

    final addressParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:city'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();

    final distanceKm =
        Geolocator.distanceBetween(originLat, originLng, lat, lng) / 1000;

    return Pharmacy(
      id: 'osm_${element['type']}_${element['id']}',
      name: (name == null || name.isEmpty) ? 'Pharmacy' : name,
      address: addressParts.isEmpty
          ? 'Address not available'
          : addressParts.join(', '),
      distance: distanceKm,
      rating: 0,
      reviewCount: 0,
      availability: const {},
      deliveryFee: 0,
      deliveryTime: 0,
      latitude: lat,
      longitude: lng,
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
    );
  }
}
