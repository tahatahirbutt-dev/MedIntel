import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';

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

  final List<Map<String, dynamic>> _history = [
    {
      'date': '2024-02-15',
      'doctor': 'Dr. Ahmed Khan',
      'diagnosis': 'Upper Respiratory Infection',
      'medicines': ['Amoxicillin', 'Paracetamol'],
    },
    {
      'date': '2023-12-10',
      'doctor': 'Dr. Sara Malik',
      'diagnosis': 'Migraine',
      'medicines': ['Sumatriptan', 'Ibuprofen'],
    },
    {
      'date': '2023-09-05',
      'doctor': 'Dr. Rizwan Ali',
      'diagnosis': 'Allergic Rhinitis',
      'medicines': ['Loratadine', 'Fluticasone'],
    },
  ];

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
                onPressed: () {},
                tooltip: 'Export profile',
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
                        const Text(
                          'Medical Profile',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your personal health record',
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
                _buildVitalsRow(),
                const SizedBox(height: 20),

                // ── Emergency Contact ────────────
                _buildEmergencyCard(),
                const SizedBox(height: 20),

                // ── Allergies ────────────────────
                _buildTagSection(
                  title: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.danger,
                  iconBg: AppColors.dangerLight,
                  items: _allergies,
                  chipColor: AppColors.danger,
                  chipBg: AppColors.dangerLight,
                  controller: _allergyCtrl,
                  hint: 'e.g. Penicillin',
                  onAdd: () => _add(_allergies, _allergyCtrl),
                  onRemove: (i) => _remove(_allergies, i),
                ),
                const SizedBox(height: 16),

                // ── Chronic Conditions ───────────
                _buildTagSection(
                  title: 'Chronic Conditions',
                  icon: Icons.monitor_heart_outlined,
                  iconColor: AppColors.warning,
                  iconBg: AppColors.warningLight,
                  items: _conditions,
                  chipColor: AppColors.warning,
                  chipBg: AppColors.warningLight,
                  controller: _conditionCtrl,
                  hint: 'e.g. Type 2 Diabetes',
                  onAdd: () => _add(_conditions, _conditionCtrl),
                  onRemove: (i) => _remove(_conditions, i),
                ),
                const SizedBox(height: 20),

                // ── Medical History ──────────────
                _buildHistorySection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow() {
    final vitals = [
      (
        'Blood Type',
        'O+',
        AppColors.danger,
        AppColors.dangerLight,
        Icons.water_drop_outlined,
      ),
      (
        'Height',
        '5\'10"',
        AppColors.primary,
        AppColors.primaryLight,
        Icons.height,
      ),
      (
        'Weight',
        '75 kg',
        AppColors.secondary,
        AppColors.secondaryLight,
        Icons.monitor_weight_outlined,
      ),
    ];
    return Row(
      children: vitals.map((v) {
        return Expanded(
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
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: v.$5 == Icons.water_drop_outlined
                        ? AppColors.dangerLight
                        : v.$5 == Icons.height
                        ? AppColors.primaryLight
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(v.$5, size: 16, color: v.$3),
                ),
                const SizedBox(height: 10),
                Text(
                  v.$2,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: v.$3,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(v.$1, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyCard() {
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
                Text('Emergency contact', style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit'),
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
                    'A',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abdullah Shakeel', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text('+92 321 9876543', style: AppTextStyles.bodyMedium),
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
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                        'None added yet',
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Medical history',
          actionLabel: 'Export all',
          onAction: () {},
        ),
        const SizedBox(height: 12),
        ..._history.map(_buildHistoryCard),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> r) {
    final parts = r['date'].split('-');
    final day = parts[2];
    final month = _monthName(parts[1]);
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
                    Text(r['diagnosis'], style: AppTextStyles.titleMedium),
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

  String _monthName(String m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[int.parse(m) - 1];
  }
}
