import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows a bottom sheet for assigning a vehicle to a driver,
/// or a driver to a vehicle — same logic, two entry points.
///
/// Pass either [vehicleId] (to pick a driver for this vehicle)
/// or [driverId] (to pick a vehicle for this driver) — not both.
class AssignVehicleSheet extends StatelessWidget {
  final String? vehicleId;
  final String? driverId;

  const AssignVehicleSheet({super.key, this.vehicleId, this.driverId})
    : assert(
        (vehicleId != null) != (driverId != null),
        'Pass either vehicleId OR driverId, not both and not neither',
      );

  @override
  Widget build(BuildContext context) {
    final ownerUid = FirebaseAuth.instance.currentUser?.uid;

    // If vehicleId is passed: show list of owner's drivers to assign to this vehicle
    // If driverId is passed: show list of owner's vehicles to assign to this driver
    final bool assigningDriverToVehicle = vehicleId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF112236),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assigningDriverToVehicle ? 'Assign Driver' : 'Assign Vehicle',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            assigningDriverToVehicle
                ? 'Select a driver to assign to this vehicle'
                : 'Select a vehicle to assign to this driver',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: assigningDriverToVehicle
                ? FirebaseFirestore.instance
                      .collection('users')
                      .where('ownerId', isEqualTo: ownerUid)
                      .snapshots()
                : FirebaseFirestore.instance
                      .collection('vehicles')
                      .where('ownerId', isEqualTo: ownerUid)
                      .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    assigningDriverToVehicle
                        ? 'No drivers in your fleet yet'
                        : 'No vehicles in your fleet yet',
                    style: const TextStyle(color: Colors.white38),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final label = assigningDriverToVehicle
                      ? (data['name'] ?? 'Driver')
                      : '${data['year']} ${data['make']} ${data['model']} • ${data['plate']}';
                  final subtitle = assigningDriverToVehicle
                      ? (data['phone'] ?? '')
                      : (data['assignedDriverId'] != null
                            ? 'Currently assigned'
                            : 'Unassigned');
                  final isCurrentlyAssigned = assigningDriverToVehicle
                      ? data['ownerId'] != null
                      : data['assignedDriverId'] != null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(
                        0xFF4FC3F7,
                      ).withValues(alpha: 0.15),
                      child: Icon(
                        assigningDriverToVehicle
                            ? Icons.person
                            : Icons.directions_car,
                        color: const Color(0xFF4FC3F7),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isCurrentlyAssigned
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFB74D,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Assigned',
                              style: TextStyle(
                                color: Color(0xFFFFB74D),
                                fontSize: 11,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _handleAssignment(
                      context,
                      selectedId: doc.id,
                      selectedLabel: label,
                      isCurrentlyAssigned: isCurrentlyAssigned,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleAssignment(
    BuildContext context, {
    required String selectedId,
    required String selectedLabel,
    required bool isCurrentlyAssigned,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E42),
        title: Text(
          isCurrentlyAssigned ? 'Reassign?' : 'Assign?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isCurrentlyAssigned
              ? '$selectedLabel is currently assigned. This will remove their existing assignment and reassign them. Continue?'
              : 'Assign $selectedLabel?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (vehicleId != null) {
        // Assigning a driver to this vehicle
        // First: remove this vehicle from any driver currently assigned to it
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get();
        final previousDriverId =
            (vehicleDoc.data() as Map<String, dynamic>)['assignedDriverId'];

        final batch = FirebaseFirestore.instance.batch();

        // Update the vehicle
        batch.update(
          FirebaseFirestore.instance.collection('vehicles').doc(vehicleId),
          {'assignedDriverId': selectedId},
        );

        if (previousDriverId != null && previousDriverId != selectedId) {
          // No additional update needed — vehicle just changes assignedDriverId
          // The old driver simply loses access since the vehicle no longer points to them
        }

        await batch.commit();
      } else {
        // Assigning a vehicle to this driver
        // First: unassign this driver from any vehicle they're currently on
        final currentVehicles = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('assignedDriverId', isEqualTo: driverId)
            .get();

        final batch = FirebaseFirestore.instance.batch();

        // Remove driver from their current vehicle(s)
        for (final doc in currentVehicles.docs) {
          batch.update(doc.reference, {'assignedDriverId': null});
        }

        // Assign them to the new vehicle
        batch.update(
          FirebaseFirestore.instance.collection('vehicles').doc(selectedId),
          {'assignedDriverId': driverId},
        );

        await batch.commit();
      }

      if (context.mounted) {
        Navigator.pop(context); // close the sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment updated successfully'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
