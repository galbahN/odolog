import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleLabel;

  const AddMaintenanceScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleLabel,
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  String? _selectedService;
  DateTime _serviceDate = DateTime.now();
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 90));
  bool _isLoading = false;
  String? _error;

  Future<void> _saveRecord() async {
    final mileage = _mileageController.text.trim();
    final cost = _costController.text.trim();

    if (_selectedService == null || mileage.isEmpty || cost.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('maintenance').add({
        'vehicleId': widget.vehicleId,
        'loggedBy': uid,
        'serviceType': _selectedService,
        'serviceDate': DateFormat('yyyy-MM-dd').format(_serviceDate),
        'mileage': int.tryParse(mileage) ?? 0,
        'cost': double.tryParse(cost) ?? 0,
        'nextDueDate': DateFormat('yyyy-MM-dd').format(_nextDueDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the vehicle's current mileage to match
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update({'currentMileage': int.tryParse(mileage) ?? 0});

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  final List<String> _serviceTypes = [
    'Oil Change',
    'Tire Rotation',
    'Brake Service',
    'Battery Replacement',
    'Air Filter',
    'Coolant Flush',
    'Spark Plugs',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Log Service — ${widget.vehicleLabel}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Service Type *'),
            _dropdown(
              _selectedService,
              _serviceTypes,
              'Select service',
              (v) => setState(() => _selectedService = v),
            ),

            const SizedBox(height: 16),
            _label('Service Date *'),
            _dateRow(_serviceDate, (d) => setState(() => _serviceDate = d)),

            const SizedBox(height: 16),
            _label('Mileage at Service *'),
            _field(
              'e.g. 45000',
              _mileageController,
              type: TextInputType.number,
            ),

            const SizedBox(height: 16),
            _label('Cost (GHS) *'),
            _field('e.g. 150', _costController, type: TextInputType.number),

            const SizedBox(height: 16),
            _label('Next Due Date *'),
            _dateRow(_nextDueDate, (d) => setState(() => _nextDueDate = d)),

            if (_error != null) ...[
              const SizedBox(height: 8),
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
                onPressed: _isLoading ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF0D1B2A),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0D1B2A))
                    : const Text(
                        'Save Record',
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

  Widget _field(
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
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

  Widget _dropdown(
    String? value,
    List<String> items,
    String hint,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2E42),
          hint: Text(hint, style: const TextStyle(color: Colors.white24)),
          style: const TextStyle(color: Colors.white),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateRow(DateTime date, void Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
          builder: (_, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4FC3F7),
                surface: Color(0xFF1A2E42),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E42),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF4FC3F7),
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('MMM d, yyyy').format(date),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
