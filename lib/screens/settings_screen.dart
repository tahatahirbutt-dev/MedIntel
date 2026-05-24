import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  String _language = 'English';
  String _timezone = 'GMT+5';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _buildSectionTitle('Preferences'),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _notificationsEnabled,
            activeThumbColor: AppColors.primary,
            title: const Text('Enable notifications'),
            subtitle: const Text('Receive order and medication alerts'),
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _reminderEnabled,
            activeThumbColor: AppColors.secondary,
            title: const Text('Daily reminder'),
            subtitle: const Text('Get a morning medication checklist'),
            onChanged: (value) => setState(() => _reminderEnabled = value),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Regional'),
          const SizedBox(height: 10),
          _buildDropdownTile(
            label: 'Language',
            value: _language,
            options: const ['English', 'اردو', 'Français'],
            onChanged: (value) => setState(() => _language = value),
          ),
          const SizedBox(height: 10),
          _buildDropdownTile(
            label: 'Timezone',
            value: _timezone,
            options: const ['GMT+5', 'GMT+4', 'UTC'],
            onChanged: (value) => setState(() => _timezone = value),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Support'),
          const SizedBox(height: 10),
          _buildOptionTile(Icons.privacy_tip_outlined, 'Privacy policy', 'Manage data sharing preferences'),
          const SizedBox(height: 10),
          _buildOptionTile(Icons.help_outline, 'Help & FAQ', 'Get support and answers'),
          const SizedBox(height: 20),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.headlineSmall);
  }

  Widget _buildDropdownTile({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          DropdownButton<String>(
            value: value,
            borderRadius: BorderRadius.circular(14),
            underline: const SizedBox.shrink(),
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {},
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Med Intel', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: 10),
          Text('Version 1.0.0 • Secure by design', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
