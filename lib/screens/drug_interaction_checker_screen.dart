import 'package:flutter/material.dart';
import 'package:med_intel/services/mock_data.dart';

class DrugInteractionCheckerScreen extends StatefulWidget {
  final List<String>? initialMedicines;
  final List<String>? userAllergies;

  const DrugInteractionCheckerScreen({
    Key? key,
    this.initialMedicines,
    this.userAllergies,
  }) : super(key: key);

  @override
  _DrugInteractionCheckerScreenState createState() =>
      _DrugInteractionCheckerScreenState();
}

class _DrugInteractionCheckerScreenState
    extends State<DrugInteractionCheckerScreen> {
  final TextEditingController _medicineController = TextEditingController();
  final List<String> _selectedMedicines = [];
  final List<String> _userAllergies = [];
  bool _isChecking = false;
  List<Map<String, dynamic>>? _interactions;
  List<Map<String, dynamic>>? _allergyConflicts;

  @override
  void initState() {
    super.initState();
    if (widget.initialMedicines != null) {
      _selectedMedicines.addAll(widget.initialMedicines!);
    }
    if (widget.userAllergies != null) {
      _userAllergies.addAll(widget.userAllergies!);
    }
  }

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _checkInteractions() async {
    if (_selectedMedicines.isEmpty) {
      _showErrorSnackBar('Please add at least one medicine');
      return;
    }

    setState(() => _isChecking = true);

    try {
      final interactions = await MockDataService.checkDrugInteractions(
        _selectedMedicines,
      );

      final List<Map<String, dynamic>> allergyConflicts =
          _userAllergies.isNotEmpty
          ? await MockDataService.checkAllergyConflicts(
              _userAllergies,
              _selectedMedicines,
            )
          : <Map<String, dynamic>>[];

      setState(() {
        _interactions = interactions;
        _allergyConflicts = allergyConflicts;
      });

      _showResultDialog();
    } catch (e) {
      _showErrorSnackBar('Error checking interactions: $e');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _addMedicine() {
    final medicine = _medicineController.text.trim();

    if (medicine.isEmpty) {
      _showErrorSnackBar('Please enter a medicine name');
      return;
    }

    if (_selectedMedicines.contains(medicine)) {
      _showErrorSnackBar('Medicine already added');
      return;
    }

    setState(() {
      _selectedMedicines.add(medicine);
      _medicineController.clear();
      _interactions = null;
      _allergyConflicts = null;
    });
  }

  void _removeMedicine(String medicine) {
    setState(() {
      _selectedMedicines.remove(medicine);
      _interactions = null;
      _allergyConflicts = null;
    });
  }

  void _showResultDialog() {
    final hasInteractions = _interactions?.isNotEmpty ?? false;
    final hasAllergyConflicts = _allergyConflicts?.isNotEmpty ?? false;
    final isSafe = !hasInteractions && !hasAllergyConflicts;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSafe ? Icons.check_circle : Icons.warning,
              color: isSafe ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(isSafe ? 'Safe to Use' : 'Caution Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSafe) ...[
                const Text(
                  'No significant interactions detected.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                if (hasInteractions) ...[
                  const Text(
                    'Drug Interactions Found:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ..._interactions!.map((interaction) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildInteractionItem(interaction),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
                if (hasAllergyConflicts) ...[
                  const Text(
                    'Allergy Warnings:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._allergyConflicts!.map((conflict) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildAllergyConflictItem(conflict),
                    );
                  }).toList(),
                ],
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '⚠️ This checker is informational only. Always consult a doctor or pharmacist before taking medicines.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isSafe)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to chat with pharmacist or doctor
              },
              child: const Text('Consult Pharmacist'),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionItem(Map<String, dynamic> interaction) {
    final severityColor = _getSeverityColor(interaction['severity'] ?? 'Minor');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${interaction['drug1']} + ${interaction['drug2']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  interaction['severity'] ?? 'Minor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            interaction['description'] ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyConflictItem(Map<String, dynamic> conflict) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.red, width: 4)),
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${conflict['allergen']} Allergy',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ALERT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Conflicting medicine: ${conflict['medicine']}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (conflict['alternatives'] != null &&
              (conflict['alternatives'] as List).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Safe alternatives: ${(conflict['alternatives'] as List).join(", ")}',
              style: TextStyle(fontSize: 11, color: Colors.green.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.yellow;
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Interaction Checker'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This tool checks for potential drug interactions. Always consult a healthcare professional.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Input Section
            const Text(
              'Add Medicines',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _medicineController,
                    decoration: InputDecoration(
                      hintText: 'Enter medicine name',
                      prefixIcon: const Icon(Icons.medication),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onSubmitted: (_) => _addMedicine(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _addMedicine,
                  backgroundColor: Colors.blue.shade700,
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected Medicines
            if (_selectedMedicines.isNotEmpty) ...[
              Text(
                'Selected Medicines (${_selectedMedicines.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMedicines.map((medicine) {
                  return Chip(
                    label: Text(medicine),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeMedicine(medicine),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade200),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // User Allergies Section
            const Text(
              'Your Allergies (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_userAllergies.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add allergies to your profile for better safety checks',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userAllergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: Colors.red.shade50,
                    side: BorderSide(color: Colors.red.shade200),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Check Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkInteractions,
                icon: _isChecking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.security_outlined),
                label: Text(
                  _isChecking ? 'Checking...' : 'Check Interactions',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Results Section
            if (_interactions != null || _allergyConflicts != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildResultsSummary(),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    final hasInteractions = _interactions?.isNotEmpty ?? false;
    final hasAllergyConflicts = _allergyConflicts?.isNotEmpty ?? false;
    final isSafe = !hasInteractions && !hasAllergyConflicts;

    return Card(
      color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSafe ? Icons.check_circle : Icons.warning_amber,
                  color: isSafe ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isSafe ? 'Safe Combination' : 'Interactions Detected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasInteractions)
              Text(
                '${_interactions!.length} interaction(s) found',
                style: TextStyle(color: Colors.red.shade700),
              ),
            if (hasAllergyConflicts)
              Text(
                '${_allergyConflicts!.length} allergy conflict(s) found',
                style: TextStyle(color: Colors.red.shade700),
              ),
            if (isSafe)
              Text(
                'No significant interactions detected',
                style: TextStyle(color: Colors.green.shade700),
              ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Checker'),
        content: const Text(
          'This tool checks for:\n\n'
          '• Drug-drug interactions\n'
          '• Allergy conflicts\n'
          '• Severity levels (Minor, Moderate, Severe)\n\n'
          'This is for informational purposes only. Always consult with a healthcare professional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
