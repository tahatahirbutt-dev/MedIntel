import 'package:flutter/material.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({Key? key}) : super(key: key);

  @override
  _MedicalProfileScreenState createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final List<String> _allergies = ['Penicillin', 'Sulfa drugs', 'Ibuprofen'];

  final List<String> _chronicConditions = ['Type 2 Diabetes', 'Hypertension'];

  final List<Map<String, dynamic>> _medicalHistory = [
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

  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  void _addAllergy() {
    if (_allergyController.text.isNotEmpty) {
      setState(() {
        _allergies.add(_allergyController.text);
        _allergyController.clear();
      });
    }
  }

  void _addCondition() {
    if (_conditionController.text.isNotEmpty) {
      setState(() {
        _chronicConditions.add(_conditionController.text);
        _conditionController.clear();
      });
    }
  }

  void _removeAllergy(int index) {
    setState(() {
      _allergies.removeAt(index);
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _chronicConditions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // TODO: Export medical profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Contact Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emergency, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Contact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Abdullah Shakeel'),
                      subtitle: Text('+92 321 9876543'),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Allergies Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allergies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showAddDialog(
                              'Add Allergy',
                              _allergyController,
                              _addAllergy,
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_allergies.isEmpty)
                      Text(
                        'No allergies recorded',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allergies.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () => _removeAllergy(entry.key),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Chronic Conditions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chronic Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showAddDialog(
                              'Add Condition',
                              _conditionController,
                              _addCondition,
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_chronicConditions.isEmpty)
                      Text(
                        'No chronic conditions recorded',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _chronicConditions.asMap().entries.map((
                          entry,
                        ) {
                          return Chip(
                            label: Text(entry.value),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () => _removeCondition(entry.key),
                            backgroundColor: Colors.orange.shade50,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Medical History
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._medicalHistory.map((record) {
                      return _buildHistoryCard(record);
                    }).toList(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Blood Type & Important Info
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Blood Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'O+',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '5\'10"',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                record['date'].split('-')[2], // Day
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                _getMonthName(record['date'].split('-')[1]),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        title: Text(
          record['diagnosis'],
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${record['doctor']}'),
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: (record['medicines'] as List)
                  .map(
                    (med) => Chip(
                      label: Text(med),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(String month) {
    final months = [
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
    return months[int.parse(month) - 1];
  }

  void _showAddDialog(
    String title,
    TextEditingController controller,
    VoidCallback onAdd,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter ${title.toLowerCase()}',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onAdd();
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}
