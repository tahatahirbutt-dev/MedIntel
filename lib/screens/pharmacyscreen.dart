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
  // Default "Our Store" data
  late final Map<String, dynamic> _ourStore = {
    'id': '1',
    'name': 'Care Pharmacy',
    'address': 'F-7 Markaz, Islamabad',
    'phone': '+92 51 2827070',
    'hours': '9:00 AM - 10:00 PM',
    'rating': 4.5,
    'reviewCount': 128,
    'deliveryFee': 120.0,
    'deliveryTime': 25,
    'isOpen': true,
    'availability': {'amoxicillin': true, 'ibuprofen': true, 'metformin': true},
  };

  bool _isEditing = false;
  late TextEditingController _nameController;
  bool _isLoading = true;

  late final AnimationController _anim;
  // Adjustable header layout values — tweak these to move the logo/text
  final EdgeInsets _headerPadding = const EdgeInsets.fromLTRB(10, 10, 10, 12);
  final double _headerIconOffset = 5.0;
  final double _headerTextOffset = -15.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nameController = TextEditingController(text: _ourStore['name']);
    _loadStore();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _loadStore() {
    // Simulate brief loading for consistency
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _anim.forward();
    });
  }

  void _toggleEditName() {
    if (_isEditing) {
      // Save the new name
      setState(() {
        _ourStore['name'] = _nameController.text.isNotEmpty
            ? _nameController.text
            : _ourStore['name'];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store name updated'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _openDirections() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_ourStore['address'])}";
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

  void _makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: _ourStore['phone']);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not make call')));
    }
  }

  void _registerNewPharmacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Register pharmacy'),
        content: const Text(
          'This feature allows pharmacies to join our network in the future. Coming soon!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
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

          // ── Content ────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading) _buildSkeleton() else _buildStoreCard(),
                const SizedBox(height: 24),
                _buildRegisterButton(),
                const SizedBox(height: 12),
                if (!_isLoading) _buildAvailabilitySection(),
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

  // Header builder separated so the logo + texts are easy to tweak.
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
                const Text(
                  'Our Pharmacy',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Store info & availability',
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
      ],
    );
  }

  Widget _buildStoreCard() {
    final isOpen = _ourStore['isOpen'] as bool;

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
          // ── Store name header (editable) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ourStore['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOpen ? 'Open now' : 'Closed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isOpen
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: _toggleEditName,
                  tooltip: _isEditing ? 'Save name' : 'Edit name',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Store details ────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Address
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _ourStore['address'],
                ),
                const SizedBox(height: 14),

                // Hours
                _buildDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Hours',
                  value: _ourStore['hours'],
                ),
                const SizedBox(height: 14),

                // Rating
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rating', style: AppTextStyles.bodySmall),
                          Text(
                            '${_ourStore['rating']} (${_ourStore['reviewCount']} reviews)',
                            style: AppTextStyles.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Delivery
                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining_outlined,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery', style: AppTextStyles.bodySmall),
                          Text(
                            'PKR ${(_ourStore['deliveryFee'] as double).toInt()} · ${_ourStore['deliveryTime']} mins',
                            style: AppTextStyles.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Action buttons ────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Directions'),
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
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Call store'),
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
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, style: AppTextStyles.bodySmall),
              Text(
                value, style: AppTextStyles.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    final availability = _ourStore['availability'] as Map<String, bool>;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
                const Text(
                  'Medicine availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              children: availability.entries.map((entry) {
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

  Widget _buildRegisterButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register a pharmacy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Help more pharmacies join our network',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: _registerNewPharmacy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}
