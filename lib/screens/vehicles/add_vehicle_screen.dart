import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _customMakeController = TextEditingController();

  String? _selectedMake;
  int? _selectedYear;
  bool _isLoading = false;
  String? _error;

  final List<String> _makes = [
    'Toyota',
    'Hyundai',
    'Kia',
    'Nissan',
    'Honda',
    'Mercedes-Benz',
    'BMW',
    'Ford',
    'Volkswagen',
    'Mitsubishi',
    'Suzuki',
    'Mazda',
    'Chevrolet',
    'Other',
  ];

  List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 2000 + 1, (i) => currentYear - i);
  }

  Future<void> _saveVehicle() async {
    final make = _selectedMake == 'Other'
        ? _customMakeController.text.trim()
        : (_selectedMake ?? '');
    final model = _modelController.text.trim();
    final plate = _plateController.text.trim();
    final color = _colorController.text.trim();

    if (make.isEmpty ||
        model.isEmpty ||
        plate.isEmpty ||
        color.isEmpty ||
        _selectedYear == null) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = userDoc.data()?['role'];

      await FirebaseFirestore.instance.collection('vehicles').add({
        'make': make.toUpperCase(),
        'model': model.toUpperCase(),
        'year': _selectedYear,
        'plate': plate.toUpperCase(),
        'color': color.toUpperCase(),
        'addedBy': uid,
        'ownerId': role == 'owner' ? uid : null,
        'assignedDriverId': role == 'driver' ? uid : null,
        'currentMileage': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Make *'),
            _dropdown<String>(
              value: _selectedMake,
              items: _makes,
              hint: 'Select make',
              onChanged: (v) => setState(() => _selectedMake = v),
              itemLabel: (v) => v,
            ),

            if (_selectedMake == 'Other') ...[
              const SizedBox(height: 14),
              _field('Enter make', _customMakeController),
            ],

            const SizedBox(height: 14),
            _label('Model *'),
            _field('e.g. Corolla', _modelController),

            const SizedBox(height: 14),
            _label('Year *'),
            _dropdown<int>(
              value: _selectedYear,
              items: _years,
              hint: 'Select year',
              onChanged: (v) => setState(() => _selectedYear = v),
              itemLabel: (v) => v.toString(),
            ),

            const SizedBox(height: 14),
            _label('Plate Number *'),
            _field('e.g. GR 1234-22', _plateController),

            const SizedBox(height: 14),
            _label('Color *'),
            _field('e.g. Silver', _colorController),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF0D1B2A),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0D1B2A))
                    : const Text(
                        'Save Vehicle',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _field(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1A2E42),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2E42),
          hint: Text(hint, style: const TextStyle(color: Colors.white24)),
          style: const TextStyle(color: Colors.white),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
