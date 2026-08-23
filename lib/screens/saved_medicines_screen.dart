import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/navigation/app_navigation.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/providers/saved_medicines_provider.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/utils/snackbar_utils.dart';

class SavedMedicinesScreen extends StatelessWidget {
  const SavedMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedMedicinesProvider>();
    final items = saved.items;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(items.length, l10n),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState(context, l10n)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildSavedCard(context, items[index], l10n),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int itemCount, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.savedMedicinesTitle,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  l10n.savedMedicinesItemCount(itemCount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.savedMedicinesEmptyTitle, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            l10n.savedMedicinesEmptyBody,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: l10n.savedMedicinesBrowse,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard(BuildContext context, Map<String, dynamic> medicine, AppLocalizations l10n) {
    final id = medicine['id']?.toString() ?? '';
    final price = (medicine['price'] as num?)?.toDouble() ?? 0.0;
    final dosage = medicine['dosage']?.toString() ?? l10n.commonNotAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name']?.toString() ?? l10n.commonUnknown,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.commonDosageLabel(dosage), style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      l10n.commonPricePkr(price.toStringAsFixed(0)),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_remove_outlined),
                color: AppColors.danger,
                onPressed: () =>
                    context.read<SavedMedicinesProvider>().remove(id),
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppNavigation.medicineDetails,
                    arguments: {
                      'medicineId': id,
                      'medicineName': medicine['name'],
                    },
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(l10n.commonDetails),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<CartProvider>().addItem(
                      id: id,
                      name: medicine['name']?.toString() ?? l10n.commonUnknown,
                      price: price,
                      dosage: dosage,
                    );
                    showAppSnackBar(
                      context,
                      l10n.commonAddedToCart(medicine['name']?.toString() ?? l10n.commonUnknown),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(l10n.commonAdd),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
