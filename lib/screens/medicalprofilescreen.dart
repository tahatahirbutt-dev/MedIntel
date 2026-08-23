import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/providers/medical_profile_provider.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({Key? key}) : super(key: key);
  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final List<String> _allergies = ['Penicillin', 'Sulfa drugs', 'Ibuprofen'];
  final List<String> _conditions = ['Type 2 Diabetes', 'Hypertension'];
  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  void _add(List<String> list, TextEditingController ctrl) {
    final val = ctrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      list.add(val);
      ctrl.clear();
    });
  }

  void _remove(List<String> list, int i) => setState(() => list.removeAt(i));

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<MedicalProfileProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Branded App Bar ──────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            expandedHeight: 130,
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_outlined, color: Colors.white),
                onPressed: () => _exportProfile(profile),
                tooltip: l10n.medProfileExportTooltip,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF0EA47D)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.medProfileTitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.medProfileSubtitle,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Vitals Row ───────────────────
                _buildVitalsRow(profile, l10n),
                const SizedBox(height: 20),

                // ── Emergency Contact ────────────
                _buildEmergencyCard(profile, l10n),
                const SizedBox(height: 20),

                // ── Allergies ────────────────────
                _buildTagSection(
                  title: l10n.medProfileAllergies,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.danger,
                  iconBg: AppColors.dangerLight,
                  items: _allergies,
                  chipColor: AppColors.danger,
                  chipBg: AppColors.dangerLight,
                  controller: _allergyCtrl,
                  hint: l10n.medProfileAllergyHint,
                  onAdd: () => _add(_allergies, _allergyCtrl),
                  onRemove: (i) => _remove(_allergies, i),
                  l10n: l10n,
                ),
                const SizedBox(height: 16),

                // ── Chronic Conditions ───────────
                _buildTagSection(
                  title: l10n.medProfileChronicConditions,
                  icon: Icons.monitor_heart_outlined,
                  iconColor: AppColors.warning,
                  iconBg: AppColors.warningLight,
                  items: _conditions,
                  chipColor: AppColors.warning,
                  chipBg: AppColors.warningLight,
                  controller: _conditionCtrl,
                  hint: l10n.medProfileConditionHint,
                  onAdd: () => _add(_conditions, _conditionCtrl),
                  onRemove: (i) => _remove(_conditions, i),
                  l10n: l10n,
                ),
                const SizedBox(height: 20),

                // ── Medical History ──────────────
                _buildHistorySection(profile, l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(MedicalProfileProvider profile, AppLocalizations l10n) {
    final vitals = [
      (
        'bloodType',
        l10n.medProfileBloodType,
        profile.bloodType,
        AppColors.danger,
        AppColors.dangerLight,
        Icons.water_drop_outlined,
      ),
      (
        'height',
        l10n.medProfileHeight,
        profile.height,
        AppColors.primary,
        AppColors.primaryLight,
        Icons.height,
      ),
      (
        'weight',
        l10n.medProfileWeight,
        profile.weight,
        AppColors.secondary,
        AppColors.secondaryLight,
        Icons.monitor_weight_outlined,
      ),
    ];
    return Row(
      children: vitals.map((v) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _editVital(v.$1, v.$2, v.$3),
            child: Container(
              margin: EdgeInsets.only(left: vitals.indexOf(v) > 0 ? 8 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: v.$5,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(v.$6, size: 16, color: v.$4),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    v.$3,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: v.$4,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(v.$2, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _editVital(String field, String label, String currentValue) {
    if (field == 'bloodType') {
      _showBloodTypePicker(currentValue);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.medProfileEditVitalTitle(label)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: field == 'height' ? l10n.medProfileHeightHint : l10n.medProfileWeightHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              final profile = context.read<MedicalProfileProvider>();
              if (field == 'height') {
                profile.updateVitals(height: value);
              } else {
                profile.updateVitals(weight: value);
              }
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.medProfileSave),
          ),
        ],
      ),
    );
  }

  void _showBloodTypePicker(String currentValue) {
    const types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: types
              .map(
                (t) => ListTile(
                  title: Text(t),
                  trailing: t == currentValue
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    context.read<MedicalProfileProvider>().updateVitals(
                      bloodType: t,
                    );
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(MedicalProfileProvider profile, AppLocalizations l10n) {
    final initial = profile.emergencyName.isNotEmpty
        ? profile.emergencyName[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emergency_outlined,
                    color: AppColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(l10n.medProfileEmergencyContact, style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _editEmergencyContact(profile),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(l10n.medProfileEdit),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initial,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.emergencyName,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.emergencyPhone,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.success,
                      size: 18,
                    ),
                    onPressed: () => _makePhoneCall(profile.emergencyPhone),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editEmergencyContact(MedicalProfileProvider profile) {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: profile.emergencyName);
    final phoneCtrl = TextEditingController(text: profile.emergencyPhone);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.medProfileEditEmergencyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.medProfileNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.medProfilePhoneLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              context.read<MedicalProfileProvider>().updateEmergencyContact(
                name: name,
                phone: phone,
              );
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.medProfileSave),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, AppLocalizations.of(context)!.medProfileCouldNotCall);
    }
  }

  Widget _buildTagSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<String> items,
    required Color chipColor,
    required Color chipBg,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required AppLocalizations l10n,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.headlineSmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        l10n.medProfileNoneAddedYet,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.asMap().entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: chipColor.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.value,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: chipColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => onRemove(e.key),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: chipColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: AppTextStyles.bodyMedium,
                        onSubmitted: (_) => onAdd(),
                        decoration: InputDecoration(
                          hintText: hint,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.borderLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(MedicalProfileProvider profile, AppLocalizations l10n) {
    final history = profile.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.medProfileMedicalHistory, style: AppTextStyles.headlineSmall),
            const Spacer(),
            IconButton(
              onPressed: () => _showHistoryDialog(),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: AppColors.primary,
              tooltip: l10n.medProfileAddRecordTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _exportHistory(history),
              child: Text(
                l10n.medProfileExportAll,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(l10n.medProfileNoHistoryYet, style: AppTextStyles.bodyMedium),
            ),
          )
        else
          ...history.asMap().entries.map(
            (e) => _buildHistoryCard(e.value, e.key, l10n),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> r, int index, AppLocalizations l10n) {
    final parts = r['date'].split('-');
    final day = parts[2];
    final month = _monthName(parts[1], l10n);
    final year = parts[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Date sidebar
            Container(
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    month,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    year,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r['diagnosis'],
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showHistoryDialog(index: index, existing: r);
                            } else if (action == 'delete') {
                              context
                                  .read<MedicalProfileProvider>()
                                  .removeHistoryEntry(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(l10n.medProfileEdit)),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.medProfileDelete),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(r['doctor'], style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (r['medicines'] as List)
                          .map(
                            (m) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(String m, AppLocalizations l10n) {
    final months = [
      l10n.medProfileMonthJan,
      l10n.medProfileMonthFeb,
      l10n.medProfileMonthMar,
      l10n.medProfileMonthApr,
      l10n.medProfileMonthMay,
      l10n.medProfileMonthJun,
      l10n.medProfileMonthJul,
      l10n.medProfileMonthAug,
      l10n.medProfileMonthSep,
      l10n.medProfileMonthOct,
      l10n.medProfileMonthNov,
      l10n.medProfileMonthDec,
    ];
    return months[int.parse(m) - 1];
  }

  void _showHistoryDialog({int? index, Map<String, dynamic>? existing}) {
    final l10n = AppLocalizations.of(context)!;
    final doctorCtrl = TextEditingController(
      text: existing?['doctor'] as String? ?? '',
    );
    final diagnosisCtrl = TextEditingController(
      text: existing?['diagnosis'] as String? ?? '',
    );
    final medicinesCtrl = TextEditingController(
      text: existing != null
          ? (existing['medicines'] as List).join(', ')
          : '',
    );
    DateTime selectedDate = existing != null
        ? DateTime.tryParse(existing['date'] as String) ?? DateTime.now()
        : DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.medProfileAddRecordTitle : l10n.medProfileEditRecordTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.medProfileDateLabel,
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.medProfileDoctorLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.medProfileDiagnosisLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: medicinesCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.medProfileMedicinesLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final diagnosis = diagnosisCtrl.text.trim();
                if (diagnosis.isEmpty) return;

                final entry = {
                  'date':
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  'doctor': doctorCtrl.text.trim(),
                  'diagnosis': diagnosis,
                  'medicines': medicinesCtrl.text
                      .split(',')
                      .map((m) => m.trim())
                      .where((m) => m.isNotEmpty)
                      .toList(),
                };

                final profile = context.read<MedicalProfileProvider>();
                if (index != null) {
                  profile.updateHistoryEntry(index, entry);
                } else {
                  profile.addHistoryEntry(entry);
                }
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.medProfileSave),
            ),
          ],
        ),
      ),
    );
  }

  void _exportProfile(MedicalProfileProvider profile) {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer()
      ..writeln(l10n.medProfileExportTitle)
      ..writeln()
      ..writeln(l10n.medProfileExportBloodTypeLine(profile.bloodType))
      ..writeln(l10n.medProfileExportHeightLine(profile.height))
      ..writeln(l10n.medProfileExportWeightLine(profile.weight))
      ..writeln()
      ..writeln(l10n.medProfileExportAllergiesLine(_allergies.isEmpty ? l10n.medProfileExportNone : _allergies.join(', ')))
      ..writeln(
        l10n.medProfileExportConditionsLine(_conditions.isEmpty ? l10n.medProfileExportNone : _conditions.join(', ')),
      )
      ..writeln()
      ..writeln(l10n.medProfileExportEmergencyLine(profile.emergencyName, profile.emergencyPhone))
      ..writeln()
      ..writeln(l10n.medProfileExportHistoryHeading);
    for (final r in profile.history) {
      buffer.writeln(
        l10n.medProfileExportHistoryLine(r['date'], r['diagnosis'], r['doctor'], (r['medicines'] as List).join(', ')),
      );
    }
    buffer.writeln('\n${l10n.medDetailShareFooter}');

    Share.share(buffer.toString(), subject: l10n.medProfileShareSubject);
  }

  void _exportHistory(List<Map<String, dynamic>> history) {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer()..writeln(l10n.medProfileExportHistoryTitle)..writeln();
    for (final r in history) {
      buffer.writeln(
        l10n.medProfileExportHistoryLine(r['date'], r['diagnosis'], r['doctor'], (r['medicines'] as List).join(', ')),
      );
    }
    buffer.writeln('\n${l10n.medDetailShareFooter}');

    Share.share(buffer.toString(), subject: l10n.medProfileHistoryShareSubject);
  }
}
