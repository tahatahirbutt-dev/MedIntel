import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/models/prescription_model.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/screens/drug_interaction_checker_screen.dart';
import 'package:med_intel/services/medicine_catalog_service.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class ResultsScreen extends StatefulWidget {
  final Prescription prescription;
  final String imagePath;

  const ResultsScreen({
    super.key,
    required this.prescription,
    required this.imagePath,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = widget.prescription.medicines;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Branded AppBar ───────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.local_pharmacy_outlined,
                  color: Colors.white,
                ),
                onPressed: _goToPharmacy,
                tooltip: l10n.resultFindPharmaciesTooltip,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.resultTitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.resultMedicinesDetected(medicines.length),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Prescription Image ───────────
                if (widget.imagePath.isNotEmpty) _buildPrescriptionCard(l10n),

                const SizedBox(height: 16),

                // ── Interaction Warning Banner ───
                _buildInteractionBanner(medicines, l10n),

                const SizedBox(height: 16),

                // ── Summary Stats Row ────────────
                _buildSummaryStats(medicines, l10n),

                const SizedBox(height: 20),

                SectionHeader(
                  title: l10n.resultDetectedMedicines,
                  actionLabel: l10n.resultCheckInteractionsAction,
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DrugInteractionCheckerScreen(
                        initialMedicines: medicines.map((m) => m.name).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Medicine Cards ───────────────
                ...medicines.asMap().entries.map(
                  (e) => _buildMedicineCard(medicine: e.value, index: e.key, l10n: l10n),
                ),

                const SizedBox(height: 24),

                // ── Bottom Action Buttons ────────
                _buildBottomActions(l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(AppLocalizations l10n) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.imagePath), fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.document_scanner, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      l10n.resultUploadedPrescription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildInteractionBanner(List<Medicine> medicines, AppLocalizations l10n) {
    final hasPotentialInteraction = medicines.length > 1;
    if (!hasPotentialInteraction) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DrugInteractionCheckerScreen(
            initialMedicines: medicines.map((m) => m.name).toList(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_outlined,
                color: AppColors.warning,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.resultCheckInteractions,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Color(0xFF92400E),
                    ),
                  ),
                  Text(
                    l10n.resultInteractionBannerBody(medicines.length),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(List<Medicine> medicines, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: l10n.resultStatMedicines,
            value: '${medicines.length}',
            icon: Icons.medication_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: l10n.resultStatAlternatives,
            value:
                '${medicines.fold(0, (sum, m) => sum + m.alternatives.length)}',
            icon: Icons.swap_horiz,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            label: l10n.resultStatScanned,
            value: l10n.resultToday,
            icon: Icons.calendar_today_outlined,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(color: color),
          ),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildMedicineCard({required Medicine medicine, required int index, required AppLocalizations l10n}) {
    final isExpanded = _expandedIndex == index;
    final accentColor = medicineColor(medicine.name);
    final bgColor = medicineBgColor(medicine.name);
    final category = medicineCategoryLabel(medicine.name);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Card Header ──────────────────
            InkWell(
              onTap: () =>
                  setState(() => _expandedIndex = isExpanded ? null : index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Category color dot
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medicine.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  medicine.dosage,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded Details ─────────────
            if (isExpanded) ...[
              Container(color: AppColors.borderLight, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Frequency / Duration row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailChip(
                            Icons.repeat_rounded,
                            l10n.resultFrequency,
                            medicine.frequency,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDetailChip(
                            Icons.hourglass_bottom,
                            l10n.resultDuration,
                            medicine.duration,
                          ),
                        ),
                      ],
                    ),

                    if (medicine.alternatives.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        l10n.resultSafeAlternatives,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: medicine.alternatives
                            .map(
                              (alt) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  alt,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDetails(medicine),
                            icon: const Icon(Icons.info_outline, size: 16),
                            label: Text(l10n.commonDetails),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCart(medicine),
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: Text(l10n.commonAddToCart),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDetails(Medicine medicine) async {
    final l10n = AppLocalizations.of(context)!;
    final matches = await MedicineCatalogService.instance.searchMedicines(
      medicine.name,
      limit: 1,
    );
    if (!mounted) return;

    if (matches.isEmpty) {
      showAppSnackBar(
        context,
        l10n.resultNotFoundInCatalogue(medicine.name),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppNavigation.medicineDetails,
      arguments: {
        'medicineId': matches.first['id'].toString(),
        'medicineName': medicine.name,
      },
    );
  }

  Future<void> _addToCart(Medicine medicine) async {
    final l10n = AppLocalizations.of(context)!;
    final matches = await MedicineCatalogService.instance.searchMedicines(
      medicine.name,
      limit: 1,
    );
    if (!mounted) return;

    if (matches.isEmpty) {
      showAppSnackBar(
        context,
        l10n.resultNotFoundInCatalogue(medicine.name),
      );
      return;
    }

    final match = matches.first;
    context.read<CartProvider>().addItem(
      id: match['id'].toString(),
      name: match['name']?.toString() ?? medicine.name,
      price: (match['price'] as num?)?.toDouble() ?? 0.0,
      dosage: match['dosage']?.toString() ?? medicine.dosage,
    );
    showAppSnackBar(
      context,
      l10n.commonAddedToCart(medicine.name),
      actionLabel: l10n.commonViewCart,
      onAction: () => Navigator.pushNamed(context, AppNavigation.cart),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: Text(l10n.resultUploadAnother),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppPrimaryButton(
            label: l10n.resultPharmaciesButton,
            icon: Icons.local_pharmacy_outlined,
            onPressed: _goToPharmacy,
          ),
        ),
      ],
    );
  }

  void _goToPharmacy() {
    Navigator.pushNamed(
      context,
      '/pharmacy',
      arguments: widget.prescription.medicines.map((m) => m.name).toList(),
    );
  }
}
