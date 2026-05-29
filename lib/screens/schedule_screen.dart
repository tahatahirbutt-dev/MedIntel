import 'package:flutter/material.dart';
import 'package:med_intel/models/medicine_schedule.dart';
import 'package:med_intel/services/firebase_schedule_service.dart';
import 'package:med_intel/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleService = FirebaseScheduleService();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _addSchedule(MedicineSchedule schedule) async {
    try {
      await _scheduleService.createSchedule(schedule);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Schedule added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteSchedule(String id) async {
    try {
      await _scheduleService.deleteSchedule(id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Schedule deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _markAsTaken(String doseId) async {
    try {
      await _scheduleService.markDoseAsTaken(doseId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Marked as taken'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildTodaysDoses(),
          const SizedBox(height: 24),
          _buildSchedulesList(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Date', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: _formatDate(_selectedDate),
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onTap: () => _selectDate(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysDoses() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _scheduleService.getTodaysDosesStream(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No medicines scheduled for today',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        final doses = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Doses', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...doses.map((dose) => _buildDoseCard(dose)),
          ],
        );
      },
    );
  }

  Widget _buildDoseCard(Map<String, dynamic> dose) {
    final isTaken = dose['isTaken'] as bool;
    final time = dose['time'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTaken
            ? AppColors.primaryLight.withOpacity(0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken ? AppColors.primary : AppColors.border,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose['medicineName'] as String,
                  style: AppTextStyles.titleMedium.copyWith(
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${dose['dosage']} at $time',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isTaken ? null : () => _markAsTaken(dose['id'] as String),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isTaken ? AppColors.primary : AppColors.borderLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.check_rounded : Icons.add,
                color: isTaken ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return StreamBuilder<List<MedicineSchedule>>(
      stream: _scheduleService.getActiveSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No medicine schedules yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        final schedules = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Schedules', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...schedules.map((schedule) => _buildScheduleCard(schedule)),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(MedicineSchedule schedule) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.medicineName, style: AppTextStyles.titleMedium),
                  Text(schedule.dosage, style: AppTextStyles.bodySmall),
                ],
              ),
              GestureDetector(
                onTap: () => _deleteSchedule(schedule.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: schedule.times.map((time) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${schedule.remainingDays} days remaining',
            style: AppTextStyles.bodySmall.copyWith(
              color: schedule.remainingDays > 3
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleModal() {
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController(text: '7');
    final List<String> selectedTimes = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Medicine Schedule',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: medicineController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage (e.g., 500mg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (days)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text('Select Times', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),
                if (selectedTimes.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: selectedTimes.map((time) {
                      return Chip(
                        label: Text(time),
                        onDeleted: () =>
                            setState(() => selectedTimes.remove(time)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () =>
                      _selectTime(context, selectedTimes, setState),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final duration =
                          int.tryParse(durationController.text) ?? 0;

                      if (medicineController.text.isEmpty ||
                          dosageController.text.isEmpty ||
                          selectedTimes.isEmpty ||
                          duration <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill all fields with valid values',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final schedule = MedicineSchedule(
                        id: '',
                        userId: '',
                        medicineName: medicineController.text.trim(),
                        dosage: dosageController.text.trim(),
                        times: selectedTimes,
                        durationDays: duration,
                        startDate: _selectedDate,
                        createdAt: DateTime.now(),
                      );

                      _addSchedule(schedule);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Create Schedule'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    List<String> selectedTimes,
    StateSetter setState,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final formattedTime = _formatTime(time);
      setState(() {
        if (!selectedTimes.contains(formattedTime)) {
          selectedTimes.add(formattedTime);
          selectedTimes.sort();
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
