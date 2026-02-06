import 'package:flutter/material.dart';
import 'package:med_intel/models/prescription_model.dart';
import 'package:med_intel/screens/medicalprofilescreen.dart';
import 'package:med_intel/screens/notificationsscreen.dart';
import 'package:med_intel/screens/pharmacyscreen.dart';
import 'package:med_intel/screens/profilescreen.dart';
import 'package:med_intel/screens/result_screen.dart';
import 'package:med_intel/screens/upload_screen.dart';

class AppNavigation {
  static const String upload = '/';
  static const String results = '/results';
  static const String pharmacy = '/pharmacy';
  static const String profile = '/profile';
  static const String medicalProfile = '/medical-profile';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case upload:
        return MaterialPageRoute(builder: (_) => UploadScreen());
      case results:
        final args = settings.arguments as ResultsScreenArgs;
        return MaterialPageRoute(
          builder: (_) =>
              ResultsScreen(prescription: args.prescription, imagePath: ''),
        );
      case pharmacy:
        final args = settings.arguments as PharmacyScreenArgs;
        return MaterialPageRoute(
          builder: (_) => PharmacyScreen(medicineIds: args.medicineIds),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case medicalProfile:
        return MaterialPageRoute(builder: (_) => MedicalProfileScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}

class ResultsScreenArgs {
  final Prescription prescription;
  ResultsScreenArgs({required this.prescription});
}

class PharmacyScreenArgs {
  final List<String> medicineIds;
  PharmacyScreenArgs({required this.medicineIds});
}
