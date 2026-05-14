import 'package:flutter/material.dart';
import 'package:med_intel/models/pharmacy.dart';
import 'package:med_intel/services/mock_data.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

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

  // Mock cart data
  final double _subtotal = 230.0;
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
      _showErrorSnackBar('Error loading pharmacies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stepper
          Expanded(
            child: _buildStepper(),
          ),

          // Order Summary at Bottom
          _buildOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
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
              title: const Text('Delivery Details'),
              content: _buildDeliveryDetailsStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),

            // Step 2: Select Pharmacy
            Step(
              title: const Text('Select Pharmacy'),
              content: _buildPharmacySelectionStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),

            // Step 3: Payment Method
            Step(
              title: const Text('Payment Method'),
              content: _buildPaymentMethodStep(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),

            // Step 4: Confirmation
            Step(
              title: const Text('Confirmation'),
              content: _buildConfirmationStep(),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Delivery Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        RadioListTile(
          title: const Text('Home Delivery'),
          subtitle: Text('PKR ${_deliveryFee.toStringAsFixed(0)} delivery fee'),
          value: 'delivery',
          groupValue: _deliveryType,
          onChanged: (value) {
            setState(() => _deliveryType = value ?? 'delivery');
          },
        ),
        RadioListTile(
          title: const Text('Pickup from Pharmacy'),
          subtitle: const Text('Free pickup'),
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
        const Text(
          'Delivery Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryAddressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your full delivery address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Phone Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneNumberController,
          decoration: InputDecoration(
            hintText: 'Your phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPharmacySelectionStep() {
    if (_isLoadingPharmacies) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Choose a Pharmacy',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._nearbyPharmacies.map((pharmacy) {
          return _buildPharmacyOption(pharmacy);
        }).toList(),
      ],
    );
  }

  Widget _buildPharmacyOption(Pharmacy pharmacy) {
    final isSelected = _selectedPharmacy == pharmacy.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
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
                        Text(
                          pharmacy.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pharmacy.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${pharmacy.rating} (${pharmacy.reviewCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${pharmacy.deliveryTime} mins',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
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

  Widget _buildPaymentMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          'cash',
          'Cash on Delivery',
          'Pay when order arrives',
          Icons.money,
        ),
        _buildPaymentOption(
          'card',
          'Credit/Debit Card',
          'Secure payment',
          Icons.credit_card,
        ),
        _buildPaymentOption(
          'wallet',
          'Digital Wallet',
          'Use your Med Intel wallet',
          Icons.account_balance_wallet,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your payment information is secure and encrypted',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
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

  Widget _buildConfirmationStep() {
    final selectedPharmacy = _nearbyPharmacies
        .firstWhere((p) => p.id == _selectedPharmacy, orElse: () {
      return _nearbyPharmacies.first;
    });

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
                _buildConfirmationRow('Pharmacy', selectedPharmacy.name),
                _buildConfirmationRow(
                  'Delivery Type',
                  _deliveryType == 'delivery' ? 'Home Delivery' : 'Pickup',
                ),
                _buildConfirmationRow(
                  'Address',
                  _deliveryAddressController.text,
                ),
                _buildConfirmationRow(
                  'Phone',
                  _phoneNumberController.text,
                ),
                _buildConfirmationRow(
                  'Payment Method',
                  _getPaymentMethodName(_selectedPaymentMethod),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your order is ready to be placed!',
                  style: TextStyle(color: Colors.green.shade900),
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
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final total = _subtotal + _deliveryFee + _tax;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        color: Colors.grey.shade50,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('PKR ${_subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery'),
              Text('PKR ${_deliveryFee.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax'),
              Text('PKR ${_tax.toStringAsFixed(2)}'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'PKR ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _currentStep == 3 ? _placeOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text(
                _currentStep == 3 ? 'Place Order' : 'Continue',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
    switch (_currentStep) {
      case 0:
        if (_deliveryAddressController.text.isEmpty) {
          _showErrorSnackBar('Please enter delivery address');
          return false;
        }
        if (_phoneNumberController.text.isEmpty) {
          _showErrorSnackBar('Please enter phone number');
          return false;
        }
        return true;
      case 1:
        if (_selectedPharmacy == null) {
          _showErrorSnackBar('Please select a pharmacy');
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 60, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Your order has been placed successfully!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Order ID: ORD-2024-12345',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      default:
        return method;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
