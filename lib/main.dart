import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/providers/medical_profile_provider.dart';
import 'package:med_intel/providers/saved_medicines_provider.dart';
import 'package:med_intel/screens/auth_wrapper.dart';
import 'package:med_intel/services/fcm_service.dart';
import 'package:med_intel/services/medicine_catalog_service.dart';
import 'package:med_intel/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MedicineCatalogService.instance.warmUp();
  await FCMService().initialize();

  final cartProvider = CartProvider();
  await cartProvider.loadFromPrefs();
  final savedMedicinesProvider = SavedMedicinesProvider();
  await savedMedicinesProvider.loadFromPrefs();
  final medicalProfileProvider = MedicalProfileProvider();
  await medicalProfileProvider.loadFromPrefs();

  runApp(
    MedIntelApp(
      cartProvider: cartProvider,
      savedMedicinesProvider: savedMedicinesProvider,
      medicalProfileProvider: medicalProfileProvider,
    ),
  );
}

class MedIntelApp extends StatelessWidget {
  final CartProvider cartProvider;
  final SavedMedicinesProvider savedMedicinesProvider;
  final MedicalProfileProvider medicalProfileProvider;

  const MedIntelApp({
    super.key,
    required this.cartProvider,
    required this.savedMedicinesProvider,
    required this.medicalProfileProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: savedMedicinesProvider),
        ChangeNotifierProvider.value(value: medicalProfileProvider),
      ],
      child: MaterialApp(
        title: 'Med Intel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthWrapper(),
        onGenerateRoute: AppNavigation.generateRoute,
      ),
    );
  }
}
