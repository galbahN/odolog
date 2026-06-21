import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _addDriver() async {
    final phone = _phoneController.text.trim();

    if (phone.length != 10 || !phone.startsWith('0')) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      // Look up the driver by phone number
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _error = 'No driver found with that phone number');
        return;
      }

      final driverDoc = query.docs.first;
      final driverData = driverDoc.data();

      if (driverData['role'] != 'driver') {
        setState(
          () =>
              _error = 'This phone number does not belong to a driver account',
        );
        return;
      }

      if (driverData['ownerId'] != null) {
        setState(() => _error = 'This driver is already assigned to a fleet');
        return;
      }

      // Link the driver to this owner
      final ownerUid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(driverDoc.id)
          .update({'ownerId': ownerUid});

      setState(() {
        _success = '${driverData['name']} added to your fleet!';
        _phoneController.clear();
      });
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
        title: const Text('Add Driver', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the driver's registered phone number",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 0241234567',
                hintStyle: const TextStyle(color: Colors.white24),
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF1A2E42),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 8),
              Text(
                _success!,
                style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: const Color(0xFF0D1B2A),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0D1B2A))
                    : const Text(
                        'Add Driver',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
