import 'package:flutter/material.dart';
import '../maintenance/add_maintenance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  final Map<String, dynamic> data;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = '${data['make']} ${data['model']}';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(vehicleLabel, style: const TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4FC3F7),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMaintenanceScreen(
              vehicleId: vehicleId,
              vehicleLabel: vehicleLabel,
            ),
          ),
        ),
        icon: const Icon(Icons.add, color: Color(0xFF0D1B2A)),
        label: const Text('Log Service', style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Vehicle Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data['year']} $vehicleLabel',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('${data['plate']} • ${data['color']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Service History',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('maintenance')
                  .where('vehicleId', isEqualTo: vehicleId)
                  .orderBy('serviceDate', descending: true)
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
                      child: Text('No service records yet', style: TextStyle(color: Colors.white38)),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final m = doc.data() as Map<String, dynamic>;
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['serviceType'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                Text('${m['serviceDate']} • ${m['mileage']} km',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('GHS ${(m['cost'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.w700)),
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
    );
  }
}