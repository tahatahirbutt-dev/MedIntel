import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med_intel/screens/login_screen.dart';
import 'package:med_intel/screens/main_navigation.dart';
import 'package:med_intel/screens/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // The splash animation reports its own completion via onFinished, so we
  // don't need to guess a fixed duration — navigation only happens once
  // BOTH the animation has genuinely finished AND auth has resolved.
  bool _animationFinished = false;
  bool _authResolved = false;
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
          _authResolved = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authResolved || !_animationFinished) {
      return SplashScreen(
        onFinished: () {
          if (mounted) setState(() => _animationFinished = true);
        },
      );
    }

    if (_user != null) {
      // Always go to MainNavigationScreen — it opens on the Upload tab
      // by default (index 0), so new users land there naturally.
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
