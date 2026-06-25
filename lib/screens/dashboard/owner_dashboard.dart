import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../owner/add_driver_screen.dart';
import '../vehicles/vehicles_screen.dart';
import '../vehicles/add_vehicle_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4FC3F7),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Overview',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
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

              const SizedBox(height: 24),

              const _FleetStatsCard(),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Drivers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.person_add_alt,
                      color: Color(0xFF4FC3F7),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDriverScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(
                      'ownerId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
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
                          'No drivers added yet',
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
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(
                                0xFF4FC3F7,
                              ).withValues(alpha: 0.15),
                              child: Text(
                                (data['name'] ?? 'D')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Driver',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    data['phone'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              const _DriverPerformanceList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetStatsCard extends StatelessWidget {
  const _FleetStatsCard();

  @override
  Widget build(BuildContext context) {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('ownerId', isEqualTo: ownerUid)
          .snapshots(),
      builder: (context, driversSnapshot) {
        final driverIds =
            driversSnapshot.data?.docs.map((d) => d.id).toList() ?? [];

        if (driverIds.isEmpty) {
          return _buildCard(0, 0);
        }

        // Firestore 'whereIn' supports up to 30 values - fine for now
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trips')
              .where('driverId', whereIn: driverIds)
              .where('date', isEqualTo: today)
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
                  .where('driverId', whereIn: driverIds)
                  .where('date', isEqualTo: today)
                  .snapshots(),
              builder: (context, expensesSnapshot) {
                double expenses = 0;
                if (expensesSnapshot.hasData) {
                  for (var doc in expensesSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    expenses += (data['amount'] ?? 0).toDouble();
                  }
                }

                return _buildCard(earnings, expenses);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(double earnings, double expenses) {
    final profit = earnings - expenses;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet Revenue Today',
            style: TextStyle(color: Colors.white70, fontSize: 13),
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
            'Net Profit (All Drivers)',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}

class _DriverPerformanceList extends StatelessWidget {
  const _DriverPerformanceList();

  @override
  Widget build(BuildContext context) {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('ownerId', isEqualTo: ownerUid)
          .snapshots(),
      builder: (context, driversSnapshot) {
        final drivers = driversSnapshot.data?.docs ?? [];

        if (drivers.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Performance Today',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...drivers.map((driverDoc) {
              final driverData = driverDoc.data() as Map<String, dynamic>;
              return _DriverPerformanceTile(
                driverId: driverDoc.id,
                name: driverData['name'] ?? 'Driver',
                today: today,
              );
            }),
          ],
        );
      },
    );
  }
}

class _DriverPerformanceTile extends StatelessWidget {
  final String driverId;
  final String name;
  final String today;

  const _DriverPerformanceTile({
    required this.driverId,
    required this.name,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .where('date', isEqualTo: today)
          .snapshots(),
      builder: (context, snapshot) {
        double earnings = 0;
        int tripCount = 0;
        if (snapshot.hasData) {
          tripCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            earnings += (data['earnings'] ?? 0).toDouble();
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E42),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(
                  0xFF4FC3F7,
                ).withValues(alpha: 0.15),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$tripCount trip${tripCount != 1 ? 's' : ''} today',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'GHS ${earnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF66BB6A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
