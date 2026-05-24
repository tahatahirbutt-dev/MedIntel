import 'package:flutter/material.dart';
import 'package:med_intel/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selectedDate;
  late List<List<bool>> _taken;
  final Map<String, List<String>> _customAlarms = {
    'Panadol': ['09:00', '13:00', '18:00'],
    'Metformin': ['08:00', '20:00'],
  };

  final List<Map<String, dynamic>> _medicines = [
    {
      'medicine': 'Panadol',
      'dosage': '500mg',
      'remainingDays': 7,
      'color': AppColors.primary,
    },
    {
      'medicine': 'Metformin',
      'dosage': '500mg',
      'remainingDays': 14,
      'color': AppColors.secondary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _taken = List.generate(2, (i) => List.filled(
        _customAlarms[_medicines[i]['medicine']]!.length, false));
    _taken[0][0] = true;
    _taken[1][0] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medicine Schedule'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildCalendarWidget(),
          const SizedBox(height: 24),
          _buildTodaysPills(),
          const SizedBox(height: 24),
          _buildMedicinesList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Date', style: AppTextStyles.titleMedium),
              Text(_formatDate(_selectedDate), style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateGrid(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap a date to view and set alarms',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGrid() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(now.year, now.month, day);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, now);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : (isToday ? AppColors.primaryLight : AppColors.surface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday ? AppColors.primary : AppColors.border,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysPills() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_pharmacy, size: 24, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Pills', style: AppTextStyles.titleMedium),
                    Text(_formatDate(DateTime.now()), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildUpcomingPills(),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingPills() {
    final pills = <Widget>[];
    int pillIndex = 0;

    for (int i = 0; i < _medicines.length; i++) {
      final medicine = _medicines[i];
      final times = _customAlarms[medicine['medicine']] ?? [];

      for (int j = 0; j < times.length; j++) {
        final taken = _taken[i][j];
        final time = times[j];
        final isPast = _isPastTime(time);

        pills.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: taken ? medicine['color'].withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: taken ? medicine['color'] : AppColors.border,
                  width: taken ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: medicine['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medication,
                      size: 20,
                      color: medicine['color'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['medicine'],
                          style: AppTextStyles.titleMedium.copyWith(
                            decoration: taken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          '${medicine['dosage']} at $time',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _taken[i][j] = !_taken[i][j]),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: taken ? medicine['color'] : AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        taken ? Icons.check_rounded : Icons.add,
                        color: taken ? Colors.white : AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        pillIndex++;
      }
    }

    if (pills.isEmpty) {
      pills.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text('No pills scheduled', style: AppTextStyles.bodyMedium),
          ),
        ),
      );
    }

    return pills;
  }

  Widget _buildMedicinesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Medicines', style: AppTextStyles.headlineSmall),
            GestureDetector(
              onTap: () => _showAddMedicineBottomSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 18, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Add', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._medicines.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMedicineCard(entry.key, entry.value),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMedicineCard(int index, Map<String, dynamic> medicine) {
    final times = _customAlarms[medicine['medicine']] ?? [];
    final color = medicine['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${medicine['medicine']} • ${medicine['dosage']}',
                        style: AppTextStyles.titleMedium),
                    Text('${medicine['remainingDays']} days left', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showEditMedicineBottomSheet(index),
                child: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: times.map((time) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${times.length} dose${times.length > 1 ? 's' : ''} daily',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _buildAddMedicineSheet(),
    );
  }

  void _showEditMedicineBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _buildEditMedicineSheet(index),
    );
  }

  Widget _buildAddMedicineSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Medicine', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          Text('Medicine Name', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter medicine name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text('Time', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select time'),
                  Icon(Icons.access_time, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.borderLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: AppTextStyles.titleMedium),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Medicine added successfully!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditMedicineSheet(int index) {
    final medicine = _medicines[index];
    final times = _customAlarms[medicine['medicine']] ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit ${medicine['medicine']}', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          Text('Current Times', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: times.map((time) {
              return Chip(
                label: Text(time),
                onDeleted: () => setState(() {
                  times.remove(time);
                }),
                backgroundColor: (medicine['color'] as Color).withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.borderLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done', style: AppTextStyles.titleMedium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      debugPrint('Selected time: ${time.format(context)}');
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPastTime(String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final timeDate = DateTime(now.year, now.month, now.day, hour, minute);
    return timeDate.isBefore(now);
  }
}
