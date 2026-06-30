import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyScreen extends StatefulWidget {
  final List<String> medicineIds;
  const PharmacyScreen({super.key, required this.medicineIds});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  // Reference pharmacy (what users should see as template)
  late final Map<String, dynamic> _referencePharmacy = {
    'id': '0',
    'name': 'Care Pharmacy',
    'address': 'F-7 Markaz, Islamabad',
    'phone': '+92 51 2827070',
    'hours': '9:00 AM - 10:00 PM',
    'rating': 4.5,
    'reviewCount': 128,
    'deliveryFee': 120.0,
    'deliveryTime': 25,
    'isOpen': true,
  };

  // Registered pharmacies (user-created)
  final List<Map<String, dynamic>> _registeredPharmacies = [];

  // Medicine availability (sample - will be integrated with backend)
  late Map<String, bool> _medicineAvailability;

  bool _isLoading = true;
  late final AnimationController _anim;

  // Adjustable header layout values — tweak these to move the logo/text.
  final EdgeInsets _headerPadding = const EdgeInsets.fromLTRB(5, 30, 20, 20);
  final double _headerIconOffset = 15.0;
  final double _headerTextOffset = -5.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeMedicineAvailability();
    _loadData();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // Initialize medicine availability with sample medicines
  void _initializeMedicineAvailability() {
    // Show only first 5-10 medicines from cart instead of all 18,000
    _medicineAvailability = {
      'amoxicillin': true,
      'ibuprofen': true,
      'metformin': false,
      'paracetamol': true,
      'aspirin': true,
    };
  }

  void _loadData() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _anim.forward();
    });
  }

  void _openDirections(String address) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  void _makePhoneCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not make call')));
    }
  }

  void _showRegistrationForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => RegisterPharmacyModal(
        onPharmacyRegistered: (pharmacy) {
          setState(() {
            _registeredPharmacies.add(pharmacy);
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pharmacy['name']} registered successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: _headerPadding,
                    child: _buildPharmacyHeader(),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading)
                  _buildSkeleton()
                else ...[
                  // ── SECTION 1: Reference Pharmacy (Template) ──
                  _buildSectionHeader('Reference Template'),
                  const SizedBox(height: 12),
                  _buildPharmacyCard(_referencePharmacy, isReference: true),
                  const SizedBox(height: 28),

                  // ── SECTION 2: Register New Pharmacy ──
                  _buildSectionHeader('Register Your Pharmacy'),
                  const SizedBox(height: 12),
                  _buildRegisterButton(),
                  const SizedBox(height: 28),

                  // ── SECTION 3: Registered Pharmacies ──
                  if (_registeredPharmacies.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Registered Pharmacies (${_registeredPharmacies.length})',
                    ),
                    const SizedBox(height: 12),
                    ..._registeredPharmacies.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pharmacy = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPharmacyCard(
                          pharmacy,
                          onDelete: () {
                            setState(
                              () => _registeredPharmacies.removeAt(index),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${pharmacy['name']} removed'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 28),
                  ],

                  // ── SECTION 4: Medicine Availability ──
                  _buildSectionHeader('Medicine Availability'),
                  const SizedBox(height: 12),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 12),
                  _buildAvailabilityInfo(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildPharmacyHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, _headerIconOffset),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Transform.translate(
            offset: Offset(0, _headerTextOffset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Pharmacy Network',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reference template for registering pharmacies',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(
    Map<String, dynamic> pharmacy, {
    bool isReference = false,
    VoidCallback? onDelete,
  }) {
    final isOpen = pharmacy['isOpen'] as bool? ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReference
              ? AppColors.border
              : AppColors.secondary.withOpacity(0.3),
          width: isReference ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pharmacy Header ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isReference
                        ? AppColors.primaryLight
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_pharmacy_rounded,
                    color: isReference
                        ? AppColors.primary
                        : AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy['name'],
                        style: AppTextStyles.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isOpen ? 'Open now' : 'Closed',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isOpen
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isReference)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Template',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button (if registered)
                if (!isReference && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: onDelete,
                    tooltip: 'Remove pharmacy',
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Details ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: pharmacy['address'],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Hours',
                  value: pharmacy['hours'],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  value:
                      '${pharmacy['rating']} (${pharmacy['reviewCount']} reviews)',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.delivery_dining_outlined,
                  label: 'Delivery',
                  value:
                      'PKR ${(pharmacy['deliveryFee'] as num).toInt()} · ${pharmacy['deliveryTime']} mins',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Action Buttons ────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(pharmacy['address']),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: Text('Directions', style: AppTextStyles.labelLarge),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(pharmacy['phone']),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: Text(
                      'Call',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 3),
              Text(
                value, style: AppTextStyles.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _showRegistrationForm,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register a pharmacy', style: AppTextStyles.titleMedium),
                  Text(
                    'Add your pharmacy to our network',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medicine availability',
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _medicineAvailability.entries.map((entry) {
                final inStock = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: inStock
                        ? AppColors.successLight
                        : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: inStock
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        inStock ? Icons.check_circle : Icons.close,
                        size: 14,
                        color: inStock ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: inStock ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing sample medicines. Full 18,000+ catalogue integrated with backend.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PHARMACY REGISTRATION MODAL
// ═══════════════════════════════════════════════════════════════════

class RegisterPharmacyModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onPharmacyRegistered;

  const RegisterPharmacyModal({super.key, required this.onPharmacyRegistered});

  @override
  State<RegisterPharmacyModal> createState() => _RegisterPharmacyModalState();
}

class _RegisterPharmacyModalState extends State<RegisterPharmacyModal> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController();
  late final _addressCtrl = TextEditingController();
  late final _phoneCtrl = TextEditingController();
  late final _hoursCtrl = TextEditingController();
  late final _deliveryFeeCtrl = TextEditingController();
  late final _deliveryTimeCtrl = TextEditingController();

  bool _isLoading = false;
  double _rating = 4.5;
  bool _isOpen = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    final pharmacy = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameCtrl.text,
      'address': _addressCtrl.text,
      'phone': _phoneCtrl.text,
      'hours': _hoursCtrl.text,
      'rating': _rating,
      'reviewCount': 0,
      'deliveryFee': double.parse(_deliveryFeeCtrl.text),
      'deliveryTime': int.parse(_deliveryTimeCtrl.text),
      'isOpen': _isOpen,
    };

    if (mounted) {
      widget.onPharmacyRegistered(pharmacy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Register Pharmacy',
                        style: AppTextStyles.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    'Fill in your pharmacy details',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _buildFormField(
                        label: 'Pharmacy Name',
                        controller: _nameCtrl,
                        hintText: 'e.g., Care Pharmacy',
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildFormField(
                        label: 'Address',
                        controller: _addressCtrl,
                        hintText: 'e.g., F-7 Markaz, Islamabad',
                        maxLines: 2,
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'Address required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildFormField(
                        label: 'Phone Number',
                        controller: _phoneCtrl,
                        hintText: '+92 51 2827070',
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'Phone required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Hours
                      _buildFormField(
                        label: 'Operating Hours',
                        controller: _hoursCtrl,
                        hintText: '9:00 AM - 10:00 PM',
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'Hours required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Delivery Fee
                      _buildFormField(
                        label: 'Delivery Fee (PKR)',
                        controller: _deliveryFeeCtrl,
                        hintText: 'e.g., 120',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Fee required';
                          if (double.tryParse(val ?? '') == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Delivery Time
                      _buildFormField(
                        label: 'Delivery Time (minutes)',
                        controller: _deliveryTimeCtrl,
                        hintText: 'e.g., 25',
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val?.isEmpty ?? true) return 'Time required';
                          if (int.tryParse(val ?? '') == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Rating Slider
                      _buildRatingSlider(),
                      const SizedBox(height: 20),

                      // Open/Closed Toggle
                      _buildStatusToggle(),
                      const SizedBox(height: 20),

                      // Preview Card
                      _buildPreviewSection(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Action Buttons ──────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: AppTextStyles.labelLarge),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Register',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial Rating', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rating: ${_rating.toStringAsFixed(1)} ⭐',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _rating,
                min: 1.0,
                max: 5.0,
                divisions: 40,
                activeColor: AppColors.secondary,
                label: _rating.toStringAsFixed(1),
                onChanged: (val) => setState(() => _rating = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOpen ? '✓ Open now' : '✕ Closed',
                style: AppTextStyles.titleMedium.copyWith(
                  color: _isOpen ? AppColors.success : AppColors.danger,
                ),
              ),
              Switch(
                value: _isOpen,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _isOpen = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'Your Pharmacy Name'
                              : _nameCtrl.text,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isOpen ? 'Open now' : 'Closed',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isOpen
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_addressCtrl.text.isNotEmpty)
                Text(
                  '📍 ${_addressCtrl.text}',
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (_hoursCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🕐 ${_hoursCtrl.text}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              if (_deliveryFeeCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🚚 PKR ${_deliveryFeeCtrl.text} · ${_deliveryTimeCtrl.text.isEmpty ? '?' : _deliveryTimeCtrl.text} mins',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
