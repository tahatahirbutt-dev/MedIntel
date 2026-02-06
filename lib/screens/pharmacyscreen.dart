import 'package:flutter/material.dart';
import 'package:med_intel/models/pharmacy.dart';

class PharmacyScreen extends StatefulWidget {
  final List<String> medicineIds;

  const PharmacyScreen({Key? key, required this.medicineIds}) : super(key: key);

  @override
  _PharmacyScreenState createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  // ignore: unused_field
  String _selectedFilter = 'distance';

  // Mock pharmacies data
  final List<Map<String, dynamic>> _mockPharmacies = [
    {
      'id': '1',
      'name': 'Care Pharmacy',
      'address': 'F-7 Markaz, Islamabad',
      'distance': 1.2,
      'rating': 4.5,
      'reviewCount': 128,
      'deliveryFee': 120,
      'deliveryTime': 25,
      'availability': {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': true,
      },
    },
    {
      'id': '2',
      'name': 'Medicare Pharmacy',
      'address': 'G-9/4, Islamabad',
      'distance': 2.5,
      'rating': 4.2,
      'reviewCount': 89,
      'deliveryFee': 150,
      'deliveryTime': 35,
      'availability': {
        'amoxicillin': true,
        'ibuprofen': false,
        'metformin': true,
      },
    },
    {
      'id': '3',
      'name': 'Life Pharmacy',
      'address': 'Blue Area, Islamabad',
      'distance': 3.1,
      'rating': 4.7,
      'reviewCount': 245,
      'deliveryFee': 100,
      'deliveryTime': 20,
      'availability': {
        'amoxicillin': true,
        'ibuprofen': true,
        'metformin': false,
      },
    },
    {
      'id': '4',
      'name': 'City Medical Store',
      'address': 'I-8/4, Islamabad',
      'distance': 4.3,
      'rating': 4.0,
      'reviewCount': 67,
      'deliveryFee': 180,
      'deliveryTime': 45,
      'availability': {
        'amoxicillin': false,
        'ibuprofen': true,
        'metformin': true,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  void _loadPharmacies() {
    // Simulate API delay
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _pharmacies = _mockPharmacies
            .map(
              (data) => Pharmacy(
                id: data['id'],
                name: data['name'],
                address: data['address'],
                distance: data['distance'],
                rating: data['rating'],
                reviewCount: data['reviewCount'],
                availability: data['availability'],
                deliveryFee: data['deliveryFee'].toDouble(),
                deliveryTime: data['deliveryTime'],
              ),
            )
            .toList();
        _isLoading = false;
      });
    });
  }

  void _sortPharmacies(String filter) {
    setState(() {
      _selectedFilter = filter;

      switch (filter) {
        case 'distance':
          _pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'rating':
          _pharmacies.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'deliveryTime':
          _pharmacies.sort((a, b) => a.deliveryTime.compareTo(b.deliveryTime));
          break;
        case 'price':
          _pharmacies.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_pharmacies.length} pharmacies found',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              PopupMenuButton<String>(
                onSelected: _sortPharmacies,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'distance',
                    child: Text('Sort by Distance'),
                  ),
                  PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
                  PopupMenuItem(
                    value: 'deliveryTime',
                    child: Text('Sort by Delivery Time'),
                  ),
                  PopupMenuItem(value: 'price', child: Text('Sort by Price')),
                ],
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 4),
                    Text('Sort'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Pharmacy List
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _pharmacies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_pharmacy_outlined,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pharmacies found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Try adjusting your search',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _pharmacies.length,
                  itemBuilder: (context, index) {
                    return _buildPharmacyCard(_pharmacies[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pharmacy.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text('${pharmacy.distance} km'),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(child: Text(pharmacy.address)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                // Rating
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('${pharmacy.rating}'),
                    SizedBox(width: 4),
                    Text(
                      '(${pharmacy.reviewCount} reviews)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Spacer(),
                // Delivery Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pharmacy.deliveryTime} min',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'PKR ${pharmacy.deliveryFee} delivery',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),

            // Availability
            Text(
              'Availability:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pharmacy.availability.entries.map((entry) {
                return Chip(
                  label: Text(entry.key),
                  backgroundColor: entry.value
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  side: BorderSide(
                    color: entry.value
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: View details
                    },
                    child: Text('View Details'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Order from this pharmacy
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                    ),
                    child: Text('Order Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
