import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:med_intel/screens/auth_wrapper.dart';
import 'package:med_intel/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MedIntelApp());
}

class MedIntelApp extends StatelessWidget {
  const MedIntelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Intel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // ← all design tokens applied here
      home: const AuthWrapper(),
    );
  }
}
