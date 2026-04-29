import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isListening = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    // Request permissions for Android 13+
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('🔔 NOTIFICATION TRIGGERED: $title - $body');
    
    if (kIsWeb) {
      // On Web, we rely on the debugPrint above for testing
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'cancellation_notifications',
      'Event Cancellations',
      channelDescription: 'Notifications for cancelled or deleted events',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  void startListening() {
    if (_isListening) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isListening = true;
    debugPrint('🔔 NotificationService: Started listening for user ${user.uid}');
    
    FirebaseFirestore.instance
        .collection('notificaciones')
        .where('userId', isEqualTo: user.uid)
        .where('leida', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔔 NotificationService: Received snapshot with ${snapshot.docs.length} docs');
      for (var change in snapshot.docChanges) {
        debugPrint('🔔 NotificationService: Change detected: ${change.type}');
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          debugPrint('🔔 NotificationService: New notification data: $data');
          showNotification(
            id: change.doc.id.hashCode,
            title: 'Plan Cancelled',
            body: data['mensaje'] ?? 'A plan you were joined to has been cancelled.',
          );
          
          // Mark as processed in Firestore
          change.doc.reference.update({'leida': true});
        }
      }
    }, onDone: () {
      debugPrint('🔔 NotificationService: Listener closed');
      _isListening = false;
    }, onError: (e) {
      debugPrint('🔔 NotificationService: Error in listener: $e');
      _isListening = false;
    });
  }
}
