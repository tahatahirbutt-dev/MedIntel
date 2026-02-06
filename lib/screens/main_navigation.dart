import 'package:flutter/material.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/screens/pharmacyscreen.dart';
import 'package:med_intel/screens/notificationsscreen.dart';
import 'package:med_intel/screens/profilescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  // List of screens for bottom navigation
  final List<Widget> _screens = [
    UploadScreen(),
    PharmacyScreen(medicineIds: []),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  // Titles for each screen
  final List<String> _screenTitles = [
    'Upload Prescription',
    'Find Pharmacies',
    'Notifications',
    'My Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // User avatar in app bar (optional)
          if (user?.photoURL != null)
            CircleAvatar(
              backgroundImage: NetworkImage(user!.photoURL!),
              radius: 16,
            )
          else if (user?.displayName != null && user!.displayName!.isNotEmpty)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                user!.displayName![0].toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
              radius: 16,
            ),
          SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              activeIcon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy_outlined),
              activeIcon: Icon(Icons.local_pharmacy),
              label: 'Pharmacies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
              // Show badge for unread notifications
              // badge: '3',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // Floating Action Button for quick prescription upload (optional)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to upload screen with camera option
              },
              child: Icon(Icons.camera_alt),
              backgroundColor: Colors.blue,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
