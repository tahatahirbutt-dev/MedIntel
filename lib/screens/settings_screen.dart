import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/providers/locale_provider.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'settings_notifications_enabled';
  static const _reminderKey = 'settings_reminder_enabled';
  static const _languageKey = 'settings_language';
  static const _timezoneKey = 'settings_timezone';

  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  String _language = 'English';
  String _timezone = 'GMT+5';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _reminderEnabled = prefs.getBool(_reminderKey) ?? true;
      _language = prefs.getString(_languageKey) ?? 'English';
      _timezone = prefs.getString(_timezoneKey) ?? 'GMT+5';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    await prefs.setBool(_reminderKey, _reminderEnabled);
    await prefs.setString(_languageKey, _language);
    await prefs.setString(_timezoneKey, _timezone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _buildSectionTitle(l10n.settingsPreferences),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _notificationsEnabled,
            activeThumbColor: AppColors.primary,
            title: Text(l10n.settingsEnableNotifications),
            subtitle: Text(l10n.settingsEnableNotificationsSubtitle),
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _savePrefs();
            },
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _reminderEnabled,
            activeThumbColor: AppColors.secondary,
            title: Text(l10n.settingsDailyReminder),
            subtitle: Text(l10n.settingsDailyReminderSubtitle),
            onChanged: (value) {
              setState(() => _reminderEnabled = value);
              _savePrefs();
            },
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.settingsRegional),
          const SizedBox(height: 10),
          _buildDropdownTile(
            label: l10n.settingsLanguage,
            value: _language,
            options: const ['English', 'اردو'],
            onChanged: (value) {
              setState(() => _language = value);
              _savePrefs();
              context.read<LocaleProvider>().setLanguage(value);
            },
          ),
          const SizedBox(height: 10),
          _buildDropdownTile(
            label: l10n.settingsTimezone,
            value: _timezone,
            options: const ['GMT+5', 'GMT+4', 'UTC'],
            onChanged: (value) {
              setState(() => _timezone = value);
              _savePrefs();
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.settingsSupport),
          const SizedBox(height: 10),
          _buildOptionTile(Icons.privacy_tip_outlined, l10n.settingsPrivacyPolicy, l10n.settingsPrivacyPolicySubtitle),
          const SizedBox(height: 10),
          _buildOptionTile(Icons.help_outline, l10n.settingsHelpFaq, l10n.settingsHelpFaqSubtitle),
          const SizedBox(height: 20),
          _buildInfoCard(l10n),
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
        onTap: () => showAppSnackBar(context, AppLocalizations.of(context)!.commonComingSoon),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
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
          Text(l10n.settingsVersionInfo, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
