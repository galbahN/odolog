import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _earningsController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _saveTrip() async {
    final start = _startController.text.trim();
    final destination = _destinationController.text.trim();
    final distance = _distanceController.text.trim();
    final earnings = _earningsController.text.trim();

    if (start.isEmpty || destination.isEmpty || earnings.isEmpty) {
      setState(() => _error = 'Please fill in start, destination and earnings');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final docRef = await FirebaseFirestore.instance.collection('trips').add({
        'driverId': uid,
        'startPoint': start,
        'destination': destination,
        'distance': double.tryParse(distance) ?? 0,
        'earnings': double.tryParse(earnings) ?? 0,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
        'TRIP SAVED SUCCESSFULLY — Document ID: ${docRef.id}, UID used: $uid',
      );

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
        title: const Text('Log Trip', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('From (start point)', _startController),
            _field('To (destination)', _destinationController),
            _field(
              'Distance (km)',
              _distanceController,
              type: TextInputType.number,
            ),
            _field(
              'Earnings (GHS)',
              _earningsController,
              type: TextInputType.number,
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF0D1B2A),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0D1B2A))
                    : const Text(
                        'Save Trip',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String hint,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
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
      ),
    );
  }
}
