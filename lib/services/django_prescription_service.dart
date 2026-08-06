import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:med_intel/models/prescription_model.dart';

/// Thrown when a prescription scan fails — message is safe to show to the user.
class DjangoScanException implements Exception {
  final String message;
  DjangoScanException(this.message);
  @override
  String toString() => message;
}

/// Sends a prescription photo to the Django backend's TrOCR pipeline and
/// returns the extracted medicines. Base URL points at the server machine's
/// LAN IP — set it at run time, it changes per network:
///   flutter run --dart-define=DJANGO_BASE_URL=http://192.168.1.42:8000
class DjangoPrescriptionService {
  static const _baseUrl = String.fromEnvironment('DJANGO_BASE_URL');
  static const _path = '/api/prescription/scan/';

  static Future<Prescription> scanPrescription(File image) async {
    if (_baseUrl.isEmpty) {
      throw DjangoScanException(
        'No server address configured. Run with '
        '--dart-define=DJANGO_BASE_URL=http://<server-lan-ip>:8000.',
      );
    }

    late final http.Response response;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_path'),
      )..files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw DjangoScanException(
        'Could not reach the server — check that it is running and both '
        'devices are on the same network.',
      );
    } on TimeoutException {
      throw DjangoScanException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw DjangoScanException(
        'Connection to the server was interrupted — this usually means an '
        'unstable network. Please try again.',
      );
    }

    if (response.statusCode != 200) {
      debugPrint(
        'DjangoPrescriptionService: HTTP ${response.statusCode} — '
        'body: ${response.body}',
      );
      String detail = 'Please try again.';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = err['error'];
        if (msg is String && msg.isNotEmpty) detail = msg;
      } catch (_) {
        // Response body wasn't JSON — logged above for inspection.
      }
      throw DjangoScanException(
        'Analysis failed (${response.statusCode}): $detail',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final medicinesJson = decoded['medicines'] as List<dynamic>? ?? [];

    if (medicinesJson.isEmpty) {
      throw DjangoScanException(
        'No medicines could be identified in this image.',
      );
    }

    final medicines = medicinesJson.map((entry) {
      final m = entry as Map<String, dynamic>;
      final name = (m['name'] as String?)?.trim() ?? '';
      return Medicine(
        name: name.isNotEmpty ? name : 'Unknown medicine',
        dosage: (m['dosage'] as String?) ?? '',
        frequency: (m['frequency'] as String?) ?? '',
        duration: (m['duration'] as String?) ?? '',
        alternatives: (m['alternatives'] as List<dynamic>? ?? [])
            .map((a) => a.toString())
            .toList(),
      );
    }).toList();

    return Prescription(
      id: 'rx_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: image.path,
      medicines: medicines,
      uploadDate: DateTime.now(),
    );
  }
}
