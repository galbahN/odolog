import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows maintenance records that are due within 7 days or overdue,
/// for a given list of vehicle IDs.
class MaintenanceAlerts extends StatelessWidget {
  final List<String> vehicleIds;

  const MaintenanceAlerts({super.key, required this.vehicleIds});

  @override
  Widget build(BuildContext context) {
    if (vehicleIds.isEmpty) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maintenance')
          .where('vehicleId', whereIn: vehicleIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final today = DateTime.now();
        final sevenDaysFromNow = today.add(const Duration(days: 7));

        final alerts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dueDateStr = data['nextDueDate'] as String?;
          if (dueDateStr == null) return false;
          final dueDate = DateTime.tryParse(dueDateStr);
          if (dueDate == null) return false;
          return dueDate.isBefore(sevenDaysFromNow);
        }).toList();

        if (alerts.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB74D),
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Maintenance Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = DateTime.parse(data['nextDueDate']);
              final isOverdue = dueDate.isBefore(today);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E42),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverdue
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.error_outline
                          : Icons.build_circle_outlined,
                      color: isOverdue
                          ? Colors.redAccent
                          : const Color(0xFFFFB74D),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['serviceType'] ?? 'Service',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isOverdue
                                ? 'Overdue — was due ${data['nextDueDate']}'
                                : 'Due: ${data['nextDueDate']}',
                            style: TextStyle(
                              color: isOverdue
                                  ? Colors.redAccent
                                  : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
