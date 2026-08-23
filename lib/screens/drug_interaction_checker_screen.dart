import 'package:flutter/material.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class DrugInteractionCheckerScreen extends StatefulWidget {
  final List<String>? initialMedicines;
  final List<String>? userAllergies;

  const DrugInteractionCheckerScreen({
    Key? key,
    this.initialMedicines,
    this.userAllergies,
  }) : super(key: key);

  @override
  _DrugInteractionCheckerScreenState createState() =>
      _DrugInteractionCheckerScreenState();
}

class _DrugInteractionCheckerScreenState
    extends State<DrugInteractionCheckerScreen> {
  final TextEditingController _medicineController = TextEditingController();
  final List<String> _selectedMedicines = [];
  final List<String> _userAllergies = [];
  bool _isChecking = false;
  List<Map<String, dynamic>>? _interactions;
  List<Map<String, dynamic>>? _allergyConflicts;

  @override
  void initState() {
    super.initState();
    if (widget.initialMedicines != null) {
      _selectedMedicines.addAll(widget.initialMedicines!);
    }
    if (widget.userAllergies != null) {
      _userAllergies.addAll(widget.userAllergies!);
    }
  }

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _checkInteractions() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedMedicines.isEmpty) {
      _showErrorSnackBar(l10n.dicAddAtLeastOne);
      return;
    }

    setState(() => _isChecking = true);

    try {
      final interactions = await MockDataService.checkDrugInteractions(
        _selectedMedicines,
      );

      final List<Map<String, dynamic>> allergyConflicts =
          _userAllergies.isNotEmpty
          ? await MockDataService.checkAllergyConflicts(
              _userAllergies,
              _selectedMedicines,
            )
          : <Map<String, dynamic>>[];

      setState(() {
        _interactions = interactions;
        _allergyConflicts = allergyConflicts;
      });

      _showResultDialog();
    } catch (e) {
      _showErrorSnackBar(l10n.dicErrorChecking(e.toString()));
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _addMedicine() {
    final l10n = AppLocalizations.of(context)!;
    final medicine = _medicineController.text.trim();

    if (medicine.isEmpty) {
      _showErrorSnackBar(l10n.dicEnterMedicineName);
      return;
    }

    if (_selectedMedicines.contains(medicine)) {
      _showErrorSnackBar(l10n.dicAlreadyAdded);
      return;
    }

    setState(() {
      _selectedMedicines.add(medicine);
      _medicineController.clear();
      _interactions = null;
      _allergyConflicts = null;
    });
  }

  void _removeMedicine(String medicine) {
    setState(() {
      _selectedMedicines.remove(medicine);
      _interactions = null;
      _allergyConflicts = null;
    });
  }

  void _showResultDialog() {
    final l10n = AppLocalizations.of(context)!;
    final hasInteractions = _interactions?.isNotEmpty ?? false;
    final hasAllergyConflicts = _allergyConflicts?.isNotEmpty ?? false;
    final isSafe = !hasInteractions && !hasAllergyConflicts;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSafe ? Icons.check_circle : Icons.warning,
              color: isSafe ? AppColors.success : AppColors.danger,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(isSafe ? l10n.dicSafeToUse : l10n.dicCautionRequired),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSafe) ...[
                Text(
                  l10n.dicNoInteractions,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ] else ...[
                if (hasInteractions) ...[
                  Text(
                    l10n.dicInteractionsFoundHeading,
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._interactions!.map((interaction) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildInteractionItem(interaction),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                if (hasAllergyConflicts) ...[
                  Text(
                    l10n.dicAllergyWarningsHeading,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._allergyConflicts!.map((conflict) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildAllergyConflictItem(conflict, l10n),
                    );
                  }),
                ],
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Text(
                  l10n.dicDisclaimer,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
          if (!isSafe)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showAppSnackBar(this.context, l10n.commonComingSoon);
              },
              child: Text(l10n.dicConsultPharmacist),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionItem(Map<String, dynamic> interaction) {
    final severityColor = _getSeverityColor(interaction['severity'] ?? 'Minor');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${interaction['drug1']} + ${interaction['drug2']}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  interaction['severity'] ?? 'Minor',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            interaction['description'] ?? '',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyConflictItem(Map<String, dynamic> conflict, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: const Border(left: BorderSide(color: AppColors.danger, width: 4)),
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${conflict['allergen']} Allergy',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.dicAlertBadge,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dicConflictingMedicine(conflict['medicine'].toString()),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (conflict['alternatives'] != null &&
              (conflict['alternatives'] as List).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.dicSafeAlternativesList((conflict['alternatives'] as List).join(", ")),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppColors.danger;
      case 'moderate':
        return AppColors.warning;
      case 'minor':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dicTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.dicInfoBanner,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input Section
            Text(l10n.dicAddMedicines, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _medicineController,
                    decoration: InputDecoration(
                      hintText: l10n.dicEnterMedicineHint,
                      prefixIcon: const Icon(Icons.medication),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.borderLight,
                    ),
                    onSubmitted: (_) => _addMedicine(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _addMedicine,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected Medicines
            if (_selectedMedicines.isNotEmpty) ...[
              Text(
                l10n.dicSelectedMedicinesCount(_selectedMedicines.length),
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMedicines.map((medicine) {
                  return Chip(
                    label: Text(medicine),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeMedicine(medicine),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // User Allergies Section
            Text(l10n.dicYourAllergies, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            if (_userAllergies.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.dicAddAllergiesHint,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userAllergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: AppColors.dangerLight,
                    side: BorderSide(color: AppColors.danger.withOpacity(0.3)),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Check Button
            AppPrimaryButton(
              label: _isChecking ? l10n.dicChecking : l10n.dicCheckInteractions,
              icon: Icons.security_outlined,
              isLoading: _isChecking,
              color: AppColors.success,
              onPressed: _isChecking ? null : _checkInteractions,
            ),

            const SizedBox(height: 20),

            // Results Section
            if (_interactions != null || _allergyConflicts != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildResultsSummary(l10n),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary(AppLocalizations l10n) {
    final hasInteractions = _interactions?.isNotEmpty ?? false;
    final hasAllergyConflicts = _allergyConflicts?.isNotEmpty ?? false;
    final isSafe = !hasInteractions && !hasAllergyConflicts;

    return Card(
      color: isSafe ? AppColors.successLight : AppColors.dangerLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSafe ? Icons.check_circle : Icons.warning_amber,
                  color: isSafe ? AppColors.success : AppColors.danger,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isSafe ? l10n.dicSafeCombination : l10n.dicInteractionsDetected,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: isSafe ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasInteractions)
              Text(
                l10n.dicInteractionsFoundCount(_interactions!.length),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
              ),
            if (hasAllergyConflicts)
              Text(
                l10n.dicAllergyConflictsFoundCount(_allergyConflicts!.length),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
              ),
            if (isSafe)
              Text(
                l10n.dicNoInteractions,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
              ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dicAboutTitle),
        content: Text(l10n.dicAboutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.dicUnderstood),
          ),
        ],
      ),
    );
  }
}
