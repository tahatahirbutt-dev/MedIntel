import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:med_intel/l10n/app_localizations.dart';
import 'package:med_intel/models/pharmacy.dart';
import 'package:med_intel/providers/cart_provider.dart';
import 'package:med_intel/providers/orders_provider.dart';
import 'package:med_intel/services/mock_data.dart';
import 'package:med_intel/theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  String? _selectedPharmacy;
  String _deliveryType = 'delivery'; // 'pickup' or 'delivery'
  String _selectedPaymentMethod = 'cash';
  final TextEditingController _deliveryAddressController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  List<Pharmacy> _nearbyPharmacies = [];
  bool _isLoadingPharmacies = true;

  final double _tax = 20.0;
  double _deliveryFee = 120.0;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _deliveryAddressController.text = 'F-7 Markaz, Islamabad';
    _phoneNumberController.text = '+92 321 1234567';
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    try {
      final pharmacies = await MockDataService.getNearbyPharmacies();
      setState(() {
        _nearbyPharmacies = pharmacies;
        _isLoadingPharmacies = false;
        if (pharmacies.isNotEmpty) {
          _selectedPharmacy = pharmacies.first.id;
          _deliveryFee = pharmacies.first.deliveryFee;
        }
      });
    } catch (e) {
      setState(() => _isLoadingPharmacies = false);
      _showErrorSnackBar(AppLocalizations.of(context)!.checkoutErrorLoadingPharmacies(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: cart.isEmpty
          ? Center(
              child: Text(
                l10n.cartEmptyTitle,
                style: AppTextStyles.bodyMedium,
              ),
            )
          : Column(
              children: [
                // Stepper
                Expanded(
                  child: _buildStepper(l10n),
                ),

                // Order Summary at Bottom
                _buildOrderSummary(cart.subtotal, l10n),
              ],
            ),
    );
  }

  Widget _buildStepper(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (index) {
            if (index < _currentStep) {
              setState(() => _currentStep = index);
            }
          },
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          steps: [
            // Step 1: Delivery Details
            Step(
              title: Text(l10n.checkoutStepDelivery),
              content: _buildDeliveryDetailsStep(l10n),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),

            // Step 2: Select Pharmacy
            Step(
              title: Text(l10n.checkoutStepPharmacy),
              content: _buildPharmacySelectionStep(l10n),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),

            // Step 3: Payment Method
            Step(
              title: Text(l10n.checkoutStepPayment),
              content: _buildPaymentMethodStep(l10n),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),

            // Step 4: Confirmation
            Step(
              title: Text(l10n.checkoutStepConfirmation),
              content: _buildConfirmationStep(l10n),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.checkoutDeliveryType,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        RadioListTile(
          title: Text(l10n.checkoutHomeDelivery),
          subtitle: Text(l10n.checkoutDeliveryFeeLabel(_deliveryFee.toStringAsFixed(0))),
          value: 'delivery',
          groupValue: _deliveryType,
          onChanged: (value) {
            setState(() => _deliveryType = value ?? 'delivery');
          },
        ),
        RadioListTile(
          title: Text(l10n.checkoutPickupFromPharmacy),
          subtitle: Text(l10n.checkoutFreePickup),
          value: 'pickup',
          groupValue: _deliveryType,
          onChanged: (value) {
            setState(() {
              _deliveryType = value ?? 'delivery';
              if (_deliveryType == 'pickup') {
                _deliveryFee = 0;
              } else {
                final pharmacy = _nearbyPharmacies
                    .firstWhere((p) => p.id == _selectedPharmacy);
                _deliveryFee = pharmacy.deliveryFee;
              }
            });
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.checkoutDeliveryAddress,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryAddressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.checkoutAddressHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.borderLight,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.profilePhoneNumber,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneNumberController,
          decoration: InputDecoration(
            hintText: l10n.checkoutPhoneHint,
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: AppColors.borderLight,
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPharmacySelectionStep(AppLocalizations l10n) {
    if (_isLoadingPharmacies) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.checkoutChoosePharmacy,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        ..._nearbyPharmacies.map((pharmacy) {
          return _buildPharmacyOption(pharmacy, l10n);
        }),
      ],
    );
  }

  Widget _buildPharmacyOption(Pharmacy pharmacy, AppLocalizations l10n) {
    final isSelected = _selectedPharmacy == pharmacy.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected ? AppColors.primaryLight : AppColors.surface,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPharmacy = pharmacy.id;
            if (_deliveryType == 'delivery') {
              _deliveryFee = pharmacy.deliveryFee;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacy.name, style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 4),
                        Text(pharmacy.address, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Radio(
                    value: pharmacy.id,
                    groupValue: _selectedPharmacy,
                    onChanged: (value) {
                      setState(() => _selectedPharmacy = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${pharmacy.rating} (${pharmacy.reviewCount})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    l10n.checkoutDeliveryTimeMins(pharmacy.deliveryTime),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.checkoutStepPayment,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'cash',
          l10n.checkoutPayCash,
          l10n.checkoutPayCashDesc,
          Icons.money,
        ),
        _buildPaymentOption(
          'card',
          l10n.checkoutPayCard,
          l10n.checkoutPayCardDesc,
          Icons.credit_card,
        ),
        _buildPaymentOption(
          'wallet',
          l10n.checkoutPayWallet,
          l10n.checkoutPayWalletDesc,
          Icons.account_balance_wallet,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.checkoutPaymentSecureNote,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return RadioListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (newValue) {
        setState(() => _selectedPaymentMethod = newValue ?? 'cash');
      },
    );
  }

  Widget _buildConfirmationStep(AppLocalizations l10n) {
    if (_nearbyPharmacies.isEmpty) {
      return Center(child: Text(l10n.checkoutNoPharmaciesAvailable));
    }

    final selectedPharmacy = _nearbyPharmacies.firstWhere(
      (p) => p.id == _selectedPharmacy,
      orElse: () => _nearbyPharmacies.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationRow(l10n.checkoutConfirmPharmacy, selectedPharmacy.name),
                _buildConfirmationRow(
                  l10n.checkoutDeliveryType,
                  _deliveryType == 'delivery' ? l10n.checkoutHomeDelivery : l10n.checkoutPickup,
                ),
                _buildConfirmationRow(
                  l10n.checkoutConfirmAddress,
                  _deliveryAddressController.text,
                ),
                _buildConfirmationRow(
                  l10n.checkoutConfirmPhone,
                  _phoneNumberController.text,
                ),
                _buildConfirmationRow(
                  l10n.checkoutStepPayment,
                  _getPaymentMethodName(_selectedPaymentMethod, l10n),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.checkoutReadyToPlace,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal, AppLocalizations l10n) {
    final total = subtotal + _deliveryFee + _tax;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.borderLight,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.cartSubtotal, style: AppTextStyles.bodyMedium),
              Text(
                l10n.commonPricePkr(subtotal.toStringAsFixed(2)),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.checkoutDeliveryLabel, style: AppTextStyles.bodyMedium),
              Text(
                l10n.commonPricePkr(_deliveryFee.toStringAsFixed(2)),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.cartTax, style: AppTextStyles.bodyMedium),
              Text(
                l10n.commonPricePkr(_tax.toStringAsFixed(2)),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.checkoutTotal, style: AppTextStyles.headlineMedium),
              Text(
                l10n.commonPricePkr(total.toStringAsFixed(2)),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: _currentStep == 3 ? l10n.checkoutPlaceOrder : l10n.checkoutContinue,
            onPressed: _currentStep == 3 ? _placeOrder : null,
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      // Validate current step
      if (_validateCurrentStep()) {
        setState(() => _currentStep += 1);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        if (_deliveryAddressController.text.isEmpty) {
          _showErrorSnackBar(l10n.checkoutEnterAddressError);
          return false;
        }
        if (_phoneNumberController.text.isEmpty) {
          _showErrorSnackBar(l10n.checkoutEnterPhoneError);
          return false;
        }
        return true;
      case 1:
        if (_selectedPharmacy == null) {
          _showErrorSnackBar(l10n.checkoutSelectPharmacyError);
          return false;
        }
        return true;
      case 2:
        return true;
      default:
        return true;
    }
  }

  void _placeOrder() {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch}';
    final cart = context.read<CartProvider>();
    final pharmacy = _nearbyPharmacies.firstWhere(
      (p) => p.id == _selectedPharmacy,
      orElse: () => _nearbyPharmacies.first,
    );

    context.read<OrdersProvider>().addOrder({
      'id': orderId,
      'date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'medicines': cart.items.map((i) => '${i.name} ${i.dosage}').toList(),
      'items': cart.items
          .map(
            (i) => {
              'id': i.id,
              'name': i.name,
              'dosage': i.dosage,
              'price': i.price,
              'quantity': i.quantity,
            },
          )
          .toList(),
      'total': cart.subtotal + _deliveryFee + _tax,
      'pharmacy': pharmacy.name,
      'status': 'pending',
      'deliveryDate': null,
      'rating': null,
      'trackingId': 'TRACK-$orderId',
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.checkoutOrderPlacedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 60, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              l10n.checkoutOrderPlacedBody,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.checkoutOrderIdLabel(orderId),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(l10n.checkoutDone),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method, AppLocalizations l10n) {
    switch (method) {
      case 'cash':
        return l10n.checkoutPayCash;
      case 'card':
        return l10n.checkoutPayCard;
      case 'wallet':
        return l10n.checkoutPayWallet;
      default:
        return method;
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
}
