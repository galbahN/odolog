import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../trips/add_trip_screen.dart';
import '../vehicles/add_vehicle_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odolog/screens/sales/add_sale_screen.dart';
import 'package:odolog/screens/vehicles/vehicles_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4FC3F7),
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF112236),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.route, color: Color(0xFF4FC3F7)),
                  title: const Text(
                    'Log Trip',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddTripScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.attach_money,
                    color: Color(0xFF66BB6A),
                  ),
                  title: const Text(
                    'Log Expense',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddExpenseScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.directions_car,
                    color: Color(0xFF4FC3F7),
                  ),
                  title: const Text(
                    'Add My Vehicle',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddVehicleScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        child: const Icon(Icons.add, color: Color(0xFF0D1B2A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning 👋',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.get('name') ?? 'Driver';
                          return Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.directions_car_outlined,
                          color: Color(0xFF4FC3F7),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehiclesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => FirebaseAuth.instance.signOut(),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF1A2E42),
                          child: Icon(
                            Icons.logout,
                            color: Color(0xFF4FC3F7),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Today's Summary Card (live)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('driverId', isEqualTo: uid)
                    .where(
                      'date',
                      isEqualTo: DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.now()),
                    )
                    .snapshots(),
                builder: (context, tripsSnapshot) {
                  double earnings = 0;
                  if (tripsSnapshot.hasData) {
                    for (var doc in tripsSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      earnings += (data['earnings'] ?? 0).toDouble();
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('expenses')
                        .where('driverId', isEqualTo: uid)
                        .where(
                          'date',
                          isEqualTo: DateFormat(
                            'dd-MM-yyyy',
                          ).format(DateTime.now()),
                        )
                        .snapshots(),
                    builder: (context, expensesSnapshot) {
                      double expenses = 0;
                      if (expensesSnapshot.hasData) {
                        for (var doc in expensesSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          expenses += (data['amount'] ?? 0).toDouble();
                        }
                      }

                      final expenseDocs = expensesSnapshot.data?.docs ?? [];
                      final profit = earnings - expenses;

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Summary",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'GHS ${profit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Net Profit',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 12),

                            // Breakdown row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Earnings: GHS ${earnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFA5D6A7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Expenses: GHS ${expenses.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFAB91),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // List of individual expenses, if any
                            if (expenseDocs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...expenseDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '• ${data['type'] ?? 'Expense'}',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'GHS ${(data['amount'] ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // Quick stats row (live)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('driverId', isEqualTo: uid)
                    .where(
                      'date',
                      isEqualTo: DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.now()),
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  int tripCount = 0;
                  double totalDistance = 0;

                  if (snapshot.hasData) {
                    tripCount = snapshot.data!.docs.length;
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalDistance += (data['distance'] ?? 0).toDouble();
                    }
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.route,
                          label: 'Trips Today',
                          value: '$tripCount',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.speed,
                          label: 'Distance',
                          value: '${totalDistance.toStringAsFixed(1)} km',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Recent Trips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('driverId', isEqualTo: uid)
                    .orderBy('date', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E42),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'No trips logged yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E42),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${data['startPoint'] ?? ''} → ${data['destination'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              'GHS ${(data['earnings'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF66BB6A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
