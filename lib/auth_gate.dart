import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/owner_dashboard.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/dashboard/driver_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Not logged in
        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        final uid = authSnap.data!.uid;

        // Logged in — now check their role from Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFF0D1B2A),
                body: Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7))),
              );
            }

            final data = userSnap.data!.data() as Map<String, dynamic>?;
            final role = data?['role'];

            if (role == null) {
              return const RoleSelectionScreen();
            } else if (role == 'owner') {
              return const OwnerDashboard();
            } else {
              return const DriverDashboard();
            }
          },
        );
      },
    );
  }
}