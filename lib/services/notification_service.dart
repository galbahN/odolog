import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> registerDeviceForNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Ask permission (mainly matters on iOS; Android grants by default)
  await FirebaseMessaging.instance.requestPermission();

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'fcmToken': token,
  });
}
