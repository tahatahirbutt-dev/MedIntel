import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/providers/saved_medicines_provider.dart';
import 'package:med_intel/services/medicine_catalog_service.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final String medicineId;
  final String? medicineName;

  const MedicineDetailsScreen({
    Key? key,
    required this.medicineId,
    this.medicineName,
  }) : super(key: key);

  @override
  _MedicineDetailsScreenState createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  late Future<Map<String, dynamic>?> _medicineFuture;
  Map<String, dynamic>? _medicine;
  bool _sideEffectsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMedicine();
  }

  @override
  void didUpdateWidget(MedicineDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicineId != widget.medicineId) {
      _loadMedicine();
    }
  }

  void _loadMedicine() {
    _medicineFuture =
        MedicineCatalogService.instance.getMedicineDetails(widget.medicineId)
          ..then((data) {
            if (mounted) setState(() => _medicine = data);
          });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'View cart',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppNavigation.cart),
                ),
                if (cart.totalQuantity > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.totalQuantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _medicine == null
                ? null
                : () => _shareMedicineInfo(_medicine!),
          ),
          Consumer<SavedMedicinesProvider>(
            builder: (context, saved, _) {
              final id = _medicine?['id']?.toString();
              final isSaved = id != null && saved.isSaved(id);
              return IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                color: isSaved ? AppColors.primary : null,
                onPressed: _medicine == null
                    ? null
                    : () => _saveMedicine(_medicine!),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _medicineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(_loadMedicine),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text('Medicine not found', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          final medicine = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card with Medicine Name and Basic Info
                _buildHeaderCard(medicine),

                // Price and Availability
                _buildPriceAvailabilityCard(medicine),

                // Description
                _buildDescriptionCard(medicine),

                // Dosage & Frequency Information
                _buildDosageCard(medicine),

                // Side Effects
                _buildSideEffectsCard(medicine),

                // Serious Side Effects Warning
                if (medicine['seriousSideEffects'] != null &&
                    (medicine['seriousSideEffects'] as List).isNotEmpty)
                  _buildSeriousWarningCard(medicine),

                // Warnings and Precautions
                if (medicine['warnings'] != null &&
                    (medicine['warnings'] as List).isNotEmpty)
                  _buildWarningsCard(medicine),

                // Alternatives
                if (medicine['alternatives'] != null &&
                    (medicine['alternatives'] as List).isNotEmpty)
                  _buildAlternativesCard(medicine),

                // Chemical Information
                _buildChemicalInfoCard(medicine),

                // Action Buttons
                _buildActionButtons(medicine),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> medicine) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              medicine['category'] ?? 'Medication',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Medicine Name
          Text(
            medicine['name'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Dosage
          Text(
            'Dosage: ${medicine['dosage'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAvailabilityCard(Map<String, dynamic> medicine) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${medicine['price']?.toString() ?? 'N/A'}',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Availability', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Text(
                        'In Stock',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(Map<String, dynamic> medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Text(
                medicine['description'] ?? 'No description available',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageCard(Map<String, dynamic> medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usage Information', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              _buildDosageRow('Dosage:', medicine['dosage'] ?? 'N/A'),
              _buildDosageRow('Frequency:', medicine['frequency'] ?? 'N/A'),
              _buildDosageRow('Duration:', medicine['duration'] ?? 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildSideEffectsCard(Map<String, dynamic> medicine) {
    final sideEffects = medicine['sideEffects'] as List? ?? [];

    if (sideEffects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(
                  () => _sideEffectsExpanded = !_sideEffectsExpanded,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Common Side Effects',
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _sideEffectsExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _sideEffectsExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sideEffects.map((effect) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    effect.toString(),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sideEffects.map((effect) {
                          return Chip(
                            label: Text(
                              effect.toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: AppColors.warningLight,
                            side: BorderSide(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriousWarningCard(Map<String, dynamic> medicine) {
    final seriousEffects = medicine['seriousSideEffects'] as List? ?? [];

    if (seriousEffects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: AppColors.dangerLight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text(
                    'Serious Side Effects',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Seek immediate medical attention if you experience:',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 8),
              ...seriousEffects.map((effect) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          effect.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningsCard(Map<String, dynamic> medicine) {
    final warnings = medicine['warnings'] as List? ?? [];

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text('Warnings & Precautions', style: AppTextStyles.headlineMedium),
                ],
              ),
              const SizedBox(height: 12),
              ...warnings.map((warning) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesCard(Map<String, dynamic> medicine) {
    final alternatives = medicine['alternatives'] as List? ?? [];

    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alternative Medicines', style: AppTextStyles.headlineMedium),
                  const Icon(Icons.swap_vert, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              ...alternatives.map((alt) {
                final id = alt is Map ? alt['id']?.toString() : null;
                final name =
                    alt is Map ? (alt['name']?.toString() ?? '') : alt.toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: id == null || id.isEmpty
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              AppNavigation.medicineDetails,
                              arguments: {
                                'medicineId': id,
                                'medicineName': name,
                              },
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.primaryLight,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChemicalInfoCard(Map<String, dynamic> medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chemical Information', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chemical Formula', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          medicine['chemicalFormula'] ?? 'N/A',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ This is for informational purposes only. Always consult with a healthcare professional before taking any medicine.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> medicine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          AppPrimaryButton(
            label: 'Add to Cart',
            icon: Icons.add_shopping_cart,
            onPressed: () => _addToCart(medicine),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> medicine) {
    context.read<CartProvider>().addItem(
      id: medicine['id']?.toString() ?? widget.medicineId,
      name: medicine['name']?.toString() ?? 'Unknown',
      price: (medicine['price'] as num?)?.toDouble() ?? 0.0,
      dosage: medicine['dosage']?.toString() ?? 'N/A',
    );
    showAppSnackBar(
      context,
      '${medicine['name']} added to cart',
      actionLabel: 'View Cart',
      onAction: () => Navigator.pushNamed(context, AppNavigation.cart),
    );
  }

  void _saveMedicine(Map<String, dynamic> medicine) {
    final saved = context.read<SavedMedicinesProvider>();
    final id = medicine['id']?.toString() ?? widget.medicineId;
    final wasSaved = saved.isSaved(id);
    saved.toggle(medicine);
    showAppSnackBar(
      context,
      wasSaved ? 'Removed from saved medicines' : 'Medicine saved',
      actionLabel: 'View Saved',
      onAction: () =>
          Navigator.pushNamed(context, AppNavigation.savedMedicines),
    );
  }

  void _shareMedicineInfo(Map<String, dynamic> medicine) {
    final name = medicine['name']?.toString() ?? 'Medicine';
    final dosage = medicine['dosage']?.toString() ?? 'N/A';
    final price = medicine['price'];
    final description = medicine['description']?.toString() ?? '';

    final buffer = StringBuffer()
      ..writeln(name)
      ..writeln('Dosage: $dosage')
      ..writeln('Price: PKR ${price ?? 'N/A'}');
    if (description.isNotEmpty) {
      buffer.writeln('\n$description');
    }
    buffer.writeln('\nShared via MedIntel');

    Share.share(buffer.toString(), subject: name);
  }
}
