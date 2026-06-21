import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Owner Dashboard (placeholder)',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: const Color(0xFF0D1B2A),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}