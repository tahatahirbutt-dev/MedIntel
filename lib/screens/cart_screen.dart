import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:med_intel/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItems = cart.items;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(cartItems.length, l10n),
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart(l10n)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (int i = 0; i < cartItems.length; i++)
                        _buildCartItemCard(cartItems[i], i, l10n),
                      const SizedBox(height: 20),
                      _buildSummarySection(cartItems, l10n),
                      const SizedBox(height: 20),
                      _buildTermsCheckbox(l10n),
                      const SizedBox(height: 20),
                      _buildCheckoutButton(l10n),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(AppLocalizations l10n) {
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
              Icons.shopping_cart_outlined,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.cartEmptyTitle,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.cartEmptyBody,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: l10n.cartContinueShopping,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, int index, AppLocalizations l10n) {
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
          // Item Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      l10n.commonDosageLabel(item.dosage),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
                onPressed: () => _removeItem(item),
                splashRadius: 24,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: item.quantity > 1
                          ? () => _updateQuantity(item.id, item.quantity - 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        item.quantity.toString(),
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () =>
                          _updateQuantity(item.id, item.quantity + 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.commonPricePkr((item.price * item.quantity).toStringAsFixed(2)),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.success,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.cartPricePerUnit(item.price.toString()),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(List<CartItem> cartItems, AppLocalizations l10n) {
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    const deliveryFee = 120.0;
    const tax = 50.0;
    final total = subtotal + deliveryFee + tax;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow(l10n.cartSubtotal, l10n.commonPricePkr(subtotal.toStringAsFixed(2))),
          _buildSummaryRow(
            l10n.cartDeliveryFee,
            l10n.commonPricePkr(deliveryFee.toStringAsFixed(2)),
          ),
          _buildSummaryRow(l10n.cartTax, l10n.commonPricePkr(tax.toStringAsFixed(2))),
          const Divider(height: 20),
          _buildSummaryRow(
            l10n.cartTotalAmount,
            l10n.commonPricePkr(total.toStringAsFixed(2)),
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.titleMedium
                : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style: (isBold
                ? AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 16,
                  )
                : AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CheckboxListTile(
        value: _agreeToTerms,
        onChanged: (value) {
          setState(() => _agreeToTerms = value ?? false);
        },
        activeColor: AppColors.primary,
        title: RichText(
          text: TextSpan(
            style: AppTextStyles.bodySmall,
            children: [
              TextSpan(text: l10n.registerAgreeToThe),
              TextSpan(
                text: l10n.registerTermsConditions,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: l10n.registerAnd),
              TextSpan(
                text: l10n.registerPrivacyPolicy,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(AppLocalizations l10n) {
    return AppPrimaryButton(
      label: l10n.cartProceedCheckout,
      onPressed: _agreeToTerms ? _proceedToCheckout : null,
      icon: Icons.shopping_bag_outlined,
    );
  }

  void _updateQuantity(String id, int newQuantity) {
    context.read<CartProvider>().updateQuantity(id, newQuantity);
  }

  void _removeItem(CartItem item) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cartRemoveItemTitle, style: AppTextStyles.headlineSmall),
        content: Text(
          l10n.cartRemoveItemBody(item.name),
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().removeItem(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.cartItemRemoved),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.cartRemoveButton),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cartClearTitle, style: AppTextStyles.headlineSmall),
        content: Text(
          l10n.cartClearBody,
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonClear),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
        );
      }
    });
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
              Icons.shopping_cart_rounded,
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
                  l10n.cartTitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  l10n.savedMedicinesItemCount(itemCount),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (itemCount > 0)
            GestureDetector(
              onTap: _clearCart,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
