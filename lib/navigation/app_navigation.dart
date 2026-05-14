import 'package:flutter/material.dart';
import 'package:med_intel/models/prescription_model.dart';
import 'package:med_intel/screens/medicalprofilescreen.dart';
import 'package:med_intel/screens/notificationsscreen.dart';
import 'package:med_intel/screens/pharmacyscreen.dart';
import 'package:med_intel/screens/profilescreen.dart';
import 'package:med_intel/screens/result_screen.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/screens/medicine_details_screen.dart';
import 'package:med_intel/screens/drug_interaction_checker_screen.dart';
import 'package:med_intel/screens/medicine_search_screen.dart';
import 'package:med_intel/screens/cart_screen.dart';
import 'package:med_intel/screens/checkout_screen.dart';
import 'package:med_intel/screens/order_history_screen.dart';

class AppNavigation {
  static const String upload = '/';
  static const String results = '/results';
  static const String pharmacy = '/pharmacy';
  static const String profile = '/profile';
  static const String medicalProfile = '/medical-profile';
  static const String notifications = '/notifications';
  static const String medicineDetails = '/medicine-details';
  static const String drugInteractionChecker = '/drug-interaction-checker';
  static const String medicineSearch = '/medicine-search';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderHistory = '/order-history';

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
      case medicineDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MedicineDetailsScreen(
            medicineId: args?['medicineId'] ?? '',
            medicineName: args?['medicineName'],
          ),
        );

      case drugInteractionChecker:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DrugInteractionCheckerScreen(
            initialMedicines: args?['medicines'],
            userAllergies: args?['allergies'],
          ),
        );

      case medicineSearch:
        return MaterialPageRoute(builder: (_) => const MedicineSearchScreen());

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}

class ResultsScreenArgs {
  final Prescription prescription;
  final String? imagePath;

  ResultsScreenArgs({required this.prescription, this.imagePath});
}

class PharmacyScreenArgs {
  final List<String> medicineIds;
  PharmacyScreenArgs({required this.medicineIds});
}
