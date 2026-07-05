import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Runs every day at 8:00 AM Accra time
export const checkMaintenanceReminders = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "Africa/Accra",
  },
  async () => {
    const today = new Date();
    const sevenDaysFromNow = new Date();
    sevenDaysFromNow.setDate(today.getDate() + 7);

    const todayStr = today.toISOString().split("T")[0];
    const sevenDaysStr = sevenDaysFromNow.toISOString().split("T")[0];

    const maintenanceSnap = await db
      .collection("maintenance")
      .where("nextDueDate", "<=", sevenDaysStr)
      .get();

    if (maintenanceSnap.empty) {
      console.log("No maintenance records due soon.");
      return;
    }

    for (const doc of maintenanceSnap.docs) {
      const record = doc.data();
      const vehicleId = record.vehicleId;
      const serviceType = record.serviceType;
      const nextDueDate = record.nextDueDate;
      const isOverdue = nextDueDate < todayStr;

      const vehicleDoc = await db.collection("vehicles").doc(vehicleId).get();
      if (!vehicleDoc.exists) continue;

      const vehicle = vehicleDoc.data()!;
      const ownerId = vehicle.ownerId;
      const assignedDriverId = vehicle.assignedDriverId;

      const uidsToNotify = new Set<string>();
      if (ownerId) uidsToNotify.add(ownerId);
      if (assignedDriverId) uidsToNotify.add(assignedDriverId);

      for (const uid of uidsToNotify) {
        const userDoc = await db.collection("users").doc(uid).get();
        if (!userDoc.exists) continue;

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) continue;

        const title = isOverdue
          ? `⚠️ Overdue: ${serviceType}`
          : `🔧 Service Due Soon: ${serviceType}`;

        const body = isOverdue
          ? `This service was due on ${nextDueDate}. Please schedule it immediately.`
          : `This service is due on ${nextDueDate}. Schedule it within 7 days.`;

        try {
          await messaging.send({
            token: fcmToken,
            notification: { title, body },
            android: {
              notification: {
                channelId: "maintenance_reminders",
                priority: "high",
              },
            },
            apns: {
              payload: {
                aps: { sound: "default" },
              },
            },
          });
          console.log(`Notification sent to ${uid} for ${serviceType}`);
        } catch (err) {
          console.error(`Failed to send to ${uid}:`, err);
        }
      }
    }
  }
);