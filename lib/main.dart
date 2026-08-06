import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/providers/medical_profile_provider.dart';
import 'package:med_intel/providers/orders_provider.dart';
import 'package:med_intel/providers/saved_medicines_provider.dart';
import 'package:med_intel/screens/auth_wrapper.dart';
import 'package:med_intel/services/fcm_service.dart';
import 'package:med_intel/services/medicine_catalog_service.dart';
import 'package:med_intel/services/schedule_service.dart';
import 'package:med_intel/theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error\n$stack');
        return true;
      };

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await MedicineCatalogService.instance.warmUp();
      await ScheduleService.instance.loadFromPrefs();
      await FCMService().initialize();

      final cartProvider = CartProvider();
      await cartProvider.loadFromPrefs();
      final savedMedicinesProvider = SavedMedicinesProvider();
      await savedMedicinesProvider.loadFromPrefs();
      final medicalProfileProvider = MedicalProfileProvider();
      await medicalProfileProvider.loadFromPrefs();
      final ordersProvider = OrdersProvider();
      await ordersProvider.loadFromPrefs();

      runApp(
        MedIntelApp(
          cartProvider: cartProvider,
          savedMedicinesProvider: savedMedicinesProvider,
          medicalProfileProvider: medicalProfileProvider,
          ordersProvider: ordersProvider,
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

class MedIntelApp extends StatelessWidget {
  final CartProvider cartProvider;
  final SavedMedicinesProvider savedMedicinesProvider;
  final MedicalProfileProvider medicalProfileProvider;
  final OrdersProvider ordersProvider;

  const MedIntelApp({
    super.key,
    required this.cartProvider,
    required this.savedMedicinesProvider,
    required this.medicalProfileProvider,
    required this.ordersProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: savedMedicinesProvider),
        ChangeNotifierProvider.value(value: medicalProfileProvider),
        ChangeNotifierProvider.value(value: ordersProvider),
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
