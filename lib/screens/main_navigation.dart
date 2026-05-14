import 'package:flutter/material.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/screens/pharmacyscreen.dart';
import 'package:med_intel/screens/notificationsscreen.dart';
import 'package:med_intel/screens/profilescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Image captured successfully - you can process it here
        print('Image captured: ${photo.path}');
        // You can pass the image path to UploadScreen or process it further
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error accessing camera: $e')));
    }
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                Navigator.pushNamed(context, AppNavigation.medicineSearch),
            tooltip: 'Search medicines',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppNavigation.cart),
            tooltip: 'View cart',
          ),
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
                style: const TextStyle(color: Colors.white),
              ),
              radius: 16,
            ),
          const SizedBox(width: 16),
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
              onPressed: _openCamera,
              child: Icon(Icons.camera_alt),
              backgroundColor: Colors.blue,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
