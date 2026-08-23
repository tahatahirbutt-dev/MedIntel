import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/screens/home_screen.dart';
import 'package:med_intel/screens/medicine_search_screen.dart';
import 'package:med_intel/screens/notificationsscreen.dart';
import 'package:med_intel/screens/profilescreen.dart';
import 'package:med_intel/screens/upload_screen.dart';
import 'package:med_intel/theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const MedicineSearchScreen(embeddedInNav: true),
    const UploadScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_outlined, Icons.home),
    _NavItem(Icons.medication_outlined, Icons.medication),
    _NavItem(Icons.document_scanner_outlined, Icons.document_scanner),
    _NavItem(Icons.notifications_outlined, Icons.notifications),
    _NavItem(Icons.person_outline, Icons.person),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  List<String> _navLabels(AppLocalizations l10n) => [
        l10n.navHome,
        l10n.navSearch,
        l10n.navScan,
        l10n.navAlerts,
        l10n.navProfile,
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomBar(AppLocalizations.of(context)!),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    final labels = _navLabels(l10n);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((e) {
              return _buildNavItem(
                item: e.value,
                label: labels[e.key],
                index: e.key,
                isSelected: _selectedIndex == e.key,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.icon, this.activeIcon);
}
