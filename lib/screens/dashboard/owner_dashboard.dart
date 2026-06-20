import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: const Center(
        child: Text('Owner Dashboard (placeholder)',
          style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}