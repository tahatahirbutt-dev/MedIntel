import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyPharmacySearchButton extends StatefulWidget {
  /// Your Google Maps API key. This must be restricted in the Google Cloud Console.
  final String googleMapsApiKey;

  /// Called when search results are successfully fetched.
  final void Function(List<NearbyPharmacyPlace> places)? onResults;

  /// Called when an error occurs during permission or network operations.
  final void Function(String message)? onError;

  /// Button text displayed to the user.
  final String buttonLabel;

  /// Maximum number of results returned by the Places API.
  final int maxResults;

  /// Search radius in meters. Defaults to 5000 (5 km).
  final double radiusMeters;

  /// Whether to show a bottom sheet with the results automatically.
  final bool showResultSheet;

  const NearbyPharmacySearchButton({
    super.key,
    required this.googleMapsApiKey,
    this.onResults,
    this.onError,
    this.buttonLabel = 'Scan nearby pharmacies',
    this.maxResults = 20,
    this.radiusMeters = 5000.0,
    this.showResultSheet = true,
  });

  @override
  State<NearbyPharmacySearchButton> createState() => _NearbyPharmacySearchButtonState();
}

class _NearbyPharmacySearchButtonState extends State<NearbyPharmacySearchButton> {
  bool _isLoading = false;
  List<NearbyPharmacyPlace> _places = [];

  Future<void> _handleTap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _getCurrentLocation();
      final places = await _fetchNearbyPharmacies(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });

      widget.onResults?.call(places);
      if (widget.showResultSheet) {
        _showPlacesSheet(places);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final message = error is String ? error : error.toString();
      widget.onError?.call(message);
      if (widget.onError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS to search nearby pharmacies.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied. Please allow location access.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Open settings and allow location access.';
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<NearbyPharmacyPlace>> _fetchNearbyPharmacies(
      double latitude, double longitude) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/nearbySearch');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': widget.googleMapsApiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location',
      },
      body: jsonEncode({
        'includedTypes': ['pharmacy'],
        'maxResultCount': widget.maxResults,
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': widget.radiusMeters,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw 'Google Places API request failed: ${response.statusCode} ${response.reasonPhrase}';
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPlaces = (body['places'] as List<dynamic>?) ?? [];
    return rawPlaces
        .map((item) => NearbyPharmacyPlace.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _showPlacesSheet(List<NearbyPharmacyPlace> places) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (places.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('No pharmacies found within 5 km.')),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.local_pharmacy, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Nearby pharmacies',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return ListTile(
                      leading: const Icon(Icons.local_pharmacy_outlined,
                          color: Colors.teal),
                      title: Text(place.name),
                      subtitle: Text(place.address),
                      onTap: () => Navigator.pop(context),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleTap,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search),
        label: Text(_isLoading ? 'Searching...' : widget.buttonLabel),
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );
  }
}

class NearbyPharmacyPlace {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  NearbyPharmacyPlace({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory NearbyPharmacyPlace.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'];
    String name;
    if (displayName is String) {
      name = displayName;
    } else if (displayName is Map<String, dynamic>) {
      name = displayName['text'] as String? ?? 'Unknown Pharmacy';
    } else {
      name = 'Unknown Pharmacy';
    }

    final address = json['formattedAddress'] as String? ?? 'No address available';

    final location = json['location'] as Map<String, dynamic>?;
    final latitude = location != null ? (location['latitude'] as num?)?.toDouble() : null;
    final longitude = location != null ? (location['longitude'] as num?)?.toDouble() : null;

    return NearbyPharmacyPlace(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
